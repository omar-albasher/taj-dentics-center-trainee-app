import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QueuedAttendance {
  final String id;
  final String qrToken;
  final DateTime scannedAt;
  final int retryCount;

  const QueuedAttendance({
    required this.id,
    required this.qrToken,
    required this.scannedAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'qr_token': qrToken,
        'scanned_at': scannedAt.toIso8601String(),
        'retry_count': retryCount,
      };

  factory QueuedAttendance.fromJson(Map<String, dynamic> json) =>
      QueuedAttendance(
        id: json['id'] as String,
        qrToken: json['qr_token'] as String,
        scannedAt: DateTime.parse(json['scanned_at'] as String),
        retryCount: (json['retry_count'] as num?)?.toInt() ?? 0,
      );

  QueuedAttendance copyWith({int? retryCount}) => QueuedAttendance(
        id: id,
        qrToken: qrToken,
        scannedAt: scannedAt,
        retryCount: retryCount ?? this.retryCount,
      );
}

class AttendanceQueueService {
  AttendanceQueueService._();
  static final AttendanceQueueService instance = AttendanceQueueService._();

  static const String _queueKey = 'offline_attendance_queue';
  SupabaseClient get _client => Supabase.instance.client;
  bool _isProcessing = false;

  Future<List<QueuedAttendance>> getQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_queueKey);
      if (raw == null || raw.isEmpty) return [];
      final List decoded = jsonDecode(raw);
      return decoded
          .map((e) => QueuedAttendance.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveQueue(List<QueuedAttendance> queue) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(queue.map((e) => e.toJson()).toList());
    await prefs.setString(_queueKey, encoded);
  }

  Future<void> enqueue({
    required String qrToken,
    required DateTime scannedAt,
  }) async {
    final queue = await getQueue();
    // Prevent duplicate entries for the same token in queue
    final existingIndex = queue.indexWhere((e) => e.qrToken == qrToken);
    if (existingIndex >= 0) {
      return;
    }

    final newItem = QueuedAttendance(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      qrToken: qrToken,
      scannedAt: scannedAt,
    );
    queue.add(newItem);
    await _saveQueue(queue);
  }

  Future<int> getPendingCount() async {
    final queue = await getQueue();
    return queue.length;
  }

  Timer? _syncTimer;

  void startPeriodicSync({Duration interval = const Duration(minutes: 2)}) {
    _syncTimer?.cancel();
    processQueue();
    _syncTimer = Timer.periodic(interval, (_) => processQueue());
  }

  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Processes pending items in the offline queue and sends them to smart-responder.
  /// Returns the number of successfully synced attendance items.
  Future<int> processQueue() async {
    if (_isProcessing) return 0;
    _isProcessing = true;

    try {
      final queue = await getQueue();
      if (queue.isEmpty) return 0;

      final now = DateTime.now();
      final resolvedIds = <String>{};
      int syncedCount = 0;

      for (final item in queue) {
        // Drop items that have exceeded 24 hours to prevent stale retry loops
        final ageHours = now.difference(item.scannedAt).inHours;
        if (ageHours > 24) {
          resolvedIds.add(item.id);
          continue;
        }

        try {
          final response = await _client.functions.invoke(
            'smart-responder',
            body: {
              'qr_token': item.qrToken,
              'scanned_at': item.scannedAt.toUtc().toIso8601String(),
            },
          );

          final data = response.data is Map<String, dynamic>
              ? response.data as Map<String, dynamic>
              : <String, dynamic>{};

          if (data['success'] == true) {
            // Either recorded newly or already recorded (200) -> mark resolved
            syncedCount++;
            resolvedIds.add(item.id);
          }
        } on FunctionException catch (fe) {
          final details = fe.details;
          if (details is Map && details['already_recorded'] == true) {
            // Already recorded -> mark resolved
            syncedCount++;
            resolvedIds.add(item.id);
          } else if (fe.status == 400 || fe.status == 403) {
            // Unrecoverable (e.g. not enrolled, expired grace period, invalid token) -> Drop
            resolvedIds.add(item.id);
          }
        } catch (_) {
          // Network connection error / offline -> Retain for subsequent sync
        }
      }

      // Race-condition safe: only remove resolved items from the fresh queue,
      // preserving any items that were newly enqueued while processing was in-flight.
      if (resolvedIds.isNotEmpty) {
        final freshQueue = await getQueue();
        freshQueue.removeWhere((item) => resolvedIds.contains(item.id));
        await _saveQueue(freshQueue);
      }

      return syncedCount;
    } finally {
      _isProcessing = false;
    }
  }
}


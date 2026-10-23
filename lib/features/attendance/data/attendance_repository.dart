import 'package:supabase_flutter/supabase_flutter.dart';
import 'attendance_queue_service.dart';

class AttendanceRepository {
  final _client = Supabase.instance.client;
  final _queueService = AttendanceQueueService.instance;

  Future<Map<String, dynamic>> recordAttendance(String qrToken) async {
    final scannedAt = DateTime.now().toUtc();

    try {
      final response = await _client.functions.invoke(
        'smart-responder',
        body: {
          'qr_token': qrToken,
          'scanned_at': scannedAt.toIso8601String(),
        },
      );

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : {'success': true, 'data': response.data};

      // Trigger background sync for any other pending queue items while connection is good
      _queueService.processQueue();

      return data;
    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map && details['already_recorded'] == true) {
        return {
          'success': true,
          'already_recorded': true,
          'message': details['message'] ?? 'تم تسجيل حضورك مسبقاً في هذه الجلسة ✓',
        };
      }

      final errorMsg = (details is Map && details['error'] != null)
          ? details['error'].toString()
          : (details?.toString() ?? 'حدث خطأ أثناء تسجيل الحضور');

      return {'success': false, 'error': errorMsg};
    } catch (_) {
      // Network connectivity failure or offline -> enqueue locally
      await _queueService.enqueue(
        qrToken: qrToken,
        scannedAt: scannedAt,
      );

      return {
        'success': true,
        'offline_queued': true,
        'message':
            'لا يتوفر اتصال بالإنترنت حالياً. تم حفظ تسجيل الحضور بأمان على جهازك وسيتم المزامنة تلقائياً عند عودة الاتصال ✓',
      };
    }
  }

  Future<int> syncOfflineQueue() => _queueService.processQueue();
  Future<int> getPendingQueueCount() => _queueService.getPendingCount();
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized session manager for the currently authenticated trainee.
/// Ensures [trainee_safe_profile] is queried at most once per user session,
/// preventing redundant network roundtrips across repositories and screens.
class TraineeSession {
  static final TraineeSession instance = TraineeSession._();

  TraineeSession._() {
    // Automatically clear cached profile when user signs out
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut || data.session?.user == null) {
        clear();
      }
    });
  }

  String? _cachedUserId;
  String? _cachedTraineeId;
  Future<String?>? _inFlightRequest;

  String? get cachedTraineeId => _cachedTraineeId;

  /// Retrieves the current trainee's ID from [trainee_safe_profile].
  /// Guarantees deduplication if called concurrently across tabs/screens.
  Future<String?> getTraineeId({bool forceRefresh = false}) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      clear();
      return null;
    }

    // Invalidate cache if user switched
    if (_cachedUserId != user.id) {
      clear();
      _cachedUserId = user.id;
    }

    if (!forceRefresh && _cachedTraineeId != null) {
      return _cachedTraineeId;
    }

    if (_inFlightRequest != null) {
      return _inFlightRequest;
    }

    _inFlightRequest = () async {
      try {
        final trainee = await client
            .from('trainee_safe_profile')
            .select('id')
            .eq('user_id', user.id)
            .maybeSingle();

        _cachedTraineeId = trainee?['id'] as String?;
        return _cachedTraineeId;
      } finally {
        _inFlightRequest = null;
      }
    }();

    return _inFlightRequest;
  }

  /// Clears in-memory cached trainee data.
  void clear() {
    _cachedUserId = null;
    _cachedTraineeId = null;
    _inFlightRequest = null;
  }
}

/// Shared Riverpod provider for obtaining the current trainee ID.
final traineeIdProvider = FutureProvider<String?>((ref) async {
  return TraineeSession.instance.getTraineeId();
});

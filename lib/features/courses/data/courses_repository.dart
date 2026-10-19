import 'package:supabase_flutter/supabase_flutter.dart';

class CoursesRepository {
  final _client = Supabase.instance.client;

  String? _cachedTraineeId;

  Future<List<Map<String, dynamic>>> getMyEnrollments() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    if (_cachedTraineeId == null) {
      final trainee = await _client
          .from('trainee_safe_profile')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (trainee == null) return [];
      _cachedTraineeId = trainee['id'] as String?;
    }

    final traineeId = _cachedTraineeId;
    if (traineeId == null) return [];

    final response = await _client
        .from('trainee_academic_progress')
        .select()
        .eq('trainee_id', traineeId);

    return List<Map<String, dynamic>>.from(response);
  }
}

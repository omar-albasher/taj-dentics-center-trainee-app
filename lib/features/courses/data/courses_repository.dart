import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/trainee_session.dart';

class CoursesRepository {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMyEnrollments({String? explicitTraineeId}) async {
    final traineeId = explicitTraineeId ?? await TraineeSession.instance.getTraineeId();
    if (traineeId == null) return [];

    final response = await _client
        .from('trainee_academic_progress')
        .select()
        .eq('trainee_id', traineeId);

    return List<Map<String, dynamic>>.from(response);
  }
}

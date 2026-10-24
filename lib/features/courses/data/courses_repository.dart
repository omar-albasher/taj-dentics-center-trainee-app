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

    try {
      final enrollments = await _client
          .from('enrollments')
          .select('id, cohorts!inner(course_id)')
          .eq('trainee_id', traineeId);

      final courseIdByEnrollment = <String, String>{};
      for (final e in (enrollments as List)) {
        final id = e['id'] as String?;
        final cohorts = e['cohorts'] as Map<String, dynamic>?;
        final cId = cohorts?['course_id'] as String?;
        if (id != null && cId != null) {
          courseIdByEnrollment[id] = cId;
        }
      }

      return List<Map<String, dynamic>>.from(response).map((row) {
        final map = Map<String, dynamic>.from(row);
        final enrollId = map['enrollment_id'] as String?;
        if (enrollId != null && courseIdByEnrollment.containsKey(enrollId)) {
          map['course_id'] = courseIdByEnrollment[enrollId];
        }
        return map;
      }).toList();
    } catch (_) {
      return List<Map<String, dynamic>>.from(response);
    }
  }
}

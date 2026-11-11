import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/trainee_session.dart';
import '../domain/cohort_seat_status.dart';
import '../domain/trainee_waitlist_entry.dart';

class CoursesRepository {
  final _client = Supabase.instance.client;

  static const _releasedStatuses = {
    'dropped',
    'cancelled',
    'canceled',
    'withdrawn',
    'refunded',
  };

  Future<List<Map<String, dynamic>>> getMyEnrollments(
      {String? explicitTraineeId}) async {
    final traineeId =
        explicitTraineeId ?? await TraineeSession.instance.getTraineeId();
    if (traineeId == null) return [];

    final progress = await _client
        .from('trainee_academic_progress')
        .select()
        .eq('trainee_id', traineeId);

    final enrollmentsResponse = await _client
        .from('enrollments')
        .select('id, lifecycle_status')
        .eq('trainee_id', traineeId);

    final lifecycleMap = <String, String>{};
    for (final row in enrollmentsResponse) {
      final id = row['id'] as String?;
      final lifecycle = row['lifecycle_status'] as String?;
      if (id != null && lifecycle != null) {
        lifecycleMap[id] = lifecycle;
      }
    }

    final list = <Map<String, dynamic>>[];
    for (final item in progress) {
      final map = Map<String, dynamic>.from(item);
      final enrId = map['enrollment_id'] as String?;
      map['lifecycle_status'] =
          (enrId != null ? lifecycleMap[enrId] : null) ?? 'active';
      list.add(map);
    }

    return list;
  }

  /// Cohort IDs where the trainee currently occupies a seat.
  Future<Set<String>> getMyOccupiedCohortIds(
      {String? explicitTraineeId}) async {
    final traineeId =
        explicitTraineeId ?? await TraineeSession.instance.getTraineeId();
    if (traineeId == null) return <String>{};

    final response = await _client
        .from('enrollments')
        .select('cohort_id, status, lifecycle_status')
        .eq('trainee_id', traineeId);

    final cohortIds = <String>{};
    for (final row in response) {
      final cohortId = row['cohort_id'] as String?;
      final lifecycle =
          (row['lifecycle_status'] as String?)?.trim().toLowerCase() ?? 'active';
      final status =
          (row['status'] as String?)?.trim().toLowerCase() ?? 'active';
      final occupiesSeat = lifecycle != 'withdrawn' &&
          (status.isEmpty || !_releasedStatuses.contains(status));
      if (occupiesSeat && cohortId != null) {
        cohortIds.add(cohortId);
      }
    }
    return cohortIds;
  }

  Future<List<CohortSeatStatus>> getActiveCohorts() async {
    final response = await _client.rpc(
      'get_cohorts_seat_status',
      params: {'p_course_id': null},
    );

    return (response as List)
        .map((e) =>
            CohortSeatStatus.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<TraineeWaitlistEntry>> getMyWaitlist(
      {String? explicitTraineeId}) async {
    final traineeId =
        explicitTraineeId ?? await TraineeSession.instance.getTraineeId();
    if (traineeId == null) return [];

    final response = await _client
        .from('course_waitlist')
        .select(
          'id, cohort_id, status, joined_at, notified_at, expires_at, promoted_at',
        )
        .eq('trainee_id', traineeId)
        .inFilter('status', ['waiting', 'notified']).order('joined_at',
            ascending: true);

    return response
        .map((e) => TraineeWaitlistEntry.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, dynamic>> joinWaitlist(String cohortId) async {
    final response = await _client.rpc(
      'join_course_waitlist',
      params: {'p_cohort_id': cohortId},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> cancelWaitlist(String waitlistId) async {
    final response = await _client.rpc(
      'cancel_course_waitlist',
      params: {'p_waitlist_id': waitlistId},
    );
    return Map<String, dynamic>.from(response as Map);
  }
}

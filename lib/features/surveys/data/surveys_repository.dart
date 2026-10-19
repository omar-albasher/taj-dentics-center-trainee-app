import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/trainee_session.dart';
import '../domain/survey_model.dart';

class SurveysRepository {
  final _client = Supabase.instance.client;

  Future<List<SurveyDispatch>> getMySurveys({String? explicitTraineeId}) async {
    final traineeId = explicitTraineeId ?? await TraineeSession.instance.getTraineeId();
    if (traineeId == null) return [];

    final enrollments = await _client
        .from('enrollments')
        .select('id')
        .eq('trainee_id', traineeId);

    if ((enrollments as List).isEmpty) return [];

    final ids = enrollments.map((e) => e['id']).take(50).toList();

    final response = await _client
        .from('survey_dispatches')
        .select('*, survey_templates(title, questions)')
        .inFilter('enrollment_id', ids)
        .order('dispatched_at', ascending: false)
        .limit(50);

    return (response as List).map((e) => SurveyDispatch.fromMap(e)).toList();
  }

  Future<void> submitAnswer({
    required String dispatchId,
    required Map<String, dynamic> answers,
  }) async {
    await _client.rpc('submit_survey_response', params: {
      'p_dispatch_id': dispatchId,
      'p_answers': answers,
    });
  }
}

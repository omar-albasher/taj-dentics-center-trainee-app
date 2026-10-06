import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/survey_model.dart';

class SurveysRepository {
  final _client = Supabase.instance.client;

  String? _cachedTraineeId;

  Future<List<SurveyDispatch>> getMySurveys() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    if (_cachedTraineeId == null) {
      final trainee = await _client
          .from('trainees')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (trainee == null) return [];
      _cachedTraineeId = trainee['id'] as String?;
    }

    final traineeId = _cachedTraineeId;
    if (traineeId == null) return [];

    final enrollments = await _client
        .from('enrollments')
        .select('id')
        .eq('trainee_id', traineeId);

    if ((enrollments as List).isEmpty) return [];

    final ids = enrollments.map((e) => e['id']).toList();

    final response = await _client
        .from('survey_dispatches')
        .select('*, survey_templates(title, questions)')
        .inFilter('enrollment_id', ids)
        .order('dispatched_at', ascending: false);

    return (response as List).map((e) => SurveyDispatch.fromMap(e)).toList();
  }

  Future<void> submitAnswer({
    required String dispatchId,
    required Map<String, dynamic> answers,
  }) async {
    await _client.from('survey_responses').insert({
      'dispatch_id': dispatchId,
      'answers': answers,
    });

    await _client
        .from('survey_dispatches')
        .update({'status': 'answered'}).eq('id', dispatchId);
  }
}

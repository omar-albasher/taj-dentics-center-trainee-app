import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/trainee_session.dart';
import '../domain/payment_model.dart';

class PaymentsRepository {
  final _client = Supabase.instance.client;

  Future<List<EnrollmentFinancial>> getMyPayments({String? explicitTraineeId}) async {
    final traineeId = explicitTraineeId ?? await TraineeSession.instance.getTraineeId();
    if (traineeId == null) return [];

    final response = await _client
        .from('enrollment_financial_summary')
        .select()
        .eq('trainee_id', traineeId);

    return (response as List)
        .map((e) => EnrollmentFinancial.fromMap(e))
        .toList();
  }
}

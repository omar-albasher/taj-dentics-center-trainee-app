import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/payment_model.dart';

class PaymentsRepository {
  final _client = Supabase.instance.client;

  String? _cachedTraineeId;

  Future<List<EnrollmentFinancial>> getMyPayments() async {
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
        .from('enrollment_financial_summary')
        .select()
        .eq('trainee_id', traineeId);

    return (response as List)
        .map((e) => EnrollmentFinancial.fromMap(e))
        .toList();
  }
}

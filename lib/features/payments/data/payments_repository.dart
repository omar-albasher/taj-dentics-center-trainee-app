import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/trainee_session.dart';
import '../domain/payment_model.dart';

class PaymentsRepository {
  final _client = Supabase.instance.client;

  Future<List<EnrollmentFinancial>> getMyPayments({String? explicitTraineeId}) async {
    final traineeId = explicitTraineeId ?? await TraineeSession.instance.getTraineeId();
    if (traineeId == null) return [];

    final response = await _client
        .from('enrollment_financial_summary_v2')
        .select()
        .eq('trainee_id', traineeId);

    return (response as List)
        .map((e) => EnrollmentFinancial.fromMap(e))
        .toList();
  }

  /// كشف الحساب (تقرير 5) للسطور المالية المسجلة على تسجيلات المتدرب.
  /// يُعاد الترتيب تصاعدياً حسب التاريخ، وتعرضه الواجهة من الأحدث.
  Future<List<StatementEntry>> getMyStatement({
    String? explicitTraineeId,
  }) async {
    final traineeId =
        explicitTraineeId ?? await TraineeSession.instance.getTraineeId();
    if (traineeId == null) return [];

    final response = await _client
        .from('trainee_statement_v')
        .select()
        .eq('trainee_id', traineeId)
        .order('entry_date', ascending: true)
        .order('entry_id', ascending: true);

    return (response as List)
        .map((e) => StatementEntry.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// جدول الأقساط لجميع تسجيلات المتدرب.
  /// سياسة RLS على installment_schedule تقيّد النتائج إلى صفوف المتدرب نفسه.
  Future<List<InstallmentScheduleItem>> getMyInstallments({
    String? explicitTraineeId,
  }) async {
    final traineeId =
        explicitTraineeId ?? await TraineeSession.instance.getTraineeId();
    if (traineeId == null) return [];

    final response = await _client
        .from('installment_schedule')
        .select('*, payment_allocations(amount)')
        .order('installment_number', ascending: true);

    return (response as List)
        .map((e) =>
            InstallmentScheduleItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// جلب سجل إيصالات الدفعات التفصيلية للمتدرب
  Future<List<PaymentReceipt>> getMyReceipts({
    String? enrollmentId,
    String? explicitTraineeId,
  }) async {
    final traineeId = explicitTraineeId ?? await TraineeSession.instance.getTraineeId();
    if (traineeId == null) return [];

    var query = _client
        .from('trainee_payment_receipts')
        .select()
        .eq('trainee_id', traineeId);

    if (enrollmentId != null && enrollmentId.isNotEmpty) {
      query = query.eq('enrollment_id', enrollmentId);
    }

    final response = await query.order('paid_at', ascending: false);
    return (response as List)
        .map((e) => PaymentReceipt.fromMap(e))
        .toList();
  }
}

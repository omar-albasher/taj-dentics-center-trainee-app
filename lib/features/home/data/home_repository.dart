import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/trainee_session.dart';
import '../domain/referral_summary.dart';

class HomeRepository {
  final _client = Supabase.instance.client;

  Future<Map<String, dynamic>> getHomeStats({String? explicitTraineeId}) async {
    final user = _client.auth.currentUser;
    if (user == null) return _emptyStats();

    final traineeId =
        explicitTraineeId ?? await TraineeSession.instance.getTraineeId();
    if (traineeId == null) return _emptyStats(isUnlinked: true);

    // تشغيل الاستعلامات الثلاثة بالتوازي لتوفير زمن الانتظار
    final results = await Future.wait([
      _client
          .from('enrollments')
          .select('id, status')
          .eq('trainee_id', traineeId),
      _client
          .from('trainee_academic_progress')
          .select('attendance_percentage')
          .eq('trainee_id', traineeId),
      _client
          .from('enrollment_financial_summary')
          .select('payment_status')
          .eq('trainee_id', traineeId),
    ]);

    final enrollments = results[0] as List;
    final progress = results[1] as List;
    final financial = results[2] as List;

    final coursesCount = enrollments.length;

    double avgAttendance = 0;
    if (progress.isNotEmpty) {
      final total = progress.fold(
        0.0,
        (sum, e) =>
            sum + ((e['attendance_percentage'] as num?)?.toDouble() ?? 0),
      );
      avgAttendance = total / progress.length;
    }

    String paymentStatus = 'لا يوجد';
    if (financial.isNotEmpty) {
      final allComplete =
          financial.every((e) => e['payment_status'] == 'complete');
      final anyPartial = financial.any((e) => e['payment_status'] == 'partial');
      final anyUnpaid = financial.any((e) => e['payment_status'] == 'unpaid');

      if (allComplete) {
        paymentStatus = 'مكتمل';
      } else if (anyPartial) {
        paymentStatus = 'جزئي';
      } else if (anyUnpaid) {
        paymentStatus = 'غير مدفوع';
      }
    }

    return {
      'courses_count': coursesCount,
      'avg_attendance': avgAttendance.toStringAsFixed(0),
      'payment_status': paymentStatus,
    };
  }

  /// جلب الجلسة القادمة للمتدرب بناءً على تسجيلاته النشطة
  Future<Map<String, dynamic>?> getNextSession(
      {String? explicitTraineeId}) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final traineeId =
        explicitTraineeId ?? await TraineeSession.instance.getTraineeId();
    if (traineeId == null) return null;

    try {
      final res = await _client
          .from('trainee_next_sessions')
          .select()
          .eq('trainee_id', traineeId)
          .order('scheduled_at', ascending: true)
          .limit(1)
          .maybeSingle();

      return res != null ? Map<String, dynamic>.from(res) : null;
    } catch (_) {
      return null;
    }
  }

  /// ملخص كود الإحالة ورصيد الخصومات (يُخفى بهدوء عند غياب الجلسة أو الخطأ)
  Future<ReferralSummary?> getReferralSummary() async {
    if (_client.auth.currentUser == null) return null;

    try {
      final res = await _client.rpc('get_my_referral_summary');
      if (res is Map) {
        final summary = ReferralSummary.fromMap(Map<String, dynamic>.from(res));
        return summary.hasCode ? summary : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _emptyStats({bool isUnlinked = false}) => {
        'courses_count': 0,
        'avg_attendance': '0',
        'payment_status': 'لا يوجد',
        'is_unlinked': isUnlinked,
      };
}

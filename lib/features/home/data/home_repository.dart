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
          .select('id, status, lifecycle_status')
          .eq('trainee_id', traineeId),
      _client
          .from('trainee_academic_progress')
          .select('attendance_percentage')
          .eq('trainee_id', traineeId),
      _client
          .from('enrollment_financial_summary_v2')
          .select('payment_status')
          .eq('trainee_id', traineeId),
    ]);

    final enrollments = results[0] as List;
    final progress = results[1] as List;
    final financial = results[2] as List;

    final activeEnrollments = enrollments.where((e) {
      final lifecycle = (e['lifecycle_status'] as String?)?.toLowerCase();
      final status = (e['status'] as String?)?.toLowerCase();
      if (lifecycle == 'withdrawn') return false;
      if (status == 'dropped' || status == 'cancelled' || status == 'withdrawn') {
        return false;
      }
      return true;
    }).toList();

    final coursesCount = activeEnrollments.length;

    final activeEnrollmentIds = activeEnrollments
        .map((e) => e['id'] as String?)
        .whereType<String>()
        .toSet();

    double avgAttendance = 0;
    final activeProgress = progress.where((e) {
      final enrId = e['enrollment_id'] as String?;
      return enrId == null || activeEnrollmentIds.contains(enrId);
    }).toList();

    if (activeProgress.isNotEmpty) {
      final total = activeProgress.fold(
        0.0,
        (sum, e) =>
            sum + ((e['attendance_percentage'] as num?)?.toDouble() ?? 0),
      );
      avgAttendance = total / activeProgress.length;
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
          .order('scheduled_at', ascending: true);

      final list = List<Map<String, dynamic>>.from(res);
      if (list.isEmpty) return null;

      final enrs = await _client
          .from('enrollments')
          .select('cohort_id, status, lifecycle_status')
          .eq('trainee_id', traineeId);

      final activeCohorts = <String>{};
      for (final e in enrs) {
        final cId = e['cohort_id'] as String?;
        final lifecycle = (e['lifecycle_status'] as String?)?.toLowerCase();
        final status = (e['status'] as String?)?.toLowerCase();
        if (cId != null &&
            lifecycle != 'withdrawn' &&
            status != 'dropped' &&
            status != 'cancelled' &&
            status != 'withdrawn') {
          activeCohorts.add(cId);
        }
      }

      for (final item in list) {
        final cId = item['cohort_id'] as String?;
        if (cId != null && activeCohorts.contains(cId)) {
          return item;
        }
      }

      return null;
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

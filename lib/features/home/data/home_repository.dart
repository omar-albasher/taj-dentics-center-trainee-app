import 'package:supabase_flutter/supabase_flutter.dart';

class HomeRepository {
  final _client = Supabase.instance.client;

  String? _cachedTraineeId;

  Future<Map<String, dynamic>> getHomeStats() async {
    final user = _client.auth.currentUser;
    if (user == null) return _emptyStats();

    if (_cachedTraineeId == null) {
      final trainee = await _client
          .from('trainees')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (trainee == null) return _emptyStats();
      _cachedTraineeId = trainee['id'] as String?;
    }

    final traineeId = _cachedTraineeId;
    if (traineeId == null) return _emptyStats();

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

  Map<String, dynamic> _emptyStats() => {
        'courses_count': 0,
        'avg_attendance': '0',
        'payment_status': 'لا يوجد',
      };
}

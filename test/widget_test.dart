import 'package:trainee_app/features/attendance/data/attendance_queue_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainee_app/features/home/presentation/widgets/next_session_card.dart';
import 'package:trainee_app/features/intro/presentation/intro_screen.dart';
import 'package:trainee_app/features/payments/domain/payment_model.dart';
import 'package:trainee_app/features/payments/presentation/widgets/payment_receipt_dialog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NextSessionCard tests', () {
    testWidgets('renders fallback title when title is null or empty',
        (tester) async {
      final mockSession = {
        'session_id': 'sess-1',
        'cohort_id': 'cohort-1',
        'course_name': 'EXOCAD',
        'cohort_name': 'المجموعة A',
        'title': null,
        'description': 'مقدمة في تصميم الجسور والعدسات',
        'scheduled_at': '2026-10-25T14:00:00Z',
        'duration_minutes': 120,
        'status': 'scheduled',
        'is_extra': false,
        'is_attended': false,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NextSessionCard(session: mockSession),
          ),
        ),
      );

      expect(find.text('جلسة EXOCAD'), findsOneWidget);
      expect(find.text('EXOCAD • المجموعة A'), findsOneWidget);
      expect(find.text('مقدمة في تصميم الجسور والعدسات'), findsOneWidget);
      expect(find.text('مجدولة'), findsOneWidget);
      expect(find.text('ساعتان'), findsOneWidget);
    });

    testWidgets('renders custom title and extra badge when provided',
        (tester) async {
      final mockSession = {
        'session_id': 'sess-2',
        'cohort_id': 'cohort-1',
        'course_name': 'EXOCAD',
        'cohort_name': 'المجموعة A',
        'title': 'تصميم التاج الخزفي المتقدم',
        'description': null,
        'scheduled_at': '2026-10-26T16:00:00Z',
        'duration_minutes': 60,
        'status': 'scheduled',
        'is_extra': true,
        'is_attended': false,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NextSessionCard(session: mockSession),
          ),
        ),
      );

      expect(find.text('تصميم التاج الخزفي المتقدم'), findsOneWidget);
      expect(find.text('إضافية'), findsOneWidget);
      expect(find.text('ساعة'), findsOneWidget);
    });

    testWidgets('renders QR scan CTA when session is open and not attended',
        (tester) async {
      final mockSession = {
        'session_id': 'sess-3',
        'cohort_id': 'cohort-1',
        'course_name': 'EXOCAD',
        'cohort_name': 'المجموعة A',
        'title': 'جلسة تطبيقية',
        'scheduled_at': '2026-10-22T10:00:00Z',
        'duration_minutes': 120,
        'status': 'open',
        'is_extra': false,
        'is_attended': false,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NextSessionCard(session: mockSession),
          ),
        ),
      );

      expect(find.text('مفتوحة الآن'), findsOneWidget);
      expect(find.text('سجّل حضورك الآن بالمسح'), findsOneWidget);
    });

    testWidgets('renders attended message when session is open and attended',
        (tester) async {
      final mockSession = {
        'session_id': 'sess-4',
        'cohort_id': 'cohort-1',
        'course_name': 'EXOCAD',
        'cohort_name': 'المجموعة A',
        'title': 'جلسة تطبيقية',
        'scheduled_at': '2026-10-22T10:00:00Z',
        'duration_minutes': 120,
        'status': 'open',
        'is_extra': false,
        'is_attended': true,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NextSessionCard(session: mockSession),
          ),
        ),
      );

      expect(find.text('تم الحضور ✓'), findsOneWidget);
      expect(find.text('تم تسجيل حضورك في هذه الجلسة بنجاح'), findsOneWidget);
    });
  });

  group('IntroScreen tests (Phase 11)', () {
    testWidgets('renders first page correctly with skip and next button',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: IntroScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تسجيل الحضور الذكي'), findsOneWidget);
      expect(find.text('تخطي'), findsOneWidget);
      expect(find.text('التالي'), findsOneWidget);
    });

    testWidgets('swiping / clicking next advances across pages to finish button',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: IntroScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Page 1 -> click التالي
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();

      expect(find.text('متابعة تقدمك الأكاديمي والمالي'), findsOneWidget);
      expect(find.text('تخطي'), findsOneWidget);

      // Page 2 -> click التالي
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();

      expect(find.text('جدول الجلسات والاستبيانات'), findsOneWidget);
      // Skip is hidden on the last page
      expect(find.text('تخطي'), findsNothing);
      expect(find.text('ابدأ الآن'), findsOneWidget);
    });
  });

  group('PaymentReceipt tests (Phase A3)', () {
    final mockReceipt = PaymentReceipt(
      paymentId: 'pay-uuid-12345678',
      enrollmentId: 'enr-1',
      amount: 150000,
      currency: 'SYP',
      paidAt: DateTime(2026, 10, 22, 14, 30),
      paymentMethod: 'sham_cash',
      externalReference: 'SC-998877',
      notes: 'دفعة أولى',
      courseName: 'EXOCAD تصميم رقمي',
      cohortName: 'المجموعة A',
      traineeId: 'trainee-1',
      traineeCode: 'T10015',
      traineeName: 'عمر البشير',
    );

    test('PaymentReceipt model formats Arabic method and currency correctly', () {
      expect(mockReceipt.paymentMethodAr, 'شام كاش (Sham Cash)');
      expect(mockReceipt.currencySymbol, 'ل.س');
    });

    testWidgets('PaymentReceiptDialog renders all receipt details and actions',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentReceiptDialog(receipt: mockReceipt),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('إيصال سداد رسمي'), findsOneWidget);
      expect(find.text('مركز تاج دنتكس للتدريب الطبي التخصصي'), findsOneWidget);
      expect(find.text('عمر البشير'), findsOneWidget);
      expect(find.text('T10015'), findsOneWidget);
      expect(find.text('EXOCAD تصميم رقمي'), findsOneWidget);
      expect(find.text('150000 ل.س'), findsOneWidget);
      expect(find.text('شام كاش (Sham Cash)'), findsOneWidget);
      expect(find.text('SC-998877'), findsOneWidget);
      expect(find.text('حفظ الإيصال كصورة (PNG)'), findsOneWidget);
      expect(find.text('إغلاق'), findsOneWidget);
    });
  });

  group('Offline Attendance Queue tests (Phase A2)', () {
    test('QueuedAttendance serializes and deserializes correctly', () {
      final now = DateTime(2026, 10, 24, 10, 15);
      final item = QueuedAttendance(
        id: '123456789',
        qrToken: 'test-token-uuid',
        scannedAt: now,
        retryCount: 2,
      );

      final json = item.toJson();
      expect(json['id'], '123456789');
      expect(json['qr_token'], 'test-token-uuid');
      expect(json['scanned_at'], now.toIso8601String());
      expect(json['retry_count'], 2);

      final revived = QueuedAttendance.fromJson(json);
      expect(revived.id, item.id);
      expect(revived.qrToken, item.qrToken);
      expect(revived.scannedAt, item.scannedAt);
      expect(revived.retryCount, item.retryCount);
    });

    test('AttendanceQueueService enqueues and prevents duplicates', () async {
      final service = AttendanceQueueService.instance;
      final now = DateTime.now();

      await service.enqueue(qrToken: 'token-abc', scannedAt: now);
      var count = await service.getPendingCount();
      expect(count, 1);

      // Duplicate scan of same token shouldn't create new queue entry
      await service.enqueue(qrToken: 'token-abc', scannedAt: now);
      count = await service.getPendingCount();
      expect(count, 1);

      // Second unique token increments queue
      await service.enqueue(qrToken: 'token-def', scannedAt: now);
      count = await service.getPendingCount();
      expect(count, 2);
    });
  });

}

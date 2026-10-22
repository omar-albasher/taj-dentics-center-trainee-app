import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainee_app/features/home/presentation/widgets/next_session_card.dart';
import 'package:trainee_app/features/intro/presentation/intro_screen.dart';

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
}

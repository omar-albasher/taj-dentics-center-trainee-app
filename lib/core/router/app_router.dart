import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/intro/presentation/intro_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/attendance/presentation/qr_scanner_screen.dart';
import '../../features/courses/presentation/courses_screen.dart';
import '../../features/payments/presentation/payments_screen.dart';
import '../../features/surveys/presentation/surveys_screen.dart';
import '../../features/surveys/presentation/survey_form_screen.dart';
import '../../features/surveys/domain/survey_model.dart';
import '../../features/courses/presentation/course_materials_screen.dart';

class AppRouter {
  AppRouter._();

  static bool hasSeenIntro = false;

  static const intro = '/intro';
  static const login = '/login';
  static const home = '/home';
  static const qrScanner = '/qr-scanner';
  static const courses = '/courses';
  static const courseMaterials = '/course-materials';
  static const payments = '/payments';
  static const surveys = '/surveys';
  static const surveyForm = '/survey-form';

  static final router = GoRouter(
    initialLocation: home,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isIntro = state.matchedLocation == intro;
      final isLogin = state.matchedLocation == login;

      // إذا لم يشاهد المقدمة بعد ولم يكن مسجل الدخول، وجّهه للمقدمة
      if (!hasSeenIntro && session == null) {
        return isIntro ? null : intro;
      }

      // إذا كان بمسار المقدمة وقد شاهدها مسبقاً
      if (isIntro) {
        return session != null ? home : login;
      }

      if (session == null && !isLogin) return login;
      if (session != null) {
        final role = (session.user.userMetadata ?? const {})['role'] ??
            session.user.appMetadata['role'];
        if (role == 'admin' || role == 'reception') {
          Supabase.instance.client.auth.signOut();
          return login;
        }
        if (isLogin) return home;
      }
      return null;
    },
    refreshListenable: _AuthNotifier(),
    routes: [
      GoRoute(
        path: intro,
        builder: (_, __) => const IntroScreen(),
      ),
      GoRoute(
        path: login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: home,
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: qrScanner,
        builder: (_, __) => const QrScannerScreen(),
      ),
      GoRoute(
        path: courses,
        builder: (_, __) => const CoursesScreen(),
      ),
      GoRoute(
        path: courseMaterials,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final courseId = extra['course_id'] as String? ?? '';
          final courseName = extra['course_name'] as String? ?? 'مواد الكورس';
          return CourseMaterialsScreen(
            courseId: courseId,
            courseName: courseName,
          );
        },
      ),
      GoRoute(
        path: payments,
        builder: (_, __) => const PaymentsScreen(),
      ),
      GoRoute(
        path: surveys,
        builder: (_, __) => const SurveysScreen(),
      ),
      GoRoute(
        path: surveyForm,
        builder: (context, state) {
          final survey = state.extra;
          if (survey is SurveyDispatch) {
            return SurveyFormScreen(survey: survey);
          }
          return Scaffold(
            appBar: AppBar(title: const Text('الاستبيان')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'تعذر تحميل بيانات الاستبيان',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go(AppRouter.surveys),
                    child: const Text('العودة للاستبيانات'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: Center(
        child: Text(
          'الصفحة غير موجودة',
          style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
        ),
      ),
    ),
  );
}

class _AuthNotifier extends ChangeNotifier {
  late final dynamic _subscription;

  _AuthNotifier() {
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

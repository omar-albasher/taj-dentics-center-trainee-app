import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/attendance/presentation/qr_scanner_screen.dart';
import '../../features/courses/presentation/courses_screen.dart';
import '../../features/payments/presentation/payments_screen.dart';
import '../../features/surveys/presentation/surveys_screen.dart';
import '../../features/surveys/presentation/survey_form_screen.dart';
import '../../features/surveys/domain/survey_model.dart';

class AppRouter {
  AppRouter._();

  static const login = '/login';
  static const home = '/home';
  static const qrScanner = '/qr-scanner';
  static const courses = '/courses';
  static const payments = '/payments';
  static const surveys = '/surveys';
  static const surveyForm = '/survey-form';

  static final router = GoRouter(
    initialLocation: home,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLogin = state.matchedLocation == login;

      if (session == null && !isLogin) return login;
      if (session != null && isLogin) return home;
      return null;
    },
    refreshListenable: _AuthNotifier(),
    routes: [
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

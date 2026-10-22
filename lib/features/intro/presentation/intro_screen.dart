import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/responsive.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_IntroPageData> _pages = const [
    _IntroPageData(
      icon: Icons.qr_code_scanner_rounded,
      accentColor: AppColors.gold,
      title: 'تسجيل الحضور الذكي',
      subtitle:
          'امسح رمز الـ QR في قاعة التدريب لتسجيل حضورك في الجلسة لحظياً وبكل سهولة وموثوقية.',
      badgeText: 'سريع • دقيق • بدون أوراق',
    ),
    _IntroPageData(
      icon: Icons.analytics_outlined,
      accentColor: AppColors.darkGreen,
      title: 'متابعة تقدمك الأكاديمي والمالي',
      subtitle:
          'شاهد تفاصيل تسجيلاتك ونسبة حضورك في كل كورس، واطّلع على سجل الدفعات والمستحقات بشفافية تامة.',
      badgeText: 'شفافية كاملة • تحديث مباشر',
    ),
    _IntroPageData(
      icon: Icons.event_available_rounded,
      accentColor: AppColors.gold,
      title: 'جدول الجلسات والاستبيانات',
      subtitle:
          'تعرّف على مواعيد جلساتك القادمة ومواضيعها من الصفحة الرئيسية مباشرة، وشارك برأيك في استبيانات التطوير.',
      badgeText: 'تنظيم يومي • صوتك مسموع',
    ),
  ];

  Future<void> _completeIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_seen', true);
    AppRouter.hasSeenIntro = true;
    if (mounted) {
      context.go(AppRouter.login);
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _completeIntro();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: Responsive.pagePadding(context),
          child: Column(
            children: [
              // Top Bar: Center Logo + Skip Button
              SizedBox(height: Responsive.spacing(context, 12)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/Untitled-1.png',
                    height: Responsive.spacing(context, 38),
                  ),
                  if (!isLastPage)
                    TextButton(
                      onPressed: _completeIntro,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: const Text(
                        'تخطي',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),

              // Page Content Slider
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (idx) {
                    setState(() {
                      _currentPage = idx;
                    });
                  },
                  itemBuilder: (context, index) {
                    final data = _pages[index];
                    return _IntroPage(data: data);
                  },
                ),
              ),

              // Bottom Area: Indicators + Action Button
              Padding(
                padding: EdgeInsets.only(bottom: Responsive.spacing(context, 20)),
                child: Column(
                  children: [
                    // Smooth Dots Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentPage == index ? 28 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? AppColors.gold
                                : AppColors.divider,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: Responsive.spacing(context, 24)),

                    // Next / Get Started Button
                    SizedBox(
                      width: double.infinity,
                      height: Responsive.buttonHeight(context),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLastPage ? AppColors.gold : AppColors.cardBg,
                          foregroundColor: isLastPage ? Colors.black : AppColors.textPrimary,
                          side: BorderSide(
                            color: isLastPage ? AppColors.gold : AppColors.divider,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: isLastPage ? 3 : 0,
                        ),
                        onPressed: _nextPage,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLastPage ? 'ابدأ الآن' : 'التالي',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: Responsive.fontSize(context, 16),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(width: Responsive.spacing(context, 8)),
                            Icon(
                              isLastPage
                                  ? Icons.check_circle_outline
                                  : Icons.arrow_forward_ios_rounded,
                              size: Responsive.iconSize(context, 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroPageData {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final String badgeText;

  const _IntroPageData({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.badgeText,
  });
}

class _IntroPage extends StatelessWidget {
  final _IntroPageData data;

  const _IntroPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.spacing(context, 12),
          vertical: Responsive.spacing(context, 8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hero Glowing Icon Container
            Container(
              width: Responsive.spacing(context, 130),
              height: Responsive.spacing(context, 130),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.35),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    blurRadius: 32,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: Responsive.spacing(context, 90),
                  height: Responsive.spacing(context, 90),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cardBg,
                    border: Border.all(
                      color: AppColors.divider,
                    ),
                  ),
                  child: Icon(
                    data.icon,
                    size: Responsive.iconSize(context, 44),
                    color: AppColors.gold,
                  ),
                ),
              ),
            ),

            SizedBox(height: Responsive.spacing(context, 20)),

            // Feature Badge Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                data.badgeText,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ),

            SizedBox(height: Responsive.spacing(context, 14)),

            // Title
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: Responsive.fontSize(context, 20),
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),

            SizedBox(height: Responsive.spacing(context, 10)),

            // Subtitle / Description
            Text(
              data.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: Responsive.fontSize(context, 13),
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

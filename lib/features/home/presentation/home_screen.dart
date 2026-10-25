import '../../../core/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/responsive.dart';
import '../data/home_repository.dart';
import '../../attendance/data/attendance_queue_service.dart';
import 'widgets/next_session_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _homeRepo = HomeRepository();
  late Future<Map<String, dynamic>> _statsFuture;
  late Future<Map<String, dynamic>?> _nextSessionFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
        AttendanceQueueService.instance.startPeriodicSync();
  }

  @override
  void dispose() {
    AttendanceQueueService.instance.stopPeriodicSync();
    super.dispose();
  }

  void _loadData() {
    _statsFuture = _homeRepo.getHomeStats();
    _nextSessionFuture = _homeRepo.getNextSession();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
    await Future.wait([_statsFuture, _nextSessionFuture]);
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.gold, fontFamily: 'Cairo')),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟', style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('خروج', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await NotificationService.instance.unregisterDeviceToken();
        await Supabase.instance.client.auth.signOut();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('حدث خطأ أثناء تسجيل الخروج'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header
            SliverAppBar(
              expandedHeight: Responsive.spacing(context, 200),
              pinned: true,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A4A38), Color(0xFF2A2A2A)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: Responsive.pagePadding(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Image.asset(
                            'assets/images/Untitled-1.png',
                            height: Responsive.spacing(context, 55),
                          ),
                          SizedBox(height: Responsive.spacing(context, 10)),
                          Text(
                            'مرحباً 👋',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 22),
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 13),
                              color: AppColors.textSecondary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          SizedBox(height: Responsive.spacing(context, 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(
                      Icons.logout,
                      color: AppColors.gold,
                      size: Responsive.iconSize(context, 24),
                    ),
                    onPressed: _confirmLogout,
                  ),
                ),
              ],
            ),

          // Content
          SliverPadding(
            padding: Responsive.pagePadding(context).copyWith(
              top: Responsive.spacing(context, 20),
              bottom: Responsive.spacing(context, 20),
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats Row
                FutureBuilder<Map<String, dynamic>>(
                  future: _statsFuture,
                  builder: (context, snapshot) {
                    final stats = snapshot.data;
                    final loading =
                        snapshot.connectionState == ConnectionState.waiting;
                    final hasError = snapshot.hasError;
                    final isUnlinked = stats?['is_unlinked'] == true;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isUnlinked) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.warning),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: AppColors.warning, size: 24),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'حسابك قيد التفعيل. يُرجى مراجعة إدارة المركز لربط ملفك التدريبي.',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontFamily: 'Cairo',
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'الحضور',
                                value: loading
                                    ? '...'
                                    : hasError
                                        ? '-'
                                        : '${stats?['avg_attendance'] ?? 0}%',
                                icon: Icons.check_circle_outline,
                                color: AppColors.success,
                              ),
                            ),
                            SizedBox(width: Responsive.spacing(context, 12)),
                            Expanded(
                              child: _StatCard(
                                title: 'المدفوعات',
                                value: loading
                                    ? '...'
                                    : hasError
                                        ? '-'
                                        : '${stats?['payment_status'] ?? '-'}',
                                icon: Icons.payment_outlined,
                                color: AppColors.warning,
                              ),
                            ),
                            SizedBox(width: Responsive.spacing(context, 12)),
                            Expanded(
                              child: _StatCard(
                                title: 'الكورسات',
                                value: loading
                                    ? '...'
                                    : hasError
                                        ? '-'
                                        : '${stats?['courses_count'] ?? 0}',
                                icon: Icons.school_outlined,
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                SizedBox(height: Responsive.spacing(context, 16)),

                // Next Session Card (Phase A4)
                FutureBuilder<Map<String, dynamic>?>(
                  future: _nextSessionFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const NextSessionCard(session: null, isLoading: true);
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                      return const SizedBox.shrink();
                    }
                    return NextSessionCard(session: snapshot.data);
                  },
                ),

                SizedBox(height: Responsive.spacing(context, 8)),

                // Section title
                Text(
                  'الخدمات',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 18),
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                    fontFamily: 'Cairo',
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, 12)),

                // Menu Items
                _MenuItem(
                  data: _MenuItemData(
                    icon: Icons.qr_code_scanner,
                    title: AppStrings.scanQr,
                    subtitle: 'سجّل حضورك بمسح الرمز',
                    color: AppColors.gold,
                    onTap: () => context.push(AppRouter.qrScanner),
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, 12)),
                _MenuItem(
                  data: _MenuItemData(
                    icon: Icons.school_outlined,
                    title: AppStrings.myCourses,
                    subtitle: 'تابع تقدمك الأكاديمي',
                    color: AppColors.darkGreen,
                    onTap: () => context.push(AppRouter.courses),
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, 12)),
                _MenuItem(
                  data: _MenuItemData(
                    icon: Icons.payment_outlined,
                    title: AppStrings.payments,
                    subtitle: 'حالة مدفوعاتك',
                    color: const Color(0xFF8A8A8A),
                    onTap: () => context.push(AppRouter.payments),
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, 12)),
                _MenuItem(
                  data: _MenuItemData(
                    icon: Icons.assignment_outlined,
                    title: AppStrings.surveys,
                    subtitle: 'استبيانات الجلسات',
                    color: AppColors.gold,
                    onTap: () => context.push(AppRouter.surveys),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    ),
  );
}
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.spacing(context, 14)),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: Responsive.iconSize(context, 24)),
          SizedBox(height: Responsive.spacing(context, 6)),
          Text(
            value,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 13),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 11),
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  _MenuItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class _MenuItem extends StatelessWidget {
  final _MenuItemData data;

  const _MenuItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(Responsive.spacing(context, 18)),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.spacing(context, 12)),
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                data.icon,
                color: data.color,
                size: Responsive.iconSize(context, 26),
              ),
            ),
            SizedBox(width: Responsive.spacing(context, 16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 15),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  Text(
                    data.subtitle,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 12),
                      color: AppColors.textSecondary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.gold,
              size: Responsive.iconSize(context, 14),
            ),
          ],
        ),
      ),
    );
  }
}

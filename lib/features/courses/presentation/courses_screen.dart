import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../data/courses_repository.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final _repo = CoursesRepository();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getMyEnrollments();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _repo.getMyEnrollments();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'كورساتي',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: Responsive.fontSize(context, 18),
            color: AppColors.gold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.gold),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    const Text(
                      'تعذر تحميل بيانات الكورسات',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            );
          }

          final courses = snapshot.data ?? [];

          if (courses.isEmpty) {
            return RefreshIndicator(
              color: AppColors.gold,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.school_outlined,
                              size: Responsive.iconSize(context, 72),
                              color: AppColors.textSecondary),
                          SizedBox(height: Responsive.spacing(context, 16)),
                          Text(
                            'لا توجد كورسات مسجّلة',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 16),
                              color: AppColors.textSecondary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.gold,
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: Responsive.pagePadding(context).copyWith(
                top: Responsive.spacing(context, 20),
                bottom: Responsive.spacing(context, 20),
              ),
            itemCount: courses.length,
            separatorBuilder: (_, __) =>
                SizedBox(height: Responsive.spacing(context, 12)),
            itemBuilder: (context, index) {
              final course = courses[index];
              final attended =
                  (course['sessions_attended'] as num?)?.toInt() ?? 0;
              final total = (course['total_sessions'] as num?)?.toInt() ?? 1;
              final percentage =
                  (course['attendance_percentage'] as num?)?.toDouble() ?? 0;
              final extraAttended =
                  (course['extra_sessions_attended'] as num?)?.toInt() ?? 0;

              return Container(
                padding: EdgeInsets.all(Responsive.spacing(context, 20)),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course name
                    Text(
                      course['course_name'] ?? '',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 18),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    SizedBox(height: Responsive.spacing(context, 16)),

                    // Stats
                    Row(
                      children: [
                        _StatChip(
                          icon: Icons.check_circle_outline,
                          label: 'حضرت',
                          value: '$attended جلسة',
                          color: AppColors.success,
                        ),
                        SizedBox(width: Responsive.spacing(context, 8)),
                        _StatChip(
                          icon: Icons.schedule,
                          label: 'متبقي',
                          value: '${course['sessions_remaining']} جلسة',
                          color: AppColors.gold,
                        ),
                        if (extraAttended > 0) ...[
                          SizedBox(width: Responsive.spacing(context, 8)),
                          _StatChip(
                            icon: Icons.add_task,
                            label: 'إضافية',
                            value: '$extraAttended جلسة',
                            color: Colors.amber,
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: Responsive.spacing(context, 16)),

                    // Progress bar
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (percentage / 100).clamp(0.0, 1.0),
                              backgroundColor: AppColors.divider,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                percentage >= 75
                                    ? AppColors.success
                                    : percentage >= 50
                                        ? AppColors.warning
                                        : AppColors.error,
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        SizedBox(width: Responsive.spacing(context, 12)),
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 14),
                            fontWeight: FontWeight.w700,
                            color: AppColors.gold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.spacing(context, 4)),
                    Text(
                      extraAttended > 0
                          ? 'نسبة الحضور من $total جلسة أساسية (تشمل $extraAttended إضافية تعويضية)'
                          : 'نسبة الحضور من $total جلسة',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 12),
                        color: AppColors.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ),
  );
}
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.spacing(context, 12),
        vertical: Responsive.spacing(context, 8),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: Responsive.iconSize(context, 16)),
          SizedBox(width: Responsive.spacing(context, 6)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 11),
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 13),
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

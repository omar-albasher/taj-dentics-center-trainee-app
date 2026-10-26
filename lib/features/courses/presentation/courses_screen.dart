import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../core/utils/responsive.dart';
import '../data/courses_repository.dart';
import '../domain/cohort_seat_status.dart';
import '../domain/trainee_waitlist_entry.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen>
    with SingleTickerProviderStateMixin {
  final _repo = CoursesRepository();
  late final TabController _tabController;
  late Future<_CoursesData> _future;
  String? _busyCohortId;
  String? _busyWaitlistId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _future = _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<_CoursesData> _load() async {
    final critical = await Future.wait<Object>([
      _repo.getMyEnrollments(),
      _repo.getMyOccupiedCohortIds(),
    ]);

    final enrollments = critical[0] as List<Map<String, dynamic>>;
    final occupied = critical[1] as Set<String>;

    var cohorts = const <CohortSeatStatus>[];
    var waitlist = const <TraineeWaitlistEntry>[];
    Object? cohortsError;
    Object? waitlistError;

    final cohortsFuture = _repo.getActiveCohorts();
    final waitlistFuture = _repo.getMyWaitlist();

    try {
      cohorts = await cohortsFuture;
    } catch (e) {
      cohortsError = e;
    }

    try {
      waitlist = await waitlistFuture;
    } catch (e) {
      waitlistError = e;
    }

    return _CoursesData(
      enrollments: enrollments,
      occupiedCohortIds: occupied,
      cohorts: cohorts,
      waitlist: waitlist,
      cohortsError: cohortsError,
      waitlistError: waitlistError,
    );
  }

  Future<void> _refresh() async {
    final future = _load();
    if (mounted) {
      setState(() => _future = future);
    }
    try {
      await future;
    } catch (_) {
      // The FutureBuilder renders the failure; RefreshIndicator only needs completion.
    }
  }

  Future<void> _joinCohort(CohortSeatStatus cohort) async {
    final confirmed = await _confirmJoin(cohort);
    if (!confirmed || !mounted) return;

    setState(() => _busyCohortId = cohort.cohortId);
    try {
      final result = await _repo.joinWaitlist(cohort.cohortId);
      final alreadyJoined = result['already_joined'] == true;
      final position = (result['queue_position'] as num?)?.toInt();

      if (!mounted) return;
      _showMessage(
        alreadyJoined
            ? 'أنت موجود مسبقاً في قائمة الانتظار لهذه المجموعة'
            : position != null
                ? 'تم الانضمام إلى قائمة الانتظار — ترتيبك $position'
                : 'تم الانضمام إلى قائمة الانتظار',
      );
      await _refresh();
    } catch (e) {
      if (mounted) {
        _showMessage(AppErrorHandler.friendlyMessage(e), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _busyCohortId = null);
      }
    }
  }

  Future<void> _cancelWaitlist(
    TraineeWaitlistEntry entry,
    CohortSeatStatus? cohort,
  ) async {
    final confirmed = await _confirmCancel(cohort);
    if (!confirmed || !mounted) return;

    setState(() => _busyWaitlistId = entry.id);
    try {
      await _repo.cancelWaitlist(entry.id);
      if (!mounted) return;
      _showMessage('تم إلغاء طلب الانتظار');
      await _refresh();
    } catch (e) {
      if (mounted) {
        _showMessage(AppErrorHandler.friendlyMessage(e), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _busyWaitlistId = null);
      }
    }
  }

  Future<bool> _confirmJoin(CohortSeatStatus cohort) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text(
          'الانضمام لقائمة الانتظار',
          style: TextStyle(color: AppColors.gold, fontFamily: 'Cairo'),
        ),
        content: Text(
          'ستنضم إلى قائمة انتظار "${cohort.cohortName}" '
          'لكورس "${cohort.courseName}".\n\n'
          'سيتم إشعارك عند توفر مقعد، ويتم تثبيت التسجيل عبر الإدارة.',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Cairo',
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'إلغاء',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.background,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'انضمام',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _confirmCancel(CohortSeatStatus? cohort) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text(
          'إلغاء طلب الانتظار',
          style: TextStyle(color: AppColors.gold, fontFamily: 'Cairo'),
        ),
        content: Text(
          cohort == null
              ? 'هل تريد إلغاء طلب الانتظار؟'
              : 'هل تريد إلغاء طلب الانتظار لكورس '
                  '"${cohort.courseName}" — "${cohort.cohortName}"؟',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Cairo',
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'تراجع',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'إلغاء الطلب',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: isError ? AppColors.error : AppColors.primary,
        ),
      );
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: Responsive.fontSize(context, 14),
          ),
          tabs: const [
            Tab(text: 'كورساتي'),
            Tab(text: 'المجموعات المتاحة'),
          ],
        ),
      ),
      body: FutureBuilder<_CoursesData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          if (snapshot.hasError && !snapshot.hasData) {
            return _ScreenError(
              message: AppErrorHandler.friendlyMessage(snapshot.error),
              onRetry: _refresh,
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return _ScreenError(
              message: 'تعذر تحميل بيانات الكورسات',
              onRetry: _refresh,
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildMyCourses(context, data),
              _buildAvailableCohorts(context, data),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMyCourses(BuildContext context, _CoursesData data) {
    final gap = SizedBox(height: Responsive.spacing(context, 12));
    final cohortById = data.cohortsById;
    final children = <Widget>[];

    if (data.waitlistError != null) {
      children.add(
        _InlineError(
          message: AppErrorHandler.friendlyMessage(data.waitlistError),
          onRetry: _refresh,
        ),
      );
      children.add(gap);
    } else if (data.waitlist.isNotEmpty) {
      children.add(
        const _SectionTitle(
          title: 'قائمة الانتظار',
          icon: Icons.hourglass_top,
        ),
      );
      for (final entry in data.waitlist) {
        final cohort = cohortById[entry.cohortId];
        children.add(
          _WaitlistCard(
            entry: entry,
            cohort: cohort,
            busy: _busyWaitlistId == entry.id,
            onCancel: () => _cancelWaitlist(entry, cohort),
          ),
        );
        children.add(gap);
      }
      children.add(gap);
    }

    if (data.enrollments.isEmpty) {
      children.add(
        const _EmptyCard(
          icon: Icons.school_outlined,
          message: 'لا توجد كورسات مسجّلة',
        ),
      );
    } else {
      if (data.waitlist.isNotEmpty) {
        children.add(
          const _SectionTitle(
            title: 'كورساتي',
            icon: Icons.menu_book_outlined,
          ),
        );
      }
      for (final course in data.enrollments) {
        children.add(_EnrolledCourseCard(course: course));
        children.add(gap);
      }
    }

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: Responsive.pagePadding(context).copyWith(
          top: Responsive.spacing(context, 20),
          bottom: Responsive.spacing(context, 20),
        ),
        children: children,
      ),
    );
  }

  Widget _buildAvailableCohorts(BuildContext context, _CoursesData data) {
    final gap = SizedBox(height: Responsive.spacing(context, 12));
    final children = <Widget>[
      const _InfoBanner(
        message: 'قائمة الانتظار متاحة للمجموعات المكتملة فقط. عند توفر مقعد '
            'سيصلك إشعار، ويتم تثبيت التسجيل عبر الإدارة.',
      ),
      gap,
    ];

    if (data.cohortsError != null) {
      children.add(
        _InlineError(
          message: AppErrorHandler.friendlyMessage(data.cohortsError),
          onRetry: _refresh,
        ),
      );
      children.add(gap);
    }

    if (data.waitlistError != null) {
      children.add(
        _InlineError(
          message: 'تعذر تحميل حالة قائمة الانتظار الخاصة بك',
          onRetry: _refresh,
        ),
      );
      children.add(gap);
    }

    final grouped = <String, List<CohortSeatStatus>>{};
    for (final cohort in data.cohorts) {
      if (data.occupiedCohortIds.contains(cohort.cohortId)) continue;
      grouped.putIfAbsent(cohort.courseId, () => []).add(cohort);
    }

    if (grouped.isEmpty && data.cohortsError == null) {
      children.add(
        const _EmptyCard(
          icon: Icons.event_busy_outlined,
          message: 'لا توجد مجموعات متاحة حالياً',
        ),
      );
    } else {
      final waitlistByCohort = data.waitlistByCohort;
      for (final group in grouped.values) {
        children.add(_CourseGroupHeader(cohort: group.first));
        for (final cohort in group) {
          final entry = waitlistByCohort[cohort.cohortId];
          children.add(
            _AvailableCohortCard(
              cohort: cohort,
              entry: entry,
              joining: _busyCohortId == cohort.cohortId,
              cancelling: entry != null && _busyWaitlistId == entry.id,
              onJoin: () => _joinCohort(cohort),
              onCancel:
                  entry == null ? null : () => _cancelWaitlist(entry, cohort),
            ),
          );
          children.add(gap);
        }
        children.add(gap);
      }
    }

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: Responsive.pagePadding(context).copyWith(
          top: Responsive.spacing(context, 20),
          bottom: Responsive.spacing(context, 20),
        ),
        children: children,
      ),
    );
  }
}

class _CoursesData {
  final List<Map<String, dynamic>> enrollments;
  final Set<String> occupiedCohortIds;
  final List<CohortSeatStatus> cohorts;
  final List<TraineeWaitlistEntry> waitlist;
  final Object? cohortsError;
  final Object? waitlistError;

  const _CoursesData({
    required this.enrollments,
    required this.occupiedCohortIds,
    required this.cohorts,
    required this.waitlist,
    required this.cohortsError,
    required this.waitlistError,
  });

  Map<String, CohortSeatStatus> get cohortsById => {
        for (final cohort in cohorts) cohort.cohortId: cohort,
      };

  Map<String, TraineeWaitlistEntry> get waitlistByCohort => {
        for (final entry in waitlist) entry.cohortId: entry,
      };
}

class _EnrolledCourseCard extends StatelessWidget {
  final Map<String, dynamic> course;

  const _EnrolledCourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final attended = (course['sessions_attended'] as num?)?.toInt() ?? 0;
    final total = (course['total_sessions'] as num?)?.toInt() ?? 1;
    final percentage =
        (course['attendance_percentage'] as num?)?.toDouble() ?? 0;
    final extraAttended =
        (course['extra_sessions_attended'] as num?)?.toInt() ?? 0;
    final remaining = (course['sessions_remaining'] as num?)?.toInt() ?? 0;

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
          Wrap(
            spacing: Responsive.spacing(context, 8),
            runSpacing: Responsive.spacing(context, 8),
            children: [
              _StatChip(
                icon: Icons.check_circle_outline,
                label: 'حضرت',
                value: '$attended جلسة',
                color: AppColors.success,
              ),
              _StatChip(
                icon: Icons.schedule,
                label: 'متبقي',
                value: '$remaining جلسة',
                color: AppColors.gold,
              ),
              if (extraAttended > 0)
                _StatChip(
                  icon: Icons.add_task,
                  label: 'إضافية',
                  value: '$extraAttended جلسة',
                  color: Colors.amber,
                ),
            ],
          ),
          SizedBox(height: Responsive.spacing(context, 16)),
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
          const SizedBox(height: 14),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              final courseId = course['course_id'] as String? ?? '';
              final courseName = course['course_name'] as String? ?? '';
              context.push(
                AppRouter.courseMaterials,
                extra: {
                  'course_id': courseId,
                  'course_name': courseName,
                },
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_shared_outlined,
                    color: AppColors.gold,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'المواد والمرفقات التعليمية',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.gold,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitlistCard extends StatelessWidget {
  final TraineeWaitlistEntry entry;
  final CohortSeatStatus? cohort;
  final bool busy;
  final VoidCallback onCancel;

  const _WaitlistCard({
    required this.entry,
    required this.cohort,
    required this.busy,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final notified = entry.isNotified;
    final statusColor = notified ? AppColors.success : AppColors.gold;
    final dateFormat = DateFormat('yyyy/MM/dd', 'ar');
    final expiryFormat = DateFormat('yyyy/MM/dd - hh:mm a', 'ar');

    return Container(
      padding: EdgeInsets.all(Responsive.spacing(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notified
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                notified
                    ? Icons.notifications_active_outlined
                    : Icons.hourglass_top,
                color: statusColor,
                size: Responsive.iconSize(context, 22),
              ),
              SizedBox(width: Responsive.spacing(context, 8)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cohort?.courseName ?? 'كورس',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 16),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cohort?.cohortName ?? 'المجموعة لم تعد متاحة',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 12),
                        color: AppColors.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              if (busy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold,
                  ),
                )
              else
                TextButton(
                  onPressed: onCancel,
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(
                      color: AppColors.error,
                      fontFamily: 'Cairo',
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: Responsive.spacing(context, 10)),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatusPill(
                label: notified ? 'تم إشعارك بمقعد متاح' : 'في قائمة الانتظار',
                color: statusColor,
              ),
              if (entry.joinedAt != null)
                Text(
                  'انضممت: ${dateFormat.format(entry.joinedAt!)}',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 11),
                    color: AppColors.textSecondary,
                    fontFamily: 'Cairo',
                  ),
                ),
            ],
          ),
          SizedBox(height: Responsive.spacing(context, 10)),
          if (notified)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                entry.expiresAt != null
                    ? 'يرجى مراجعة الإدارة لتثبيت التسجيل قبل '
                        '${expiryFormat.format(entry.expiresAt!)}'
                    : 'يرجى مراجعة الإدارة لتثبيت التسجيل.',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 12),
                  color: AppColors.success,
                  fontFamily: 'Cairo',
                  height: 1.5,
                ),
              ),
            )
          else
            Text(
              'سيتم إشعارك عند توفر مقعد في هذه المجموعة.',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 12),
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
        ],
      ),
    );
  }
}

class _AvailableCohortCard extends StatelessWidget {
  final CohortSeatStatus cohort;
  final TraineeWaitlistEntry? entry;
  final bool joining;
  final bool cancelling;
  final VoidCallback onJoin;
  final VoidCallback? onCancel;

  const _AvailableCohortCard({
    required this.cohort,
    required this.entry,
    required this.joining,
    required this.cancelling,
    required this.onJoin,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final startFormat = DateFormat('EEEE، d MMMM yyyy', 'ar');
    final activeEntry = entry;
    final notified = activeEntry?.isNotified == true;

    return Container(
      padding: EdgeInsets.all(Responsive.spacing(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cohort.isFull
              ? AppColors.error.withValues(alpha: 0.4)
              : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cohort.cohortName,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 15),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              SizedBox(width: Responsive.spacing(context, 8)),
              _SeatChip(cohort: cohort),
            ],
          ),
          SizedBox(height: Responsive.spacing(context, 8)),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  cohort.cohortStartsAt != null
                      ? 'تبدأ: ${startFormat.format(cohort.cohortStartsAt!)}'
                      : 'موعد الانطلاق غير محدد',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 12),
                    color: AppColors.textSecondary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          if (cohort.waitlistCount > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${cohort.waitlistCount} متدرب في قائمة الانتظار',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 11),
                color: AppColors.warning,
                fontFamily: 'Cairo',
              ),
            ),
          ],
          SizedBox(height: Responsive.spacing(context, 12)),
          if (activeEntry != null)
            Row(
              children: [
                Expanded(
                  child: _StatusPill(
                    label: notified
                        ? 'تم إشعارك — بانتظار التثبيت'
                        : 'أنت في قائمة الانتظار',
                    color: notified ? AppColors.success : AppColors.gold,
                  ),
                ),
                if (cancelling)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.gold,
                    ),
                  )
                else
                  TextButton(
                    onPressed: onCancel,
                    child: const Text(
                      'إلغاء الطلب',
                      style: TextStyle(
                        color: AppColors.error,
                        fontFamily: 'Cairo',
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            )
          else if (cohort.isFull)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: joining ? null : onJoin,
                icon: joining
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.background,
                        ),
                      )
                    : const Icon(Icons.playlist_add),
                label: Text(
                  joining ? 'جارٍ الانضمام...' : 'انضم لقائمة الانتظار',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'توجد مقاعد متاحة — التسجيل يتم عبر الإدارة',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 12),
                      color: AppColors.textSecondary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CourseGroupHeader extends StatelessWidget {
  final CohortSeatStatus cohort;

  const _CourseGroupHeader({required this.cohort});

  @override
  Widget build(BuildContext context) {
    final price =
        NumberFormat('#,##0', 'ar').format(cohort.coursePrice.toInt());

    return Padding(
      padding: EdgeInsets.only(
        top: Responsive.spacing(context, 4),
        bottom: Responsive.spacing(context, 8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cohort.courseName,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 17),
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$price ل.س • ${cohort.courseTotalSessions} جلسة',
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 12),
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _SeatChip extends StatelessWidget {
  final CohortSeatStatus cohort;

  const _SeatChip({required this.cohort});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;

    if (cohort.isUnlimited) {
      label = 'مقاعد غير محدودة';
      color = AppColors.textSecondary;
    } else if (cohort.isFull) {
      label = 'مكتمل (${cohort.enrolledCount}/${cohort.capacity})';
      color = AppColors.error;
    } else {
      label = 'متبقي ${cohort.availableSeats ?? 0} من ${cohort.capacity}';
      color = AppColors.success;
    }

    return _StatusPill(label: label, color: color);
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: Responsive.fontSize(context, 11),
          color: color,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 18),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 15),
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String message;

  const _InfoBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.gold,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 12),
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: Responsive.spacing(context, 40),
        horizontal: Responsive.spacing(context, 20),
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: Responsive.iconSize(context, 56),
            color: AppColors.textSecondary,
          ),
          SizedBox(height: Responsive.spacing(context, 12)),
          Text(
            message,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 15),
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 12),
                color: AppColors.textPrimary,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'إعادة المحاولة',
              style: TextStyle(
                color: AppColors.gold,
                fontFamily: 'Cairo',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ScreenError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'إعادة المحاولة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
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

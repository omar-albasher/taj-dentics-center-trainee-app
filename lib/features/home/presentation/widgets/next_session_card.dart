import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/responsive.dart';

class NextSessionCard extends StatelessWidget {
  final Map<String, dynamic>? session;
  final bool isLoading;

  const NextSessionCard({
    super.key,
    required this.session,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: Responsive.spacing(context, 140),
        margin: EdgeInsets.only(bottom: Responsive.spacing(context, 16)),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
          ),
        ),
      );
    }

    if (session == null) {
      return const SizedBox.shrink();
    }

    final rawTitle = (session!['title'] as String?)?.trim();
    final courseName = (session!['course_name'] as String?)?.trim() ?? '';
    final cohortName = (session!['cohort_name'] as String?)?.trim() ?? '';
    final description = (session!['description'] as String?)?.trim();
    final isExtra = session!['is_extra'] == true;
    final status = (session!['status'] as String?) ?? 'scheduled';
    final isOpen = status == 'open';
    final isAttended = session!['is_attended'] == true;
    final durationMinutes = (session!['duration_minutes'] as num?)?.toInt() ?? 120;

    // Fallback: إذا لم تُدخل الإدارة عنواناً مخصصاً، يُعرض اسم الكورس كبديل افتراضي
    final displayTitle = (rawTitle != null && rawTitle.isNotEmpty)
        ? rawTitle
        : (courseName.isNotEmpty ? 'جلسة $courseName' : 'الجلسة القادمة');

    // Parse date & format in Arabic
    DateTime? scheduledDate;
    if (session!['scheduled_at'] != null) {
      scheduledDate = DateTime.tryParse(session!['scheduled_at'].toString())?.toLocal();
    }

    String formattedDate = '';
    String formattedTime = '';
    if (scheduledDate != null) {
      try {
        formattedDate = DateFormat('EEEE، d MMMM yyyy', 'ar').format(scheduledDate);
        formattedTime = DateFormat('hh:mm a', 'ar').format(scheduledDate);
      } catch (_) {
        formattedDate = scheduledDate.toIso8601String().split('T').first;
        formattedTime = '';
      }
    }

    String durationText;
    if (durationMinutes == 60) {
      durationText = 'ساعة';
    } else if (durationMinutes == 120) {
      durationText = 'ساعتان';
    } else if (durationMinutes % 60 == 0) {
      durationText = '${durationMinutes ~/ 60} ساعات';
    } else {
      durationText = '$durationMinutes د';
    }

    return Container(
      margin: EdgeInsets.only(bottom: Responsive.spacing(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOpen ? AppColors.gold : AppColors.divider,
          width: isOpen ? 1.5 : 1.0,
        ),
        boxShadow: isOpen
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Padding(
            padding: EdgeInsets.fromLTRB(
              Responsive.spacing(context, 16),
              Responsive.spacing(context, 14),
              Responsive.spacing(context, 16),
              Responsive.spacing(context, 8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_available_outlined,
                  color: AppColors.gold,
                  size: Responsive.iconSize(context, 20),
                ),
                SizedBox(width: Responsive.spacing(context, 8)),
                Text(
                  'الجلسة القادمة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: Responsive.fontSize(context, 13),
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
                const Spacer(),
                if (isExtra) ...[
                  _Badge(
                    text: 'إضافية',
                    backgroundColor: AppColors.warning.withValues(alpha: 0.2),
                    textColor: AppColors.warning,
                  ),
                  SizedBox(width: Responsive.spacing(context, 6)),
                ],
                if (isOpen && !isAttended)
                  _Badge(
                    text: 'مفتوحة الآن',
                    backgroundColor: AppColors.success.withValues(alpha: 0.2),
                    textColor: AppColors.success,
                    hasPulse: true,
                  )
                else if (isOpen && isAttended)
                  _Badge(
                    text: 'تم الحضور ✓',
                    backgroundColor: AppColors.success.withValues(alpha: 0.2),
                    textColor: AppColors.success,
                  )
                else
                  _Badge(
                    text: 'مجدولة',
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    textColor: AppColors.textSecondary,
                  ),
              ],
            ),
          ),

          const Divider(color: AppColors.divider, height: 1),

          // Body Content
          Padding(
            padding: EdgeInsets.all(Responsive.spacing(context, 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Session Title
                Text(
                  displayTitle,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: Responsive.fontSize(context, 16),
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),

                SizedBox(height: Responsive.spacing(context, 6)),

                // Course & Cohort
                if (courseName.isNotEmpty || cohortName.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: Responsive.iconSize(context, 15),
                        color: AppColors.silver,
                      ),
                      SizedBox(width: Responsive.spacing(context, 6)),
                      Expanded(
                        child: Text(
                          cohortName.isNotEmpty
                              ? '$courseName • $cohortName'
                              : courseName,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: Responsive.fontSize(context, 12),
                            color: AppColors.silver,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.spacing(context, 10)),
                ],

                // Scheduled Date & Time
                if (formattedDate.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.spacing(context, 10),
                      vertical: Responsive.spacing(context, 8),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: AppColors.gold,
                          size: Responsive.iconSize(context, 17),
                        ),
                        SizedBox(width: Responsive.spacing(context, 8)),
                        Expanded(
                          child: Text(
                            formattedTime.isNotEmpty
                                ? '$formattedDate - $formattedTime'
                                : formattedDate,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: Responsive.fontSize(context, 12),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            durationText,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: Responsive.fontSize(context, 11),
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Description (if available)
                if (description != null && description.isNotEmpty) ...[
                  SizedBox(height: Responsive.spacing(context, 10)),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(Responsive.spacing(context, 10)),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: Responsive.iconSize(context, 15),
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: Responsive.spacing(context, 8)),
                        Expanded(
                          child: Text(
                            description,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: Responsive.fontSize(context, 12),
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action button if session is currently OPEN and trainee not yet attended
                if (isOpen && !isAttended) ...[
                  SizedBox(height: Responsive.spacing(context, 14)),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(
                          vertical: Responsive.spacing(context, 10),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () => context.push(AppRouter.qrScanner),
                      icon: const Icon(Icons.qr_code_scanner, size: 20),
                      label: const Text(
                        'سجّل حضورك الآن بالمسح',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ] else if (isOpen && isAttended) ...[
                  SizedBox(height: Responsive.spacing(context, 10)),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'تم تسجيل حضورك في هذه الجلسة بنجاح',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final bool hasPulse;

  const _Badge({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.hasPulse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasPulse) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: textColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

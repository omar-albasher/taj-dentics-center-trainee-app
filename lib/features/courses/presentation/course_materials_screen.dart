import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../data/course_materials_repository.dart';
import '../domain/course_material_model.dart';

class CourseMaterialsScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String courseName;

  const CourseMaterialsScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  ConsumerState<CourseMaterialsScreen> createState() =>
      _CourseMaterialsScreenState();
}

class _CourseMaterialsScreenState
    extends ConsumerState<CourseMaterialsScreen> {
  String? _openingId;

  Future<void> _openMaterial(CourseMaterial material) async {
    setState(() => _openingId = material.id);

    try {
      Uri uri;
      if (material.isLink && material.externalUrl != null) {
        uri = Uri.parse(material.externalUrl!);
      } else if (material.isFile && material.filePath != null) {
        final signedUrl = await ref
            .read(courseMaterialsRepositoryProvider)
            .getSignedUrl(material.filePath!);
        uri = Uri.parse(signedUrl);
      } else {
        throw Exception('الرابط أو الملف غير متوفر');
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر فتح الرابط. يرجى التأكد من توفر متصفح مناسب على جهازك',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ أثناء فتح الملف: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _openingId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final materialsAsync =
        ref.watch(courseMaterialsProvider(widget.courseId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المواد التعليمية',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: Responsive.fontSize(context, 17),
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
              ),
            ),
            Text(
              widget.courseName,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: Responsive.fontSize(context, 12),
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.gold),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () async {
          ref.invalidate(courseMaterialsProvider(widget.courseId));
        },
        child: materialsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  const Text(
                    'تعذر تحميل المواد التعليمية',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref
                        .invalidate(courseMaterialsProvider(widget.courseId)),
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'إعادة المحاولة',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (materials) {
            if (materials.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open_outlined,
                            size: Responsive.iconSize(context, 72),
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: Responsive.spacing(context, 16)),
                          Text(
                            'لا توجد مواد تعليمية مضافة لهذا الكورس بعد',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 15),
                              color: AppColors.textSecondary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'سيتم إدراج المراجع والسلايدات هنا فور نشرها من قبل إدارة المركز',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 12),
                              color: AppColors.textSecondary.withValues(alpha: 0.7),
                              fontFamily: 'Cairo',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: Responsive.pagePadding(context).copyWith(
                top: Responsive.spacing(context, 16),
                bottom: Responsive.spacing(context, 24),
              ),
              itemCount: materials.length,
              separatorBuilder: (_, __) =>
                  SizedBox(height: Responsive.spacing(context, 12)),
              itemBuilder: (context, index) {
                final material = materials[index];
                final isOpening = _openingId == material.id;
                final dateStr =
                    DateFormat('dd MMM yyyy', 'ar').format(material.createdAt);

                return Container(
                  padding: EdgeInsets.all(Responsive.spacing(context, 16)),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      // File/Link Type Icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: material.iconColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          material.icon,
                          color: material.iconColor,
                          size: Responsive.iconSize(context, 26),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Material details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              material.title,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: Responsive.fontSize(context, 14),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (material.isFile &&
                                    material.fileSizeDisplay.isNotEmpty) ...[
                                  Text(
                                    material.fileSizeDisplay,
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: Responsive.fontSize(context, 11),
                                      color: AppColors.gold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('•',
                                      style: TextStyle(
                                          color: AppColors.textSecondary)),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: Responsive.fontSize(context, 11),
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            if (material.description != null &&
                                material.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                material.description!,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: Responsive.fontSize(context, 12),
                                  color: Colors.white70,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Action button
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor:
                              AppColors.gold.withValues(alpha: 0.15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: isOpening
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.gold,
                                ),
                              )
                            : Icon(
                                material.isLink
                                    ? Icons.open_in_new
                                    : Icons.download_outlined,
                                color: AppColors.gold,
                                size: Responsive.iconSize(context, 20),
                              ),
                        tooltip: material.isLink ? 'فتح الرابط' : 'تحميل ومعاينة',
                        onPressed: isOpening ? null : () => _openMaterial(material),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

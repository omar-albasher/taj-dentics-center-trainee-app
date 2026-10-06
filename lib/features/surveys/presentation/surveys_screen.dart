import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../data/surveys_repository.dart';
import '../domain/survey_model.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';

class SurveysScreen extends StatefulWidget {
  const SurveysScreen({super.key});

  @override
  State<SurveysScreen> createState() => _SurveysScreenState();
}

class _SurveysScreenState extends State<SurveysScreen> {
  final _repo = SurveysRepository();
  late Future<List<SurveyDispatch>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getMySurveys();
  }

  void _refresh() => setState(() => _future = _repo.getMySurveys());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الاستبيانات',
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
      body: FutureBuilder<List<SurveyDispatch>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          final surveys = snapshot.data ?? [];

          if (surveys.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: Responsive.iconSize(context, 72),
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: Responsive.spacing(context, 16)),
                  Text(
                    'لا توجد استبيانات حالياً',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 16),
                      color: AppColors.textSecondary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            );
          }

          final pending = surveys.where((s) => !s.isAnswered).toList();
          final answered = surveys.where((s) => s.isAnswered).toList();

          return ListView(
            padding: Responsive.pagePadding(context).copyWith(
              top: Responsive.spacing(context, 20),
              bottom: Responsive.spacing(context, 20),
            ),
            children: [
              if (pending.isNotEmpty) ...[
                _SectionTitle(title: 'بانتظار إجابتك', color: AppColors.gold),
                SizedBox(height: Responsive.spacing(context, 12)),
                ...pending.map((s) => _SurveyCard(
                      survey: s,
                      onTap: () async {
                        await context.push(AppRouter.surveyForm, extra: s);
                        _refresh();
                      },
                    )),
                SizedBox(height: Responsive.spacing(context, 24)),
              ],
              if (answered.isNotEmpty) ...[
                _SectionTitle(
                    title: 'الاستبيانات المكتملة', color: AppColors.success),
                SizedBox(height: Responsive.spacing(context, 12)),
                ...answered.map((s) => _SurveyCard(survey: s)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: Responsive.fontSize(context, 16),
        fontWeight: FontWeight.w700,
        color: color,
        fontFamily: 'Cairo',
      ),
    );
  }
}

class _SurveyCard extends StatelessWidget {
  final SurveyDispatch survey;
  final VoidCallback? onTap;

  const _SurveyCard({required this.survey, this.onTap});

  @override
  Widget build(BuildContext context) {
    final answered = survey.isAnswered;

    return GestureDetector(
      onTap: answered ? null : onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: Responsive.spacing(context, 12)),
        padding: EdgeInsets.all(Responsive.spacing(context, 18)),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: answered
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.gold.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.spacing(context, 12)),
              decoration: BoxDecoration(
                color: (answered ? AppColors.success : AppColors.gold)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                answered ? Icons.check_circle : Icons.assignment_outlined,
                color: answered ? AppColors.success : AppColors.gold,
                size: Responsive.iconSize(context, 26),
              ),
            ),
            SizedBox(width: Responsive.spacing(context, 16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    survey.surveyTitle,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 15),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  SizedBox(height: Responsive.spacing(context, 4)),
                  Text(
                    answered ? 'تم الإجابة ✓' : 'اضغط للإجابة',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 12),
                      color: answered
                          ? AppColors.success
                          : AppColors.textSecondary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
            if (!answered)
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

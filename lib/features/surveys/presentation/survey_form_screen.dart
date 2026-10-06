import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../data/surveys_repository.dart';
import '../domain/survey_model.dart';
import 'package:go_router/go_router.dart';

class SurveyFormScreen extends StatefulWidget {
  final SurveyDispatch survey;

  const SurveyFormScreen({super.key, required this.survey});

  @override
  State<SurveyFormScreen> createState() => _SurveyFormScreenState();
}

class _SurveyFormScreenState extends State<SurveyFormScreen> {
  final _repo = SurveysRepository();
  final Map<String, dynamic> _answers = {};
  bool _submitting = false;

  Future<void> _submit() async {
    for (final q in widget.survey.questions) {
      if (q['required'] == true && _answers[q['id']] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى الإجابة على جميع الأسئلة الإلزامية'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() => _submitting = true);

    try {
      await _repo.submitAnswer(
        dispatchId: widget.survey.dispatchId,
        answers: _answers,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('شكراً! تم إرسال إجابتك بنجاح ✓'),
          backgroundColor: AppColors.success,
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.survey.surveyTitle,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: Responsive.fontSize(context, 16),
            color: AppColors.gold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.gold),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: Responsive.pagePadding(context).copyWith(
          top: Responsive.spacing(context, 24),
          bottom: Responsive.spacing(context, 24),
        ),
        children: [
          ...widget.survey.questions.asMap().entries.map((entry) {
            final index = entry.key;
            final q = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: Responsive.spacing(context, 24)),
              child: _buildQuestion(context, q, index),
            );
          }),
          SizedBox(height: Responsive.spacing(context, 16)),
          SizedBox(
            height: Responsive.buttonHeight(context),
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'إرسال الإجابة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: Responsive.fontSize(context, 16),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(BuildContext context, Map q, int index) {
    final qId = q['id'] as String;
    final text = q['text'] as String;
    final type = q['type'] as String;
    final required = q['required'] == true;

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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.spacing(context, 6)),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 14),
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              SizedBox(width: Responsive.spacing(context, 10)),
              Expanded(
                child: Text(
                  '$text${required ? ' *' : ''}',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 15),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.spacing(context, 16)),
          if (type == 'rating') _buildRating(context, qId),
          if (type == 'text') _buildTextField(context, qId),
        ],
      ),
    );
  }

  Widget _buildRating(BuildContext context, String qId) {
    final current = (_answers[qId] as int?) ?? 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final val = i + 1;
        return GestureDetector(
          onTap: () => setState(() => _answers[qId] = val),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: Responsive.spacing(context, 4)),
            child: Icon(
              val <= current ? Icons.star : Icons.star_border,
              color: AppColors.gold,
              size: Responsive.iconSize(context, 36),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTextField(BuildContext context, String qId) {
    return TextField(
      maxLines: 3,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontFamily: 'Cairo',
        fontSize: Responsive.fontSize(context, 14),
      ),
      decoration: InputDecoration(
        hintText: 'اكتب ملاحظاتك هنا...',
        hintStyle: TextStyle(
          color: AppColors.textSecondary,
          fontFamily: 'Cairo',
          fontSize: Responsive.fontSize(context, 13),
        ),
      ),
      onChanged: (val) => _answers[qId] = val,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/referral_summary.dart';

class ReferralCard extends StatelessWidget {
  final ReferralSummary summary;

  const ReferralCard({super.key, required this.summary});

  String _formatAmount(double amount) =>
      NumberFormat('#,##0', 'ar').format(amount.toInt());

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: summary.referralCode));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم نسخ كود الإحالة',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
      ),
    );
  }

  Future<void> _shareCode(BuildContext context) async {
    final text =
        'سجّل في Taj Dentics باستخدام كود الإحالة الخاص بي: ${summary.referralCode}';
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');

    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }

    if (launched || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تعذر فتح واتساب — يمكنك نسخ الكود ومشاركته يدوياً',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.spacing(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard, color: AppColors.gold, size: 22),
              SizedBox(width: Responsive.spacing(context, 8)),
              Expanded(
                child: Text(
                  'ادعُ صديقاً واحصل على خصم',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 15),
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              IconButton(
                tooltip: 'نسخ الكود',
                onPressed: () => _copyCode(context),
                icon: const Icon(Icons.copy, color: AppColors.textSecondary),
              ),
            ],
          ),
          SizedBox(height: Responsive.spacing(context, 8)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.spacing(context, 14),
              vertical: Responsive.spacing(context, 12),
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: SelectableText(
              summary.referralCode,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 20),
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: AppColors.textPrimary,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          if (summary.hasAvailableCredits) ...[
            SizedBox(height: Responsive.spacing(context, 10)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: summary.availableCredits
                  .where((credit) => credit.amount > 0)
                  .map(
                    (credit) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'رصيد ${_formatAmount(credit.amount)} ${credit.currency}',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontFamily: 'Cairo',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (summary.qualifiedCount > 0) ...[
            SizedBox(height: Responsive.spacing(context, 8)),
            Text(
              'أصدقاء سجّلوا بكودك: ${summary.qualifiedCount}',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 12),
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
          ],
          SizedBox(height: Responsive.spacing(context, 12)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _shareCode(context),
              icon: const Icon(Icons.share, size: 18),
              label: const Text(
                'شارك الكود عبر واتساب',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../data/payments_repository.dart';
import '../domain/payment_model.dart';
import 'widgets/payment_receipt_dialog.dart';

class _PaymentsPageData {
  final List<EnrollmentFinancial> enrollments;
  final List<PaymentReceipt> receipts;

  const _PaymentsPageData({
    required this.enrollments,
    required this.receipts,
  });
}

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final _repo = PaymentsRepository();
  late Future<_PaymentsPageData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_PaymentsPageData> _loadData() async {
    final results = await Future.wait([
      _repo.getMyPayments(),
      _repo.getMyReceipts(),
    ]);

    return _PaymentsPageData(
      enrollments: results[0] as List<EnrollmentFinancial>,
      receipts: results[1] as List<PaymentReceipt>,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadData();
    });
    await _future;
  }

  Color _statusColor(EnrollmentFinancial e) {
    if (e.isComplete) return AppColors.success;
    if (e.isPartial) return AppColors.warning;
    return AppColors.error;
  }

  String _statusLabel(EnrollmentFinancial e) {
    if (e.isComplete) return 'مكتمل';
    if (e.isPartial) return 'جزئي';
    return 'غير مدفوع';
  }

  IconData _statusIcon(EnrollmentFinancial e) {
    if (e.isComplete) return Icons.check_circle;
    if (e.isPartial) return Icons.timelapse;
    return Icons.cancel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'المدفوعات والإيصالات',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: Responsive.fontSize(context, 18),
            color: AppColors.gold,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.gold),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<_PaymentsPageData>(
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
                      'تعذر تحميل بيانات المدفوعات',
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

          final data = snapshot.data;
          final enrollments = data?.enrollments ?? [];
          final receipts = data?.receipts ?? [];

          if (enrollments.isEmpty) {
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
                          Icon(
                            Icons.payment_outlined,
                            size: Responsive.iconSize(context, 72),
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: Responsive.spacing(context, 16)),
                          Text(
                            'لا توجد مدفوعات مسجلة',
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

          // Summary card
          final totalDue = enrollments.fold(0.0, (s, e) => s + e.totalDue);
          final totalPaid = enrollments.fold(0.0, (s, e) => s + e.totalPaid);
          final totalBal = enrollments.fold(0.0, (s, e) => s + e.balance);
          final defaultCurrency = enrollments.first.currencySymbol;

          return RefreshIndicator(
            color: AppColors.gold,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: Responsive.pagePadding(context).copyWith(
                top: Responsive.spacing(context, 20),
                bottom: Responsive.spacing(context, 20),
              ),
              children: [
                // Summary Card
                Container(
                  padding: EdgeInsets.all(Responsive.spacing(context, 20)),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A4A38), Color(0xFF2A2A2A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ملخص المدفوعات',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 16),
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      SizedBox(height: Responsive.spacing(context, 16)),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryItem(
                              label: 'الإجمالي',
                              value: '${totalDue.toStringAsFixed(0)} $defaultCurrency',
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Expanded(
                            child: _SummaryItem(
                              label: 'المدفوع',
                              value: '${totalPaid.toStringAsFixed(0)} $defaultCurrency',
                              color: AppColors.success,
                            ),
                          ),
                          Expanded(
                            child: _SummaryItem(
                              label: 'المتبقي',
                              value: '${totalBal.toStringAsFixed(0)} $defaultCurrency',
                              color: totalBal > 0
                                  ? AppColors.error
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.spacing(context, 12)),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: totalDue == 0
                              ? 0.0
                              : (totalPaid / totalDue).clamp(0.0, 1.0),
                          backgroundColor: AppColors.divider,
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.gold),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: Responsive.spacing(context, 24)),

                Text(
                  'تفاصيل الكورسات وسجل الإيصالات',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 16),
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                    fontFamily: 'Cairo',
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, 12)),

                // Course payment cards
                ...enrollments.map((e) {
                  final courseReceipts = receipts
                      .where((r) => r.enrollmentId == e.enrollmentId)
                      .toList();

                  return Padding(
                    padding: EdgeInsets.only(
                        bottom: Responsive.spacing(context, 14)),
                    child: Container(
                      padding: EdgeInsets.all(Responsive.spacing(context, 18)),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  e.courseName,
                                  style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 16),
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: Responsive.spacing(context, 10),
                                  vertical: Responsive.spacing(context, 4),
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(e).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _statusColor(e).withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _statusIcon(e),
                                      color: _statusColor(e),
                                      size: Responsive.iconSize(context, 14),
                                    ),
                                    SizedBox(
                                        width: Responsive.spacing(context, 4)),
                                    Text(
                                      _statusLabel(e),
                                      style: TextStyle(
                                        fontSize:
                                            Responsive.fontSize(context, 12),
                                        color: _statusColor(e),
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: Responsive.spacing(context, 16)),

                          // Amounts
                          Row(
                            children: [
                              Expanded(
                                child: _AmountItem(
                                  label: 'الرسوم',
                                  amount: e.totalDue,
                                  currency: e.currencySymbol,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Expanded(
                                child: _AmountItem(
                                  label: 'المدفوع',
                                  amount: e.totalPaid,
                                  currency: e.currencySymbol,
                                  color: AppColors.success,
                                ),
                              ),
                              Expanded(
                                child: _AmountItem(
                                  label: 'المتبقي',
                                  amount: e.balance,
                                  currency: e.currencySymbol,
                                  color: e.balance > 0
                                      ? AppColors.error
                                      : AppColors.success,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: Responsive.spacing(context, 12)),

                          // Progress
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: e.progressPercent,
                              backgroundColor: AppColors.divider,
                              valueColor:
                                  AlwaysStoppedAnimation(_statusColor(e)),
                              minHeight: 6,
                            ),
                          ),
                          SizedBox(height: Responsive.spacing(context, 4)),
                          Text(
                            '${(e.progressPercent * 100).toStringAsFixed(0)}% مدفوع',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 11),
                              color: AppColors.textSecondary,
                              fontFamily: 'Cairo',
                            ),
                          ),

                          // Receipts Section for this enrollment
                          if (courseReceipts.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Divider(color: AppColors.divider, height: 1),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.receipt_long_rounded,
                                  color: AppColors.gold,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'الإيصالات المسددة (${courseReceipts.length})',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...courseReceipts.map((receipt) => _ReceiptTile(
                                  receipt: receipt,
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => PaymentReceiptDialog(
                                        receipt: receipt,
                                      ),
                                    );
                                  },
                                )),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReceiptTile extends StatelessWidget {
  final PaymentReceipt receipt;
  final VoidCallback onTap;

  const _ReceiptTile({
    required this.receipt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String dateStr;
    try {
      dateStr = DateFormat('yyyy/MM/dd', 'ar').format(receipt.paidAt);
    } catch (_) {
      dateStr =
          '${receipt.paidAt.year}/${receipt.paidAt.month.toString().padLeft(2, '0')}/${receipt.paidAt.day.toString().padLeft(2, '0')}';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_outlined,
                color: AppColors.gold,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${receipt.amount.toStringAsFixed(0)} ${receipt.currencySymbol}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '$dateStr • ${receipt.paymentMethodAr}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'عرض الإيصال',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.gold,
                  size: 12,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: Responsive.fontSize(context, 16),
            fontWeight: FontWeight.w900,
            color: color,
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: Responsive.fontSize(context, 11),
            color: AppColors.textSecondary,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}

class _AmountItem extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final Color color;

  const _AmountItem({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
          '${amount.toStringAsFixed(0)} $currency',
          style: TextStyle(
            fontSize: Responsive.fontSize(context, 14),
            fontWeight: FontWeight.w700,
            color: color,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}

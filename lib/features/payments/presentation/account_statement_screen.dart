import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../data/payments_repository.dart';
import '../domain/payment_model.dart';

class _StatementPageData {
  final List<EnrollmentFinancial> enrollments;
  final List<StatementEntry> entries;
  final List<InstallmentScheduleItem> installments;

  const _StatementPageData({
    required this.enrollments,
    required this.entries,
    required this.installments,
  });
}

/// كشف حساب المتدرب (تقرير 5) وجدول الأقساط — للقراءة فقط.
class AccountStatementScreen extends StatefulWidget {
  const AccountStatementScreen({super.key});

  @override
  State<AccountStatementScreen> createState() => _AccountStatementScreenState();
}

class _AccountStatementScreenState extends State<AccountStatementScreen> {
  final _repo = PaymentsRepository();
  late Future<_StatementPageData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_StatementPageData> _loadData() async {
    final results = await Future.wait([
      _repo.getMyPayments(),
      _repo.getMyStatement(),
      _repo.getMyInstallments(),
    ]);

    return _StatementPageData(
      enrollments: results[0] as List<EnrollmentFinancial>,
      entries: results[1] as List<StatementEntry>,
      installments: results[2] as List<InstallmentScheduleItem>,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadData();
    });
    await _future;
  }

  String _date(DateTime date) {
    try {
      return DateFormat('yyyy/MM/dd', 'ar').format(date);
    } catch (_) {
      return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    }
  }

  String _money(double value, String symbol) =>
      '${value.toStringAsFixed(0)} $symbol';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'كشف الحساب',
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
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh, color: AppColors.gold),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<_StatementPageData>(
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
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'تعذر تحميل كشف الحساب',
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

          final data = snapshot.data ??
              const _StatementPageData(
                enrollments: [],
                entries: [],
                installments: [],
              );

          if (data.enrollments.isEmpty &&
              data.entries.isEmpty &&
              data.installments.isEmpty) {
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
                            Icons.receipt_long_outlined,
                            size: Responsive.iconSize(context, 72),
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: Responsive.spacing(context, 16)),
                          Text(
                            'لا توجد حركات مالية مسجلة',
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

          final enrollmentById = {
            for (final e in data.enrollments) e.enrollmentId: e,
          };

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
                ..._buildSummary(context, data.enrollments),
                SizedBox(height: Responsive.spacing(context, 24)),
                Text(
                  'جدول الأقساط',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 16),
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                    fontFamily: 'Cairo',
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, 12)),
                ..._buildInstallments(
                  context,
                  data.installments,
                  enrollmentById,
                ),
                SizedBox(height: Responsive.spacing(context, 24)),
                Text(
                  'كشف الحساب',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 16),
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                    fontFamily: 'Cairo',
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, 12)),
                ..._buildLedger(context, data.entries, enrollmentById),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSummary(
    BuildContext context,
    List<EnrollmentFinancial> enrollments,
  ) {
    if (enrollments.isEmpty) return const [];

    final groups = <String, List<EnrollmentFinancial>>{};
    for (final e in enrollments) {
      groups.putIfAbsent(e.currency, () => []).add(e);
    }

    return groups.entries.map((group) {
      final items = group.value;
      final due = items.fold(0.0, (s, e) => s + e.totalDue);
      final paid = items.fold(0.0, (s, e) => s + e.totalPaid);
      final balance = items.fold(0.0, (s, e) => s + e.balance);
      final symbol = items.first.currencySymbol;

      return Padding(
        padding: EdgeInsets.only(bottom: Responsive.spacing(context, 12)),
        child: Container(
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
                'ملخص الحساب (${group.key})',
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
                      value: _money(due, symbol),
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: _SummaryItem(
                      label: 'المدفوع',
                      value: _money(paid, symbol),
                      color: AppColors.success,
                    ),
                  ),
                  Expanded(
                    child: _SummaryItem(
                      label: 'المتبقي',
                      value: _money(balance, symbol),
                      color:
                          balance > 0 ? AppColors.error : AppColors.success,
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.spacing(context, 12)),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: due == 0 ? 0.0 : (paid / due).clamp(0.0, 1.0),
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildInstallments(
    BuildContext context,
    List<InstallmentScheduleItem> installments,
    Map<String, EnrollmentFinancial> enrollmentById,
  ) {
    if (installments.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.only(bottom: Responsive.spacing(context, 12)),
          child: const _EmptyHint(text: 'لا يوجد جدول أقساط مسجل بعد'),
        ),
      ];
    }

    final groups = <String, List<InstallmentScheduleItem>>{};
    for (final item in installments) {
      groups.putIfAbsent(item.enrollmentId, () => []).add(item);
    }

    return groups.entries.map((group) {
      final rows = group.value
        ..sort((a, b) => a.installmentNumber.compareTo(b.installmentNumber));
      final paidCount = rows.where((i) => i.isPaid).length;
      final courseName =
          enrollmentById[group.key]?.courseName ?? 'تسجيل';

      return Padding(
        padding: EdgeInsets.only(bottom: Responsive.spacing(context, 14)),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      courseName,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 15),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  Text(
                    '$paidCount/${rows.length} مسدد',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 11),
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 4),
              ...rows.map((item) => _InstallmentRow(
                    item: item,
                    dateText: _date(item.dueDate),
                    money: _money,
                  )),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildLedger(
    BuildContext context,
    List<StatementEntry> entries,
    Map<String, EnrollmentFinancial> enrollmentById,
  ) {
    if (entries.isEmpty) {
      return [
        const _EmptyHint(text: 'لا توجد حركات مالية مسجلة'),
      ];
    }

    final groups = <String, List<StatementEntry>>{};
    for (final entry in entries) {
      groups.putIfAbsent(entry.enrollmentId, () => []).add(entry);
    }

    return groups.entries.map((group) {
      final rows = group.value.toList().reversed.toList();
      final latest = rows.first;
      final courseName =
          enrollmentById[group.key]?.courseName ?? 'تسجيل';

      return Padding(
        padding: EdgeInsets.only(bottom: Responsive.spacing(context, 14)),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      courseName,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 15),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  Text(
                    'الرصيد: ${_money(latest.runningBalance, latest.currencySymbol)}',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 11),
                      color: latest.runningBalance > 0
                          ? AppColors.error
                          : AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(color: AppColors.divider, height: 1),
              ...rows.map((entry) => _LedgerRow(
                    entry: entry,
                    dateText: _date(entry.entryDate),
                    money: _money,
                  )),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _InstallmentRow extends StatelessWidget {
  final InstallmentScheduleItem item;
  final String dateText;
  final String Function(double, String) money;

  const _InstallmentRow({
    required this.item,
    required this.dateText,
    required this.money,
  });

  Color _statusColor() {
    if (item.isPaid) return AppColors.success;
    if (item.isOverdue) return AppColors.error;
    if (item.isPartiallyPaid) return AppColors.warning;
    return AppColors.textSecondary;
  }

  String _statusLabel() {
    if (item.isPaid) return 'مسدد';
    if (item.isOverdue) return 'متأخر';
    if (item.isPartiallyPaid) return 'جزئي';
    return 'قادم';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _statusColor().withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${item.installmentNumber}',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _statusColor(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateText,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _statusLabel(),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                money(item.amount, item.currencySymbol),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'مسدد ${item.paid.toStringAsFixed(0)} • متبقٍ ${item.remaining.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final StatementEntry entry;
  final String dateText;
  final String Function(double, String) money;

  const _LedgerRow({
    required this.entry,
    required this.dateText,
    required this.money,
  });

  IconData _icon() {
    switch (entry.entryType) {
      case 'initial_fee':
        return Icons.receipt_long_outlined;
      case 'discount':
        return Icons.percent;
      case 'fee_adjustment':
        return Icons.tune;
      case 'payment':
        return Icons.payments_outlined;
      case 'refund':
        return Icons.undo;
      default:
        return Icons.swap_horiz;
    }
  }

  Color _color() {
    switch (entry.entryType) {
      case 'discount':
      case 'payment':
        return AppColors.success;
      case 'refund':
        return AppColors.error;
      case 'fee_adjustment':
        return AppColors.warning;
      default:
        return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final sign = entry.isDebit ? '+' : '-';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(_icon(), size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$dateText • ${entry.typeLabel}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${money(entry.amount, entry.currencySymbol)}',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                'الرصيد ${money(entry.runningBalance, entry.currencySymbol)}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
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

class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.spacing(context, 18)),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: Responsive.fontSize(context, 13),
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

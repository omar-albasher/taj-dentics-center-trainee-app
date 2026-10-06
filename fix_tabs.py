import sys

file_path = r"d:\flutter-projects\admin_dashboard\lib\features\payments\presentation\payments_screen.dart"

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find section boundaries
tab1_start = None
tab2_start = None  
tab3_start = None
dialog_start = None

for i, line in enumerate(lines):
    if 'Tab 1: Recent Payments' in line:
        tab1_start = i
    elif 'Tab 2: Enrollments' in line:
        tab2_start = i
    elif 'Tab 3: Overdue' in line:
        tab3_start = i
    elif 'Add Payment Dialog' in line:
        dialog_start = i

print(f"Tab1: {tab1_start}, Tab2: {tab2_start}, Tab3: {tab3_start}, Dialog: {dialog_start}")

# Keep everything before tab1 and from dialog onwards
before = lines[:tab1_start]
after = lines[dialog_start:]

new_tabs = '''// ─── Tab 1: Recent Payments ───
class _RecentPaymentsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_RecentPaymentsTab> createState() => _RecentPaymentsTabState();
}

class _RecentPaymentsTabState extends ConsumerState<_RecentPaymentsTab> {
  final _searchCtrl = TextEditingController();
  String _methodFilter = 'all';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final params = PaymentFilterParams(
      search: _searchQuery.isEmpty ? null : _searchQuery,
      method: _methodFilter == 'all' ? null : _methodFilter,
    );
    final paymentsAsync = ref.watch(recentPaymentsProvider(params));
    final fmt = NumberFormat('#,###');

    return Column(
      children: [
        // ── Search & Filter Bar ──
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo'),
                decoration: InputDecoration(
                  hintText: 'بحث بالاسم، الكورس، رقم الوصل...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Cairo', fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold, width: 2)),
                ),
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _methodFilter,
                  dropdownColor: AppColors.cardBg,
                  style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo', fontSize: 13),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('الكل', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'cash', child: Text('نقداً', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'sham_cash', child: Text('شام كاش', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'hawala', child: Text('حوالة', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'transfer', child: Text('تحويل بنكي', style: TextStyle(fontFamily: 'Cairo'))),
                  ],
                  onChanged: (v) => setState(() => _methodFilter = v ?? 'all'),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.spacing(context, 12)),
        // ── List ──
        Expanded(
          child: paymentsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: AppColors.gold)),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text('خطأ: $e',
                      style: const TextStyle(
                          color: AppColors.error, fontFamily: 'Cairo')),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(recentPaymentsProvider),
                    child: const Text('إعادة المحاولة',
                        style: TextStyle(fontFamily: 'Cairo')),
                  ),
                ],
              ),
            ),
            data: (payments) {
              if (payments.isEmpty) {
                return Center(
                  child: Text('لا توجد دفعات مسجّلة',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontFamily: 'Cairo',
                          fontSize: Responsive.fontSize(context, 16))),
                );
              }

              return ListView.separated(
                itemCount: payments.length,
                separatorBuilder: (_, __) =>
                    SizedBox(height: Responsive.spacing(context, 8)),
                itemBuilder: (context, index) {
                  final p = payments[index];
                  final enrollment = p['enrollments'] as Map<String, dynamic>? ?? {};
                  final trainee =
                      enrollment['trainees'] as Map<String, dynamic>? ?? {};
                  final user = trainee['users'] as Map<String, dynamic>? ?? {};
                  final cohort = enrollment['cohorts'] as Map<String, dynamic>? ?? {};
                  final course = cohort['courses'] as Map<String, dynamic>? ?? {};

                  final name = user['full_name'] ?? 'متدرب';
                  final courseName = course['name'] ?? '';
                  final amount = (p['amount'] as num?)?.toDouble() ?? 0;
                  final currency = p['currency'] ?? 'SYP';
                  final date = DateTime.tryParse(p['paid_at'] ?? '');

                  return Container(
                    padding: EdgeInsets.all(Responsive.spacing(context, 16)),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.payment, color: AppColors.success),
                        ),
                        SizedBox(width: Responsive.spacing(context, 12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: TextStyle(
                                      fontSize: Responsive.fontSize(context, 15),
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      fontFamily: 'Cairo')),
                              Text(courseName,
                                  style: TextStyle(
                                      fontSize: Responsive.fontSize(context, 12),
                                      color: AppColors.textSecondary,
                                      fontFamily: 'Cairo')),
                              if (date != null)
                                Text(
                                  DateFormat('yyyy/MM/dd').format(date),
                                  style: TextStyle(
                                      fontSize: Responsive.fontSize(context, 11),
                                      color: AppColors.textSecondary,
                                      fontFamily: 'Cairo'),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${fmt.format(amount.toInt())} ${currency == 'USD' ? '\\$' : 'ل.س'}',
                              style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 16),
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.success,
                                  fontFamily: 'Cairo'),
                            ),
                            Text(
                              _getMethodLabel(p['method']),
                              style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 12),
                                  color: AppColors.textSecondary,
                                  fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _getMethodLabel(String? method) {
    switch (method) {
      case 'cash': return 'نقداً';
      case 'sham_cash': return 'شام كاش';
      case 'hawala': return 'حوالة';
      case 'transfer': return 'تحويل بنكي';
      default: return 'أخرى';
    }
  }
}

// ─── Tab 2: Enrollments ───
class _EnrollmentsTab extends ConsumerStatefulWidget {
  final Function(BuildContext, {String? enrollmentId, String? traineeName})
      onAddPayment;

  const _EnrollmentsTab({required this.onAddPayment});

  @override
  ConsumerState<_EnrollmentsTab> createState() => _EnrollmentsTabState();
}

class _EnrollmentsTabState extends ConsumerState<_EnrollmentsTab> {
  final _searchCtrl = TextEditingController();
  String _statusFilter = 'all';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final params = PaymentFilterParams(
      search: _searchQuery.isEmpty ? null : _searchQuery,
      status: _statusFilter == 'all' ? null : _statusFilter,
    );
    final enrollmentsAsync = ref.watch(allEnrollmentsProvider(params));
    final fmt = NumberFormat('#,###');

    return Column(
      children: [
        // ── Search & Filter Bar ──
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo'),
                decoration: InputDecoration(
                  hintText: 'بحث بالاسم أو الكورس...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Cairo', fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold, width: 2)),
                ),
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _statusFilter,
                  dropdownColor: AppColors.cardBg,
                  style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo', fontSize: 13),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('كل الحالات', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'unpaid', child: Text('غير مدفوع', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'partial', child: Text('جزئي', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'complete', child: Text('مكتمل', style: TextStyle(fontFamily: 'Cairo'))),
                  ],
                  onChanged: (v) => setState(() => _statusFilter = v ?? 'all'),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.spacing(context, 12)),
        // ── List ──
        Expanded(
          child: enrollmentsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: AppColors.gold)),
            error: (e, _) => Center(
              child: Text('خطأ: $e',
                  style:
                      const TextStyle(color: AppColors.error, fontFamily: 'Cairo')),
            ),
            data: (enrollments) {
              if (enrollments.isEmpty) {
                return Center(
                  child: Text('لا توجد تسجيلات',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontFamily: 'Cairo',
                          fontSize: Responsive.fontSize(context, 16))),
                );
              }

              return ListView.separated(
                itemCount: enrollments.length,
                separatorBuilder: (_, __) =>
                    SizedBox(height: Responsive.spacing(context, 8)),
                itemBuilder: (context, index) {
                  final e = enrollments[index];
                  final due = (e['net_due'] as num?)?.toDouble() ?? 0;
                  final paid = (e['total_paid'] as num?)?.toDouble() ?? 0;
                  final balance = (e['balance'] as num?)?.toDouble() ?? 0;
                  final status = e['payment_status'] ?? 'unpaid';
                  final currency = e['currency'] ?? 'SYP';
                  final sym = currency == 'USD' ? '\\$' : 'ل.س';

                  return Container(
                    padding: EdgeInsets.all(Responsive.spacing(context, 16)),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e['trainee_name'] ?? '',
                                      style: TextStyle(
                                          fontSize: Responsive.fontSize(context, 15),
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                          fontFamily: 'Cairo')),
                                  Text(e['course_name'] ?? '',
                                      style: TextStyle(
                                          fontSize: Responsive.fontSize(context, 12),
                                          color: AppColors.textSecondary,
                                          fontFamily: 'Cairo')),
                                ],
                              ),
                            ),
                            _StatusBadge(status: status),
                          ],
                        ),
                        SizedBox(height: Responsive.spacing(context, 12)),
                        Row(
                          children: [
                            _AmountInfo(
                                label: 'المستحق',
                                value: '${fmt.format(due.toInt())} $sym',
                                color: AppColors.textPrimary),
                            _AmountInfo(
                                label: 'المدفوع',
                                value: '${fmt.format(paid.toInt())} $sym',
                                color: AppColors.success),
                            _AmountInfo(
                                label: 'المتبقي',
                                value: '${fmt.format(balance.toInt())} $sym',
                                color: balance > 0
                                    ? AppColors.error
                                    : AppColors.success),
                          ],
                        ),
                        SizedBox(height: Responsive.spacing(context, 12)),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => widget.onAddPayment(
                              context,
                              enrollmentId: e['enrollment_id'],
                              traineeName: e['trainee_name'],
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('تسجيل دفعة',
                                style: TextStyle(fontFamily: 'Cairo')),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Tab 3: Overdue ───
class _OverdueTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_OverdueTab> createState() => _OverdueTabState();
}

class _OverdueTabState extends ConsumerState<_OverdueTab> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overdueAsync = ref.watch(overduePaymentsProvider(_searchQuery.isEmpty ? null : _searchQuery));
    final fmt = NumberFormat('#,###');

    return Column(
      children: [
        // ── Search Bar ──
        TextField(
          controller: _searchCtrl,
          style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo'),
          decoration: InputDecoration(
            hintText: 'بحث بالاسم أو الكود أو الكورس...',
            hintStyle: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Cairo', fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: AppColors.gold),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold, width: 2)),
          ),
          onChanged: (v) => setState(() => _searchQuery = v.trim()),
        ),
        SizedBox(height: Responsive.spacing(context, 12)),
        // ── List ──
        Expanded(
          child: overdueAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: AppColors.gold)),
            error: (e, _) => Center(
              child: Text('خطأ: $e',
                  style:
                      const TextStyle(color: AppColors.error, fontFamily: 'Cairo')),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Text('🎉 لا توجد مستحقات متأخرة',
                      style: TextStyle(
                          color: AppColors.success,
                          fontFamily: 'Cairo',
                          fontSize: Responsive.fontSize(context, 16))),
                );
              }

              return ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                    SizedBox(height: Responsive.spacing(context, 8)),
                itemBuilder: (context, index) {
                  final e = list[index];
                  final balance = (e['balance_due'] as num?)?.toDouble() ?? 0;
                  final phone = e['phone'] ?? '';

                  return Container(
                    padding: EdgeInsets.all(Responsive.spacing(context, 16)),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.error.withValues(alpha: 0.15),
                          child: Text('${index + 1}',
                              style: const TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Cairo')),
                        ),
                        SizedBox(width: Responsive.spacing(context, 12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e['trainee_name'] ?? '',
                                  style: TextStyle(
                                      fontSize: Responsive.fontSize(context, 15),
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      fontFamily: 'Cairo')),
                              Text(e['course_name'] ?? '',
                                  style: TextStyle(
                                      fontSize: Responsive.fontSize(context, 12),
                                      color: AppColors.textSecondary,
                                      fontFamily: 'Cairo')),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${fmt.format(balance.toInt())} ل.س',
                              style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 15),
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.error,
                                  fontFamily: 'Cairo'),
                            ),
                            if (phone.isNotEmpty)
                              GestureDetector(
                                onTap: () async {
                                  String formattedPhone =
                                      phone.replaceAll(RegExp(r'[^0-9]'), '');
                                  if (formattedPhone.startsWith('09')) {
                                    formattedPhone =
                                        '963${formattedPhone.substring(1)}';
                                  } else if (formattedPhone.startsWith('9') &&
                                      formattedPhone.length == 9) {
                                    formattedPhone = '963$formattedPhone';
                                  }
                                  final url =
                                      Uri.parse('https://wa.me/$formattedPhone');
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url);
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF25D366).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.chat,
                                          color: Color(0xFF25D366), size: 14),
                                      SizedBox(width: 4),
                                      Text('واتساب',
                                          style: TextStyle(
                                              color: Color(0xFF25D366),
                                              fontSize: 12,
                                              fontFamily: 'Cairo',
                                              fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

'''

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(before)
    f.write(new_tabs)
    f.writelines(after)

print("File updated successfully!")
print(f"Before: {len(before)} lines, After: {len(after)} lines")

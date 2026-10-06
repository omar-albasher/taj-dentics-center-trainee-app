$file = "d:\flutter-projects\admin_dashboard\lib\features\payments\presentation\payments_screen.dart"
$lines = [System.Collections.ArrayList]@(Get-Content $file)

# Tab sections: Tab1=116..247, Tab2=248..366, Tab3=367..502
# We'll replace from index 116 to 502 (inclusive) with new content

$newTabs = @"
// ─── Tab 1: Recent Payments ───
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
                  hintText: '\u0628\u062d\u062b \u0628\u0627\u0644\u0627\u0633\u0645\u060c \u0627\u0644\u0643\u0648\u0631\u0633\u060c \u0631\u0642\u0645 \u0627\u0644\u0648\u0635\u0644...',
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
                    DropdownMenuItem(value: 'all', child: Text('\u0627\u0644\u0643\u0644', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'cash', child: Text('\u0646\u0642\u062f\u0627\u064b', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'sham_cash', child: Text('\u0634\u0627\u0645 \u0643\u0627\u0634', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'hawala', child: Text('\u062d\u0648\u0627\u0644\u0629', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'transfer', child: Text('\u062a\u062d\u0648\u064a\u0644 \u0628\u0646\u0643\u064a', style: TextStyle(fontFamily: 'Cairo'))),
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
                  Text('\u062e\u0637\u0623: `$e',
                      style: const TextStyle(
                          color: AppColors.error, fontFamily: 'Cairo')),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(recentPaymentsProvider),
                    child: const Text('\u0625\u0639\u0627\u062f\u0629 \u0627\u0644\u0645\u062d\u0627\u0648\u0644\u0629',
                        style: TextStyle(fontFamily: 'Cairo')),
                  ),
                ],
              ),
            ),
            data: (payments) {
              if (payments.isEmpty) {
                return Center(
                  child: Text('\u0644\u0627 \u062a\u0648\u062c\u062f \u062f\u0641\u0639\u0627\u062a \u0645\u0633\u062c\u0651\u0644\u0629',
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

                  final name = user['full_name'] ?? '\u0645\u062a\u062f\u0631\u0628';
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
                              '`${fmt.format(amount.toInt())} `${currency == 'USD' ? '\\\$' : '\u0644.\u0633'}',
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
      case 'cash': return '\u0646\u0642\u062f\u0627\u064b';
      case 'sham_cash': return '\u0634\u0627\u0645 \u0643\u0627\u0634';
      case 'hawala': return '\u062d\u0648\u0627\u0644\u0629';
      case 'transfer': return '\u062a\u062d\u0648\u064a\u0644 \u0628\u0646\u0643\u064a';
      default: return '\u0623\u062e\u0631\u0649';
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
                  hintText: '\u0628\u062d\u062b \u0628\u0627\u0644\u0627\u0633\u0645 \u0623\u0648 \u0627\u0644\u0643\u0648\u0631\u0633...',
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
                    DropdownMenuItem(value: 'all', child: Text('\u0643\u0644 \u0627\u0644\u062d\u0627\u0644\u0627\u062a', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'unpaid', child: Text('\u063a\u064a\u0631 \u0645\u062f\u0641\u0648\u0639', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'partial', child: Text('\u062c\u0632\u0626\u064a', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'complete', child: Text('\u0645\u0643\u062a\u0645\u0644', style: TextStyle(fontFamily: 'Cairo'))),
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
              child: Text('\u062e\u0637\u0623: `$e',
                  style:
                      const TextStyle(color: AppColors.error, fontFamily: 'Cairo')),
            ),
            data: (enrollments) {
              if (enrollments.isEmpty) {
                return Center(
                  child: Text('\u0644\u0627 \u062a\u0648\u062c\u062f \u062a\u0633\u062c\u064a\u0644\u0627\u062a',
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
                  final sym = currency == 'USD' ? '\\\$' : '\u0644.\u0633';

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
                                label: '\u0627\u0644\u0645\u0633\u062a\u062d\u0642',
                                value: '`${fmt.format(due.toInt())} `$sym',
                                color: AppColors.textPrimary),
                            _AmountInfo(
                                label: '\u0627\u0644\u0645\u062f\u0641\u0648\u0639',
                                value: '`${fmt.format(paid.toInt())} `$sym',
                                color: AppColors.success),
                            _AmountInfo(
                                label: '\u0627\u0644\u0645\u062a\u0628\u0642\u064a',
                                value: '`${fmt.format(balance.toInt())} `$sym',
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
                            label: const Text('\u062a\u0633\u062c\u064a\u0644 \u062f\u0641\u0639\u0629',
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
            hintText: '\u0628\u062d\u062b \u0628\u0627\u0644\u0627\u0633\u0645 \u0623\u0648 \u0627\u0644\u0643\u0648\u062f \u0623\u0648 \u0627\u0644\u0643\u0648\u0631\u0633...',
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
              child: Text('\u062e\u0637\u0623: `$e',
                  style:
                      const TextStyle(color: AppColors.error, fontFamily: 'Cairo')),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Text('\ud83c\udf89 \u0644\u0627 \u062a\u0648\u062c\u062f \u0645\u0633\u062a\u062d\u0642\u0627\u062a \u0645\u062a\u0623\u062e\u0631\u0629',
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
                          child: Text('`${index + 1}',
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
                              '`${fmt.format(balance.toInt())} \u0644.\u0633',
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
                                        '963`${formattedPhone.substring(1)}';
                                  } else if (formattedPhone.startsWith('9') &&
                                      formattedPhone.length == 9) {
                                    formattedPhone = '963`$formattedPhone';
                                  }
                                  final url =
                                      Uri.parse('https://wa.me/`$formattedPhone');
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
                                      Text('\u0648\u0627\u062a\u0633\u0627\u0628',
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

"@

# Build new content: keep lines 0-115 (before Tab1), insert new tabs, keep lines 503+ (after Tab3)
$before = $lines[0..115] -join "`r`n"
$after = $lines[503..($lines.Count - 1)] -join "`r`n"
$result = $before + "`r`n" + $newTabs + $after

[System.IO.File]::WriteAllText($file, $result, [System.Text.Encoding]::UTF8)
Write-Host "File written successfully"

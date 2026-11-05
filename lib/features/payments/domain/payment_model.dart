class EnrollmentFinancial {
  final String enrollmentId;
  final String courseName;
  final double totalDue;
  final double totalPaid;
  final double balance;
  final String paymentStatus;
  final String currency;

  const EnrollmentFinancial({
    required this.enrollmentId,
    required this.courseName,
    required this.totalDue,
    required this.totalPaid,
    required this.balance,
    required this.paymentStatus,
    this.currency = 'SYP',
  });

  factory EnrollmentFinancial.fromMap(Map<String, dynamic> map) {
    return EnrollmentFinancial(
      enrollmentId: map['enrollment_id'] ?? '',
      courseName: map['course_name'] ?? '',
      totalDue: (map['total_due'] as num?)?.toDouble() ?? 0,
      totalPaid: (map['total_paid'] as num?)?.toDouble() ?? 0,
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      paymentStatus: map['payment_status'] ?? 'unpaid',
      currency: map['currency'] ?? 'SYP',
    );
  }

  double get progressPercent =>
      totalDue == 0 ? 0 : (totalPaid / totalDue).clamp(0, 1);

  bool get isComplete => paymentStatus == 'complete';
  bool get isPartial => paymentStatus == 'partial';
  bool get isUnpaid => paymentStatus == 'unpaid';

  String get currencySymbol => currency == 'USD' ? '\$' : 'ل.س';
}

class PaymentReceipt {
  final String paymentId;
  final String enrollmentId;
  final double amount;
  final String currency;
  final DateTime paidAt;
  final String paymentMethod;
  final String? externalReference;
  final String? receiptNumber;
  final String? notes;
  final String courseName;
  final String cohortName;
  final String traineeId;
  final String? traineeCode;
  final String traineeName;

  const PaymentReceipt({
    required this.paymentId,
    required this.enrollmentId,
    required this.amount,
    required this.currency,
    required this.paidAt,
    required this.paymentMethod,
    this.externalReference,
    this.receiptNumber,
    this.notes,
    required this.courseName,
    required this.cohortName,
    required this.traineeId,
    this.traineeCode,
    required this.traineeName,
  });

  factory PaymentReceipt.fromMap(Map<String, dynamic> map) {
    return PaymentReceipt(
      paymentId: map['payment_id'] ?? '',
      enrollmentId: map['enrollment_id'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'SYP',
      paidAt: map['paid_at'] != null
          ? (DateTime.tryParse(map['paid_at'].toString()) ?? DateTime.now()).toLocal()
          : DateTime.now(),
      paymentMethod: map['payment_method'] ?? 'cash',
      externalReference: map['external_reference'],
      receiptNumber: map['receipt_number'],
      notes: map['notes'],
      courseName: map['course_name'] ?? '',
      cohortName: map['cohort_name'] ?? '',
      traineeId: map['trainee_id'] ?? '',
      traineeCode: map['trainee_code'],
      traineeName: map['trainee_name'] ?? '',
    );
  }

  String get paymentMethodAr {
    switch (paymentMethod) {
      case 'cash':
        return 'نقداً';
      case 'sham_cash':
        return 'شام كاش (Sham Cash)';
      case 'hawala':
        return 'حوالة هرم';
      case 'bank':
      case 'bank_transfer':
        return 'تحويل مصرفي';
      default:
        return paymentMethod;
    }
  }

  String get currencySymbol => currency == 'USD' ? '\$' : 'ل.س';
}

/// سطر واحد من كشف الحساب (تقرير 5) القادم من trainee_statement_v.
class StatementEntry {
  final String enrollmentId;
  final String entryId;
  final DateTime entryDate;
  final String entryType;
  final String description;
  final double debit;
  final double credit;
  final String currency;
  final double runningBalance;

  const StatementEntry({
    required this.enrollmentId,
    required this.entryId,
    required this.entryDate,
    required this.entryType,
    required this.description,
    required this.debit,
    required this.credit,
    required this.currency,
    required this.runningBalance,
  });

  factory StatementEntry.fromMap(Map<String, dynamic> map) {
    return StatementEntry(
      enrollmentId: map['enrollment_id'] ?? '',
      entryId: map['entry_id'] ?? '',
      entryDate:
          (DateTime.tryParse(map['entry_date']?.toString() ?? '') ??
                  DateTime.now())
              .toLocal(),
      entryType: map['entry_type'] ?? '',
      description: map['description'] ?? '',
      debit: (map['debit'] as num?)?.toDouble() ?? 0,
      credit: (map['credit'] as num?)?.toDouble() ?? 0,
      currency: map['currency'] ?? 'SYP',
      runningBalance: (map['running_balance'] as num?)?.toDouble() ?? 0,
    );
  }

  bool get isDebit => debit > 0;
  double get amount => isDebit ? debit : credit;
  String get currencySymbol => currency == 'USD' ? '\$' : 'ل.س';

  String get typeLabel {
    switch (entryType) {
      case 'initial_fee':
        return 'رسوم';
      case 'discount':
        return 'خصم';
      case 'fee_adjustment':
        return 'تعديل';
      case 'payment':
        return 'دفعة';
      case 'refund':
        return 'استرداد';
      default:
        return 'حركة';
    }
  }
}

/// قسط واحد من installment_schedule مع مجموع المخصص له من الدفعات.
class InstallmentScheduleItem {
  final String id;
  final String enrollmentId;
  final int installmentNumber;
  final DateTime dueDate;
  final double amount;
  final double paid;
  final String currency;
  final String? notes;

  const InstallmentScheduleItem({
    required this.id,
    required this.enrollmentId,
    required this.installmentNumber,
    required this.dueDate,
    required this.amount,
    required this.paid,
    required this.currency,
    this.notes,
  });

  factory InstallmentScheduleItem.fromMap(Map<String, dynamic> map) {
    final allocations = map['payment_allocations'] as List?;
    final paid = allocations == null
        ? 0.0
        : allocations.fold<double>(
            0,
            (sum, a) =>
                sum +
                ((a is Map ? a['amount'] as num? : null)?.toDouble() ?? 0),
          );

    return InstallmentScheduleItem(
      id: map['id'] ?? '',
      enrollmentId: map['enrollment_id'] ?? '',
      installmentNumber: (map['installment_number'] as num?)?.toInt() ?? 0,
      dueDate:
          (DateTime.tryParse(map['due_date']?.toString() ?? '') ??
                  DateTime.now())
              .toLocal(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      paid: paid,
      currency: map['currency'] ?? 'SYP',
      notes: map['notes'],
    );
  }

  double get remaining {
    final value = amount - paid;
    return value > 0 ? value : 0;
  }

  bool get isPaid => remaining <= 0.009;
  bool get isPartiallyPaid => !isPaid && paid > 0.009;

  bool get isOverdue {
    if (isPaid) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isBefore(today);
  }

  String get currencySymbol => currency == 'USD' ? '\$' : 'ل.س';
}

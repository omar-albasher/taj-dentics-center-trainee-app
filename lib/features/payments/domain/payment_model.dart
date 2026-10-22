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

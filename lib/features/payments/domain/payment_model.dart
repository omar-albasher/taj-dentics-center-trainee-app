class EnrollmentFinancial {
  final String enrollmentId;
  final String courseName;
  final double totalDue;
  final double totalPaid;
  final double balance;
  final String paymentStatus;

  const EnrollmentFinancial({
    required this.enrollmentId,
    required this.courseName,
    required this.totalDue,
    required this.totalPaid,
    required this.balance,
    required this.paymentStatus,
  });

  factory EnrollmentFinancial.fromMap(Map<String, dynamic> map) {
    return EnrollmentFinancial(
      enrollmentId: map['enrollment_id'] ?? '',
      courseName: map['course_name'] ?? '',
      totalDue: (map['total_due'] as num?)?.toDouble() ?? 0,
      totalPaid: (map['total_paid'] as num?)?.toDouble() ?? 0,
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      paymentStatus: map['payment_status'] ?? 'unpaid',
    );
  }

  double get progressPercent =>
      totalDue == 0 ? 0 : (totalPaid / totalDue).clamp(0, 1);

  bool get isComplete => paymentStatus == 'complete';
  bool get isPartial => paymentStatus == 'partial';
  bool get isUnpaid => paymentStatus == 'unpaid';
}

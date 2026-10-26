class ReferralCredit {
  final String currency;
  final double amount;
  final int count;

  const ReferralCredit({
    required this.currency,
    required this.amount,
    required this.count,
  });

  factory ReferralCredit.fromMap(Map<String, dynamic> map) {
    return ReferralCredit(
      currency: (map['currency'] as String?)?.trim().toUpperCase() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      count: (map['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ReferralEntry {
  final String id;
  final String refereeName;
  final String courseName;
  final double amount;
  final String currency;
  final String status;

  const ReferralEntry({
    required this.id,
    required this.refereeName,
    required this.courseName,
    required this.amount,
    required this.currency,
    required this.status,
  });

  bool get isAvailable => status == 'available';
  bool get isApplied => status == 'applied';
  bool get isCancelled => status == 'cancelled';

  factory ReferralEntry.fromMap(Map<String, dynamic> map) {
    return ReferralEntry(
      id: map['id'] as String? ?? '',
      refereeName: (map['referee_name'] as String?)?.trim() ?? '',
      courseName: (map['course_name'] as String?)?.trim() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      currency: (map['currency'] as String?)?.trim().toUpperCase() ?? '',
      status: map['status'] as String? ?? 'available',
    );
  }
}

class ReferralSummary {
  final String referralCode;
  final List<ReferralCredit> availableCredits;
  final List<ReferralEntry> referrals;

  const ReferralSummary({
    required this.referralCode,
    required this.availableCredits,
    required this.referrals,
  });

  bool get hasCode => referralCode.trim().isNotEmpty;

  bool get hasAvailableCredits =>
      availableCredits.any((credit) => credit.amount > 0);

  int get qualifiedCount => referrals.length;

  factory ReferralSummary.fromMap(Map<String, dynamic> map) {
    final credits = (map['available_credits'] as List?) ?? const [];
    final referrals = (map['referrals'] as List?) ?? const [];

    return ReferralSummary(
      referralCode:
          (map['referral_code'] as String?)?.trim().toUpperCase() ?? '',
      availableCredits: credits
          .map(
            (e) => ReferralCredit.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      referrals: referrals
          .map(
            (e) => ReferralEntry.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }
}

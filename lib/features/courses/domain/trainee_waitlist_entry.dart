class TraineeWaitlistEntry {
  final String id;
  final String cohortId;
  final String status;
  final DateTime? joinedAt;
  final DateTime? notifiedAt;
  final DateTime? expiresAt;
  final DateTime? promotedAt;

  const TraineeWaitlistEntry({
    required this.id,
    required this.cohortId,
    required this.status,
    this.joinedAt,
    this.notifiedAt,
    this.expiresAt,
    this.promotedAt,
  });

  factory TraineeWaitlistEntry.fromMap(Map<String, dynamic> map) {
    return TraineeWaitlistEntry(
      id: map['id'] as String? ?? '',
      cohortId: map['cohort_id'] as String? ?? '',
      status: map['status'] as String? ?? 'waiting',
      joinedAt: _parseDate(map['joined_at']),
      notifiedAt: _parseDate(map['notified_at']),
      expiresAt: _parseDate(map['expires_at']),
      promotedAt: _parseDate(map['promoted_at']),
    );
  }

  bool get isWaiting => status == 'waiting';

  bool get isNotified => status == 'notified';

  bool get isActive => isWaiting || isNotified;

  bool get isOfferExpired {
    final expiry = expiresAt;
    return expiry != null && DateTime.now().isAfter(expiry);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}

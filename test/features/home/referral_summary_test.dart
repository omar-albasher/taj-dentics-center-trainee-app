import 'package:flutter_test/flutter_test.dart';
import 'package:trainee_app/features/home/domain/referral_summary.dart';

void main() {
  group('ReferralSummary', () {
    test('parses code, credits and ledger entries', () {
      final summary = ReferralSummary.fromMap({
        'referral_code': ' t10042 ',
        'available_credits': [
          {'currency': 'syp', 'amount': 50000, 'count': 2},
          {'currency': 'USD', 'amount': 10, 'count': 1},
        ],
        'referrals': [
          {
            'id': 'r-1',
            'referee_name': 'سارة',
            'course_name': 'أساسيات طب الأسنان',
            'amount': 50000,
            'currency': 'syp',
            'status': 'available',
          },
          {
            'id': 'r-2',
            'referee_name': 'ليلى',
            'course_name': 'تجميل',
            'amount': 25000,
            'currency': 'syp',
            'status': 'applied',
          },
        ],
      });

      expect(summary.referralCode, 'T10042');
      expect(summary.hasCode, true);
      expect(summary.availableCredits.length, 2);
      expect(summary.hasAvailableCredits, true);
      expect(summary.qualifiedCount, 2);
      expect(summary.referrals.first.isAvailable, true);
      expect(summary.referrals.last.isApplied, true);
      expect(summary.referrals.last.isCancelled, false);
    });

    test('handles an empty summary', () {
      final summary = ReferralSummary.fromMap({});

      expect(summary.referralCode, '');
      expect(summary.hasCode, false);
      expect(summary.hasAvailableCredits, false);
      expect(summary.availableCredits, isEmpty);
      expect(summary.referrals, isEmpty);
    });

    test('ignores zero-amount credits when computing availability', () {
      final summary = ReferralSummary.fromMap({
        'referral_code': 'T10099',
        'available_credits': [
          {'currency': 'SYP', 'amount': 0, 'count': 0},
        ],
      });

      expect(summary.hasAvailableCredits, false);
    });
  });
}

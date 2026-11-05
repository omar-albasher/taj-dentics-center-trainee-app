import 'package:flutter_test/flutter_test.dart';
import 'package:trainee_app/features/payments/domain/payment_model.dart';

void main() {
  group('StatementEntry', () {
    test('parses a debit entry with its running balance', () {
      final entry = StatementEntry.fromMap({
        'enrollment_id': 'enr-1',
        'entry_id': 'entry-1',
        'entry_date': '2026-11-01T09:30:00+03:00',
        'entry_type': 'initial_fee',
        'description': 'رسوم التسجيل الأساسية - تجميل الأسنان',
        'debit': 1500000,
        'credit': 0,
        'currency': 'SYP',
        'running_balance': 1500000,
      });

      expect(entry.enrollmentId, 'enr-1');
      expect(entry.isDebit, isTrue);
      expect(entry.amount, 1500000);
      expect(entry.runningBalance, 1500000);
      expect(entry.currencySymbol, 'ل.س');
      expect(entry.typeLabel, 'رسوم');
    });

    test('parses a credit entry and exposes its type label', () {
      final entry = StatementEntry.fromMap({
        'enrollment_id': 'enr-1',
        'entry_id': 'entry-2',
        'entry_date': '2026-11-02T10:00:00+03:00',
        'entry_type': 'payment',
        'description': 'دفعة نقدية - إيصال #1001',
        'debit': 0,
        'credit': 500000,
        'currency': 'USD',
        'running_balance': 1000000,
      });

      expect(entry.isDebit, isFalse);
      expect(entry.amount, 500000);
      expect(entry.currencySymbol, r'$');
      expect(entry.typeLabel, 'دفعة');
    });

    test('falls back safely when optional fields are missing', () {
      final entry = StatementEntry.fromMap({});

      expect(entry.enrollmentId, '');
      expect(entry.debit, 0);
      expect(entry.credit, 0);
      expect(entry.runningBalance, 0);
    });
  });

  group('InstallmentScheduleItem', () {
    test('sums payment allocations and detects a fully paid installment', () {
      final item = InstallmentScheduleItem.fromMap({
        'id': 'ins-1',
        'enrollment_id': 'enr-1',
        'installment_number': 1,
        'due_date': '2026-11-01',
        'amount': 750000,
        'currency': 'SYP',
        'payment_allocations': [
          {'amount': 500000},
          {'amount': 250000},
        ],
      });

      expect(item.paid, 750000);
      expect(item.remaining, 0);
      expect(item.isPaid, isTrue);
      expect(item.isPartiallyPaid, isFalse);
      expect(item.isOverdue, isFalse);
    });

    test('detects a partially paid overdue installment', () {
      final due = DateTime.now().subtract(const Duration(days: 2));
      final item = InstallmentScheduleItem.fromMap({
        'id': 'ins-2',
        'enrollment_id': 'enr-1',
        'installment_number': 2,
        'due_date':
            '${due.year}-${due.month.toString().padLeft(2, '0')}-${due.day.toString().padLeft(2, '0')}',
        'amount': 400000,
        'currency': 'SYP',
        'payment_allocations': [
          {'amount': 100000},
        ],
      });

      expect(item.paid, 100000);
      expect(item.remaining, 300000);
      expect(item.isPaid, isFalse);
      expect(item.isPartiallyPaid, isTrue);
      expect(item.isOverdue, isTrue);
    });

    test('treats a future unpaid installment as upcoming', () {
      final due = DateTime.now().add(const Duration(days: 7));
      final item = InstallmentScheduleItem.fromMap({
        'id': 'ins-3',
        'enrollment_id': 'enr-1',
        'installment_number': 3,
        'due_date':
            '${due.year}-${due.month.toString().padLeft(2, '0')}-${due.day.toString().padLeft(2, '0')}',
        'amount': 200000,
        'currency': 'USD',
        'payment_allocations': null,
      });

      expect(item.paid, 0);
      expect(item.remaining, 200000);
      expect(item.isOverdue, isFalse);
      expect(item.currencySymbol, r'$');
    });
  });
}

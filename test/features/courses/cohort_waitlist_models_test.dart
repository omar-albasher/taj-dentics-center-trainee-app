import 'package:flutter_test/flutter_test.dart';
import 'package:trainee_app/features/courses/domain/cohort_seat_status.dart';
import 'package:trainee_app/features/courses/domain/trainee_waitlist_entry.dart';

void main() {
  group('CohortSeatStatus (trainee_app)', () {
    test('parses a full limited cohort', () {
      final status = CohortSeatStatus.fromMap({
        'cohort_id': 'cohort-1',
        'course_id': 'course-1',
        'cohort_name': 'المجموعة الأولى',
        'course_name': 'التعويضات الأساسية',
        'cohort_starts_at': '2026-11-01T09:00:00Z',
        'course_price': 1500000,
        'course_total_sessions': 12,
        'capacity': 4,
        'enrolled_count': 4,
        'waitlist_count': 2,
        'available_seats': 0,
        'is_full': true,
      });

      expect(status.cohortId, 'cohort-1');
      expect(status.isUnlimited, false);
      expect(status.isFull, true);
      expect(status.availableSeats, 0);
      expect(status.waitlistCount, 2);
      expect(status.cohortStartsAt, isNotNull);
    });

    test('treats null capacity as unlimited', () {
      final status = CohortSeatStatus.fromMap({
        'cohort_id': 'cohort-2',
        'course_id': 'course-1',
        'cohort_name': 'المجموعة الثانية',
        'course_name': 'التعويضات الأساسية',
        'capacity': null,
        'enrolled_count': 7,
        'waitlist_count': 0,
        'available_seats': null,
        'is_full': false,
      });

      expect(status.isUnlimited, true);
      expect(status.availableSeats, isNull);
      expect(status.isFull, false);
      expect(status.waitlistCount, 0);
    });

    test('falls back safely when optional fields are missing', () {
      final status = CohortSeatStatus.fromMap(const {});

      expect(status.cohortId, '');
      expect(status.coursePrice, 0);
      expect(status.courseTotalSessions, 0);
      expect(status.capacity, isNull);
      expect(status.isFull, false);
    });
  });

  group('TraineeWaitlistEntry (trainee_app)', () {
    test('parses a waiting entry', () {
      final entry = TraineeWaitlistEntry.fromMap({
        'id': 'wait-1',
        'cohort_id': 'cohort-1',
        'status': 'waiting',
        'joined_at': '2026-10-20T10:00:00Z',
        'notified_at': null,
        'expires_at': null,
      });

      expect(entry.id, 'wait-1');
      expect(entry.isWaiting, true);
      expect(entry.isNotified, false);
      expect(entry.isActive, true);
      expect(entry.joinedAt, isNotNull);
    });

    test('parses a notified entry and exposes its expiry', () {
      final entry = TraineeWaitlistEntry.fromMap({
        'id': 'wait-2',
        'cohort_id': 'cohort-1',
        'status': 'notified',
        'joined_at': '2026-10-20T10:00:00Z',
        'notified_at': '2026-10-25T10:00:00Z',
        'expires_at': '2099-10-26T10:00:00Z',
      });

      expect(entry.isNotified, true);
      expect(entry.isOfferExpired, false);
      expect(entry.expiresAt, isNotNull);
    });

    test('detects an expired offer', () {
      final entry = TraineeWaitlistEntry.fromMap({
        'id': 'wait-3',
        'cohort_id': 'cohort-1',
        'status': 'notified',
        'expires_at': '2020-01-01T00:00:00Z',
      });

      expect(entry.isOfferExpired, true);
    });

    test('rejects unknown statuses from the active predicate', () {
      final entry = TraineeWaitlistEntry.fromMap({
        'id': 'wait-4',
        'cohort_id': 'cohort-1',
        'status': 'cancelled',
      });

      expect(entry.isActive, false);
    });
  });
}

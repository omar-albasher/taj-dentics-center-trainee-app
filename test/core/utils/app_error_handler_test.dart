import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trainee_app/core/utils/app_error_handler.dart';

void main() {
  group('AppErrorHandler B4 domain codes (trainee_app)', () {
    test('maps ALREADY_ENROLLED from the RPC message', () {
      final message = AppErrorHandler.friendlyMessage(
        PostgrestException(
          message: 'ALREADY_ENROLLED',
          code: 'P0001',
        ),
      );

      expect(message, 'أنت مسجل بالفعل في هذه المجموعة');
    });

    test('maps COHORT_HAS_AVAILABLE_SEATS', () {
      final message = AppErrorHandler.friendlyMessage(
        PostgrestException(
          message: 'COHORT_HAS_AVAILABLE_SEATS',
          code: 'P0001',
        ),
      );

      expect(message, contains('مقاعد متاحة'));
    });

    test('maps a domain code embedded in details', () {
      final message = AppErrorHandler.friendlyMessage(
        PostgrestException(
          message: 'unexpected database error',
          details: 'WAITLIST_NOT_ACTIVE',
          code: 'P0001',
        ),
      );

      expect(message, contains('طلب الانتظار'));
    });

    test('maps expired session codes', () {
      final message = AppErrorHandler.friendlyMessage(
        PostgrestException(
          message: 'AUTH_REQUIRED',
          code: 'P0001',
        ),
      );

      expect(message, contains('الجلسة'));
    });

    test('falls back safely for unknown P0001 messages', () {
      final message = AppErrorHandler.friendlyMessage(
        PostgrestException(
          message: 'SOMETHING_ELSE',
          code: 'P0001',
        ),
      );

      expect(message, contains('قاعدة البيانات'));
    });
  });
}

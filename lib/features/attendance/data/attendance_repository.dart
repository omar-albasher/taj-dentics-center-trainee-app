import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceRepository {
  final _client = Supabase.instance.client;

  Future<Map<String, dynamic>> recordAttendance(String qrToken) async {
    try {
      final response = await _client.functions.invoke(
        'smart-responder',
        body: {'qr_token': qrToken},
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
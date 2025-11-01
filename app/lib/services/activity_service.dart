// lib/services/activity_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../services/config.dart';
import '../services/api_client.dart';
import '../models/activity.dart';
import '../models/attendance_record.dart';

class ActivityService {
  // dùng lại client để tự gắn token
  final ApiClient _client = ApiClient();

  // ======= 1. LẤY DS HOẠT ĐỘNG (PUBLIC / SV) =======
  Future<List<Activity>> fetchActivities() async {
    // nếu API này không cần auth thì có thể dùng http trực tiếp
    final baseUrl = await Config.getBaseUrl();
    final res = await http.get(Uri.parse('$baseUrl/activities'));

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Activity.fromJson(e)).toList();
    }
    throw Exception('Lỗi lấy danh sách hoạt động: ${res.statusCode}');
  }

  // ======= 2. LẤY LỊCH SỬ HOẠT ĐỘNG CỦA USER (CẦN TOKEN) =======
  Future<List<Activity>> fetchMyHistory() async {
    final data = await _client.get('activities/history');
    // server trả mảng
    return (data as List).map((e) => Activity.fromJson(e)).toList();
  }

  // ======= 3. ĐĂNG KÝ HOẠT ĐỘNG (CẦN TOKEN) =======
  Future<void> registerForActivity(String id) async {
    await _client.post('activities/$id/register', {});
  }

  // ======= 4. HỦY ĐĂNG KÝ HOẠT ĐỘNG (CẦN TOKEN) =======
  Future<void> unregisterFromActivity(String id) async {
    await _client.post('activities/$id/unregister', {});
  }

  // ======= 5. ĐIỂM DANH (CẦN TOKEN) =======
  Future<void> markAttendance(String id) async {
    await _client.post('activities/$id/attendance', {});
  }

  // ======= 6. ADMIN: LẤY DS ĐIỂM DANH =======
  Future<List<AttendanceRecord>> fetchAttendanceList(String id) async {
    final data = await _client.get('activities/$id/attendance');
    return (data as List).map((e) => AttendanceRecord.fromJson(e)).toList();
  }

  // ======= 7. ADMIN: TẠO HOẠT ĐỘNG =======
  Future<Activity> createActivity(Map<String, dynamic> data) async {
    final res = await _client.post('activities', data);
    return Activity.fromJson(res);
  }

  // ======= 8. ADMIN: CẬP NHẬT HOẠT ĐỘNG =======
  Future<Activity> updateActivity(String id, Map<String, dynamic> data) async {
    final res = await _client.put('activities/$id', data);
    return Activity.fromJson(res);
  }

  // ======= 9. ADMIN: XÓA HOẠT ĐỘNG =======
  Future<void> deleteActivity(String id) async {
    await _client.delete('activities/$id');
  }
}

// lib/services/activity_service.dart - ĐÃ SỬA
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../services/config.dart';
import '../services/api_client.dart';
import '../models/activity.dart';
import '../models/attendance_record.dart';

class ActivityService {
  final ApiClient _client = ApiClient();

  // ======= 1. LẤY DS HOẠT ĐỘNG (SINH VIÊN) =======
  Future<List<Activity>> fetchActivities() async {
    final data = await _client.get('activities');
    return (data as List).map((e) => Activity.fromJson(e)).toList();
  }

  // ======= 2. LẤY LỊCH SỬ (FIXED ENDPOINT) =======
  Future<List<Activity>> fetchMyHistory() async {
    // ✅ SỬA: Đúng endpoint từ backend
    final data = await _client.get('activities/my-history');
    return (data as List).map((e) => Activity.fromJson(e)).toList();
  }

  // ======= 3. ĐĂNG KÝ HOẠT ĐỘNG =======
  Future<void> registerForActivity(String id) async {
    await _client.post('activities/$id/register', {});
  }

  // ======= 4. HỦY ĐĂNG KÝ =======
  Future<void> unregisterFromActivity(String id) async {
    await _client.post('activities/$id/unregister', {});
  }

  // ======= 5. ĐIỂM DANH (FIXED) =======
  Future<void> markAttendance(String activityId) async {
    // ✅ SỬA: Gửi đúng format body
    await _client.post('activities/attend', {'activityId': activityId});
  }

  // ======= 6. ADMIN: LẤY DS ĐIỂM DANH (FIXED) =======
  Future<List<AttendanceRecord>> fetchAttendanceList(String activityId) async {
    // ✅ SỬA: Đúng endpoint từ backend
    final data = await _client.get('activities/$activityId/attendance');
    return (data as List).map((e) => AttendanceRecord.fromJson(e)).toList();
  }

  // ======= 7. ADMIN: TẠO HOẠT ĐỘNG =======
  Future<Activity> createActivity(Map<String, dynamic> data) async {
    final res = await _client.post('activities', data);
    return Activity.fromJson(res);
  }

  // ======= 8. ADMIN: CẬP NHẬT =======
  Future<Activity> updateActivity(String id, Map<String, dynamic> data) async {
    final res = await _client.put('activities/$id', data);
    return Activity.fromJson(res);
  }

  // ======= 9. ADMIN: XÓA =======
  Future<void> deleteActivity(String id) async {
    await _client.delete('activities/$id');
  }
}

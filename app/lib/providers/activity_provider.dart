// lib/providers/activity_provider.dart
import 'package:flutter/material.dart';

import '../models/activity.dart';
import '../models/attendance_record.dart';
import '../services/activity_service.dart';

class ActivityProvider with ChangeNotifier {
  final ActivityService _activityService = ActivityService();

  // ----- STATE -----
  List<Activity> _activities = [];
  List<Activity> _history = [];

  bool _isLoadingActivities = false;
  bool _isLoadingHistory = false;

  String? _activitiesError;
  String? _historyError;

  // để disable nút khi đang gọi API từng activity
  final Set<String> _loadingButtons = {};

  // ----- GETTERS -----
  List<Activity> get activities => _activities;
  List<Activity> get history => _history;

  bool get isLoadingActivities => _isLoadingActivities;
  bool get isLoadingHistory => _isLoadingHistory;

  String? get activitiesError => _activitiesError;
  String? get historyError => _historyError;

  bool isActivityLoading(String id) => _loadingButtons.contains(id);

  // =========================================================
  // 1. LẤY DANH SÁCH HOẠT ĐỘNG (SV)
  // =========================================================
  Future<void> fetchActivities() async {
    _isLoadingActivities = true;
    _activitiesError = null;
    notifyListeners();

    try {
      // 👉 service bên dưới PHẢI dùng Config.getBaseUrl()
      _activities = await _activityService.fetchActivities();
    } catch (e) {
      _activitiesError = e.toString();
    } finally {
      _isLoadingActivities = false;
      notifyListeners();
    }
  }

  // =========================================================
  // 2. LẤY LỊCH SỬ / HOẠT ĐỘNG ĐÃ THAM GIA
  // =========================================================
  Future<void> fetchHistory() async {
    _isLoadingHistory = true;
    _historyError = null;
    notifyListeners();

    try {
      _history = await _activityService.fetchMyHistory();
    } catch (e) {
      _historyError = e.toString();
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  // =========================================================
  // 3. ĐĂNG KÝ / HỦY ĐĂNG KÝ HOẠT ĐỘNG
  // =========================================================
  Future<void> toggleRegistration(Activity activity) async {
    // chặn double tap trên chính activity đó
    _loadingButtons.add(activity.id);
    notifyListeners();

    try {
      if (activity.isRegistered) {
        // HỦY
        await _activityService.unregisterFromActivity(activity.id);
        activity.isRegistered = false;
        // bỏ khỏi history nếu có
        _history.removeWhere((a) => a.id == activity.id);
      } else {
        // ĐĂNG KÝ
        await _activityService.registerForActivity(activity.id);
        activity.isRegistered = true;
        // nếu history chưa có thì add
        if (!_history.any((a) => a.id == activity.id)) {
          _history.add(activity);
        }
      }
    } catch (e) {
      // có thể show snackbar ngoài UI
      debugPrint('toggleRegistration error: $e');
      rethrow;
    } finally {
      _loadingButtons.remove(activity.id);
      notifyListeners();
    }
  }

  // =========================================================
  // 4. ĐIỂM DANH BẰNG QR (SV)
  // =========================================================
  Future<void> markAttendance(String activityId) async {
    try {
      await _activityService.markAttendance(activityId);

      // cập nhật trong _activities
      final i = _activities.indexWhere((a) => a.id == activityId);
      if (i != -1) {
        _activities[i].isRegistered = true; // phòng trường hợp chưa đăng ký
        _activities[i].attended = true; // cần có field này trong model
      }

      // cập nhật trong _history
      final h = _history.indexWhere((a) => a.id == activityId);
      if (h != -1) {
        _history[h].attended = true;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('markAttendance error: $e');
      rethrow;
    }
  }

  // =========================================================
  // 5. ADMIN: XEM DANH SÁCH ĐIỂM DANH CỦA 1 HOẠT ĐỘNG
  // =========================================================
  Future<List<AttendanceRecord>> fetchAttendanceList(String activityId) async {
    try {
      return await _activityService.fetchAttendanceList(activityId);
    } catch (e) {
      debugPrint('fetchAttendanceList error: $e');
      throw Exception('Lỗi lấy danh sách điểm danh: $e');
    }
  }

  // =========================================================
  // 6. ADMIN: LẤY DS HOẠT ĐỘNG (CÓ THỂ DÙNG CHUNG)
  // =========================================================
  Future<void> fetchActivitiesAdmin() async {
    await fetchActivities();
  }

  // =========================================================
  // 7. ADMIN: TẠO HOẠT ĐỘNG
  // =========================================================
  Future<void> createActivity(Map<String, dynamic> data) async {
    try {
      final newActivity = await _activityService.createActivity(data);
      _activities.add(newActivity);
      notifyListeners();
    } catch (e) {
      debugPrint('createActivity error: $e');
      rethrow;
    }
  }

  // =========================================================
  // 8. ADMIN: CẬP NHẬT HOẠT ĐỘNG
  // =========================================================
  Future<void> updateActivity(String id, Map<String, dynamic> data) async {
    try {
      final updated = await _activityService.updateActivity(id, data);
      final index = _activities.indexWhere((a) => a.id == id);
      if (index != -1) {
        _activities[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('updateActivity error: $e');
      rethrow;
    }
  }

  // =========================================================
  // 9. ADMIN: XÓA HOẠT ĐỘNG
  // =========================================================
  Future<void> deleteActivity(String id) async {
    try {
      await _activityService.deleteActivity(id);
      _activities.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('deleteActivity error: $e');
      rethrow;
    }
  }
}

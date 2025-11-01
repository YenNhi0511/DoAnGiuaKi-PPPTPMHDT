// lib/services/auth_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  String? _token;
  User? _currentUser;
  bool _isAuthLoading = true;

  bool get isAuthenticated => _token != null;
  User? get currentUser => _currentUser;
  String? get userRole => _currentUser?.role;
  String? get userId => _currentUser?.id;
  bool get isAuthLoading => _isAuthLoading;

  AuthService() {
    tryAutoLogin();
  }

  // ----- Lấy hồ sơ người dùng -----
  Future<void> _getUserProfile() async {
    try {
      final responseData = await _apiClient.get('auth/me');
      _currentUser = User.fromJson(responseData);
    } catch (e) {
      debugPrint('Không thể tải thông tin user: $e');
      await logout();
    }
  }

  // ----- Tự động đăng nhập -----
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('token');

    if (savedToken == null) {
      _isAuthLoading = false;
      notifyListeners();
      return;
    }

    _token = savedToken;
    await _getUserProfile();
    _isAuthLoading = false;
    notifyListeners();
  }

  // ----- Đăng nhập -----
  Future<void> login(String email, String password) async {
    try {
      final response = await _apiClient.post('auth/login', {
        'email': email,
        'password': password,
      });

      _token = response['token'];
      if (_token == null) {
        throw Exception('Không nhận được token từ server');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);

      await _getUserProfile();
      notifyListeners();
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ----- Đăng ký -----
  Future<void> register(String fullName, String email, String password) async {
    try {
      final response = await _apiClient.post('auth/register', {
        'fullName': fullName,
        'email': email,
        'password': password,
      });

      _token = response['token'];
      if (_token == null) {
        throw Exception('Không nhận được token từ server');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);

      await _getUserProfile();
      notifyListeners();
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ----- Đổi mật khẩu -----
  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await _apiClient.post(
        'auth/change-password',
        {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
          'confirmPassword': newPassword,
        },
      );

      if (response['message'] == null) {
        throw Exception('Không nhận được phản hồi từ server');
      }

      debugPrint('Đổi mật khẩu thành công!');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ----- Đăng xuất -----
  Future<void> logout() async {
    _token = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    notifyListeners();
  }
}

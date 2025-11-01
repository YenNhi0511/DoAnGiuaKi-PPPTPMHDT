// lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class ApiClient {
  // Cache baseUrl sau lần đầu
  String? _cachedBaseUrl;

  Future<String> _getBaseUrl() async {
    _cachedBaseUrl ??= await Config.getBaseUrl();
    return _cachedBaseUrl!;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    if (token != null) {
      return {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
    };
  }

  // ===== GET =====
  Future<dynamic> get(String endpoint) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl/$endpoint');
    print('🔍 API GET: $url');

    final headers = await _getHeaders();
    try {
      final response = await http.get(url, headers: headers);
      print('✅ Response ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      print('❌ Lỗi GET: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // ===== POST =====
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl/$endpoint');
    print('🔍 API POST: $url');
    print('📤 Body: ${json.encode(data)}');

    final headers = await _getHeaders();
    final body = json.encode(data);
    try {
      final response = await http.post(url, headers: headers, body: body);
      print('✅ Response ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      print('❌ Lỗi POST: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // ===== PUT =====
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl/$endpoint');
    print('🔍 API PUT: $url');

    final headers = await _getHeaders();
    final body = json.encode(data);
    try {
      final response = await http.put(url, headers: headers, body: body);
      print('✅ Response ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      print('❌ Lỗi PUT: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // ===== DELETE =====
  Future<dynamic> delete(String endpoint) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl/$endpoint');
    print('🔍 API DELETE: $url');

    final headers = await _getHeaders();
    try {
      final response = await http.delete(url, headers: headers);
      print('✅ Response ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      print('❌ Lỗi DELETE: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // ===== XỬ LÝ RESPONSE =====
  dynamic _handleResponse(http.Response response) {
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null; // Thành công nhưng không có body
      } else {
        throw Exception('Lỗi máy chủ (code: ${response.statusCode})');
      }
    }

    final responseData = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    } else {
      throw Exception(responseData['message'] ?? 'Lỗi không xác định');
    }
  }
}

// lib/services/api_client.dart - ĐÃ CẢI THIỆN
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

// ✅ THÊM: Custom exceptions
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => message;
}

class TimeoutException implements Exception {
  final String message = 'Yêu cầu quá thời gian chờ. Vui lòng thử lại.';

  @override
  String toString() => message;
}

class UnauthorizedException implements Exception {
  final String message = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';

  @override
  String toString() => message;
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);

  @override
  String toString() => message;
}

class ApiClient {
  String? _cachedBaseUrl;

  // ✅ THÊM: Timeout configuration
  static const Duration _timeout = Duration(seconds: 30);

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

  // ✅ CẢI THIỆN: GET with better error handling
  Future<dynamic> get(String endpoint) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl/$endpoint');
    print('🔍 API GET: $url');

    final headers = await _getHeaders();

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(_timeout); // ✅ THÊM timeout

      print('✅ Response ${response.statusCode}');
      return _handleResponse(response);
    } on TimeoutException {
      print('❌ Timeout');
      throw TimeoutException();
    } on http.ClientException catch (e) {
      print('❌ Network error: $e');
      throw NetworkException(
          'Không thể kết nối tới máy chủ. Vui lòng kiểm tra kết nối mạng.');
    } catch (e) {
      print('❌ Error: $e');
      throw NetworkException('Lỗi không xác định: $e');
    }
  }

  // ✅ CẢI THIỆN: POST with better error handling
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl/$endpoint');
    print('🔍 API POST: $url');
    print('📤 Body: ${json.encode(data)}');

    final headers = await _getHeaders();
    final body = json.encode(data);

    try {
      final response =
          await http.post(url, headers: headers, body: body).timeout(_timeout);

      print('✅ Response ${response.statusCode}');
      return _handleResponse(response);
    } on TimeoutException {
      print('❌ Timeout');
      throw TimeoutException();
    } on http.ClientException catch (e) {
      print('❌ Network error: $e');
      throw NetworkException(
          'Không thể kết nối tới máy chủ. Vui lòng kiểm tra kết nối mạng.');
    } catch (e) {
      print('❌ Error: $e');
      throw NetworkException('Lỗi không xác định: $e');
    }
  }

  // ✅ CẢI THIỆN: PUT with better error handling
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl/$endpoint');
    print('🔍 API PUT: $url');

    final headers = await _getHeaders();
    final body = json.encode(data);

    try {
      final response =
          await http.put(url, headers: headers, body: body).timeout(_timeout);

      print('✅ Response ${response.statusCode}');
      return _handleResponse(response);
    } on TimeoutException {
      print('❌ Timeout');
      throw TimeoutException();
    } on http.ClientException catch (e) {
      print('❌ Network error: $e');
      throw NetworkException(
          'Không thể kết nối tới máy chủ. Vui lòng kiểm tra kết nối mạng.');
    } catch (e) {
      print('❌ Error: $e');
      throw NetworkException('Lỗi không xác định: $e');
    }
  }

  // ✅ CẢI THIỆN: DELETE with better error handling
  Future<dynamic> delete(String endpoint) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl/$endpoint');
    print('🔍 API DELETE: $url');

    final headers = await _getHeaders();

    try {
      final response =
          await http.delete(url, headers: headers).timeout(_timeout);

      print('✅ Response ${response.statusCode}');
      return _handleResponse(response);
    } on TimeoutException {
      print('❌ Timeout');
      throw TimeoutException();
    } on http.ClientException catch (e) {
      print('❌ Network error: $e');
      throw NetworkException(
          'Không thể kết nối tới máy chủ. Vui lòng kiểm tra kết nối mạng.');
    } catch (e) {
      print('❌ Error: $e');
      throw NetworkException('Lỗi không xác định: $e');
    }
  }

  // ✅ CẢI THIỆN: Response handler with better error messages
  dynamic _handleResponse(http.Response response) {
    // Handle empty body
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null;
      } else {
        throw ServerException('Lỗi máy chủ (${response.statusCode})');
      }
    }

    // Parse response
    dynamic responseData;
    try {
      responseData = json.decode(response.body);
    } catch (e) {
      throw ServerException('Dữ liệu trả về không hợp lệ');
    }

    // ✅ CẢI THIỆN: Handle different status codes
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    } else if (response.statusCode == 400) {
      throw Exception(responseData['message'] ?? 'Yêu cầu không hợp lệ');
    } else if (response.statusCode == 401) {
      throw UnauthorizedException();
    } else if (response.statusCode == 403) {
      throw Exception('Bạn không có quyền thực hiện hành động này');
    } else if (response.statusCode == 404) {
      throw Exception('Không tìm thấy dữ liệu');
    } else if (response.statusCode == 409) {
      throw Exception(responseData['message'] ?? 'Dữ liệu đã tồn tại');
    } else if (response.statusCode >= 500) {
      throw ServerException('Lỗi máy chủ. Vui lòng thử lại sau.');
    } else {
      throw Exception(responseData['message'] ??
          'Lỗi không xác định (${response.statusCode})');
    }
  }

  // ✅ THÊM: Retry mechanism
  Future<dynamic> getWithRetry(
    String endpoint, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        return await get(endpoint);
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          rethrow;
        }

        print('🔄 Retry attempt $attempt/$maxRetries');
        await Future.delayed(retryDelay);
      }
    }
  }

  // ✅ THÊM: Check network connectivity
  Future<bool> checkConnectivity() async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse('$baseUrl/health');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

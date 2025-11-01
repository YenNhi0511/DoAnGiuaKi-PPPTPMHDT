// lib/services/config.dart
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class Config {
  // IP của laptop bạn trong cùng WiFi
  // lấy từ ipconfig: 192.168.77.104
  static const String _pcIp = '192.168.77.104';
  static const String _port = '4000';

  // base cho emulator Android
  static const String _emulatorBase = 'http://10.0.2.2:$_port/api';

  // base cho điện thoại thật / web / desktop cùng mạng
  static const String _realDeviceBase = 'http://$_pcIp:$_port/api';

  static String? _cachedBaseUrl;

  /// Dùng: `final baseUrl = await Config.getBaseUrl();`
  static Future<String> getBaseUrl() async {
    // đã detect rồi thì khỏi detect nữa
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;

    // chạy trên PC (flutter run -d windows/web/macos)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _cachedBaseUrl = _realDeviceBase;
      return _cachedBaseUrl!;
    }

    // chạy trên Android -> phân biệt emulator vs máy thật
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      final isEmulator = !androidInfo.isPhysicalDevice ||
          (androidInfo.model?.toLowerCase().contains('sdk') ?? false) ||
          (androidInfo.product?.toLowerCase().contains('sdk') ?? false) ||
          (androidInfo.manufacturer?.toLowerCase().contains('genymotion') ??
              false);

      _cachedBaseUrl = isEmulator ? _emulatorBase : _realDeviceBase;
      return _cachedBaseUrl!;
    }

    // iOS tạm dùng luôn real
    _cachedBaseUrl = _realDeviceBase;
    return _cachedBaseUrl!;
  }
}

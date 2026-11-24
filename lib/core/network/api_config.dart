import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

abstract final class ApiConfig {
  static const _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.trim().isNotEmpty) {
      return _override.trim().replaceAll(RegExp(r'/+$'), '');
    }
    // Android emulator uses 10.0.2.2 to access host machine's localhost
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    // Windows desktop & Chrome web use localhost:8080
    return 'http://localhost:8080';
  }
}

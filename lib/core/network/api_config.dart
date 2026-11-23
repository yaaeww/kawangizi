abstract final class ApiConfig {
  static const _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.trim().isNotEmpty) {
      return _override.trim().replaceAll(RegExp(r'/+$'), '');
    }
    return 'http://10.0.2.2:8080';
  }
}

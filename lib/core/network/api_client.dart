import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'api_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

String apiErrorMessage(Object error) {
  if (error is ApiException) return error.message;
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['error'] ?? data['message'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Tidak dapat terhubung ke server KawanGizi.';
    }
    return error.message ?? 'Terjadi kesalahan pada server.';
  }
  return error.toString();
}

class ApiClient {
  ApiClient._(this._dio, this._refreshDio);

  final Dio _dio;
  final Dio _refreshDio;

  String? _accessToken;
  Future<bool>? _refreshFuture;

  String? get accessToken => _accessToken;
  set accessToken(String? value) => _accessToken = value;

  static Future<ApiClient> create() async {
    final directory = await getApplicationSupportDirectory();
    final cookiePath = '${directory.path}${Platform.pathSeparator}cookies';
    final cookieJar = PersistCookieJar(
      ignoreExpires: false,
      storage: FileStorage(cookiePath),
    );

    final options = BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 90),
      sendTimeout: const Duration(seconds: 90),
      headers: {'Accept': 'application/json'},
    );

    final dio = Dio(options);
    final refreshDio = Dio(options);
    dio.interceptors.add(CookieManager(cookieJar));
    refreshDio.interceptors.add(CookieManager(cookieJar));

    final client = ApiClient._(dio, refreshDio);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          final token = client._accessToken;
          if (token != null && token.isNotEmpty) {
            request.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(request);
        },
        onError: (error, handler) async {
          final path = error.requestOptions.path;
          final shouldRefresh = error.response?.statusCode == 401 &&
              !path.startsWith('/api/auth/') &&
              error.requestOptions.extra['retried'] != true;
          if (!shouldRefresh) {
            handler.next(error);
            return;
          }
          final refreshed = await client.refresh();
          if (!refreshed) {
            handler.next(error);
            return;
          }
          final options = error.requestOptions;
          options.extra['retried'] = true;
          try {
            final response = await client._dio.fetch(options);
            handler.resolve(response);
          } on DioException catch (retryError) {
            handler.next(retryError);
          }
        },
      ),
    );

    return client;
  }

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) {
    return _dio.get(path, queryParameters: query);
  }

  Future<Response<dynamic>> post(String path, {Object? data}) {
    return _dio.post(path, data: data);
  }

  Future<Response<dynamic>> postForm(String path, FormData data) {
    return _dio.post(path, data: data);
  }

  Future<bool> refresh() async {
    final existing = _refreshFuture;
    if (existing != null) return existing;
    final future = _performRefresh();
    _refreshFuture = future;
    try {
      return await future;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<bool> _performRefresh() async {
    try {
      final response = await _refreshDio.post('/api/auth/refresh');
      final body = response.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        final token = body['data']['accessToken']?.toString();
        if (token != null && token.isNotEmpty) {
          _accessToken = token;
          return true;
        }
      }
    } catch (_) {
      // Refresh cookie may be absent or expired.
    }
    return false;
  }

  Future<void> clearCookies() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final cookiePath = '${directory.path}${Platform.pathSeparator}cookies';
      await PersistCookieJar(storage: FileStorage(cookiePath)).deleteAll();
    } catch (_) {
      // Ignore cookie cleanup failures.
    }
  }
}

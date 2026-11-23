import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kawangizi_mobile/features/auth/domain/backend_user.dart';

class SessionStore {
  SessionStore({
    FlutterSecureStorage? secureStorage,
    SharedPreferences? preferences,
  })  : _secure = secureStorage ?? const FlutterSecureStorage(),
        _prefs = preferences;

  final FlutterSecureStorage _secure;
  SharedPreferences? _prefs;

  static const _tokenKey = 'kawangizi_token';
  static const _userKey = 'kawangizi_user';
  static const _permsKey = 'kawangizi_perms';
  static const _guestKey = 'kawangizi_is_guest';

  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> save({
    required String token,
    required BackendUser user,
    required List<String> permissions,
    required bool isGuest,
  }) async {
    final prefs = await _preferences;
    await _secure.write(key: _tokenKey, value: token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setStringList(_permsKey, permissions);
    await prefs.setBool(_guestKey, isGuest);
  }

  Future<StoredSession?> load() async {
    final prefs = await _preferences;
    final token = await _secure.read(key: _tokenKey);
    final userJson = prefs.getString(_userKey);
    if (token == null || token.isEmpty || userJson == null) return null;
    try {
      final user = BackendUser.fromJson(
        Map<String, dynamic>.from(jsonDecode(userJson) as Map),
      );
      return StoredSession(
        token: token,
        user: user,
        permissions: prefs.getStringList(_permsKey) ?? const [],
        isGuest: prefs.getBool(_guestKey) ?? user.isGuest,
      );
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await _preferences;
    await _secure.delete(key: _tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_permsKey);
    await prefs.remove(_guestKey);
  }
}

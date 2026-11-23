import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  LocalStore({SharedPreferences? preferences}) : _prefs = preferences;

  SharedPreferences? _prefs;

  static const forumKey = 'forum_posts';
  static const legacyForumKey = '@kawangizi_community_posts';

  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<String?> getString(String key) async => (await _preferences).getString(key);

  Future<void> setString(String key, String value) async {
    await (await _preferences).setString(key, value);
  }

  Future<void> remove(String key) async {
    await (await _preferences).remove(key);
  }

  Future<List<Map<String, dynamic>>?> getJsonList(String key) async {
    final prefs = await _preferences;
    var raw = prefs.getString(key);
    if (raw == null && key == forumKey) raw = prefs.getString(legacyForumKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> setJsonList(String key, List<Map<String, dynamic>> value) async {
    final prefs = await _preferences;
    final raw = jsonEncode(value);
    await prefs.setString(key, raw);
    if (key == forumKey) await prefs.setString(legacyForumKey, raw);
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class ProfileCache {
  static const String _key = 'cached_user_profile';

  static Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toCacheMap()));
  }

  static Future<UserProfile?> load(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return null;

      final map = jsonDecode(raw) as Map<String, dynamic>;

      // Safety check: do not return another user's cached profile
      if ((map['uid'] ?? '') != uid) return null;

      return UserProfile.fromCacheMap(map);
    } catch (e) {
      print('⚠️ ProfileCache.load failed: $e');
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const String _key = 'authToken';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // ===================================================
  // 🔐 Get Token (Web + Mobile)
  // ===================================================
  static Future<String?> getToken() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_key);
      } else {
        return await _storage.read(key: _key);
      }
    } catch (e) {
      debugPrint("❌ TokenService.getToken error: $e");
      return null;
    }
  }

  // ===================================================
  // 💾 Save Token (Web + Mobile)
  // ===================================================
  static Future<void> saveToken(String token) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_key, token);
      } else {
        await _storage.write(key: _key, value: token);
      }
    } catch (e) {
      debugPrint("❌ TokenService.saveToken error: $e");
    }
  }

  // ===================================================
  // 🧹 Clear Token (Logout)
  // ===================================================
  static Future<void> clear() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_key);
      } else {
        await _storage.delete(key: _key);
      }
    } catch (e) {
      debugPrint("❌ TokenService.clear error: $e");
    }
  }

  // ===================================================
  // 👤 Extract user_id from JWT
  // ===================================================
  static Future<int?> getUserId() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return null;

      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = jsonDecode(
        utf8.decode(
          base64Url.decode(
            base64Url.normalize(parts[1]),
          ),
        ),
      );

      final userId = payload['user_id'];

      if (userId is int) return userId;
      if (userId is String) return int.tryParse(userId);

      return null;
    } catch (e) {
      debugPrint("❌ TokenService.getUserId error: $e");
      return null;
    }
  }
}

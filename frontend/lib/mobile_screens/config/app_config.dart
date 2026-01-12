import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// إعدادات التخزين الآمن
const FlutterSecureStorage _storage = FlutterSecureStorage();

// مفاتيح التخزين
class StorageKeys {
  static const String authToken = 'authToken'; // ✅ التهجئة الصحيحة
  static const String userId = 'userId';
  static const String userEmail = 'userEmail';
  static const String userRole = 'userRole';
}

// عنوان الـ API
const String BASE_URL = 'http://10.0.2.2:5000/api';

// 🔐 دوال إدارة التوكن والمستخدم
class AuthStorage {
  
  // حفظ بيانات المستخدم بعد التسجيل
  static Future<void> saveUserData({
    required String token,
    required String userId,
    required String email,
    required String role,
  }) async {
    await _storage.write(key: StorageKeys.authToken, value: token); // ✅ صحح التهجئة
    await _storage.write(key: StorageKeys.userId, value: userId);
    await _storage.write(key: StorageKeys.userEmail, value: email);
    await _storage.write(key: StorageKeys.userRole, value: role);
  }

  // جلب التوكن
  static Future<String> getToken() async {
    return await _storage.read(key: StorageKeys.authToken) ?? ''; // ✅ صحح التهجئة
  }

  // جلب ID المستخدم
  static Future<String> getUserId() async {
    return await _storage.read(key: StorageKeys.userId) ?? '';
  }

  // جلب بيانات المستخدم كاملة
  static Future<Map<String, String>> getUserData() async {
    return {
      'token': await _storage.read(key: StorageKeys.authToken) ?? '', // ✅ صحح التهجئة
      'userId': await _storage.read(key: StorageKeys.userId) ?? '',
      'email': await _storage.read(key: StorageKeys.userEmail) ?? '',
      'role': await _storage.read(key: StorageKeys.userRole) ?? '',
    };
  }

  // حذف جميع بيانات المستخدم (تسجيل الخروج)
  static Future<void> clearUserData() async {
    await _storage.delete(key: StorageKeys.authToken); // ✅ صحح التهجئة
    await _storage.delete(key: StorageKeys.userId);
    await _storage.delete(key: StorageKeys.userEmail);
    await _storage.delete(key: StorageKeys.userRole);
  }

  // التحقق مما إذا كان المستخدم مسجلاً دخوله
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token.isNotEmpty;
  }
}

// دوال التوافق مع الكود القديم
Future<String> getTokenFromStorage() async {
  return await AuthStorage.getToken();
}

Future<void> saveToken(String token) async {
  await _storage.write(key: StorageKeys.authToken, value: token); // ✅ صحح التهجئة
}

Future<void> deleteToken() async {
  await AuthStorage.clearUserData();
}
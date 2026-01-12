// File: lib/services/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/models/activity.dart';
import 'package:mobile/services/token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  // ===========================================================================
  // 🚀 Base URL ديناميكي للويب والموبايل
  // ===========================================================================
  static String get _host {
    if (kIsWeb) {
      return "localhost"; // للويب
    } else {
      return "10.0.2.2"; // للموبايل
    }
  }

  static String get _baseUrl => "http://$_host:5000/api";
  static String get baseUrl => _baseUrl;

  static final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const storage = FlutterSecureStorage();

  // ===========================================================================
  // Headers & Token Helpers
  // ===========================================================================

  static Future<Map<String, String>> getHeaders() async {
    return {
      'Content-Type': 'application/json',
    };
  }

// ===================================================
// 🟣 Admin: Import Students Excel
// ===================================================
  static Future<Map<String, dynamic>> importStudentsExcel({
    required Uint8List fileBytes,
    required String filename,
  }) async {
    final token = await _readJwtToken();
    if (token == null) {
      throw Exception("No auth token found");
    }

    final uri = Uri.parse("$_baseUrl/users/admin/import-students");

    final request = http.MultipartRequest("POST", uri);

    // ✅ Authorization
    request.headers["Authorization"] = "Bearer $token";

    // ✅ Excel file
    request.files.add(
      http.MultipartFile.fromBytes(
        "file",
        fileBytes,
        filename: filename,
        contentType: MediaType(
          "application",
          "vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        ),
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (!response.headers["content-type"]!.contains("application/json")) {
      throw Exception("Server returned non-JSON response:\n${response.body}");
    }

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data["message"] ?? "Import failed");
    }
  }

  static Future<String?> _readJwtToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final t1 = prefs.getString('authToken');
      if (t1 != null && t1.isNotEmpty) return t1;

      final t2 = prefs.getString('jwt_token');
      return (t2 != null && t2.isNotEmpty) ? t2 : null;
    } else {
      final t1 = await _storage.read(key: 'authToken');
      if (t1 != null && t1.isNotEmpty) return t1;

      final t2 = await _storage.read(key: 'jwt_token');
      return (t2 != null && t2.isNotEmpty) ? t2 : null;
    }
  }

  static Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await _readJwtToken();
    return {
      if (json) 'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, String>> _authHeaders({bool json = true}) async {
    final token = await _readJwtToken();
    if (token == null) {
      throw Exception('⚠️ No JWT token found in secure storage.');
    }
    return {
      if (json) 'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  // ===========================================================================
  // I) الأنشطة (Activities)
  // ===========================================================================

  static Future<void> addActivityWithFiles({
    required String title,
    required String description,
    required String location,
    required int createdBy,
    required String startDate,
    required String endDate,
    required String status,
    required File imageFile,
    File? formFile,
  }) async {
    final token = await _readJwtToken();
    if (token == null) throw Exception('⚠️ No token found.');

    final uri = Uri.parse('$_baseUrl/activities');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['title'] = title
      ..fields['description'] = description
      ..fields['location'] = location
      ..fields['created_by'] = createdBy.toString()
      ..fields['start_date'] = startDate
      ..fields['end_date'] = endDate
      ..fields['status'] = status
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    if (formFile != null) {
      request.files
          .add(await http.MultipartFile.fromPath('form', formFile.path));
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 201) {
      throw Exception('❌ Failed to add activity: ${res.body}');
    }
  }

  static Future<void> updateActivityWithFiles({
    required int id,
    required String title,
    required String description,
    required String location,
    required int createdBy,
    required String startDate,
    required String endDate,
    required String status,
    File? imageFile,
    File? formFile,
  }) async {
    final token = await _readJwtToken();
    if (token == null) throw Exception('⚠️ No token found.');

    final uri = Uri.parse('$_baseUrl/activities/$id');
    final request = http.MultipartRequest('PUT', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['title'] = title
      ..fields['description'] = description
      ..fields['location'] = location
      ..fields['created_by'] = createdBy.toString()
      ..fields['start_date'] = startDate
      ..fields['end_date'] = endDate
      ..fields['status'] = status;

    if (imageFile != null) {
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));
    }
    if (formFile != null) {
      request.files
          .add(await http.MultipartFile.fromPath('form', formFile.path));
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) {
      try {
        final err = jsonDecode(res.body);
        throw Exception(
            'Failed to update activity: ${err['message'] ?? res.body}');
      } catch (_) {
        throw Exception('Failed to update activity. Status: ${res.statusCode}');
      }
    }
  }

  static Future<void> deleteActivityWithAuth(int activityId) async {
    final url = Uri.parse('$_baseUrl/activities/$activityId');
    final res = await http.delete(url, headers: await _authHeaders());
    if (res.statusCode != 200) {
      try {
        final err = jsonDecode(res.body);
        throw Exception(
            'Failed to delete activity: ${err['message'] ?? res.body}');
      } catch (_) {
        throw Exception('Failed to delete activity. Status: ${res.statusCode}');
      }
    }
  }

  static Future<List<Activity>> getAllActivities() async {
    final url = Uri.parse('$_baseUrl/activities');
    final res = await http.get(url, headers: await _headers());
    if (res.statusCode == 200) {
      final jsonData = jsonDecode(res.body);
      final List<Activity> items =
          (jsonData['data'] as List).map((a) => Activity.fromJson(a)).toList();
      return items;
    }
    throw Exception('Failed to load activities. Status: ${res.statusCode}');
  }

  // ===========================================================================
  // II) مصادقة المستخدمين (Users Auth) + بروفايل
  // ===========================================================================

  static Future<http.Response> signUp({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) {
    final url = Uri.parse('$_baseUrl/users/signup');
    return http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': fullName,
        'email': email,
        'password': password,
        'role': role,
      }),
    );
  }

  static Future<http.Response> signIn({
    required String email,
    required String password,
  }) {
    final url = Uri.parse('$_baseUrl/users/signIn');
    return http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
  }

  static Future<http.Response> sendResetCode({required String email}) {
    final url = Uri.parse('$_baseUrl/users/forgot-password');
    return http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
  }

  static Future<http.Response> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    final url = Uri.parse('$_baseUrl/users/reset-password');
    return http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'email': email, 'code': code, 'newPassword': newPassword}),
    );
  }

  static Future<http.Response> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    final url = Uri.parse('$_baseUrl/change-password');
    return http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );
  }

  static Future<http.Response> uploadPhoto({
    required String email,
    required File imageFile,
  }) async {
    final url = Uri.parse('$_baseUrl/profile/photo');
    final token = await _readJwtToken();
    final req = http.MultipartRequest('PUT', url)
      ..headers['Authorization'] = 'Bearer ${token ?? ''}'
      ..fields['email'] = email
      ..files.add(await http.MultipartFile.fromPath('photo', imageFile.path));

    final streamed = await req.send();
    return http.Response.fromStream(streamed);
  }

  static Future<http.Response> fetchStudentProfile(String studentId) async {
    final url = Uri.parse("$_baseUrl/student/profile/$studentId");
    final res = await http.get(url,
        headers: await _authHeaders()); // ✅ استخدم الدالة الصحيحة
    return res;
  }

  static Future<http.Response> updateStudentProfile({
    required String studentId,
    required String fullName,
    required String email,
    required String phone,
    required String preferences,
    required String hobbies,
    File? imageFile,
  }) async {
    final url = Uri.parse('$_baseUrl/student/profile/$studentId');

    if (imageFile != null) {
      final req = http.MultipartRequest('PUT', url)
        ..headers.addAll(await _authHeaders(json: false))
        ..fields['full_name'] = fullName
        ..fields['email'] = email
        ..fields['phone_number'] = phone
        ..fields['preferences'] = preferences
        ..fields['hobbies'] = hobbies
        ..files.add(await http.MultipartFile.fromPath('photo', imageFile.path));
      final streamed = await req.send();
      return http.Response.fromStream(streamed);
    } else {
      return http.put(
        url,
        headers: await _authHeaders(),
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'phone_number': phone,
          'preferences': preferences,
          'hobbies': hobbies,
        }),
      );
    }
  }

  static Future<List<dynamic>> fetchAllStudents() async {
    final url = Uri.parse('$_baseUrl/students');
    final res = await http.get(url, headers: await _headers());

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);

      // ✅ إذا السيرفر رجع {"data": [...]}
      if (decoded is Map && decoded.containsKey('data')) {
        return List<Map<String, dynamic>>.from(decoded['data']);
      }

      // ✅ أو رجع قائمة مباشرة
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }

      // ⚠️ في حال غير متوقع
      print("⚠️ Unexpected response format: $decoded");
      return [];
    }

    throw Exception('Failed to load students: ${res.statusCode}');
  }

  // ===========================================================================
  // III) طلبات مخصّصة للطالب
  // ===========================================================================
  static Future<String?> getToken() async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: 'authToken');
  }

  static Future<http.Response> authGet(Uri url, {String? token}) async {
    // إذا ما تم تمرير توكن، نقرأه من التخزين الآمن
    final effectiveToken = token ?? await _readJwtToken();

    final headers = {
      'Content-Type': 'application/json',
      if (effectiveToken != null) 'Authorization': 'Bearer $effectiveToken',
    };

    return await http.get(url, headers: headers);
  }

  static Future<Map<String, dynamic>> postCustomRequest(Map body) async {
    final url = Uri.parse('$_baseUrl/student/requests');
    try {
      final res = await http.post(
        url,
        headers: await _headers(),
        body: json.encode(body),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        return {'success': true, 'data': json.decode(res.body)};
      }
      final err = json.decode(res.body);
      return {'success': false, 'message': err['error'] ?? res.body};
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> getMyRequests(String studentId) async {
    final url = Uri.parse('$_baseUrl/student/requests/$studentId');
    try {
      final res = await http.get(url, headers: await _headers());
      if (res.statusCode == 200) {
        return {'success': true, 'data': json.decode(res.body)};
      }
      final err = json.decode(res.body);
      return {'success': false, 'message': err['error'] ?? res.body};
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

// PATCH /requests/:id/status   Body: { "status": "approved" | "rejected" }
  static Future<void> updateCustomRequestStatus({
    required int requestId,
    required String status,
  }) async {
    final url =
        Uri.parse('$_baseUrl/student/requests/$requestId/status'); // ✅ fix
    final res = await http.patch(
      url,
      headers: await _authHeaders(),
      body: jsonEncode({'status': status}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Update status failed: ${res.body}');
    }
  }

  // ===========================================================================
  // IV) أدوات عامة مغطّاة بـ JWT
  // ===========================================================================

  static Future<http.Response> authMultipartPut(
    Uri url, {
    required Map<String, String> fields,
    String? fileField,
    File? file,
  }) async {
    final req = http.MultipartRequest('PUT', url)
      ..headers.addAll(await _authHeaders(json: false))
      ..fields.addAll(fields);

    if (fileField != null && file != null) {
      req.files.add(await http.MultipartFile.fromPath(fileField, file.path));
    }

    final streamed = await req.send();
    return http.Response.fromStream(streamed);
  }

  // ===========================================================================
  // V) إشعارات (FCM + النظام)
  // ===========================================================================

  /// تسجيل توكن FCM في الباك-إند
  static Future<void> registerFcmToken(String fcmToken) async {
    final url = Uri.parse('$_baseUrl/notifications/register-token');
    final res = await http.post(
      url,
      headers: await _authHeaders(),
      body: jsonEncode({'token': fcmToken, 'platform': 'android'}),
    );
    if (res.statusCode != 200) {
      throw Exception('Register token failed: ${res.body}');
    }
  }

  /// إرسال طلب تطوّع (المسار رقم 1: notifications/volunteer-request)
  static Future<Map<String, dynamic>> sendVolunteerRequest(
      int activityId) async {
    final url = Uri.parse('$_baseUrl/notifications/volunteer-request');
    final res = await http.post(
      url,
      headers: await _authHeaders(),
      body: jsonEncode({'activity_id': activityId}),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Volunteer request failed: ${res.body}');
  }

  /// (اختياري) إرسال طلب تطوع بالمسار البديل إذا كنتِ عاملة /volunteer/request في الباك-إند
  static Future<Map<String, dynamic>> requestVolunteerAlt(
      int activityId) async {
    final url = Uri.parse('$_baseUrl/volunteer/request');
    final res = await http.post(
      url,
      headers: await _authHeaders(),
      body: jsonEncode({'activityId': activityId}),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Volunteer request (alt) failed: ${res.body}');
  }

  /// قائمة إشعاراتي
  static Future<List<dynamic>> getMyNotifications(
      {int page = 1, int limit = 20}) async {
    final url = Uri.parse('$_baseUrl/notifications/my?page=$page&limit=$limit');
    final res = await http.get(url, headers: await _authHeaders(json: false));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['data'] as List?) ?? <dynamic>[];
    }
    throw Exception('Fetch notifications failed: ${res.body}');
  }

  /// عدد غير المقروء
  static Future<int> getUnreadCount() async {
    final url = Uri.parse('$_baseUrl/notifications/unread-count');
    final res = await http.get(url, headers: await _authHeaders(json: false));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      // يدعم { unread: N } أو { count: N }
      return (data['unread'] as int?) ?? (data['count'] as int?) ?? 0;
    }
    throw Exception('Fetch unread failed: ${res.body}');
  }

  /// تعليم إشعار كمقروء
  static Future<void> markNotificationRead(int id) async {
    final url = Uri.parse('$_baseUrl/notifications/$id/read');
    final res = await http.patch(url, headers: await _authHeaders(json: false));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Mark read failed: ${res.body}');
    }
  }

  /// تنفيذ (قبول/رفض) على إشعار التطوع — خاص بالسنتر
  static Future<void> actOnNotification(int id, String action) async {
    final url = Uri.parse('$_baseUrl/notifications/$id/act');
    final res = await http.post(
      url,
      headers: await _authHeaders(),
      body: jsonEncode({'action': action}), // 'accept' | 'reject'
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Act failed: ${res.body}');
    }
  }

// === Student Progress ===
  static Future<Map<String, dynamic>> getStudentProgress(
      String studentUniId) async {
    final url = Uri.parse('$_baseUrl/student/progress/$studentUniId');
    final res = await http.get(url, headers: await _authHeaders(json: false));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch progress: ${res.body}');
  }

// ====== Calendar APIs ======
  static Future<Map<String, dynamic>> getCalendarMonth({
    required String studentUniId,
    required int year,
    required int month,
  }) async {
    final url = Uri.parse(
        '$_baseUrl/calendar/month/$studentUniId?year=$year&month=$month');
    final res = await http.get(url, headers: await _authHeaders());
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Calendar month fetch failed: ${res.body}');
  }

  static Future<int> getCalendarDueCount(String studentUniId) async {
    final url = Uri.parse('$_baseUrl/calendar/due-count/$studentUniId');
    final res = await http.get(url, headers: await _authHeaders());
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['upcoming_distinct_days'] as int?) ?? 0;
    }
    throw Exception('Calendar due count failed: ${res.body}');
  }

  // ===========================================================================
// VI) الرسائل (Messages)
// ===========================================================================

  /// جلب كل المحادثة بين مستخدمين
  static Future<http.Response> getConversation(int user1, int user2) async {
    final url = Uri.parse('$_baseUrl/messages/conversation/$user1/$user2');
    return await http.get(url, headers: await _authHeaders());
  }

  /// إرسال رسالة جديدة
  /// إرسال رسالة (نص + ملف اختياري)
  static Future<http.Response> sendMessage({
    required int senderId,
    required int receiverId,
    String? content,
    File? attachment,
  }) async {
    final token = await _readJwtToken();
    final url = Uri.parse('$_baseUrl/messages/send');

    var request = http.MultipartRequest("POST", url);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['sender_id'] = senderId.toString();
    request.fields['receiver_id'] = receiverId.toString();
    if (content != null) request.fields['content'] = content;

    if (attachment != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'attachment',
          attachment.path,
        ),
      );
    }

    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  /// عدد الرسائل غير المقروءة للمستخدم
  /// عدد الرسائل غير المقروءة للمستخدم
  static Future<http.Response> getMessagesUnreadCount(int userId) async {
    final url = Uri.parse('$_baseUrl/messages/unread-count/$userId');
    return await http.get(url, headers: await _authHeaders());
  }

  /// الرسائل غير المقروءة مجمعة مع آخر محتوى وتاريخ
  static Future<http.Response> getUnreadGrouped(int userId) async {
    final url = Uri.parse('$_baseUrl/messages/unread-grouped/$userId');
    return await http.get(url, headers: await _authHeaders());
  }

  /// تعليم رسالة كمقروءة
  static Future<http.Response> markMessageRead(int messageId) async {
    final url = Uri.parse('$_baseUrl/messages/$messageId/read');
    return await http.patch(url, headers: await _authHeaders());
  }

  static Future<int?> getUserIdByStudentId(String studentId) async {
    try {
      final token = await _readJwtToken();
      if (token == null) {
        throw Exception("No token found");
      }

      final url = Uri.parse("$_baseUrl/student/user-id/$studentId");

      final res = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return data['user_id'];
      } else {
        print("⚠️ Failed to get userId from studentId: ${res.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching userId: $e");
      return null;
    }
  }

  // ===========================================================================
// VII) صفحة المساعدة (Help / FAQs)
// ===========================================================================
  static Future<List<Map<String, dynamic>>> getFaqs() async {
    final url = Uri.parse('$_baseUrl/help/faqs');
    final res = await http.get(url, headers: await _headers());

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to fetch FAQs: ${res.statusCode}');
    }
  }

  static Future<List<dynamic>> getAllUsers() async {
    final url = Uri.parse('$_baseUrl/users');
    final res = await http.get(url, headers: await _authHeaders());

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        return decoded;
      }
      return [];
    } else {
      throw Exception("Failed to load users: ${res.statusCode}");
    }
  }

  static Future<int?> getUserIdFromUniId(String uniId) async {
    final url = Uri.parse("$_baseUrl/users/get-userid-by-uni/$uniId");

    final res = await http.get(
      url,
      headers: await _authHeaders(), // ✅ لازم توكن
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body)["user_id"];
    }
    return null;
  }

  static Future<List<dynamic>> getDoctorStudents(int doctorId) async {
    final url = Uri.parse("$_baseUrl/users/admin/doctor/$doctorId/students");
    final res = await http.get(url, headers: await _authHeaders());

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data["data"]; // قائمة الطلاب
    } else {
      print("⚠️ Failed to fetch doctor students: ${res.body}");
      return [];
    }
  }

  static Future<int?> getUserIdByDoctorId(int doctorId) async {
    try {
      final url = Uri.parse("$_baseUrl/doctor/user-id/$doctorId");
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return data['user_id'];
      } else {
        print("⚠️ Failed to get userId from doctorId: ${res.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching userId by doctorId: $e");
      return null;
    }
  }

  //---------service requests (FIXED WITH AUTH)
  static Future<http.Response> getVolunteerRequests() async {
    return await http.get(
      Uri.parse("$_baseUrl/requests/volunteer"),
      headers: await _authHeaders(),
    );
  }

  static Future<http.Response> getCustomRequests() async {
    return await http.get(
      Uri.parse("$_baseUrl/requests/custom"),
      headers: await _authHeaders(),
    );
  }

  static Future<http.Response> acceptVolunteerRequest(int id) async {
    return await http.put(
      Uri.parse("$_baseUrl/requests/volunteer/accept/$id"),
      headers: await _authHeaders(),
    );
  }

  static Future<http.Response> rejectVolunteerRequest(int id) async {
    return await http.put(
      Uri.parse("$_baseUrl/requests/volunteer/reject/$id"),
      headers: await _authHeaders(),
    );
  }

//-------service approvals (FIXED WITH AUTH)
  static Future<http.Response> getApprovedVolunteer() async {
    return await http.get(
      Uri.parse("$_baseUrl/requests/approved/volunteer"),
      headers: await _authHeaders(),
    );
  }

  static Future<http.Response> getApprovedCustom() async {
    return await http.get(
      Uri.parse("$_baseUrl/requests/approved/custom"),
      headers: await _authHeaders(),
    );
  }

  static Future<void> sendCourseResult(int studentUserId) async {
    final token = await getUnifiedToken();
    final serverIP = kIsWeb ? "localhost" : "10.0.2.2";

    final res = await http.post(
      Uri.parse("http://$serverIP:5000/api/hours/send-result/$studentUserId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }
  }

// ===============================================
// 🟣 Student Submission – Auto Fetch
// يستخدمه: StudentSubmissionScreen
// ===============================================

  // ===============================================
// 🟣 Upload Submission File
// ===============================================

  static Future<http.Response> getCustomRequestSimilarity(int requestId) async {
    final token = await getUnifiedToken(); // ✅ الحل

    if (token == null) {
      throw Exception("No auth token found");
    }

    final url = Uri.parse('$_baseUrl/ai/center/requests/$requestId/similarity');

    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  static Future<Map<String, dynamic>?> getStudentSubmissionAuto(
      String studentId) async {
    final token = await _readJwtToken();
    if (token == null) throw Exception("No token found");

    final url = Uri.parse("$_baseUrl/submissions/student/$studentId");

    final res = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    });

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    // لو ما لقى سبميشن، نرجّع null
    return null;
  }

  static Future<Map<String, dynamic>> uploadSubmission({
    required File file,
    required String studentId,
    required String activityId,
  }) async {
    final token = await _readJwtToken();
    if (token == null) throw Exception("No token found");

    final uri = Uri.parse("$_baseUrl/submissions/upload");

    var request = http.MultipartRequest("POST", uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['studentId'] = studentId
      ..fields['activityId'] = activityId
      ..files.add(await http.MultipartFile.fromPath(
        "submission_file",
        file.path,
      ));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    }

    throw Exception("Upload failed: ${res.body}");
  }

  static Future<List<dynamic>> getStudentAllSubmissions(
    int userId,
  ) async {
    final token = await _readJwtToken();
    if (token == null) throw Exception("No token found");

    final url = Uri.parse("$_baseUrl/submissions/student/$userId/all");

    final res = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    return [];
  }

  // =============================
// Center: Update Custom Request
// PATCH /requests/custom/:id/status
// =============================
  static Future<Map<String, dynamic>> updateCenterCustomRequestStatus({
    required int requestId,
    required String status,
  }) async {
    final url = Uri.parse('$_baseUrl/requests/custom/$requestId/status');
    final res = await http.patch(
      url,
      headers: await _authHeaders(),
      body: jsonEncode({"status": status}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Center update failed: ${res.body}");
    }
  }

  //------------------------------- calendar ---------------------------------------
  static Future<List<dynamic>> getCalendarActivities() async {
    final token = await _readJwtToken();
    if (token == null) throw Exception("No token found");

    final response = await http.get(
      Uri.parse("$_baseUrl/service/activities/calendar"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception("Failed to fetch calendar activities: ${response.body}");
    }
  }

// ===================== REMINDERS =====================
  static Future<void> addReminder({
    required int activityId,
    required DateTime remindDate,
    required String note,
  }) async {
    final token = await _readJwtToken();
    if (token == null) throw Exception("No token found");

    final url = Uri.parse("$_baseUrl/service/reminders");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "activity_id": activityId,
        "remind_date": remindDate.toIso8601String(),
        "note": note,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to add reminder: ${response.body}");
    }
  }
/*
  static Future<List<dynamic>> getDoctorSummary() async {
    final token = await storage.read(key: 'authToken');

    final response = await http.get(
      Uri.parse("http://10.0.2.2:5000/api/hours/doctor-summary"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load doctor summary");
    }
  }
*/

  static Future<List<dynamic>> getDoctorSummary() async {
    final token = await TokenService.getToken();
    if (token == null) throw Exception("No token");

    final serverIP = kIsWeb ? "localhost" : "10.0.2.2";

    final res = await http.get(
      Uri.parse("http://$serverIP:5000/api/hours/doctor-summary"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load doctor summary");
    }

    final body = jsonDecode(res.body);
    return body is List ? body : body['data'] ?? [];
  }

  // ===============================
// Admin Dashboard API
// ===============================
  static Future<Map<String, dynamic>> getAdminDashboard({
    String? range,
    String? start,
    String? end,
  }) async {
    String url = "$_baseUrl/admin/dashboard";

    // إضافة الفلاتر للـ URL
    if (range != null) {
      url += "?range=$range";
    } else if (start != null && end != null) {
      url += "?start=$start&end=$end";
    }

    final res = await http.get(
      Uri.parse(url),
      headers: await _authHeaders(),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load admin dashboard: ${res.body}");
    }
  }

  /// ✅ توكن موحّد (Web: SharedPrefs / Mobile: SecureStorage)
  static Future<String?> getAuthToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString("authToken");
    }
    return await _storage.read(key: "authToken");
  }

  // ===============================
// 🔵 WEB: Send Message (No dart:io)
// ===============================
  static Future<http.Response> sendMessageWeb({
    required int senderId,
    required int receiverId,
    String? content,
    Uint8List? attachmentBytes,
    String? attachmentName,
  }) async {
    final token = await _readJwtToken();
    final url = Uri.parse('$_baseUrl/messages/send');

    final request = http.MultipartRequest("POST", url);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['sender_id'] = senderId.toString();
    request.fields['receiver_id'] = receiverId.toString();
    if (content != null) request.fields['content'] = content;

    if (attachmentBytes != null && attachmentName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'attachment',
          attachmentBytes,
          filename: attachmentName,
        ),
      );
    }

    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

// ApiService.dart

  static Future<String?> getUnifiedToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString("authToken");
    } else {
      return await _storage.read(key: "authToken");
    }
  }

  static Future<Map<String, String>> chatHeaders() async {
    final token = await getUnifiedToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }
// ===================================================
// 💬 Messages – Unified Web & Mobile (NO API CHANGE)
// ===================================================

  static Future<http.Response> getConversationUnified(
    int user1,
    int user2,
  ) async {
    final url = Uri.parse("$_baseUrl/messages/conversation/$user1/$user2");
    return await http.get(url, headers: await chatHeaders());
  }

  static Future<http.Response> getUnreadGroupedUnified(int userId) async {
    final url = Uri.parse("$_baseUrl/messages/unread-grouped/$userId");
    return await http.get(url, headers: await chatHeaders());
  }

  static Future<http.Response> sendMessageUnified({
    required int senderId,
    required int receiverId,
    String? content,
  }) async {
    final url = Uri.parse("$_baseUrl/messages/send");
    return await http.post(
      url,
      headers: await chatHeaders(),
      body: jsonEncode({
        "sender_id": senderId,
        "receiver_id": receiverId,
        "content": content ?? "",
      }),
    );
  }

  static Future<Map<String, dynamic>> uploadSubmissionWeb({
    required Uint8List fileBytes,
    required String filename,
    required String studentId,
    required String activityId,
  }) async {
    final token = await TokenService.getToken();

    final uri = Uri.parse(
      "${ApiService.baseUrl}/submissions/upload", // ✨ تأكدي هذا نفس route بالسيرفر
    );

    final request = http.MultipartRequest("POST", uri);

    // ✅ Authorization
    if (token != null) {
      request.headers["Authorization"] = "Bearer $token";
    }

    // ✅ file
    request.files.add(
      http.MultipartFile.fromBytes(
        "file",
        fileBytes,
        filename: filename,
      ),
    );

    // ✅ fields
    request.fields["student_id"] = studentId;
    request.fields["activity_id"] = activityId;

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    // 🛑 إذا السيرفر رجّع HTML
    if (!response.headers["content-type"]!.contains("application/json")) {
      throw Exception(
        "Server returned non-JSON response:\n${response.body}",
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Upload failed: ${response.body}");
    }
  }

// ===========================================================
// 🟣 WEB: Add Activity (Uint8List – NO dart:io)
// ===========================================================
  static Future<void> addActivityWeb({
    required String title,
    required String description,
    required String location,
    required int createdBy,
    required String startDate,
    required String endDate,
    required String status,
    required Uint8List imageBytes,
    required String imageName,
    Uint8List? pdfBytes,
    String? pdfName,
  }) async {
    final token = await _readJwtToken();
    if (token == null) {
      throw Exception("⚠️ No JWT token found");
    }

    final uri = Uri.parse("$_baseUrl/activities");
    final request = http.MultipartRequest("POST", uri);

    // ✅ Headers
    request.headers["Authorization"] = "Bearer $token";

    // ✅ Fields
    request.fields["title"] = title;
    request.fields["description"] = description;
    request.fields["location"] = location;
    request.fields["created_by"] = createdBy.toString();
    request.fields["start_date"] = startDate;
    request.fields["end_date"] = endDate;
    request.fields["status"] = status;

    // ✅ Image (REQUIRED)
    request.files.add(
      http.MultipartFile.fromBytes(
        "image",
        imageBytes,
        filename: imageName,
        contentType: MediaType("image", "jpeg"),
      ),
    );

    // ✅ PDF (OPTIONAL)
    if (pdfBytes != null && pdfName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          "form",
          pdfBytes,
          filename: pdfName,
          contentType: MediaType("application", "pdf"),
        ),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 201) {
      throw Exception(
        "❌ Failed to add activity (WEB): ${response.body}",
      );
    }
  }

  static Future<List<dynamic>> getServiceConversations(int myId) async {
    final token = await TokenService.getToken();
    final url = Uri.parse("$baseUrl/messages/unread-grouped/$myId");
    final res = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      return decoded['data'] ?? [];
    } else {
      throw Exception("Failed to load conversations");
    }
  }
  // ===============================
// Admin Users Management
// ===============================

  static Future<List<dynamic>> getAdminUsers() async {
    final url = Uri.parse('$_baseUrl/admin/users');
    final res = await http.get(url, headers: await _authHeaders());

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load users");
    }
  }

  static Future<void> deactivateUser(int userId) async {
    final url = Uri.parse('$_baseUrl/admin/users/$userId/deactivate');
    final res = await http.put(url, headers: await _authHeaders());

    if (res.statusCode != 200) {
      throw Exception("Failed to deactivate user");
    }
  }

  static Future<void> activateUser(int userId) async {
    final url = Uri.parse('$_baseUrl/admin/users/$userId/activate');
    final res = await http.put(url, headers: await _authHeaders());

    if (res.statusCode != 200) {
      throw Exception("Failed to activate user");
    }
  }

  static Future<void> changeUserRole(int userId, String role) async {
    final url = Uri.parse('$_baseUrl/admin/users/$userId/role');
    final res = await http.put(
      url,
      headers: await _authHeaders(),
      body: jsonEncode({"role": role}),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to change user role");
    }
  }
  // ===============================
// 🔐 Admin Roles & Permissions
// ===============================

// 🔹 Get all roles
  static Future<List<dynamic>> getAllRoles() async {
    final url = Uri.parse('$_baseUrl/admin/roles');
    final res = await http.get(url, headers: await _authHeaders());

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load roles");
    }
  }

// 🔹 Get all permissions
  static Future<List<dynamic>> getAllPermissions() async {
    final url = Uri.parse('$_baseUrl/admin/permissions');
    final res = await http.get(url, headers: await _authHeaders());

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load permissions");
    }
  }

// 🔹 Get permissions for a specific role
  static Future<List<dynamic>> getRolePermissions(int roleId) async {
    final url = Uri.parse('$_baseUrl/admin/roles/$roleId/permissions');
    final res = await http.get(url, headers: await _authHeaders());

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load role permissions");
    }
  }

// 🔹 Create new role
  static Future<void> createRole({
    required String name,
    String? description,
    required List<String> permissions,
  }) async {
    final url = Uri.parse('$_baseUrl/admin/roles');
    final res = await http.post(
      url,
      headers: await _authHeaders(),
      body: jsonEncode({
        "name": name,
        "description": description,
        "permissions": permissions, // BY NAME ✔️
      }),
    );

    if (res.statusCode != 201) {
      throw Exception("Failed to create role: ${res.body}");
    }
  }

// 🔹 Update role
  static Future<void> updateRole({
    required int roleId,
    required String name,
    String? description,
    required List<String> permissions,
  }) async {
    final url = Uri.parse('$_baseUrl/admin/roles/$roleId');
    final res = await http.put(
      url,
      headers: await _authHeaders(),
      body: jsonEncode({
        "name": name,
        "description": description,
        "permissions": permissions,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to update role: ${res.body}");
    }
  }

// 🔹 Delete role
  static Future<void> deleteRole(int roleId) async {
    final url = Uri.parse('$_baseUrl/admin/roles/$roleId');
    final res = await http.delete(url, headers: await _authHeaders());

    if (res.statusCode != 200) {
      throw Exception("Failed to delete role: ${res.body}");
    }
  }
}

// File: lib/services/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/models/activity.dart';

class ApiService {
  // ===========================================================================
  // إعدادات عامة
  // ===========================================================================
  static const String _baseUrl = 'http://10.0.2.2:5000/api';
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const storage = FlutterSecureStorage();
  static const String baseUrl = _baseUrl;

  static Future<Map<String, String>> getHeaders() async {
    return {
      'Content-Type': 'application/json',
    };
  }

  /// نقرأ JWT من التخزين الآمن — ندعم مفتاحين لتجنّب 401 بسبب اختلافات قديمة.
  static Future<String?> _readJwtToken() async {
    final t1 = await _storage.read(key: 'authToken');
    if (t1 != null && t1.isNotEmpty) return t1;
    final t2 = await _storage.read(key: 'jwt_token');
    return (t2 != null && t2.isNotEmpty) ? t2 : null;
  }

  /// هيدر بـ Authorization إن وُجد توكن. استعمله للطلبات العامة.
  static Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await _readJwtToken();
    return {
      if (json) 'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// هيدر مُلزِم يتطلّب JWT. استعمله مع كل Endpoint محمي.
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

  /// إضافة نشاط جديد مع صورة + ملف (اختياري)
  static Future<void> addActivityWithFiles({
    required String title,
    required String description,
    required String location,
    required int createdBy,
    required String startDate, // ISO string
    required String endDate, // ISO string
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

  /// تحديث نشاط مع إمكانية تغيير الملفات
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

  /// حذف نشاط
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

  /// جلب كل الأنشطة
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
      final url = Uri.parse("$_baseUrl/student/user-id/$studentId");
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return data['user_id']; // ✅ هذا هو الـ user_id اللي بدك تستخدمه
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
    final res = await http.get(url);
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
      Uri.parse("$baseUrl/requests/volunteer"),
      headers: await _authHeaders(),
    );
  }

  static Future<http.Response> getCustomRequests() async {
    return await http.get(
      Uri.parse("$baseUrl/requests/custom"),
      headers: await _authHeaders(),
    );
  }

  static Future<http.Response> acceptVolunteerRequest(int id) async {
    return await http.put(
      Uri.parse("$baseUrl/requests/volunteer/accept/$id"),
      headers: await _authHeaders(),
    );
  }

  static Future<http.Response> rejectVolunteerRequest(int id) async {
    return await http.put(
      Uri.parse("$baseUrl/requests/volunteer/reject/$id"),
      headers: await _authHeaders(),
    );
  }

//-------service approvals (FIXED WITH AUTH)
  static Future<http.Response> getApprovedVolunteer() async {
    return await http.get(
      Uri.parse("$baseUrl/requests/approved/volunteer"),
      headers: await _authHeaders(),
    );
  }

  static Future<http.Response> getApprovedCustom() async {
    return await http.get(
      Uri.parse("$baseUrl/requests/approved/custom"),
      headers: await _authHeaders(),
    );
  }

// ===============================================
// 🟣 Student Submission – Auto Fetch
// يستخدمه: StudentSubmissionScreen
// ===============================================
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

  // ===============================================
// 🟣 Upload Submission File
// ===============================================
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
      String studentId) async {
    final token = await _readJwtToken();
    if (token == null) throw Exception("No token found");

    final url = Uri.parse("$_baseUrl/submissions/student/$studentId/all");

    final res = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    });

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }

  static Future<http.Response> getCustomRequestSimilarity(int requestId) async {
    final token = await _storage.read(key: 'authToken');

    final url = Uri.parse('$baseUrl/ai/center/requests/$requestId/similarity');

    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  // =============================
// Center: Update Custom Request
// PATCH /requests/custom/:id/status
// =============================
  static Future<Map<String, dynamic>> updateCenterCustomRequestStatus({
    required int requestId,
    required String status,
  }) async {
    final url = Uri.parse('$baseUrl/requests/custom/$requestId/status');
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
}

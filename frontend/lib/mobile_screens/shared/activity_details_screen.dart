import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile/mobile_screens/center/updateActivityScreen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/models/activity.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // ✅ استيراد صحيح

const Color primaryColor = Color(0xFF064F54);
const String _BASE_URL = "http://10.0.2.2:5000";

class ActivityDetailsScreen extends StatefulWidget {
  final int activityId;
  const ActivityDetailsScreen({super.key, required this.activityId});

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  Map<String, dynamic>? _activity;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchActivityDetails();
  }

  Activity _mapToActivity(Map<String, dynamic> a) {
    DateTime _parse(String? v) => (v == null || v.isEmpty)
        ? DateTime.now()
        : DateTime.tryParse(v) ?? DateTime.now();

    return Activity(
      id: a['id'] as int,
      title: (a['title'] ?? '') as String,
      description: (a['description'] ?? '') as String,
      location: (a['location'] ?? '') as String,
      createdBy: (a['created_by'] ?? 0) as int,
      startDate: _parse(a['start_date'] as String?),
      endDate: _parse(a['end_date'] as String?),
      status: (a['status'] ?? 'pending') as String,
      imageUrl: (a['image_url'] ?? '') as String,
      formTemplatePath: a['form_template_path'] as String?,
      createdAt: _parse(a['created_at'] as String?),
      updatedAt: _parse(a['updated_at'] as String?),
    );
  }

  // 🌐 جلب تفاصيل النشاط
  // 🌐 جلب تفاصيل النشاط (مع التوكن)
  // 🌐 جلب تفاصيل النشاط (مع التوكن الصحيح)
  Future<void> _fetchActivityDetails() async {
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'authToken'); // ✅ من تسجيل الدخول

      if (token == null) {
        print("⚠️ No token found in storage!");
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse("$_BASE_URL/api/activities/${widget.activityId}");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', // ✅ إرسال التوكن
          'Content-Type': 'application/json',
        },
      );

      print("📡 GET ${url.toString()} → ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        setState(() {
          _activity = decoded;
          _isLoading = false;
          _hasError = false;
        });

        print("✅ Activity loaded successfully!");
      } else {
        print("❌ Failed to fetch: ${response.statusCode}");
        print(response.body);
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Exception fetching activity: $e");
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  // 🗑️ حذف النشاط
  Future<void> _deleteActivity() async {
    try {
      await ApiService.deleteActivityWithAuth(_activity!['id']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Activity deleted successfully!")),
      );
      Navigator.pop(context, true); // للرجوع وتحديث الصفحة السابقة
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete: $e")),
      );
    }
  }

  // ✏️ تعديل النشاط
  void _editActivity() {
    // نحول الماب إلى كائن Activity قبل ما نمرره
    final activityObj = _mapToActivity(_activity!);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateActivityScreen(activity: activityObj),
      ),
    ).then((updated) {
      if (updated == true) _fetchActivityDetails();
    });
  }

  // 🧾 تحميل PDF
  Future<void> _downloadAndOpenPdf(String url) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = url.split('/').last;
      final filePath = '${dir.path}/$fileName';

      await Dio().download(url, filePath);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Downloaded: $fileName')));

      await OpenFilex.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _formatDate(String date) {
    try {
      return DateFormat('yyyy-MM-dd | hh:mm a')
          .format(DateTime.parse(date).toLocal());
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    if (_hasError || _activity == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Activity Details"),
          backgroundColor: primaryColor,
        ),
        body: const Center(
          child: Text(
            "❌ Failed to load activity details.",
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }

    final activity = _activity!;
    final imageUrl = '$_BASE_URL${activity["image_url"] ?? ""}';
    final formUrl = activity["form_template_path"] != null
        ? '$_BASE_URL${activity["form_template_path"]}'
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FB),
      appBar: AppBar(
        title: const Text("Activity Details"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Card(
          elevation: 5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🖼️ الصورة
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, __) => Container(
                      height: 220,
                      color: Colors.grey[300],
                      child: const Center(
                          child:
                              Icon(Icons.image, size: 60, color: Colors.grey)),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                Text(
                  activity["title"] ?? "No Title",
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryColor),
                ),
                const SizedBox(height: 10),
                Text(
                  activity["description"] ?? "No description available.",
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
                const Divider(height: 25, color: Colors.grey),

                _buildRow(Icons.place, "Location", activity["location"]),
                _buildRow(Icons.person, "Created By",
                    activity["created_by"].toString()),
                _buildRow(Icons.event, "Start Date",
                    _formatDate(activity["start_date"] ?? "")),
                _buildRow(Icons.event_available, "End Date",
                    _formatDate(activity["end_date"] ?? "")),
                _buildRow(Icons.check_circle, "Status",
                    activity["status"] ?? "Unknown"),

                if (formUrl != null) ...[
                  const SizedBox(height: 15),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.picture_as_pdf,
                          color: Colors.red, size: 40),
                      title: const Text("Service Form (PDF)"),
                      subtitle: const Text("Tap to view or download"),
                      onTap: () => _downloadAndOpenPdf(formUrl),
                    ),
                  ),
                ],

                const SizedBox(height: 25),

                // 🧰 الأزرار
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_forever,
                          color: Colors.red, size: 26),
                      onPressed: _deleteActivity,
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon:
                          const Icon(Icons.edit, color: primaryColor, size: 26),
                      onPressed: _editActivity,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: "$label: ",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: primaryColor),
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                        color: Colors.black87, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

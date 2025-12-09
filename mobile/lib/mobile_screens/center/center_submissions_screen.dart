import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'student_submission_details_screen.dart';

class CenterSubmissionsScreen extends StatefulWidget {
  const CenterSubmissionsScreen({super.key});

  @override
  State<CenterSubmissionsScreen> createState() =>
      _CenterSubmissionsScreenState();
}

class _CenterSubmissionsScreenState extends State<CenterSubmissionsScreen> {
  final storage = const FlutterSecureStorage();
  static const String serverIP = "10.0.2.2";

  bool loading = true;
  List<dynamic> students = [];

  @override
  void initState() {
    super.initState();
    fetchSummary();
  }

  Future<void> fetchSummary() async {
    try {
      final token = await storage.read(key: 'authToken');
      final url =
          Uri.parse("http://$serverIP:5000/api/submissions/center-summary");

      final res = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          students = data;
          loading = false;
        });
      } else {
        print("Error: ${res.body}");
        setState(() => loading = false);
      }
    } catch (e) {
      print("❌ Error fetching summary: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ---------------------- APPBAR ------------------------
      appBar: AppBar(
        backgroundColor: Colors.transparent, // بدون خلفية
        elevation: 0,
        toolbarHeight: 90, // ينزل التايتل لتحت
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF7B1FA2), // السهم بنفسجي
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Padding(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            "Students Submissions",
            style: TextStyle(
              fontFamily: "Baloo",
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Color(0xFF7B1FA2), // Purple
            ),
          ),
        ),
        centerTitle: true,
      ),

      // ---------------------- BODY ------------------------
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? const Center(
                  child: Text(
                    "No submissions yet.",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final s = students[index];

                    final studentId = s["student_id"];
                    final name = s["full_name"];
                    final totalHours = s["total_hours"];
                    final photo = s["photo_url"] != null
                        ? "http://$serverIP:5000${s["photo_url"]}"
                        : null;

                    final submissions = s["submissions"] ?? [];
                    final submissionsCount = submissions.length;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      child: Material(
                        elevation: 6,
                        shadowColor: Colors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFF7F2FF),
                                Color(0xFFEDE3FF),
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // ---------------- Avatar ----------------
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.purple.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  image: photo != null
                                      ? DecorationImage(
                                          image: NetworkImage(photo),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                              ),

                              const SizedBox(width: 18),

                              // ---------------- Student Info ----------------
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontFamily: "Baloo",
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4A148C),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.timer_outlined,
                                            size: 18, color: Colors.purple),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Hours: $totalHours",
                                          style: const TextStyle(
                                            color: Colors.purple,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.file_copy_outlined,
                                            size: 18, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Submissions: $submissionsCount",
                                          style: const TextStyle(
                                              color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // ---------------- View Button ----------------
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 10),
                                  backgroundColor: Colors.purple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 3,
                                ),
                                onPressed: () async {
                                  final updated = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          StudentSubmissionDetailsScreen(
                                        studentData: s,
                                      ),
                                    ),
                                  );

                                  if (updated == true) {
                                    fetchSummary();
                                    setState(() {});
                                  }
                                },
                                child: const Text(
                                  "View",
                                  style: TextStyle(
                                    fontFamily: "Baloo",
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile/mobile_screens/center/student_submission_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';


class CenterSubmissionsScreen extends StatefulWidget {
  const CenterSubmissionsScreen({super.key});

  @override
  State<CenterSubmissionsScreen> createState() =>
      _CenterSubmissionsScreenState();
}

class _CenterSubmissionsScreenState extends State<CenterSubmissionsScreen> {
  final storage = const FlutterSecureStorage();

  static String get serverIP =>
      kIsWeb ? "localhost" : "10.0.2.2";

  bool loading = true;
  List<dynamic> students = [];

  @override
  void initState() {
    super.initState();
    fetchSummary();
  }

  // ================= TOKEN (WEB + MOBILE) =================
  Future<String?> _getToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString("authToken");
    } else {
      return await storage.read(key: 'authToken');
    }
  }

  // ================= FETCH SUMMARY =================
  Future<void> fetchSummary() async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final url = Uri.parse(
        "http://$serverIP:5000/api/submissions/center-summary",
      );

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
        loading = false;
      }
    } catch (e) {
      loading = false;
    }
  }

  // ================= PROCESS HOURS =================
  Future<void> processHours() async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final url =
          Uri.parse("http://$serverIP:5000/api/hours/process");

      final res = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.statusCode == 200
                ? "Hours processed and sent to doctors!"
                : "Error processing hours",
          ),
          backgroundColor:
              res.statusCode == 200 ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {}
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 90,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF7B1FA2)),
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
              color: Color(0xFF7B1FA2),
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text(
                      "Process All Hours",
                      style: TextStyle(
                        fontFamily: "Baloo",
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () async {
                      await processHours();
                      fetchSummary();
                    },
                  ),
                ),
                Expanded(
                  child: students.isEmpty
                      ? const Center(
                          child: Text("No submissions yet."),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: students.length,
                          itemBuilder: (_, index) {
                            final s = students[index];

                            final photo = s["photo_url"] != null
                                ? "http://$serverIP:5000${s["photo_url"]}"
                                : null;

                            return Card(
                              margin:
                                  const EdgeInsets.only(bottom: 16),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: photo != null
                                      ? NetworkImage(photo)
                                      : null,
                                  child: photo == null
                                      ? Text(
                                          s["full_name"][0],
                                        )
                                      : null,
                                ),
                                title: Text(s["full_name"]),
                                subtitle: Text(
                                    "Hours: ${s["total_hours"]} | Submissions: ${s["submissions"].length}"),
                                trailing: ElevatedButton(
                                  onPressed: () async {
                                    final updated =
                                        await Navigator.push(
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
                                    }
                                  },
                                  child: const Text("View"),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

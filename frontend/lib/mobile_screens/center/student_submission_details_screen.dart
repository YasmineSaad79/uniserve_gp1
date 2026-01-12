import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

const Color uniPurple = Color(0xFF7B1FA2);

class StudentSubmissionDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> studentData;

  const StudentSubmissionDetailsScreen({
    super.key,
    required this.studentData,
  });

  // -------------------------------------------------------
  // APPROVE FUNCTION
  // -------------------------------------------------------
  Future<void> approveSubmission(sub, storage, serverIP, context) async {
    final token = await storage.read(key: 'authToken');

    final url = Uri.parse(
      "http://$serverIP:5000/api/submissions/approve/${sub["submission_id"]}",
    );

    final res = await http.put(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode == 200) {
      sub["status"] = "approved";
      (context as Element).markNeedsBuild();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Submission Approved ✔️")),
      );
    }
  }

  // -------------------------------------------------------
  // REJECT FUNCTION
  // -------------------------------------------------------
  Future<void> rejectSubmission(sub, storage, serverIP, context) async {
    final token = await storage.read(key: 'authToken');

    final url = Uri.parse(
      "http://$serverIP:5000/api/submissions/reject/${sub["submission_id"]}",
    );

    final res = await http.put(url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(
            {"reason": "Rejected by supervisor"}) // مهم لبعض السيرفرات
        );

    print("Reject response: ${res.statusCode} - ${res.body}");

    if (res.statusCode == 200) {
      sub["status"] = "rejected";
      (context as Element).markNeedsBuild();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Submission Rejected ❌")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Reject failed: ${res.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final submissions = studentData["submissions"] ?? [];
    final totalHours = studentData["total_hours"] ?? 0;
    const serverIP = "10.0.2.2";
    final storage = const FlutterSecureStorage();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: uniPurple, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 🔵 BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF9C27B0),
                  Color(0xFFE1BEE7),
                  Color(0xFFF3E5F5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 🔵 MAIN CONTENT
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Submissions",
                    style: const TextStyle(
                      fontSize: 32,
                      fontFamily: "Baloo",
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ⭐ PROFILE CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: (studentData["photo_url"] != null)
                            ? NetworkImage(
                                "http://$serverIP:5000${studentData["photo_url"]}")
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        studentData["full_name"] ?? "Student",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 5),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFC1E3), Color(0xFFEA80FC)],
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          "Total Hours: $totalHours",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ⭐ Submissions Title

                const SizedBox(height: 20),

                // ⭐ LIST OF SUBMISSIONS
                ...submissions.map((sub) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          sub["activity_title"] ?? "Activity",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6A1B9A),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // STATUS
                        Row(
                          children: [
                            const Text("Status: ",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              sub["status"] ?? "unknown",
                              style: TextStyle(
                                color: sub["status"] == "approved"
                                    ? Colors.green
                                    : sub["status"] == "pending"
                                        ? Colors.orange
                                        : sub["status"] == "submitted"
                                            ? Colors.blue
                                            : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // HOURS
                        Row(
                          children: [
                            const Text("Hours Earned: ",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              "${sub["earned_hours"] ?? 0}",
                              style: const TextStyle(
                                color: Color(0xFF0085FF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // PDF BUTTON
                        if (sub["uploaded_file"] != null)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.purple.shade300),
                            ),
                            icon: const Icon(Icons.picture_as_pdf,
                                color: Colors.red),
                            label: const Text("View Submitted File"),
                            onPressed: () async {
                              final pdfUrl =
                                  "http://$serverIP:5000${sub["uploaded_file"]}";
                              await launchUrl(Uri.parse(pdfUrl),
                                  mode: LaunchMode.externalApplication);
                            },
                          ),

                        const SizedBox(height: 16),

                        // APPROVE BUTTON
                        if (sub["status"] != "approved" && totalHours < 50)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              minimumSize: const Size.fromHeight(45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () async {
                              await approveSubmission(
                                  sub, storage, serverIP, context);
                            },
                            child: const Text(
                              "Approve Submission",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontFamily: "Baloo",
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18),
                            ),
                          ),

                        const SizedBox(height: 10),

                        // REJECT BUTTON
                        if (sub["status"] != "rejected" &&
                            sub["status"] != "approved")
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade500,
                              minimumSize: const Size.fromHeight(45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () async {
                              await rejectSubmission(
                                  sub, storage, serverIP, context);
                            },
                            child: const Text(
                              "Reject Submission",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontFamily: "Baloo",
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

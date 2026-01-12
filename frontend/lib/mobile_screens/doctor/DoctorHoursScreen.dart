import 'package:flutter/material.dart';
import '../../services/api_service.dart';

const Color uniPurple = Color(0xFF7B1FA2);

class DoctorHoursScreen extends StatefulWidget {
  const DoctorHoursScreen({super.key});

  @override
  State<DoctorHoursScreen> createState() => _DoctorHoursScreenState();
}

class _DoctorHoursScreenState extends State<DoctorHoursScreen> {
  bool _loading = true;
  List<dynamic> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchHoursSummary();
  }

  Future<void> _fetchHoursSummary() async {
    try {
      setState(() => _loading = true);
      final data = await ApiService.getDoctorSummary();

      // 🔹 منع التكرار حسب student_user_id
      final Map<int, dynamic> uniqueStudents = {};

      for (final s in data) {
        final id = s["student_user_id"];
        if (id != null) {
          uniqueStudents[id] = s; // آخر سجل يغلب
        }
      }

      setState(() {
        _students = uniqueStudents.values.toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load summary: $e")),
      );
    }
  }

  // ===============================
  // 🔔 Send result to ONE student
  // ===============================
  Future<void> _sendResult(int studentUserId) async {
    try {
      await ApiService.sendCourseResult(studentUserId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Result sent successfully"),
          backgroundColor: Colors.green,
        ),
      );

      _fetchHoursSummary();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ===============================
  // 🔔 Send ALL pending results
  // ===============================
  Future<void> _sendAllResults() async {
    final pendingStudents = _students
        .where((s) => s["status"] == "pending" && s["student_user_id"] != null)
        .toList();

    if (pendingStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No pending results to send"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    int success = 0;
    int failed = 0;

    for (final s in pendingStudents) {
      try {
        await ApiService.sendCourseResult(s["student_user_id"]);
        success++;
      } catch (_) {
        failed++;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Sent: $success ✔️   Failed: $failed ❌"),
        backgroundColor: failed == 0 ? Colors.green : Colors.orange,
      ),
    );

    _fetchHoursSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Students Summary",
          style: TextStyle(
            fontFamily: "Baloo",
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: uniPurple,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: uniPurple),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: uniPurple))
          : Column(
              children: [
                // ===============================
                // 🔘 Send All Results Button
                // ===============================
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text(
                        "Send All Results",
                        style: TextStyle(
                          fontFamily: "Baloo",
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: uniPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _sendAllResults,
                    ),
                  ),
                ),

                // ===============================
                // 📋 Students List
                // ===============================
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchHoursSummary,
                    color: uniPurple,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final s = _students[index];

                        final name = s["full_name"] ?? "Unknown";
                        final studentUniId = s["student_id"] ?? "";
                        final studentUserId = s["student_user_id"];
                        final hours = s["total_hours"] ?? 0;
                        final result = s["result"] ?? "pending";
                        final status = s["status"] ?? "pending";

                        final bool isPass = result == "pass";
                        final bool canSend = status == "pending";

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 40,
                                color: isPass ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: "Baloo",
                                      ),
                                    ),
                                    Text(
                                      "ID: $studentUniId",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Hours: $hours",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: uniPurple,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isPass
                                          ? Colors.green.withOpacity(0.15)
                                          : Colors.red.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Text(
                                      isPass ? "PASS" : "FAIL",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isPass ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

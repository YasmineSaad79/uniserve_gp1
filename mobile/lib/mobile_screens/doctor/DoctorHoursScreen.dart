import 'package:flutter/material.dart';
import '../../services/api_service.dart'; // ⭐ مهم

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

      final data = await ApiService.getDoctorSummary(); // ⭐ استخدم الـ API
      setState(() {
        _students = data;
        _loading = false;
      });
    } catch (e) {
      print("❌ Error loading summary: $e");
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load summary")),
      );
    }
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
          : RefreshIndicator(
              onRefresh: _fetchHoursSummary,
              color: uniPurple,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _students.length,
                itemBuilder: (context, index) {
                  final s = _students[index];

                  final name = s["full_name"] ?? "Unknown";
                  final studentId = s["student_id"] ?? "";
                  final hours = s["total_hours"] ?? 0;
                  final result = s["result"] ?? "pending";

                  bool isPass = result == "pass";

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
                                "ID: $studentId",
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
                              color: isPass ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}

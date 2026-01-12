import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';

class AssignStudentScreen extends StatefulWidget {
  const AssignStudentScreen({super.key});

  @override
  State<AssignStudentScreen> createState() => _AssignStudentScreenState();
}

class _AssignStudentScreenState extends State<AssignStudentScreen> {
  final TextEditingController controller = TextEditingController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final doctorId = args?["doctorId"];
    final doctorName = args?["doctorName"];

    return Scaffold(
      extendBodyBehindAppBar: true,

      // ================= APP BAR =================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          "Assign to $doctorName",
          style: const TextStyle(
            fontFamily: "Baloo",
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),

      // ================= BODY =================
      body: Stack(
        children: [
          // 🌤️ BACKGROUND (same family as Assigned Students)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFEFF6FF),
                  Color(0xFFE5E7EB),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🔵 FLOATING SHAPES
          Positioned(
            top: -80,
            left: -60,
            child: _blob(220, Colors.blue.withOpacity(0.08)),
          ),
          Positioned(
            bottom: -120,
            right: -80,
            child: _blob(300, Colors.cyan.withOpacity(0.06)),
          ),

          // ================= CONTENT =================
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _glassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔖 TITLE
                      const Text(
                        "Assign Student",
                        style: TextStyle(
                          fontFamily: "Baloo",
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Enter the university ID of the student you want to assign",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // 🆔 INPUT FIELD
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.badge_outlined,
                              color: Color(0xFF2563EB),
                            ),
                            hintText: "Student University ID (e.g. 12112345)",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // 🚀 ASSIGN BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: loading ? null : () => _assign(doctorId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFa5B3FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 6,
                          ),
                          child: loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Assign Student",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= LOGIC (UNCHANGED) =================

  Future<void> _assign(int doctorId) async {
    final uniId = controller.text.trim();
    if (uniId.isEmpty) return _msg("Enter student ID");

    setState(() => loading = true);

    try {
      final userId = await ApiService.getUserIdFromUniId(uniId);

      if (userId == null) {
        return _msg("Student not found");
      }

      final res = await http.post(
        Uri.parse("http://10.0.2.2:5000/api/users/admin/assign-student"),
        headers: {
          "Authorization": "Bearer ${await ApiService.getToken()}",
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "studentId": userId,
          "doctorId": doctorId,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        controller.clear();
        _msg("Student assigned successfully", ok: true);
      } else {
        _msg(data["message"] ?? "Error");
      }
    } catch (e) {
      _msg("Connection error: $e");
    }

    setState(() => loading = false);
  }

  void _msg(String text, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white.withOpacity(0.7),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

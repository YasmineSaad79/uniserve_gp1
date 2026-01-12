import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../student/EditProfileScreen.dart';

class DoctorStudentsScreen extends StatefulWidget {
  const DoctorStudentsScreen({super.key});

  @override
  State<DoctorStudentsScreen> createState() => _DoctorStudentsScreenState();
}

class _DoctorStudentsScreenState extends State<DoctorStudentsScreen> {
  List students = [];
  bool loading = true;
  String? doctorName;

  @override
  void didChangeDependencies() {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    doctorName = args?["doctorName"];
    int? doctorId = args?["doctorId"];

    if (doctorId != null) {
      _load(doctorId);
    }

    super.didChangeDependencies();
  }

  Future<void> _load(int doctorId) async {
    final data = await ApiService.getDoctorStudents(doctorId);

    setState(() {
      students = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      // ================= APP BAR =================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              doctorName ?? "",
              style: const TextStyle(
                fontFamily: "Baloo",
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Assigned Students",
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),

      // ================= BODY =================
      body: Stack(
        children: [
          // 🌤️ LIGHT MODERN BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF8FAFC), // almost white
                  Color(0xFFEFF6FF), // light blue
                  Color(0xFFE5E7EB), // soft gray
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🔵 SOFT FLOATING SHAPES
          Positioned(
            top: -90,
            left: -60,
            child: _blob(240, Colors.blue.withOpacity(0.08)),
          ),
          Positioned(
            bottom: -120,
            right: -70,
            child: _blob(280, Colors.cyan.withOpacity(0.06)),
          ),

          // ================= CONTENT =================
          SafeArea(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                  )
                : students.isEmpty
                    ? const Center(
                        child: Text(
                          "No students assigned",
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                        itemCount: students.length,
                        itemBuilder: (context, i) {
                          final s = students[i];

                          final photoUrl = s['photo_url'] != null
                              ? "http://10.0.2.2:5000${s['photo_url']}?t=${DateTime.now().millisecondsSinceEpoch}"
                              : null;

                          return InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StudentProfileScreen(
                                    studentId: s["student_id"].toString(),
                                    email: s["email"],
                                    readOnly: true, // ⭐⭐⭐ هذا هو المفتاح
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.65),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // AVATAR
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor:
                                            Colors.blue.withOpacity(0.12),
                                        backgroundImage: photoUrl != null
                                            ? NetworkImage(photoUrl)
                                            : null,
                                        child: photoUrl == null
                                            ? Text(
                                                s["full_name"]
                                                    .toString()
                                                    .substring(0, 1)
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1E3A8A),
                                                ),
                                              )
                                            : null,
                                      ),

                                      const SizedBox(width: 16),

                                      // INFO
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s["full_name"],
                                              style: const TextStyle(
                                                fontFamily: "Baloo",
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              "Student ID • ${s["student_id"]}",
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 16,
                                        color: Colors.black38,
                                      ),
                                    ],
                                  ),
                                ),
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

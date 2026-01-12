import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import '../student/showProfileScreen.dart';

class DoctorStudentsScreenForDoctor extends StatefulWidget {
  final String doctorName;

  const DoctorStudentsScreenForDoctor({
    super.key,
    required this.doctorName,
  });

  @override
  State<DoctorStudentsScreenForDoctor> createState() =>
      _DoctorStudentsScreenForDoctorState();
}

class _DoctorStudentsScreenForDoctorState
    extends State<DoctorStudentsScreenForDoctor> {
  List<dynamic> students = [];
  List<dynamic> filtered = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyStudents();
  }

  Future<void> _fetchMyStudents() async {
    try {
      final token = await ApiService.getToken();

      final res = await http.get(
        Uri.parse("http://10.0.2.2:5000/api/doctor/my-students"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        setState(() {
          students = data["data"] ?? [];
          filtered = students;
          isLoading = false;
        });
      } else {
        isLoading = false;
      }
    } catch (e) {
      isLoading = false;
    }
  }

  void _search(String text) {
    final q = text.toLowerCase();
    setState(() {
      filtered = students.where((s) {
        final name = s["full_name"].toString().toLowerCase();
        final id = s["student_id"].toString().toLowerCase();
        return name.contains(q) || id.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      // -------------------- APP BAR --------------------
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Student of Dr. ${widget.doctorName}",
          style: const TextStyle(
            fontFamily: "Baloo",
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF7B1FA2),
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF7B1FA2)),
      ),

      // -------------------- BODY --------------------
      body: Stack(
        children: [
          // 🌸 BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFDF7FF),
                  Color(0xFFF8F1FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🔮 FLOATING CIRCLES
          Positioned(
            top: -40,
            left: -30,
            child: _circle(180, const Color(0xFFDBB7FF), 0.25),
          ),
          Positioned(
            top: 150,
            right: -50,
            child: _circle(220, const Color(0xFFF8AFFF), 0.22),
          ),
          Positioned(
            bottom: -60,
            left: 20,
            child: _circle(260, const Color(0xFFC29BFF), 0.20),
          ),

          // 🔍 SEARCH BAR
          Positioned(
            top: 110,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: _search,
                decoration: const InputDecoration(
                  hintText: "Search students...",
                  border: InputBorder.none,
                  icon: Icon(Icons.search),
                ),
              ),
            ),
          ),

          // 🚀 STUDENTS LIST
          Positioned.fill(
            top: 170,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(
                        child: Text(
                          "لا يوجد طلاب مرتبطين بك",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 20),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final s = filtered[index];
                          final photoUrl = s['photo_url'] != null
                              ? "http://10.0.2.2:5000${s['photo_url']}?t=${DateTime.now().millisecondsSinceEpoch}"
                              : null;

                          return ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 18),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.07),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // AVATAR
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: const Color(0xFF7B1FA2)
                                          .withOpacity(0.2),
                                      backgroundImage: photoUrl != null
                                          ? NetworkImage(photoUrl)
                                          : null,
                                      child: photoUrl == null
                                          ? Text(
                                              s['full_name'][0].toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 22,
                                                color: Color(0xFF7B1FA2),
                                                fontWeight: FontWeight.bold,
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
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "ID: ${s["student_id"]}",
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // VIEW BUTTON
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ShowProfileScreen(
                                              studentId:
                                                  s["student_id"].toString(),
                                              email: s["email"],
                                              fullName: s["full_name"],
                                              photoUrl: photoUrl,
                                              showEditButton: false,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "View",
                                        style: TextStyle(
                                          fontFamily: "Baloo",
                                          fontWeight: FontWeight.bold,
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
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }
}

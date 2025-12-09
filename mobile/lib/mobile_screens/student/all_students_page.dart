import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'showProfileScreen.dart';
import 'dart:ui';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  List<dynamic> students = [];
  List<dynamic> filtered = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    try {
      final data = await ApiService.fetchAllStudents();
      setState(() {
        students = data;
        filtered = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching students: $e");
      setState(() => isLoading = false);
    }
  }

  void search(String text) {
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
        title: const Text(
          "All Students",
          style: TextStyle(
            fontFamily: "Baloo",
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: Color(0xFF7B1FA2),
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF7B1FA2)),
      ),

      // -------------------- BODY --------------------
      body: Stack(
        children: [
          // 🌸 SOFT PINK–PURPLE BACKGROUND (same as Messages)
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

          // 🔮 PASTEL FLOATING CIRCLES
          Positioned(
            top: -40,
            left: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFDBB7FF).withOpacity(0.25),
              ),
            ),
          ),

          Positioned(
            top: 150,
            right: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF8AFFF).withOpacity(0.22),
              ),
            ),
          ),

          Positioned(
            bottom: -60,
            left: 20,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFC29BFF).withOpacity(0.20),
              ),
            ),
          ),

          // 🌫️ SEARCH BAR
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
                onChanged: search,
                style: const TextStyle(color: Colors.black87),
                decoration: const InputDecoration(
                  hintText: "Search students...",
                  hintStyle: TextStyle(color: Colors.black38),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.black54),
                ),
              ),
            ),
          ),

          // 🚀 STUDENTS LIST
          Positioned.fill(
            top: 170,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
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
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.55), // GLASS
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
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // 🌟 AVATAR WITH PURPLE GLOW
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF7B1FA2)
                                            .withOpacity(0.28),
                                        blurRadius: 18,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: const Color(0xFF7B1FA2)
                                        .withOpacity(0.20),
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
                                ),

                                const SizedBox(width: 16),

                                // STUDENT INFO
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s["full_name"],
                                        style: const TextStyle(
                                          fontFamily: "Baloo",
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
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

                                // PURPLE BUTTON
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ShowProfileScreen(
                                          studentId: s["student_id"].toString(),
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
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'EditDoctorProfileScreen.dart';

class ShowDoctorProfileScreen extends StatefulWidget {
  final int doctorId;

  const ShowDoctorProfileScreen({
    super.key,
    required this.doctorId,
  });

  @override
  State<ShowDoctorProfileScreen> createState() =>
      _ShowDoctorProfileScreenState();
}

class _ShowDoctorProfileScreenState extends State<ShowDoctorProfileScreen> {
  final storage = const FlutterSecureStorage();

  String fullName = "";
  String email = "";
  String? photoUrl;
  bool loading = true;

  static const String serverIP = "10.0.2.2";

  @override
  void initState() {
    super.initState();
    _fetchDoctorProfile();
  }

  Future<void> _fetchDoctorProfile() async {
    try {
      final token = await storage.read(key: 'authToken');

      final url = Uri.parse(
          "http://$serverIP:5000/api/doctor/profile/${widget.doctorId}");

      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final data = jsonDecode(res.body);

      setState(() {
        fullName = data["full_name"] ?? "";
        email = data["email"] ?? "";

        final serverPhoto = data["photo_url"];
        photoUrl = (serverPhoto != null && serverPhoto.isNotEmpty)
            ? "http://$serverIP:5000$serverPhoto?t=${DateTime.now().millisecondsSinceEpoch}"
            : null;

        loading = false;
      });
    } catch (e) {
      loading = false;
      print("⚠ Error fetching doctor profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.purple),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "My Profile",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // 🎨 الخلفية المتدرجة مثل السنتر
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7E57C2), Color(0xFF512DA8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: const SizedBox(),
                  ),

                  // 🖼 صورة الدكتور فوق الكارد
                  Transform.translate(
                    offset: const Offset(0, -60),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: photoUrl != null
                            ? NetworkImage(photoUrl!)
                            : const AssetImage("assets/images/default.png")
                                as ImageProvider,
                      ),
                    ),
                  ),

                  // 📄 كارد البروفايل
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 25),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF512DA8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // badge نفس شكل السنتر
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Text(
                              "DOCTOR",
                              style: TextStyle(
                                color: Color(0xFF512DA8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          // زر التعديل
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              label: const Text(
                                "Edit Profile",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white, // ← اللون الأبيض
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5E35B1),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditDoctorProfileScreen(
                                      doctorId: widget.doctorId,
                                      onUpdated: _fetchDoctorProfile,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

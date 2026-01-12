import 'package:flutter/material.dart';
import 'dart:convert';
import '/services/api_service.dart';
import 'EditProfileScreen.dart';

class ShowProfileScreen extends StatefulWidget {
  final String studentId;
  final String email;
  final String fullName;
  final String? photoUrl;
  final bool showEditButton; // 🟣 متغير جديد

  const ShowProfileScreen({
    super.key,
    required this.studentId,
    required this.email,
    required this.fullName,
    this.photoUrl,
    this.showEditButton = true, // ✅ القيمة الافتراضية
  });

  @override
  State<ShowProfileScreen> createState() => _ShowProfileScreenState();
}

class _ShowProfileScreenState extends State<ShowProfileScreen> {
  String? fullName;

  String? phone, preferences, hobbies, photoUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      final token = await ApiService.getToken();
      final response = await ApiService.authGet(
        Uri.parse(
            "http://10.0.2.2:5000/api/student/profile/${widget.studentId}"),
        token: token,
      );

      print("📡 Profile status: ${response.statusCode}");
      print("📦 Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          fullName = data['full_name'] ?? widget.fullName;
          phone = data['phone_number'] ?? '';
          preferences = data['preferences'] ?? '';
          hobbies = data['hobbies'] ?? '';
          photoUrl = data['photo_url'] != null
              ? "http://10.0.2.2:5000${data['photo_url']}"
              : widget.photoUrl;
          isLoading = false;
        });
      } else {
        print("❌ Failed to load profile: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("⚠️ Error fetching profile: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(widget.showEditButton ? "My Profile" : "Student Profile"),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.deepPurple.shade100,
                    backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                        ? NetworkImage(
                            "${photoUrl!}?t=${DateTime.now().millisecondsSinceEpoch}")
                        : null,
                    child: (photoUrl == null || photoUrl!.isEmpty)
                        ? const Icon(Icons.person,
                            color: Colors.deepPurple, size: 50)
                        : null,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    fullName ?? widget.fullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6A1B9A),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(widget.email,
                      style: const TextStyle(
                          fontSize: 16, color: Colors.black54, height: 1.5)),
                  const SizedBox(height: 25),
                  const Divider(color: Colors.purple, thickness: 0.8),

                  // 🟢 بيانات الملف الشخصي
                  _buildInfoTile(Icons.phone, "Phone Number",
                      phone?.isNotEmpty == true ? phone! : "Not added"),
                  _buildInfoTile(Icons.favorite, "Preferences",
                      preferences?.isNotEmpty == true ? preferences! : "—"),
                  _buildInfoTile(Icons.interests, "Hobbies",
                      hobbies?.isNotEmpty == true ? hobbies! : "—"),
                  const SizedBox(height: 40),

                  // 🟣 زر التعديل يظهر فقط لو showEditButton = true
                  if (widget.showEditButton)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentProfileScreen(
                                studentId: widget.studentId,
                                email: widget.email,
                                onProfileUpdated: () async {
                                  await fetchProfile();
                                },
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text(
                          "Edit Profile",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.black87)),
      subtitle: Text(value, style: const TextStyle(color: Colors.black54)),
    );
  }
}

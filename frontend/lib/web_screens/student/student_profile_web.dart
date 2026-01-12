import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/services/token_service.dart';

class StudentProfileWeb extends StatefulWidget {
  final String studentId;
  final String fullName;
  final String email;
  final String? photoUrl;
  final VoidCallback? onEditProfile;

  const StudentProfileWeb({
    super.key,
    required this.studentId,
    required this.fullName,
    required this.email,
    this.photoUrl,
    this.onEditProfile,
  });

  @override
  State<StudentProfileWeb> createState() => _StudentProfileWebState();
}

class _StudentProfileWebState extends State<StudentProfileWeb> {
  static const String serverIP = "localhost";

  bool isLoading = true;

  String? fullName;
  String? phone;
  String? preferences;
  String? hobbies;
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        setState(() => isLoading = false);
        return;
      }

      final url = Uri.parse(
          "http://$serverIP:5000/api/student/profile/${widget.studentId}");

      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            fullName = data["full_name"] ?? widget.fullName;
            phone = data["phone_number"] ?? "Not added";
            preferences = data["preferences"] ?? "—";
            hobbies = data["hobbies"] ?? "—";

            final p = data["photo_url"];
            photoUrl = (p != null && p.isNotEmpty)
                ? "http://$serverIP:5000$p"
                : widget.photoUrl;

            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("⚠️ Error loading profile: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return isLoading
      ? const Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        )
      : SingleChildScrollView(
          child: _buildProfileUI(),
        );

  }

  Widget _buildProfileUI() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT CARD
        Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 55,
                backgroundColor: Colors.deepPurple.shade100,
                backgroundImage: (photoUrl != null)
                    ? NetworkImage(photoUrl!)
                    : null,
                child: (photoUrl == null)
                    ? const Icon(Icons.person,
                        color: Colors.deepPurple, size: 60)
                    : null,
              ),
              const SizedBox(height: 20),
              Text(
                fullName ?? "",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.email,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: widget.onEditProfile,
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

            ],
          ),
        ),

        const SizedBox(width: 30),

        // RIGHT DETAILS
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Profile Details",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 24),

                _infoItem("Full Name", fullName ?? ""),
                _infoItem("Phone Number", phone ?? "Not added"),
                _infoItem("Preferences", preferences ?? "—"),
                _infoItem("Hobbies", hobbies ?? "—"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              )),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const Divider(height: 24),
        ],
      ),
    );
  }
}

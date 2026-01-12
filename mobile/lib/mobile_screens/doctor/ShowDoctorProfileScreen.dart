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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6EEFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6A1B9A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6A1B9A)),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // ===== Title =====
                  const Text(
                    "Doctor Profile",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6A1B9A),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ===== Avatar =====
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF6A1B9A),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image(
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                        image: photoUrl != null
                            ? NetworkImage(photoUrl!)
                            : const AssetImage(
                                "assets/images/default.png",
                              ) as ImageProvider,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ===== Info Card =====
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 22),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFE1FF),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFB388FF),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            "Personal Information",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6A1B9A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _infoRow(Icons.person, "Full Name", fullName),
                        _infoRow(Icons.email, "Email", email),
                        _infoRow(Icons.badge, "Role", "Doctor"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ===== Buttons =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {},
                            child: const Text("Update Password"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6A1B9A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
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
                            child: const Text("Edit Profile"),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6A1B9A), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6A1B9A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? "Not provided" : value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

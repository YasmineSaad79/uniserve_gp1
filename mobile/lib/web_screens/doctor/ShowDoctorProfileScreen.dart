import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:mobile/mobile_screens/doctor/EditDoctorProfileScreen.dart';
import 'package:mobile/services/token_service.dart';

const Color purple = Color(0xFF512DA8);

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
  String fullName = "";
  String email = "";
  String? photoUrl;
  bool loading = true;

  // ===============================
  // 🌍 Base URL (Web + Mobile)
  // ===============================
  String get baseUrl =>
      kIsWeb ? "http://localhost:5000" : "http://10.0.2.2:5000";

  @override
  void initState() {
    super.initState();
    _fetchDoctorProfile();
  }

  // =====================================================
  // FETCH PROFILE (SAFE FOR WEB)
  // =====================================================
  Future<void> _fetchDoctorProfile() async {
    try {
      final token = await TokenService.getToken();

      if (token == null) {
        if (!mounted) return;
        setState(() => loading = false);
        debugPrint("❌ No token found");
        return;
      }

      final res = await http.get(
        Uri.parse("$baseUrl/api/doctor/profile/${widget.doctorId}"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode != 200) {
        debugPrint("❌ Profile error ${res.statusCode}");
        if (!mounted) return;
        setState(() => loading = false);
        return;
      }

      final data = jsonDecode(res.body);

      if (!mounted) return;
      setState(() {
        fullName = data["full_name"] ?? "";
        email = data["email"] ?? "";

        final serverPhoto = data["photo_url"];
        photoUrl = (serverPhoto != null && serverPhoto.isNotEmpty)
            ? "$baseUrl$serverPhoto?t=${DateTime.now().millisecondsSinceEpoch}"
            : null;

        loading = false;
      });
    } catch (e) {
      debugPrint("❌ Doctor profile error: $e");
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  // =====================================================
  // UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: purple),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // 🎨 Header Gradient
          Container(
            height: 160,
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
          ),

          // 🖼 Avatar
          Transform.translate(
            offset: const Offset(0, -70),
            child: CircleAvatar(
              radius: 58,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 52,
                backgroundImage: photoUrl != null
                    ? NetworkImage(photoUrl!)
                    : const AssetImage("assets/images/default.png")
                        as ImageProvider,
              ),
            ),
          ),

          // 📄 Profile Card
          Transform.translate(
            offset: const Offset(0, -50),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              margin: const EdgeInsets.symmetric(horizontal: 22),
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
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
                      color: purple,
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
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon:
                          const Icon(Icons.edit, color: Colors.white),
                      label: const Text(
                        "Edit Profile",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),

                      // 🔒 SAFE NAVIGATION
                      onPressed: () async {
                        if (kIsWeb) {
                          debugPrint(
                              "Edit Profile clicked (handled by shell on web)");
                          return;
                        }

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
    );
  }
}

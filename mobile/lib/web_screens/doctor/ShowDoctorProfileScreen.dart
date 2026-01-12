import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:mobile/services/token_service.dart';
import 'package:mobile/mobile_screens/doctor/EditDoctorProfileScreen.dart';

class ShowDoctorProfileScreen extends StatefulWidget {
  final int doctorId;

  const ShowDoctorProfileScreen({
    super.key,
    required this.doctorId,
  });

  @override
  State<ShowDoctorProfileScreen> createState() => _ShowDoctorProfileScreenState();
}

class _ShowDoctorProfileScreenState extends State<ShowDoctorProfileScreen> {
  String fullName = "";
  String email = "";
  String? photoUrl;
  bool loading = true;

  String get baseUrl => kIsWeb ? "http://localhost:5000" : "http://10.0.2.2:5000";

  @override
  void initState() {
    super.initState();
    _fetchDoctorProfile();
  }

  Future<void> _fetchDoctorProfile() async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      final token = await TokenService.getToken();

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No token found. Please sign in again.")),
        );
        setState(() => loading = false);
        return;
      }

      final url = Uri.parse("$baseUrl/api/doctor/profile/${widget.doctorId}");
      debugPrint("📌 GET Profile => $url");

      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode != 200) {
        debugPrint("❌ Profile load failed ${res.statusCode}: ${res.body}");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load profile (${res.statusCode})")),
        );
        setState(() => loading = false);
        return;
      }

      final data = jsonDecode(res.body);

      final serverPhoto = data["photo_url"];
      final resolvedPhoto = (serverPhoto != null && serverPhoto.toString().isNotEmpty)
          ? "$baseUrl$serverPhoto?t=${DateTime.now().millisecondsSinceEpoch}"
          : null;

      if (!mounted) return;
      setState(() {
        fullName = data["full_name"] ?? "";
        email = data["email"] ?? "";
        photoUrl = resolvedPhoto;
        loading = false;
      });
    } catch (e) {
      debugPrint("⚠ _fetchDoctorProfile error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error loading profile")),
      );
      setState(() => loading = false);
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
                  ),
                  Transform.translate(
                    offset: const Offset(0, -60),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                            ? NetworkImage(photoUrl!)
                            : const AssetImage("assets/images/default.png") as ImageProvider,
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 22),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
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
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.purpleAccent.withOpacity(0.08),
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
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              label: const Text(
                                "Edit Profile",
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5E35B1),
                                padding: const EdgeInsets.symmetric(vertical: 14),
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

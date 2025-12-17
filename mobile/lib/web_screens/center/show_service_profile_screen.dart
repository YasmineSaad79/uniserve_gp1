// File: lib/screens/center/show_service_profile_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile/web_screens/center/service_profile_screen.dart'; // edit profile web 
import '/services/api_service.dart';

class ShowServiceProfileScreen extends StatefulWidget {
  const ShowServiceProfileScreen({super.key});

  @override
  State<ShowServiceProfileScreen> createState() =>
      _ShowServiceProfileScreenState();
}

class _ShowServiceProfileScreenState extends State<ShowServiceProfileScreen> {
  String fullName = '';
  String email = '';
  String role = '';
  String? photoUrl;
  bool _loading = true;

  // 🌍 Server حسب المنصة
  String get serverIP => kIsWeb ? "localhost" : "10.0.2.2";

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await ApiService.authGet(
        Uri.parse("http://$serverIP:5000/api/service/profile"),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body["profile"];

        setState(() {
          fullName = data["full_name"] ?? '';
          email = data["email"] ?? '';
          role = data["role"] ?? '';
          if (data["photo_url"] != null && data["photo_url"].isNotEmpty) {
            photoUrl = "http://$serverIP:5000${data["photo_url"]}";
          }
          _loading = false;
        });
      } else {
        _loading = false;
        debugPrint("❌ Error fetching profile: ${response.statusCode}");
      }
    } catch (e) {
      _loading = false;
      debugPrint("⚠️ Error fetching service profile: $e");
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF5E60CE);
    const accentColor = Color(0xFF7400B8);

    final content = _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // 🌈 Gradient Header
                Container(
                  height: 180,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),

                // 🟣 Profile Card
                Transform.translate(
                  offset: const Offset(0, -70),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            photoUrl != null ? NetworkImage(photoUrl!) : null,
                        child: photoUrl == null
                            ? const Icon(Icons.person,
                                size: 65, color: primaryColor)
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // 🧾 Info Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: kIsWeb ? 520 : double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 18,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                fullName.isNotEmpty ? fullName : "No Name",
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 10),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 18),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  role.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 30),

                              // ✏️ Edit Button
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ServiceProfileScreen(
                                        email: email,
                                        onProfileUpdated: _fetchProfile,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text(
                                  "Edit Profile",
                                  style: TextStyle(fontSize: 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  minimumSize:
                                      const Size(double.infinity, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "My Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: !kIsWeb,
      ),
      body: kIsWeb
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: content,
              ),
            )
          : content,
    );
  }
}

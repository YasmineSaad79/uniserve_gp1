// File: lib/screens/center/ShowServiceProfileScreen.dart
import 'package:flutter/material.dart';
import '/services/api_service.dart';
import 'editCenterProfileScreen.dart';
import 'dart:convert';

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

  static const String serverIP = "10.0.2.2";

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
        setState(() => _loading = false);
        print("❌ Error fetching profile: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _loading = false);
      print("⚠️ Error fetching service profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF5E60CE);
    final accentColor = const Color(0xFF7400B8);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("My Profile",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // 🌈 خلفية متدرجة
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                  ),

                  // 🟣 الصورة والكرت
                  Transform.translate(
                    offset: const Offset(0, -60),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              photoUrl != null ? NetworkImage(photoUrl!) : null,
                          child: photoUrl == null
                              ? Icon(Icons.person,
                                  size: 60, color: primaryColor)
                              : null,
                        ),
                        const SizedBox(height: 10),

                        // ✨ البطاقة
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  fullName.isNotEmpty ? fullName : "No Name",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 15),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    role.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 25),

                                // 🔹 أزرار
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
                                  icon: const Icon(Icons.edit,
                                      color: Colors.white),
                                  label: const Text(
                                    "Edit Profile",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    minimumSize:
                                        const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
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
            ),
    );
  }
}

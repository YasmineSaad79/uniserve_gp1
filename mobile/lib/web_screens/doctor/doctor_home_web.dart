import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:mobile/services/token_service.dart';
import 'package:mobile/shared_screens/signin_screen.dart';
import 'package:mobile/web_screens/doctor/ShowDoctorProfileScreen.dart';
import 'package:mobile/web_screens/doctor/doctor_hours_screen.dart';

const Color purple = Color(0xFF7B1FA2);

class DoctorHomeWeb extends StatefulWidget {
  const DoctorHomeWeb({super.key});

  @override
  State<DoctorHomeWeb> createState() => _DoctorHomeWebState();
}

class _DoctorHomeWebState extends State<DoctorHomeWeb> {
  bool _ready = false;

  // ===============================
  // 🌍 Base URL
  // ===============================
  String get baseUrl =>
      kIsWeb ? "http://localhost:5000" : "http://10.0.2.2:5000";

  // NAV
  int _selectedPage = 0;

  // DOCTOR DATA
  int? doctorId;
  int? serviceCenterId;
  String fullName = "Doctor";
  String email = "";
  String? photoUrl;

  // COUNTERS
  int unreadNotifCount = 0;

  final List<String> menuItems = [
    "Dashboard",
    "Messages",
    "Students",
    "Hours",
    "Notifications",
    "Profile",
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  // =====================================================
  // INIT
  // =====================================================
  Future<void> _init() async {
    await _fetchDoctorProfile();
    await _fetchUnreadNotificationsCount();
    if (!mounted) return;
    setState(() => _ready = true);
  }

  // =====================================================
  // FETCH DOCTOR PROFILE
  // =====================================================
  Future<void> _fetchDoctorProfile() async {
    try {
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();

      if (token == null || userId == null) return;

      final res = await http.get(
        Uri.parse("$baseUrl/api/doctor/profile/$userId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode != 200) {
        debugPrint("❌ Profile error ${res.statusCode}");
        return;
      }

      final data = jsonDecode(res.body);

      if (!mounted) return;
      setState(() {
        doctorId = data['id'];
        serviceCenterId = data['service_center_id'];
        fullName = data['full_name'] ?? "Doctor";
        email = data['email'] ?? "";

        final p = data['photo_url'];
        photoUrl = (p != null && p.isNotEmpty) ? "$baseUrl$p" : null;
      });
    } catch (e) {
      debugPrint("❌ Doctor profile exception: $e");
    }
  }

  // =====================================================
  // UNREAD NOTIFICATIONS
  // =====================================================
  Future<void> _fetchUnreadNotificationsCount() async {
    try {
      final token = await TokenService.getToken();
      if (token == null) return;

      final res = await http.get(
        Uri.parse("$baseUrl/api/notifications/unread-count"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (!mounted) return;
        setState(() {
          unreadNotifCount = int.tryParse("${data['unread']}") ?? 0;
        });
      }
    } catch (e) {
      debugPrint("❌ Notifications error: $e");
    }
  }

  // =====================================================
  // UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F8),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: _buildPages(), // 👈 IndexedStack
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // SIDEBAR
  // =====================================================
  Widget _buildSidebar() {
    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(2, 0)),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "UNISERVE",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: purple,
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (_, i) {
                final active = _selectedPage == i;
                return InkWell(
                  onTap: () => setState(() => _selectedPage = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                    color: active ? purple.withOpacity(0.12) : null,
                    child: Row(
                      children: [
                        Icon(Icons.circle,
                            size: 10,
                            color: active ? purple : Colors.grey),
                        const SizedBox(width: 14),
                        Text(
                          menuItems[i],
                          style: TextStyle(
                            fontSize: 16,
                            color: active ? purple : Colors.black87,
                            fontWeight:
                                active ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () async {
                await TokenService.clear();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SigninScreen()),
                );
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label:
                  const Text("Logout", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // TOP BAR
  // =====================================================
  Widget _buildTopBar() {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fullName,
                  style: const TextStyle(
                      color: purple,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Text(email,
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: purple),
                onPressed: () => setState(() => _selectedPage = 1),
              ),
              _iconWithBadge(Icons.notifications_outlined, unreadNotifCount),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() => _selectedPage = 5),
                child: CircleAvatar(
                  radius: 22,
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl!) : null,
                  backgroundColor: purple.withOpacity(0.15),
                  child: photoUrl == null
                      ? const Icon(Icons.person, color: purple)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconWithBadge(IconData icon, int count) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(icon, color: purple),
          onPressed: () => setState(() => _selectedPage = 4),
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                "$count",
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  // =====================================================
  // PAGES (IndexedStack 🔥)
  // =====================================================
  Widget _buildPages() {
    return IndexedStack(
      index: _selectedPage,
      children: [
        _dashboard(),
        const Center(child: Text("Messages coming soon")),
        const Center(child: Text("Students coming soon")),
        const DoctorHoursScreen(),
        const Center(child: Text("Notifications coming soon")),
        doctorId == null
            ? const Center(child: CircularProgressIndicator())
            : ShowDoctorProfileScreen(doctorId: doctorId!),
      ],
    );
  }

  // =====================================================
  // DASHBOARD
  // =====================================================
  Widget _dashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Welcome back 👋",
          style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.bold, color: purple),
        ),
        const SizedBox(height: 8),
        const Text("Here is your doctor dashboard"),
        const SizedBox(height: 30),
        Row(
          children: [
            _statCard("Notifications", "$unreadNotifCount",
                Icons.notifications),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: purple, size: 30),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

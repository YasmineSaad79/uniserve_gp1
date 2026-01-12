import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/mobile_screens/center/calendar_activities.dart';

import 'package:mobile/services/token_service.dart';
import 'package:mobile/shared_screens/signin_screen.dart';
import 'package:mobile/web_screens/doctor/doctor_hours_screen.dart';

// صفحاتك
import 'doctorStudentsScreenForDoctor.dart';
import 'doctorMessagesScreen.dart';
import 'ShowDoctorProfileScreen.dart';

class DoctorHomeWeb extends StatefulWidget {
  const DoctorHomeWeb({super.key});

  @override
  State<DoctorHomeWeb> createState() => _DoctorHomeWebState();
}

class _DoctorHomeWebState extends State<DoctorHomeWeb> {
  // ===============================
  // 🌍 Base URL (Web vs Mobile)
  // ===============================
  String get baseUrl =>
      kIsWeb ? "http://localhost:5000" : "http://10.0.2.2:5000";

  // Doctor Data
  String fullName = "Doctor";
  String email = "Loading...";
  String? photoUrl;
  int? serviceCenterId;

  // IDs
  int? doctorId;

  // UI State
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _loadingProfile = true;

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
    if (!mounted) return;
    setState(() => _loadingProfile = false);
  }

  // =====================================================
  // FETCH DOCTOR PROFILE
  // =====================================================
  Future<void> _fetchDoctorProfile() async {
    try {
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserIdFixed();

      if (token == null || userId == null) {
        debugPrint("⚠ No token/userId -> redirect to signin");
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SigninScreen()),
        );
        return;
      }

      doctorId = userId;

      final url = Uri.parse("$baseUrl/api/doctor/profile/$userId");
      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode != 200) {
        debugPrint("❌ Profile error ${res.statusCode}: ${res.body}");
        return;
      }

      final data = jsonDecode(res.body);

      if (!mounted) return;
      setState(() {
        fullName = data["full_name"] ?? "Doctor";
        email = data["email"] ?? "Unknown";
        serviceCenterId = data["service_center_id"];

        final serverPhoto = data['photo_url'];
        photoUrl = (serverPhoto != null && serverPhoto.toString().isNotEmpty)
            ? "$baseUrl$serverPhoto?t=${DateTime.now().millisecondsSinceEpoch}"
            : null;
      });
    } catch (e) {
      debugPrint("⚠ Error loading doctor profile: $e");
    }
  }

  // =====================================================
  // Bottom Nav Tap
  // =====================================================
  void _onItemTapped(int index) {
    if (index == 2) {
      _scaffoldKey.currentState?.openEndDrawer();
      return;
    }

    if (index == 1 && serviceCenterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Still loading service center... try again."),
        ),
      );
      return;
    }

    setState(() => _selectedIndex = index);
  }

  // =====================================================
  // BUILD
  // =====================================================
  @override
  Widget build(BuildContext context) {
    if (_loadingProfile) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final body = _selectedIndex == 0
        ? _buildHomePage()
        : _selectedIndex == 1
            ? DoctorMessagesScreen(
                doctorId: doctorId ?? -1,
                serviceCenterId: serviceCenterId ?? -1,
              )
            : const SizedBox();

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _buildDrawer(),
      backgroundColor: const Color(0xFFF7F3FB),
      body: body,

      // ✅ Web NavigationBar مرتب
      bottomNavigationBar: NavigationBar(
        height: 64,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: "Home"),
          NavigationDestination(icon: Icon(Icons.message), label: "Messages"),
          NavigationDestination(icon: Icon(Icons.menu), label: "Menu"),
        ],
      ),
    );
  }

  // =====================================================
  // HOME PAGE (مرتب + Responsive)
  // =====================================================
  Widget _buildHomePage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final bool isWide = w >= 980; // ✅ عشان الكروت تصير جنب بعض فعلياً
        final double maxWidth = 1180;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 28 : 16,
                  vertical: 26,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderWeb(isWide: isWide),
                    const SizedBox(height: 16),
                    _buildSearchBarWeb(),
                    const SizedBox(height: 18),

                    // ✅ الكروت جنب بعض على الواسع
                    _buildFeatureRowWeb(isWide: isWide),

                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // =====================================================
  // HEADER (مرتب للويب) + ✅ ربط الكاليندر
  // =====================================================
  Widget _buildHeaderWeb({required bool isWide}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 26 : 18,
        vertical: isWide ? 22 : 18,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome!",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isWide ? 28 : 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          // ✅ زر الكاليندر مربوط
          IconButton(
            tooltip: "Activities Calendar",
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CalendarActivitiesScreen(),
                ),
              );
            },
          ),

          const SizedBox(width: 8),

          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () async {
              if (doctorId == null) return;

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShowDoctorProfileScreen(doctorId: doctorId!),
                ),
              );
              _fetchDoctorProfile();
            },
            child: CircleAvatar(
              radius: 22,
              backgroundImage:
                  photoUrl != null ? NetworkImage(photoUrl!) : null,
              backgroundColor: Colors.white.withOpacity(0.22),
              child: photoUrl == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // SEARCH BAR (Web Style)
  // =====================================================
  Widget _buildSearchBarWeb() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: Colors.purple),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Search student or lesson...",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // FEATURE ROW (Students + Hours) ✅ جنب بعض على الويب
  // =====================================================
  Widget _buildFeatureRowWeb({required bool isWide}) {
    final double cardHeight = isWide ? 190 : 170;

    if (isWide) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: cardHeight,
              child: _featureCardWeb(
                icon: Icons.people_alt,
                title: "Students",
                subtitle: "View and manage your students",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoctorStudentsScreenForDoctor(
                        doctorName: fullName,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: cardHeight,
              child: _featureCardWeb(
                icon: Icons.access_time_filled,
                title: "Hours Summary",
                subtitle: "Track and process your hours",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DoctorHoursScreen()),
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    // موبايل/ضيق: تحت بعض
    return Column(
      children: [
        SizedBox(
          height: cardHeight,
          child: _featureCardWeb(
            icon: Icons.people_alt,
            title: "Students",
            subtitle: "View and manage your students",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoctorStudentsScreenForDoctor(
                    doctorName: fullName,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: cardHeight,
          child: _featureCardWeb(
            icon: Icons.access_time_filled,
            title: "Hours Summary",
            subtitle: "Track and process your hours",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DoctorHoursScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _featureCardWeb({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.purple),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  "Open",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // DRAWER
  // =====================================================
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)],
              ),
            ),
            accountName: Text(fullName),
            accountEmail: Text(email),
            currentAccountPicture: CircleAvatar(
              backgroundImage: photoUrl != null
                  ? NetworkImage(photoUrl!)
                  : const AssetImage("assets/images/uniserve_logo.jpeg")
                      as ImageProvider,
            ),
          ),
          _drawerItem(Icons.person, "Profile", onTap: () async {
            Navigator.pop(context);
            if (doctorId == null) return;

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ShowDoctorProfileScreen(doctorId: doctorId!),
              ),
            );
            _fetchDoctorProfile();
          }),
          _drawerItem(Icons.logout, "Logout", onTap: () async {
            Navigator.pop(context);
            await TokenService.clear();
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SigninScreen()),
            );
          }),
        ],
      ),
    );
  }

  ListTile _drawerItem(
    IconData icon,
    String title, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.purple),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}

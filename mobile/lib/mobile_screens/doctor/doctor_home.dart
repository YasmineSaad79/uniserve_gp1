// DoctorHome.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../shared_screens/signin_screen.dart';

import 'doctorStudentsScreenForDoctor.dart';
import 'doctorMessagesScreen.dart';
import 'ShowDoctorProfileScreen.dart';
import 'DoctorHoursScreen.dart';
import 'CalendarActivities.dart';

class DoctorHome extends StatefulWidget {
  final int doctorId;
  const DoctorHome({super.key, required this.doctorId});

  @override
  State<DoctorHome> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHome> {
  final storage = const FlutterSecureStorage();

  String fullName = "Doctor";
  String email = "Loading...";
  String? photoUrl;
  int? serviceCenterId;

  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

      final res = await http.get(url, headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      });

      final data = jsonDecode(res.body);

      setState(() {
        fullName = data["full_name"] ?? "Doctor";
        email = data["email"] ?? "Unknown";
        serviceCenterId = data["service_center_id"];
        final serverPhoto = data['photo_url'];
        photoUrl = (serverPhoto != null && serverPhoto.toString().isNotEmpty)
            ? "http://$serverIP:5000$serverPhoto?t=${DateTime.now().millisecondsSinceEpoch}"
            : null;
      });
    } catch (_) {}
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      _scaffoldKey.currentState?.openEndDrawer();
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _buildDrawer(),
      backgroundColor: const Color(0xFFF7F3FB),
      body: _selectedIndex == 0
          ? _buildHomePage()
          : _selectedIndex == 1
              ? DoctorMessagesScreen(
                  doctorId: widget.doctorId,
                  serviceCenterId: serviceCenterId ?? -1,
                )
              : const SizedBox(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF7B1FA2),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: "Messages"),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: "Menu"),
        ],
      ),
    );
  }

  // ================= HOME PAGE =================
  Widget _buildHomePage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 50),
          _buildHeader(),
          const SizedBox(height: 20),
          _buildSearchBar(),
          const SizedBox(height: 25),
          _buildFeatureGrid(),
          const SizedBox(height: 30),
          _infoCards(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Welcome!", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(fullName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
          ]),
          Row(children: [
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ShowDoctorProfileScreen(doctorId: widget.doctorId),
                  ),
                );
                _fetchDoctorProfile();
              },
              child: CircleAvatar(
                radius: 22,
                backgroundImage: photoUrl != null
                    ? NetworkImage(photoUrl!)
                    : const AssetImage("assets/images/uniserve_logo.jpeg")
                        as ImageProvider,
              ),
            )
          ])
        ],
      ),
    );
  }

  // ================= SEARCH =================
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: const Row(
        children: [
          SizedBox(width: 15),
          Icon(Icons.search, color: Colors.purple),
          SizedBox(width: 10),
          Text("Search student or lesson...",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // ================= QUICK ACTIONS =================
  Widget _quickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _quickCard(Icons.calendar_month, "Calendar", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CalendarActivitiesScreenMobile(),
              ),
            );
          }),
          const SizedBox(width: 15),
          _quickCard(Icons.message, "Messages", () {
            setState(() => _selectedIndex = 1);
          }),
        ],
      ),
    );
  }

  Widget _quickCard(IconData icon, String title, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.12),
                blurRadius: 10,
              )
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.purple, size: 32),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // ================= FEATURES =================
  Widget _buildFeatureGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // الصف الأول (2 كروت)
          Row(
            children: [
              Expanded(
                child: _feature(
                  Icons.calendar_month,
                  "Calendar",
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CalendarActivitiesScreenMobile(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _feature(
                  Icons.people_alt,
                  "Students",
                  () {
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
            ],
          ),

          const SizedBox(height: 15),

          _wideFeature(
            Icons.access_time,
            "Hours Summary",
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DoctorHoursScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _wideFeature(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.1),
              blurRadius: 6,
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.purple, size: 40),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feature(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.1),
              blurRadius: 6,
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.purple, size: 38),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.purple)),
          ],
        ),
      ),
    );
  }

  // ================= INFO CARDS =================
  Widget _infoCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: const [
          _InfoCard(
            icon: Icons.info_outline,
            text: "You can manage your students and track their hours easily.",
          ),
          SizedBox(height: 12),
          _InfoCard(
            icon: Icons.notifications_none,
            text: "Check notifications regularly for new updates.",
          ),
        ],
      ),
    );
  }

  // ================= DRAWER =================
  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Expanded(
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
                        : const AssetImage(
                            "assets/images/uniserve_logo.jpeg",
                          ) as ImageProvider,
                  ),
                ),
                _drawerNavItem(
                  icon: Icons.calendar_month,
                  title: "Calendar",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CalendarActivitiesScreenMobile(),
                      ),
                    );
                  },
                ),
                _drawerNavItem(
                  icon: Icons.people_alt,
                  title: "Students",
                  onTap: () {
                    Navigator.pop(context);
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
                _drawerNavItem(
                  icon: Icons.access_time,
                  title: "Hours Summary",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DoctorHoursScreen(),
                      ),
                    );
                  },
                ),
                _drawerNavItem(
                  icon: Icons.notifications,
                  title: "Notifications",
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _drawerNavItem(
              icon: Icons.logout,
              title: "Logout",
              onTap: () async {
                Navigator.pop(context); // سكّر الـ Drawer أولاً

                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Confirm Logout"),
                      content: const Text("Are you sure you want to log out?"),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Cancel
                          },
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context); // إغلاق الديالوج
                            await _logout(); // 🔥 نفس الطالب
                          },
                          child: const Text(
                            "Logout",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      // 🧹 حذف التوكنات
      await storage.delete(key: 'authToken');
      await storage.delete(key: 'jwt_token');
      await storage.delete(key: 'doctorId');

      if (!mounted) return;

      // 🚫 منع الرجوع + تحويل للوجن
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const SigninScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint("Logout error (Doctor): $e");
    }
  }

  Widget _drawerNavItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.purple),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      onTap: onTap,
    );
  }

  ListTile _drawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.purple),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: Colors.black)),
      onTap: () => Navigator.pop(context),
    );
  }
}

// ================= INFO CARD =================
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
          )
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

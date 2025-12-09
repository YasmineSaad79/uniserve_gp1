import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/api_service.dart';
import 'doctorStudentsScreenForDoctor.dart';
import 'doctorMessagesScreen.dart';
import 'ShowDoctorProfileScreen.dart';

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

      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final data = jsonDecode(res.body);
      print("📸 Doctor photo_url from API: ${data["photo_url"]}");

      setState(() {
        fullName = data["full_name"] ?? "Doctor";
        email = data["email"] ?? "Unknown";
        serviceCenterId = data["service_center_id"]; // 👈 أضفنا هذا السطر

        final serverPhoto = data['photo_url'];

        photoUrl = (serverPhoto != null && serverPhoto.toString().isNotEmpty)
            ? "http://$serverIP:5000$serverPhoto?t=${DateTime.now().millisecondsSinceEpoch}"
            : null;
      });
      print("📌 Doctor Profile Loaded:");
      print("fullName = $fullName");
      print("email = $email");
      print("service_center_id = $serviceCenterId");
    } catch (e) {
      print("⚠ Error loading doctor profile: $e");
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      _scaffoldKey.currentState?.openEndDrawer();
    } else {
      setState(() => _selectedIndex = index);

      if (index == 1) {
        if (serviceCenterId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Still loading service center... try again."),
            ),
          );
          return;
        }
        setState(() => _selectedIndex = index);
      }
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

  Widget _buildHomePage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(top: 50, bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildHeader(),
            const SizedBox(height: 25),
            _buildSearchBar(),
            const SizedBox(height: 25),
            _buildFeatureGrid(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LEFT
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome!",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                fullName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),

          // RIGHT
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.calendar_today, color: Colors.white),
                onPressed: () {
                  // هنا لاحقًا ممكن نفتح صفحة تقويم للدكتور
                },
              ),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShowDoctorProfileScreen(
                        doctorId: widget.doctorId,
                      ),
                    ),
                  );

                  // 👈 تحديث الصورة مباشرة
                  _fetchDoctorProfile();
                }, // ← هون كان الخطأ: لازم تسكّري الـ onTap

                child: CircleAvatar(
                  radius: 22,
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl!)
                      : const AssetImage("assets/images/uniserve_logo.jpeg")
                          as ImageProvider,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

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
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: const Row(
        children: [
          SizedBox(width: 15),
          Icon(Icons.search, color: Colors.purple),
          SizedBox(width: 10),
          Text(
            "Search student or lesson...",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildFeatureButton(Icons.people_alt, "Students", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DoctorStudentsScreenForDoctor(
                  doctorName: fullName,
                ),
              ),
            );
          }),
          _buildFeatureButton(Icons.menu_book, "Manage Lessons", () {}),
        ],
      ),
    );
  }

  Widget _buildFeatureButton(IconData icon, String label, VoidCallback action) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: action,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.purple, size: 38),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.purple),
            ),
          ],
        ),
      ),
    );
  }

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
          _drawerItem(Icons.person, "Profile"),
          _drawerItem(Icons.notifications, "Notifications"),
          _drawerItem(Icons.logout, "Logout"),
        ],
      ),
    );
  }

  ListTile _drawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.purple),
      title: Text(title,
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.w600)),
      onTap: () => Navigator.pop(context),
    );
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/models/activity.dart';

import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/token_service.dart';
import 'package:mobile/web_screens/center/service_messages_web.dart';
import 'package:mobile/web_screens/center/service_notifications_web.dart';

// ===== CENTER SCREENS =====
import 'package:mobile/web_screens/center/studentQuestionsScreen.dart';
import 'package:mobile/web_screens/center/calendar_activities.dart';
import 'package:mobile/web_screens/center/service_profile_screen.dart'; //edit profile
import 'package:mobile/web_screens/center/requests_page.dart';
import 'package:mobile/web_screens/center/approvals_web.dart';
import 'package:mobile/web_screens/center/show_service_profile_screen.dart';

// ===== AUTH =====
import 'package:mobile/shared_screens/signin_screen.dart';
import 'package:mobile/web_screens/center/add_activity_web.dart';
import 'package:mobile/web_screens/center/center_submissions_screen.dart';
import 'package:mobile/web_screens/center/update_activity_web.dart';
import 'package:mobile/web_screens/center/view_activity_web.dart';
import 'package:mobile/web_screens/center/select_user_screen.dart';

const Color purple = Color(0xFF7B1FA2);

class ServiceHomeWeb extends StatefulWidget {
  const ServiceHomeWeb({super.key});

  @override
  State<ServiceHomeWeb> createState() => _ServiceHomeWebState();
}

class _ServiceHomeWebState extends State<ServiceHomeWeb> {
  static const String serverIP = "localhost";

  bool _disposed = false;

  Map<String, dynamic>? selectedStudentData;

  // NAV
  int _selectedPage = 0;

  // CENTER DATA
  int? serviceCenterId;
  String fullName = "Service Center";
  String email = "loading...";
  String? photoUrl;

  // SEARCH
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<dynamic> _searchResults = [];
  bool _searchLoading = false;

  // DASHBOARD
  List<dynamic> recentRequests = [];
  bool loadingRecent = true;
  Map<int, String> _aiSummaries = {};

  // COUNTERS
  int unreadNotifCount = 0;

  Activity? _editingActivity;

String? serviceCenterEmail;

  final List<String> menuItems = [
    "Dashboard",       // 0
    "View Activities", // 1
    "Add New Activity",// 2
    "Update Activity", // 3
    "Requests",        // 4
    "Approvals",       // 5
    "Submissions",     // 6
    "Questions",       // 7
    "Calendar",        // 8
    "Profile",         // 9
    "Students",        // 10
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _disposed = true;
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }



void _openSearchOverlay() {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return Dialog(
        insetPadding: const EdgeInsets.all(40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SizedBox(
          width: 700,
          height: 500,
          child: _buildSearchContent(),
        ),
      );
    },
  );
}

  // ==========================================================
  // INIT
  // ==========================================================

  Future<void> _init() async {
    await _fetchServiceData();
    await _fetchRecentRequests();
    await _fetchUnreadNotificationsCount();
  }

  Future<void> _fetchServiceData() async {
    try {
      final token = await TokenService.getToken();
      if (token == null) return;

      final res = await http.get(
        Uri.parse("http://$serverIP:5000/api/service/profile"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final data = decoded['profile'] ?? decoded;

        if (!_disposed && mounted) {
          setState(() {
            fullName = data['full_name'] ?? "Service Center";
            email = data['email'] ?? "";
            serviceCenterEmail = data['email'];
            serviceCenterId = data['id'];

            final p = data['photo_url'];
            photoUrl = (p != null && p.isNotEmpty)
                ? "http://$serverIP:5000$p"
                : null;
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Service profile error: $e");
    }
  }

  Future<void> _fetchUnreadNotificationsCount() async {
    try {
      final token = await TokenService.getToken();
      if (token == null) return;

      final res = await http.get(
        Uri.parse("http://$serverIP:5000/api/notifications/unread-count"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200 && !_disposed) {
        final data = jsonDecode(res.body);
        setState(() {
          unreadNotifCount = int.tryParse("${data['unread']}") ?? 0;
        });
      }
    } catch (_) {}
  }

  // ==========================================================
  // REQUESTS + AI
  // ==========================================================

  Future<void> _fetchRecentRequests() async {
    try {
      final vRes = await ApiService.getVolunteerRequests();
      final cRes = await ApiService.getCustomRequests();

      List all = [];

      if (vRes.statusCode == 200) {
        final v = jsonDecode(vRes.body);
        for (var item in v) {
          all.add({
            "title": item["activity_title"],
            "student_name": item["student_name"],
            "created_at": item["created_at"],
            "status": item["status"],
          });
        }
      }

      if (cRes.statusCode == 200) {
        final c = jsonDecode(cRes.body);
        for (var item in c) {
          all.add({
            "request_id": item["request_id"],
            "title": item["title"],
            "student_name": item["student_name"],
            "created_at": item["created_at"],
            "status": item["status"],
          });
        }
      }

      all.sort((a, b) =>
          DateTime.parse(b["created_at"]).compareTo(DateTime.parse(a["created_at"])));

      if (!_disposed && mounted) {
        setState(() {
          recentRequests = all.take(4).toList();
          loadingRecent = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Recent requests error: $e");
    }
  }

  Future<void> _loadAiForRequest(int requestId) async {
    if (_aiSummaries.containsKey(requestId)) return;

    try {
      final res = await ApiService.getCustomRequestSimilarity(requestId);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final matches = data['matches'] ?? [];

        String summary = matches.isEmpty
            ? "No similar services found"
            : "Closest: ${matches[0]['title']}";

        setState(() => _aiSummaries[requestId] = summary);
      }
    } catch (_) {
      _aiSummaries[requestId] = "AI unavailable";
    }
  }


Future<void> _searchWeb(String q, StateSetter setStateSheet) async {
  if (q.isEmpty) {
    setStateSheet(() {
      _searchResults.clear();
      _searchLoading = false;
    });
    return;
  }

  setStateSheet(() => _searchLoading = true);

  try {
    final token = await TokenService.getToken();

    final res = await http.get(
      Uri.parse(
        "http://$serverIP:5000/api/search?q=$q&role=service",
      ),
      headers: {
        if (token != null) "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setStateSheet(() => _searchResults = data);
    }
  } catch (e) {
    debugPrint("❌ Search error: $e");
  }

  setStateSheet(() => _searchLoading = false);
}

  // ==========================================================
  // UI
  // ==========================================================

  @override
  Widget build(BuildContext context) {
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
                    child: _buildPage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SIDEBAR
  // ==========================================================

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
                    padding:
                        const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    color: active ? purple.withOpacity(0.12) : null,
                    child: Row(
                      children: [
                        Icon(Icons.circle,
                            size: 10, color: active ? purple : Colors.grey),
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
              label: const Text("Logout", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TOP BAR
  // ==========================================================

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
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          Row(
            children: [
              Row(
  children: [
      // 🔍 SEARCH
      IconButton(
        tooltip: "Search",
        icon: const Icon(Icons.search, color: purple),
        onPressed: _openSearchOverlay,
      ),

      // 📅 CALENDAR
      IconButton(
        tooltip: "Calendar",
        icon: const Icon(Icons.calendar_month, color: purple),
        onPressed: () {
          setState(() => _selectedPage = 8); // Calendar
        },
      ),

      // 💬 MESSAGES
      IconButton(
        tooltip: "Messages",
        icon: const Icon(Icons.chat_bubble_outline, color: purple),
        onPressed: () {
          setState(() => _selectedPage = 11);
        },
      ),

      const SizedBox(width: 6),

      // 🔔 Notifications
      _iconWithBadge(Icons.notifications_outlined, unreadNotifCount),

      const SizedBox(width: 10),

      // 👤 PROFILE
      GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ShowServiceProfileScreen(),
            ),
          );
        },
        child: CircleAvatar(
          radius: 22,
          backgroundImage:
              photoUrl != null ? NetworkImage(photoUrl!) : null,
          backgroundColor: purple.withOpacity(0.15),
          child: photoUrl == null
              ? const Icon(Icons.business, color: purple)
              : null,
        ),
      ),
    ],
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
          onPressed: () {
            setState(() {
              _selectedPage = 12; // 👈 صفحة Notifications
            });
          },
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
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }


  // ==========================================================
  // PAGE MAPPING
  // ==========================================================

  Widget _buildPage() {
    switch (_selectedPage) {
      case 0:
        return _dashboard();
      case 1:
        return ViewActivityWeb(
          onEdit: (activity) {
            setState(() {
              _editingActivity = activity;
              _selectedPage = 3; // صفحة Update Activity
            });
          },
        );
      case 2:
        return AddActivityWeb(
          onSuccess: () {
            setState(() {
              _selectedPage = 1; // View Activities
            });
          },
        );
      case 3:
        if (_editingActivity == null) {
          return const Center(child: Text("No activity selected"));
        }
        return UpdateActivityWeb(
          activity: _editingActivity!,
          onSuccess: () {
            setState(() {
              _editingActivity = null;
              _selectedPage = 1; // الرجوع لعرض الأنشطة
            });
          },
        );
      case 4:
        return const RequestsPage();
      case 5:
        return const ApprovalsWeb();
      case 6:
        return const CenterSubmissionsScreen();
      case 7:
        return const StudentQuestionsScreen();
      case 8:
        return const CalendarActivitiesScreen();
      case 9:
        // ✅ Service Center Profile
        if (serviceCenterEmail == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ServiceProfileScreen(
          email: serviceCenterEmail!,
        );
      case 10: 
        // ✅ Students / Messages
        if (serviceCenterId == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return SelectUserScreen(
          currentUserId: serviceCenterId!,
        );
      case 11:
        if (serviceCenterId == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return StudentMessagesWeb(myId: serviceCenterId!);
        case 12:
          return ServiceNotificationsWeb(serverIP: "localhost");
      default:
        return const Center(child: Text("Unknown Page"));
    }
  }

  // ==========================================================
  // DASHBOARD
  // ==========================================================

  Widget _dashboard() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Welcome back 👋",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: purple,
            ),
          ),
          const SizedBox(height: 8),
          const Text("Here is an overview of your service center"),

          const SizedBox(height: 30),

          Row(
            children: [
              _statCard("Requests", recentRequests.length.toString(),
                  Icons.assignment),
              const SizedBox(width: 20),
              _statCard(
                  "Notifications", "$unreadNotifCount", Icons.notifications),
            ],
          ),

          const SizedBox(height: 30),

          const Text("Recent Requests",
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: purple)),
          const SizedBox(height: 12),

          loadingRecent
              ? const CircularProgressIndicator()
              : Column(
                  children: recentRequests.map((r) {
                    final id = r["request_id"];
                    if (id != null) _loadAiForRequest(id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(r["title"] ?? ""),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r["student_name"] ?? ""),
                            if (id != null)
                              Text(_aiSummaries[id] ?? "AI analyzing...",
                                  style: const TextStyle(
                                      color: purple, fontSize: 12)),
                          ],
                        ),
                        trailing: _statusBadge(r["status"]),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
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
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: purple, size: 30),
            const SizedBox(height: 12),
            Text(value,
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color c = status == "accepted"
        ? Colors.green
        : status == "rejected"
            ? Colors.red
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: c.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
      child: Text(status.toUpperCase(),
          style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildSearchContent() {
  return StatefulBuilder(
    builder: (context, setStateSheet) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // SEARCH BAR
            TextField(
              controller: _searchController,
              onChanged: (v) => _searchWeb(v, setStateSheet),
              decoration: InputDecoration(
                hintText: "Search students, activities, doctors...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _searchLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? const Center(child: Text("No results"))
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (_, i) {
                            final item = _searchResults[i];
                            return ListTile(
                              leading: const Icon(Icons.search),
                              title: Text(item['name'] ?? item['title']),
                              subtitle: Text(
                                (item['type'] ?? '').toString().toUpperCase(),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                // navigation حسب النوع لاحقاً
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      );
    },
  );
}

}

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/token_service.dart';


// شاشات مشتركة
import 'package:mobile/mobile_screens/student/studentNotificationsScreen.dart';
import 'package:mobile/web_screens/student/student_submissions_web.dart';
import 'package:mobile/web_screens/student/chat_screen_web.dart';
import 'package:mobile/web_screens/student/help_screen_web.dart';
import 'package:mobile/mobile_screens/center/viewActivitiesScreen.dart';
import 'package:mobile/web_screens/student/student_activities_web.dart';
import 'package:mobile/web_screens/student/student_edit_profile_web.dart';
import 'package:mobile/web_screens/student/student_messages_web.dart';
import 'package:mobile/web_screens/student/student_notifications_web.dart';
import 'package:mobile/web_screens/student/student_profile_web.dart';
import 'package:mobile/web_screens/student/student_suggest_activity_web.dart';
import 'package:mobile/web_screens/student/view_my_suggestions.dart';
import 'package:mobile/web_screens/student/student_progress_web.dart';
import 'package:mobile/web_screens/student/student_calendar_web.dart';


class StudentHomeWeb extends StatefulWidget {
  final String studentId;
  const StudentHomeWeb({super.key, required this.studentId});

  @override
  State<StudentHomeWeb> createState() => _StudentHomeWebState();
}

class _StudentHomeWebState extends State<StudentHomeWeb> {
  static const String serverIP = "localhost";

  bool _isDisposed = false;

  // Navigation index
  int _selectedPage = 0;

  // User data
  String fullName = "Student Name";
  String email = "student@email.com";
  String? photoUrl;
  int? userId;
  int? serviceCenterId;
  // Counters
  int unreadNotifCount = 0;
  int unreadMessageCount = 0;

  // Dashboard data
  List<Map<String, dynamic>> _recentActivities = [];
  List<Map<String, dynamic>> _recommendations = [];
  List<Map<String, dynamic>> _publicActivities = [];


  // Timers
  Timer? _notifTimer;
  Timer? _messageTimer;

  final purple = const Color(0xFF7B1FA2);

  final List<String> menuItems = [
    "Dashboard",        // 0
    "Activities",       // 1
    "Messages",         // 2
    "Notifications",    // 3
    "Submissions",      // 4
    "Help",             // 5
    "Profile",          // 6
    "Suggest Activity", // 7
    "My Suggestions",   // 8
    "Progress",         // 9
    "Calendar",         // 10
  ];

  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<dynamic> _searchResults = [];
  bool _searchLoading = false;

int? _chatOtherId;
String? _chatOtherName;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initStudentData();
    });

    _notifTimer = Timer.periodic(
        const Duration(seconds: 12), (_) => _fetchUnreadNotificationsCount());
    _messageTimer = Timer.periodic(
        const Duration(seconds: 10), (_) => _fetchUnreadMessagesCount());
  }


@override
void dispose() {
  _isDisposed = true;
  _notifTimer?.cancel();
  _messageTimer?.cancel();
  _searchDebounce?.cancel(); // ✅ لازم
  _searchController.dispose(); // ✅ مهم
  super.dispose();
}


  // ============================================================
  //                LOAD USER + DASHBOARD DATA
  // ============================================================

  Future<void> _initStudentData() async {
    await _fetchUserData();
    await _loadRecentActivities();
    await _loadRecommendations();
    await _fetchUnreadMessagesCount();
    await _fetchUnreadNotificationsCount();
    await _loadPublicActivities();
  }

  Future<String?> _getToken() async {
    return await TokenService.getToken();
  }

  Future<void> _fetchUserData() async {
    try {
      final token = await _getToken();
        if (token == null) return;

      final url = Uri.parse(
          "http://$serverIP:5000/api/student/profile/${widget.studentId}");

      final response = await http.get(url, headers: {
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

      if (!_isDisposed && mounted) {
        setState(() {
          fullName = data["full_name"] ?? "";
          email = data["email"] ?? "";
          userId = data["user_id"];
          serviceCenterId = data["service_center_id"];

          final p = data["photo_url"];
          photoUrl =
              (p != null && p.isNotEmpty) ? "http://$serverIP:5000$p" : null;
        });
      }
      }
    } catch (e) {
      debugPrint("⚠️ Error loading profile (WEB): $e");
    }
  }

  Future<void> _loadRecentActivities() async {
    if (userId == null) return;

    try {
      final url = Uri.parse(
          "http://$serverIP:5000/api/submissions/student/$userId/all");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

      if (!_isDisposed && mounted) {
        setState(() {
          _recentActivities = (data is List ? data : [])
            .map<Map<String, dynamic>>(
                (e) => Map<String, dynamic>.from(e))
            .take(3)
            .toList();

        });
      }
      }
    } catch (e) {
      debugPrint("⚠️ Error loading activities: $e");
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      final token = await _getToken();
        if (token == null) return;

      if (token == null) return;

      final url = Uri.parse(
          "http://$serverIP:5000/api/students/${widget.studentId}/recommendations");

      final response = await http.get(url, headers: {
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!_isDisposed && mounted) {
        setState(() {
          _recommendations = (data["recommendations"] ?? [])
            .map<Map<String, dynamic>>(
                (e) => Map<String, dynamic>.from(e))
            .toList();
        });
        }
      }
    } catch (e) {
      debugPrint("⚠️ Error loading recommendations: $e");
    }
  }

  Future<void> _fetchUnreadMessagesCount() async {
  if (userId == null) return;

  try {
    final res =
        await ApiService.getUnreadGroupedUnified(userId!);

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final List list =
          decoded is List ? decoded : decoded['data'] ?? [];

      int totalUnread = 0;

      for (final chat in list) {
        totalUnread += (chat["unreadCount"] ?? 0) as int;
      }

      if (!_isDisposed && mounted) {
        setState(() {
          unreadMessageCount = totalUnread;
        });
      }
    }
  } catch (e) {
    debugPrint("❌ Error fetching unread messages count: $e");
  }
}


  Future<void> _fetchUnreadNotificationsCount() async {
    try {
      final token = await _getToken();
        if (token == null) return;


      final url =
          Uri.parse("http://$serverIP:5000/api/notifications/unread-count");

      final response = await http.get(url, headers: {
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        unreadNotifCount = int.tryParse("${data['unread']}") ?? 0;
        if (!_isDisposed && mounted) {
        setState(() {});}
      }
    } catch (e) {
      debugPrint("⚠️ Error notifications count: $e");
    }
  }



Future<void> _loadPublicActivities() async {
  try {
    final token = await _getToken();
      if (token == null) return;


    final url = Uri.parse("http://$serverIP:5000/api/activities");

    final response = await http.get(url, headers: {
      "Authorization": "Bearer $token"
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (!_isDisposed && mounted) {
      setState(() {
        _publicActivities = (data["data"] ?? [])
          .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e))
          .take(3)
          .toList();
      });
      }
    }
  } catch (e) {
    debugPrint("⚠️ Error loading public activities (WEB): $e");
  }
}


Future<void> _performSearch(String query) async {
  if (query.trim().isEmpty) {
    setState(() => _searchResults = []);
    return;
  }

  setState(() => _searchLoading = true);

  try {
    // 🔹 1) Global Search
    final globalUrl = Uri.parse(
      "http://$serverIP:5000/api/search?q=$query&role=student",
    );

    final globalRes = await http.get(globalUrl);

    List<dynamic> results = [];
    if (globalRes.statusCode == 200) {
      results = jsonDecode(globalRes.body);
    }

    // 🔹 2) لو فاضي → AI Search
    if (results.isEmpty) {
      final token = await _getToken();
      if (token != null) {
        final aiUrl =
            Uri.parse("http://$serverIP:5000/api/ai-search/query");

        final aiRes = await http.post(
          aiUrl,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({"q": query}),
        );

        if (aiRes.statusCode == 200) {
          final aiData = jsonDecode(aiRes.body);
          results = aiData["matches"] ?? [];
        }
      }
    }

    if (!_isDisposed && mounted) {
      setState(() => _searchResults = results);
    }
  } catch (e) {
    debugPrint("❌ Search error: $e");
  } finally {
    if (!_isDisposed && mounted) {
      setState(() => _searchLoading = false);
    }
  }
}

  // ============================================================
  //                           UI
  // ============================================================
Widget _buildSearchResultsOverlay() {
  return Positioned(
    top: 85, // تحت الـ TopBar
    right: 40,
    child: Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 380,
        constraints: const BoxConstraints(maxHeight: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: _searchLoading
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            : _searchResults.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      "No results found",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final item = _searchResults[index];

                      return ListTile(
                        leading: _searchIcon(item["type"]),
                        title: Text(
                          item["name"] ?? item["title"] ?? "",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          item["description"] ??
                              item["reason"] ??
                              "",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _onSearchResultTap(item),
                      );
                    },
                  ),
      ),
    ),
  );
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF4F4F8),
    body: GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (_showSearch) {
          setState(() {
            _showSearch = false;
            _searchResults.clear();
          });
        }
      },
      child: Stack(
        children: [
          // ===============================
          // MAIN LAYOUT
          // ===============================
          Row(
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

          // ===============================
          // SEARCH OVERLAY
          // ===============================
          if (_showSearch && (_searchLoading || _searchResults.isNotEmpty))
            _buildSearchResultsOverlay(),
        ],
      ),
    ),
  );
}

Icon _searchIcon(String? type) {
  switch (type) {
    case "activity":
      return Icon(Icons.event, color: purple);
    case "student":
      return Icon(Icons.person, color: purple);
    case "doctor":
      return Icon(Icons.school, color: purple);
    default:
      return Icon(Icons.search, color: purple);
  }
}

void _onSearchResultTap(dynamic item) {
  // أوقف أي debounce شغال
  _searchDebounce?.cancel();

  setState(() {
    // سكّر السيرتش
    _showSearch = false;

    // نظّف النتائج والـ input
    _searchResults.clear();
    _searchController.clear();
  });

  // تنقّل حسب نوع النتيجة
  switch (item["type"]) {
    case "activity":
      // صفحة الأنشطة
      setState(() {
        _selectedPage = 1;
      });
      break;

    case "student":
      // لاحقًا: صفحة Student Profile
      // مثال مستقبلي:
      // Navigator.push(context, MaterialPageRoute(
      //   builder: (_) => StudentProfileWeb(studentId: item["id"].toString()),
      // ));
      break;

    case "doctor":
      // لاحقًا: صفحة Doctor Profile
      break;

    default:
      debugPrint("⚠️ Unknown search result type: ${item["type"]}");
  }
}

  // ---------------------------------------------------------
  //  SIDEBAR
  // ---------------------------------------------------------

  Widget _buildSidebar() {
    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(2, 0))
        ],
      ),
      child: Column(
        children: [
          const Text(
            "UNISERVE",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6A1B9A),
            ),
          ),
          const SizedBox(height: 40),

          // MENU
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final active = index == _selectedPage;

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (menuItems[index] == "Calendar") {
                        _selectedPage = 12; // ✅ الصفحة الصح
                      } else {
                        _selectedPage = index;
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                    decoration: BoxDecoration(
                      color: active ? purple.withOpacity(0.12) : null,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.circle,
                            size: 10,
                            color: active ? purple : Colors.grey),
                        const SizedBox(width: 14),
                        Text(
                          menuItems[index],
                          style: TextStyle(
                            fontSize: 16,
                            color: active ? purple : Colors.black87,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // LOGOUT
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
                Navigator.pushNamedAndRemoveUntil(
                    context, "/signin", (_) => false);
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label:
                  const Text("Logout", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  //  TOP BAR
  // ---------------------------------------------------------
  Widget _buildTopBar() {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ===============================
          // NAME + EMAIL
          // ===============================
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fullName,
                style: const TextStyle(
                  color: Color(0xFF6A1B9A),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                email,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          // ===============================
          // RIGHT ACTIONS
          // ===============================
          Row(
            children: [
              // -------------------------------
              // SEARCH BAR
              // -------------------------------
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _showSearch
                    ? Container(
                        width: 320,
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  hintText: "Search...",
                                  border: InputBorder.none,
                                ),
                                onChanged: (value) {
                                  _searchDebounce?.cancel();
                                  _searchDebounce = Timer(
                                    const Duration(milliseconds: 400),
                                    () {
                                      _performSearch(value);
                                    },
                                  );
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() {
                                  _showSearch = false;
                                  _searchResults.clear();
                                  _searchController.clear();
                                });
                              },
                            ),
                          ],
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () =>
                            setState(() => _showSearch = true),
                      ),
              ),

              const SizedBox(width: 20),

              // -------------------------------
              // NOTIFICATIONS
              // -------------------------------
              _iconWithBadge(
                Icons.notifications_outlined,
                unreadNotifCount,
                3,
              ),

              const SizedBox(width: 10),

              // -------------------------------
              // CALENDAR 📅 (NEW)
              // -------------------------------
              _iconWithBadge(
                Icons.calendar_month_outlined,
                0, // ما في badge حالياً
                12, // صفحة الكاليندر
              ),

              const SizedBox(width: 10),

              // -------------------------------
              // MESSAGES
              // -------------------------------
              _iconWithBadge(
                Icons.message_outlined,
                unreadMessageCount,
                2,
              ),

              const SizedBox(width: 10),

              // -------------------------------
              // PROFILE AVATAR
              // -------------------------------
              GestureDetector(
                onTap: () => setState(() => _selectedPage = 6),
                child: CircleAvatar(
                  radius: 22,
                  backgroundImage:
                      (photoUrl != null) ? NetworkImage(photoUrl!) : null,
                  backgroundColor: purple.withOpacity(0.15),
                  child: (photoUrl == null)
                      ? const Icon(Icons.person, color: Colors.purple)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconWithBadge(IconData icon, int count, int page) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(icon, color: purple, size: 26),
          onPressed: () => setState(() => _selectedPage = page),
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
              child: Text("$count",
                  style: const TextStyle(fontSize: 10, color: Colors.white)),
            ),
          )
      ],
    );
  }

  // ---------------------------------------------------------
  //               PAGE MAPPING
  // ---------------------------------------------------------

  Widget _buildPage() {
    switch (_selectedPage) {
      case 0:
        return _dashboard();

      case 1:
        return StudentActivitiesWeb(studentId: widget.studentId);

      case 2:
        if (userId == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return StudentMessagesWeb(
          userId: userId!,
        );

      case 3:
        return StudentNotificationsWeb(serverIP: serverIP);

      case 4:
        return _submissionsPage();

      case 5:
        return _helpPage();

      case 6:
        return StudentProfileWeb(
          studentId: widget.studentId,
          fullName: fullName,
          email: email,
          photoUrl: photoUrl,
          onEditProfile: () {
            if (!_isDisposed && mounted) {
              setState(() {
                _selectedPage = 10; // 👈 صفحة مخفية
              });
            }
          },
        );

      case 7:
        return StudentSuggestActivityWeb(
          studentId: widget.studentId,
          serverIP: serverIP,
        );

      case 8:
        return StudentViewRequestsWeb(
          studentId: widget.studentId,
          serverIP: serverIP,
        );

      case 9:
        return StudentProgressWeb(
          studentUniId: widget.studentId,
        );

      case 10: 
        return StudentEditProfileWeb(
          studentId: widget.studentId,
          fullName: fullName,
          email: email,
          photoUrl: photoUrl,
        );

      case 11: 
        if (userId == null || _chatOtherId == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ChatScreenWeb(
          myId: userId!,
          otherId: _chatOtherId!,
          otherName: _chatOtherName ?? "Service Center",
        );

        case 12:
          return StudentCalendarScreen(
            studentId: widget.studentId,
          );


      default:
        return const Center(child: Text("Unknown page"));
    }
  }


  // ---------------------------------------------------------
  //               DASHBOARD SECTION
  // ---------------------------------------------------------
Widget _dashboard() {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Welcome back! 👋",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6A1B9A),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Here's an overview of your volunteering journey.",
          style: TextStyle(color: Colors.black54),
        ),

        const SizedBox(height: 30),

        Row(
          children: [
            _statCard(
              "Recent Activities",
              "${_recentActivities.length}",
              Icons.event_available,
            ),
            const SizedBox(width: 20),
            _statCard(
              "Recommendations",
              "${_recommendations.length}",
              Icons.recommend_outlined,
            ),
            const SizedBox(width: 20),
            _statCard(
              "Unread Messages",
              "$unreadMessageCount",
              Icons.message_outlined,
            ),
          ],
        ),

        // -------------------------------
        //    BUTTONS
        // -------------------------------
        const SizedBox(height: 25),

        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                if (!_isDisposed && mounted) {
                setState(() {
                  _selectedPage = 7;
                });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Suggest New Activity",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),

            const SizedBox(width: 15),

            OutlinedButton.icon(
              onPressed: () {
                if (!_isDisposed && mounted) {
                setState(() {
                  _selectedPage = 8;
                });
                }
              },
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                side: BorderSide(color: purple, width: 1.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.list_alt, color: purple),
              label: Text(
                "View My Suggestions",
                style: TextStyle(color: purple, fontSize: 16),
              ),
            ),
          ],
        ),

        const SizedBox(height: 40),

        Text(
          "Recent Activities",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: purple,
          ),
        ),
        const SizedBox(height: 16),
        _recentActivitiesList(),

        const SizedBox(height: 40),

        Text(
          "Recommended for you",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: purple,
          ),
        ),
        const SizedBox(height: 16),
        _recommendationsList(),

        const SizedBox(height: 40),

        const Text(
          "Available Activities",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7B1FA2),
          ),
        ),
        const SizedBox(height: 16),
        _publicActivitiesList(),
      ],
    ),
  );
}


  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 140),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: purple, size: 32),
            const SizedBox(height: 14),
            Text(value,
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _recentActivitiesList() {
    if (_recentActivities.isEmpty) {
      return const Text("No recent activities yet.",
          style: TextStyle(color: Colors.grey));
    }

    return Column(
      children: _recentActivities.map((a) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.event, color: purple),
              const SizedBox(width: 12),
              Expanded(
                child: Text(a["activity_title"] ?? "Activity",
                    style: TextStyle(
                        color: purple,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
              Text(a["status"] ?? "",
                  style: TextStyle(
                      color: (a["status"] == "approved")
                          ? Colors.green
                          : Colors.orange)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _recommendationsList() {
    if (_recommendations.isEmpty) {
      return const Text("No recommendations available.",
          style: TextStyle(color: Colors.grey));
    }

    return Column(
      children: _recommendations.map((r) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.recommend, color: purple),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  r["service_title"] ?? r["title"] ?? "Service",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: purple,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------
  //               OTHER PAGES
  // ---------------------------------------------------------

  Widget _activitiesPage() {
    return ViewActivitiesScreen(isStudent: true);
  }

  Widget _messagesPage() {
    if (userId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return StudentMessagesWeb(
      userId: userId!, // ✅ user_id فقط
    );
  }


  Widget _notificationsPage() {
    return StudentNotificationsScreen(serverIP: serverIP);
  }

  Widget _submissionsPage() {
    return StudentSubmissionsWeb(
      studentId: widget.studentId,
    );
  }


  Widget _helpPage() {
    if (userId == null || serviceCenterId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return HelpScreen(
      studentId: widget.studentId,
      userId: userId!,
      serviceCenterId: serviceCenterId!,
    );
  }

  Widget _publicActivitiesList() {
  if (_publicActivities.isEmpty) {
    return const Text(
      "No available activities.",
      style: TextStyle(color: Colors.grey),
    );
  }

  return Column(
    children: _publicActivities.map((a) {
      final img = a["image_url"] != null
          ? "http://$serverIP:5000/${a["image_url"]}"
          : "";

      return Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                img,
                width: 90,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 90,
                  height: 70,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a["title"] ?? "Activity",
                    style: TextStyle(
                        color: Color(0xFF7B1FA2),
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(a["location"] ?? "",
                      style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

}

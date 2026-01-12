import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:mobile/services/notifications.dart';
import 'helpScreen.dart';
import 'addRequestScreen.dart';
import 'viewRequestsScreen.dart';
import 'EditProfileScreen.dart';
import 'studentMessagesScreen.dart';
import 'studentNotificationsScreen.dart';
import '../center/viewActivitiesScreen.dart';
import 'myProgressScreen.dart';
import 'student_calendar_screen.dart';
import 'studentSubmissionScreen.dart';
import '../../shared_screens/signin_screen.dart'; // 👈 عدّليها لمسار شاشة اللوجن عندك

class StudentHome extends StatefulWidget {
  final String studentId;

  const StudentHome({super.key, required this.studentId});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome>
    with SingleTickerProviderStateMixin {
  // 🔍 متغيرات البحث

  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  String _selectedFilter = "all";
  Timer? _debounce;
  List<dynamic> _recentActivities = [];
  bool _expanded = false;

  int? userId; // user_id الداخلي

  int notificationCount = 3; // (غير مستخدم مباشرة الآن)
  int calendarCount = 2; // (للديمو)
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  final storage = const FlutterSecureStorage();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _welcomeCardKey = GlobalKey();
  final GlobalKey _calendarIconKey = GlobalKey();
  final GlobalKey _notifIconKey = GlobalKey();
  final GlobalKey _profilePicKey = GlobalKey();
  final GlobalKey _searchBarKey = GlobalKey();
  final GlobalKey _submissionsKey = GlobalKey();
  final GlobalKey _progressKey = GlobalKey();
  final GlobalKey _serviceKey = GlobalKey();
  final GlobalKey _helpKey = GlobalKey();
  final GlobalKey _allActivitiesKey = GlobalKey();
  final GlobalKey _recentActivitiesKey = GlobalKey();
  final GlobalKey _recommendationsKey = GlobalKey();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int? serviceCenterId;

  String fullName = "Student Name";
  String email = "student@email.com";
  String? photoUrl;

  static const String serverIP = "10.0.2.2";

  int unreadMessageCount = 0;
  int _previousUnreadCount = 0;
  Timer? _messageTimer;

  // عدّاد الإشعارات غير المقروءة
  int unreadNotifCount = 0;
  Timer? _notifTimer;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _initStudentData();

    _messageTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _fetchUnreadMessagesCount(),
    );

    _notifTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => _fetchUnreadNotificationsCount(),
    );

    // 🔔 إشعارات أثناء فتح التطبيق
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final title = message.notification?.title ?? 'Notification';
      final body = message.notification?.body ?? '';

      setState(() => unreadNotifCount++);

      try {
        await _audioPlayer.play(AssetSource('sounds/message_alert.mp3'));
      } catch (_) {}

      await Notifications.showSimple(title, body);
    });

    // 🔔 عند الضغط على الإشعار
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      final data = message.data;

      if (data.isNotEmpty) {
        await _handleStudentNotificationTap(data);
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const StudentNotificationsScreen(serverIP: serverIP),
          ),
        );
      }

      _fetchUnreadNotificationsCount();
    });
  }

//---------------------------------------------------------------------------------
// =======================
// ⭐ FETCH RECOMMENDATIONS FROM BACKEND
// =======================
  List<dynamic> _recommendations = [];
  Future<void> _loadRecommendations() async {
    if (userId == null) return;

    try {
      final token = await storage.read(key: 'authToken');
      if (token == null) {
        print("⚠️ No token found");
        return;
      }

      final url = Uri.parse(
        "http://$serverIP:5000/api/students/${widget.studentId}/recommendations",
      );

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      print("📩 Rec response: ${response.statusCode}");
      print("📩 Rec body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _recommendations = data["recommendations"] ?? [];
        });
      } else {
        print("❌ Error getting recommendations: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Exception getting recommendations: $e");
    }
  }

//---------------------------------------------------------------------------------

  Future<void> _loadRecentActivities() async {
    try {
      if (userId == null) return;

      final url = Uri.parse(
          "http://$serverIP:5000/api/submissions/student/$userId/all");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          // نعرض فقط آخر 3 أنشطة
          _recentActivities = (data is List ? data : []).take(3).toList();
        });
      }
    } catch (e) {
      print("❌ Error loading recent activities: $e");
    }
  }

  Future<void> _initStudentData() async {
    print("⏳ Loading student info...");

    await _fetchUserData(); // ننتظر تحميل بيانات الطالب أولاً
    await _loadRecentActivities();
    await _loadRecommendations();

    print(
        "✅ After fetchUserData → userId: $userId, serviceCenterId: $serviceCenterId");

    if (mounted) {
      // بعد جلب البيانات بنجاح
      await _fetchUnreadMessagesCount();
      await _fetchUnreadNotificationsCount();
    }
    print("🔥 DEBUG userId in StudentHome = $userId");
  }

  ContentAlign _smartAlign(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return ContentAlign.bottom;

    final box = context.findRenderObject() as RenderBox;
    final position = box.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;

    // لو العنصر تحت نص الشاشة → اعرض الشرح فوقه
    if (position.dy > screenHeight * 0.6) {
      return ContentAlign.top;
    }

    // غير هيك → اعرضه تحته
    return ContentAlign.bottom;
  }

  void _showTutorial() {
    late TutorialCoachMark
        tutorial; // ✅ نعلن عنه أولاً كـ متغيّر قابل للتخصيص لاحقًا

    tutorial = TutorialCoachMark(
      colorShadow: Colors.black.withOpacity(0.7),
      textSkip: "Skip",
      paddingFocus: 8,
      opacityShadow: 0.8,
      pulseEnable: false, // 🚫 نوقف النبض تمامًا
      focusAnimationDuration:
          const Duration(milliseconds: 500), // 🌿 انتقال ناعم وواضح
      pulseAnimationDuration:
          const Duration(milliseconds: 500), // لتوحيد التوقيت

      targets: [
        // 🎯 1. الترحيب والاسم
        TargetFocus(
          identify: "welcomeText",
          keyTarget: _welcomeCardKey,
          shape: ShapeLightFocus.RRect,
          radius: 12,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "This is your welcome card.\nIt shows your name and email.",
                      style: TextStyle(
                          color: Colors.white, fontSize: 18, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      tutorial.next(); // ✅ شغالة الآن
                    },
                    child: const Text("Next"),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 🎯 2. أيقونة الكالندر
        TargetFocus(
          identify: "calendarIcon",
          keyTarget: _calendarIconKey,
          shape: ShapeLightFocus.Circle,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "Tap here to open your calendar\nand view deadlines or events.",
                      style: TextStyle(
                          color: Colors.white, fontSize: 17, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      tutorial.next();
                    },
                    child: const Text("Next"),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 🎯 3. أيقونة الإشعارات
        // 🎯 3. أيقونة الإشعارات
        TargetFocus(
          identify: "notifIcon",
          keyTarget: _notifIconKey,
          shape: ShapeLightFocus.Circle,
          radius: 20, // ✅ صغّرنا الدائرة (كانت كبيرة)
          paddingFocus: 1, // ✅ قللنا المسافة حولها
          contents: [
            TargetContent(
              align: ContentAlign.custom,
              customPosition: CustomTargetContentPosition(
                top: 220,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "This bell shows your notifications.\nYou’ll get alerts for approvals, messages, and updates.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      tutorial.next();
                    },
                    child: const Text("Next"),
                  ),
                ],
              ),
            ),
          ],
        ),

        TargetFocus(
          identify: "profilePic",
          keyTarget: _profilePicKey,
          shape: ShapeLightFocus.Circle,
          radius: 35, // حجم الدائرة أصغر
          paddingFocus: 4,
          contents: [
            TargetContent(
              align: ContentAlign.custom,
              customPosition: CustomTargetContentPosition(
                top: MediaQuery.of(context).size.height *
                    0.2, // ✅ النص بالمنتصف تماماً
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "Tap here to view or edit your profile information.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                    onPressed: () async {
                      await _scrollTo(_submissionsKey);
                      tutorial.next();
                    },
                    child: const Text("Next"),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 🎯 5. شريط البحث
        TargetFocus(
          identify: "searchBar",
          keyTarget: _searchBarKey,
          shape: ShapeLightFocus.RRect,
          radius: 10,
          contents: [
            TargetContent(
              align: _smartAlign(_searchBarKey),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "You can search for activities, services, or ask the AI assistant from here.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      tutorial.next();
                    },
                    child: const Text("Next"),
                  ),
                ],
              ),
            ),
          ],
        ),

        TargetFocus(
          identify: "quickActions",
          keyTarget: _submissionsKey,
          shape: ShapeLightFocus.Circle,
          radius: 40,
          contents: [
            TargetContent(
              align: _smartAlign(_searchBarKey),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "These quick actions let you access submissions, progress, services, and help instantly.",
                    style: TextStyle(color: Colors.white, fontSize: 17),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => tutorial.next(),
                    child: const Text("Next"),
                  ),
                ],
              ),
            ),
          ],
        ),
        TargetFocus(
          identify: "allActivities",
          keyTarget: _allActivitiesKey,
          shape: ShapeLightFocus.RRect,
          radius: 20,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Tap here to explore all available volunteer activities.",
                    style: TextStyle(color: Colors.white, fontSize: 17),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => tutorial.next(),
                    child: const Text("Next"),
                  ),
                ],
              ),
            ),
          ],
        ),

        TargetFocus(
          identify: "recentActivities",
          keyTarget: _recentActivitiesKey,
          shape: ShapeLightFocus.RRect,
          radius: 16,
          contents: [
            TargetContent(
              align: _smartAlign(_searchBarKey),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Here you can see your most recent activities and their current status.",
                    style: TextStyle(color: Colors.white, fontSize: 17),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => tutorial.next(),
                    child: const Text("Next"),
                  ),
                ],
              ),
            ),
          ],
        ),

        TargetFocus(
          identify: "recommendations",
          keyTarget: _recommendationsKey,
          shape: ShapeLightFocus.RRect,
          radius: 16,
          contents: [
            TargetContent(
              align: _smartAlign(_searchBarKey),
              child: Column(
                children: [
                  const Text(
                    "These recommendations are personalized for you based on your activity and interests.",
                    style: TextStyle(color: Colors.white, fontSize: 17),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => tutorial.finish(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text("Finish"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
      onFinish: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🎉 Tutorial finished!"),
            backgroundColor: Colors.deepPurple,
            duration: Duration(seconds: 2),
          ),
        );
      },
      onSkip: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⏭️ Tutorial skipped"),
            backgroundColor: Colors.deepPurple,
            duration: Duration(seconds: 2),
          ),
        );
        return true;
      },
    );

    tutorial.show(context: context);
  }

  // نافذة Pop-up عند وصول إشعار

  Future<void> _search(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (query.isEmpty) {
        setState(() {
          _searchResults.clear();
          _isSearching = false;
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _isSearching = true;
      });

      try {
        final token = await storage.read(key: 'authToken');

        final url = Uri.parse(
          "http://$serverIP:5000/api/search?q=$query&role=student",
        );

        final response = await http.get(
          url,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );

        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          setState(() {
            _searchResults = decoded is List ? decoded : [];
          });
        } else {
          print("❌ Search failed: ${response.statusCode}");
        }
      } catch (e) {
        print("❌ Error searching: $e");
      }

      setState(() => _isLoading = false);
    });
  }

  Future<void> _askAI(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchResults.clear();
    });

    try {
      final token =
          await storage.read(key: 'authToken'); // ✅ جلب التوكن من التخزين
      if (token == null) {
        print("⚠️ No token found in storage!");
        setState(() => _isLoading = false);
        return;
      }

      final url = Uri.parse("http://$serverIP:5000/api/ai/query");
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token", // ✅ إرسال التوكن
          "Content-Type": "application/json",
        },
        body: json.encode({"q": query}),
      );

      print("🧠 AI Response: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> results = [];

        // 🧠 الحالة الأساسية: السيرفر رجع matches
        if (decoded is Map && decoded['matches'] is List) {
          results = decoded['matches'].map((e) {
            return {
              "id": e["id"],
              "name": e["title"] ?? "Unnamed Activity",
              "description": e["description"] ?? "",
              "image_url": e["image_url"],
              "type": e["type"] ?? "activity",
            };
          }).toList();
        }
        // 🧠 لو رجع List مباشرة
        else if (decoded is List) {
          results = decoded;
        }
        // 🧠 fallback
        else {
          results = [
            {
              "name": decoded["message"] ?? "No AI results found",
              "type": "info"
            }
          ];
        }

        setState(() {
          _searchResults = results;
        });
      } else {
        print("❌ AI Error: ${response.statusCode}");
        print("Body: ${response.body}");
      }
    } catch (e) {
      print("❌ AI Search Error: $e");
    }

    setState(() => _isLoading = false);
  }

  void _showAIDialog(BuildContext context, StateSetter setStateSheet) {
    final TextEditingController aiController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.smart_toy_outlined, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text("Ask AI", style: TextStyle(color: Colors.deepPurple)),
            ],
          ),
          content: TextField(
            controller: aiController,
            decoration: InputDecoration(
              hintText: "Ask something like: activities about hospitals...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.send, size: 18, color: Colors.white),
              label: const Text("Ask", style: TextStyle(color: Colors.white)),
              onPressed: () async {
                final query = aiController.text.trim();
                if (query.isNotEmpty) {
                  Navigator.pop(context); // أغلق النافذة
                  setStateSheet(() => _isLoading = true);
                  await _askAI(query); // استدعاء الذكاء الاصطناعي
                  setStateSheet(() => _isLoading = false);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _openSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateSheet) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              children: [
                // شريط البحث
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) async {
                          setStateSheet(() => _isLoading = true);
                          await _search(v);
                          setStateSheet(() => _isLoading = false);
                        },
                        decoration: InputDecoration(
                          hintText: "Search activities or services...",
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.purple),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Colors.purple),
                          ),
                        ),
                      ),
                    ),

                    // 🔹 زر "Ask AI"
                    IconButton(
                      icon: const Icon(Icons.smart_toy_outlined,
                          color: Colors.deepPurple),
                      tooltip: "Ask AI",
                      onPressed: () {
                        _showAIDialog(context, setStateSheet);
                      },
                    ),

                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.purple),
                      tooltip: "Close",
                      onPressed: () {
                        Navigator.pop(context); // ← يغلق نافذة السيرتش بالكامل
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // فلترة
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 10),
                  height: 45,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterChip(
                            setStateSheet, "all", "All", Icons.all_inclusive),
                        const SizedBox(width: 10),
                        _buildFilterChip(setStateSheet, "activity",
                            "Activities", Icons.event_note),
                        const SizedBox(width: 10),
                        _buildFilterChip(setStateSheet, "service", "Services",
                            Icons.business_center),
                        const SizedBox(width: 10),
                        _buildFilterChip(setStateSheet, "request", "Requests",
                            Icons.assignment),
                      ],
                    ),
                  ),
                ),

                // نتائج البحث
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child:
                              CircularProgressIndicator(color: Colors.purple),
                        )
                      : _searchResults.isEmpty
                          ? const Center(
                              child: Text(
                                "No results found.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final item = _searchResults[index];

                                // 🔍 فلترة حسب النوع (activity / student / all)
                                if (_selectedFilter != "all" &&
                                    item["type"] != _selectedFilter) {
                                  return const SizedBox.shrink();
                                }

                                // 🖼️ تجهيز رابط الصورة (مع معالجة المسارات المطلقة)
                                String imageUrl;

                                final img = item["image_url"];

                                if (img != null &&
                                    img.toString().trim().isNotEmpty) {
                                  final imgStr = img.toString();

                                  if (imgStr.startsWith("http")) {
                                    // URL كامل
                                    imageUrl = imgStr;
                                  } else if (imgStr.contains("uploads")) {
                                    // مسار من السيرفر
                                    final cleanPath = imgStr
                                        .substring(imgStr.indexOf("uploads"));
                                    imageUrl =
                                        "http://10.0.2.2:5000/$cleanPath";
                                  } else {
                                    // اسم ملف فقط
                                    imageUrl =
                                        "http://10.0.2.2:5000/uploads/$imgStr";
                                  }
                                } else {
                                  // fallback
                                  imageUrl =
                                      "http://10.0.2.2:5000/uploads/default.jpg";
                                }

                                return ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      imageUrl,
                                      width: 55,
                                      height: 55,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Image.asset(
                                        "assets/images/default.jpg", // لو عندك صورة ديفولت محلية
                                        width: 55,
                                        height: 55,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    item["name"] ?? item["title"] ?? "",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF7B1FA2),
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (item["type"] != null)
                                        Text(
                                          item["type"].toUpperCase(),
                                          style: const TextStyle(
                                              color: Colors.grey),
                                        ),
                                      if (item["reason"] != null &&
                                          item["reason"].toString().isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            "🤖 ${item["reason"]}",
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  onTap: () {
                                    if (item["type"] == "activity") {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ViewActivitiesScreen(
                                                  isStudent: true),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              "Opening ${item["type"]}..."),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                )
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildActivityCard(dynamic item) {
    final title = item["activity_title"] ?? "Activity";
    final status = item["status"] ?? "pending";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.event, color: Colors.deepPurple, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7B1FA2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Status: $status",
                  style: TextStyle(
                    fontSize: 13,
                    color: status == "submitted"
                        ? const Color.fromARGB(255, 1, 2, 1)
                        : Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    StateSetter setStateSheet,
    String value,
    String label,
    IconData icon,
  ) {
    final bool isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setStateSheet(() {
          _selectedFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18, color: isSelected ? Colors.purple : Colors.grey),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.purple : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchUserData() async {
    try {
      final token = await storage.read(key: 'authToken');
      final studentId = widget.studentId;

      final url =
          Uri.parse('http://$serverIP:5000/api/student/profile/$studentId');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("📦 Response data: $data"); // ✅ أطبع الرد كامل من السيرفر

        setState(() {
          fullName = data['full_name'] ?? fullName;
          email = data['email'] ?? email;
          serviceCenterId = data['service_center_id']; // ✅ تأكد إنه نفس الاسم

          userId = data['user_id']; // حفظ user_id الداخلي
          final serverPhoto = data['photo_url'];
          photoUrl = (serverPhoto != null && serverPhoto.isNotEmpty)
              ? "http://$serverIP:5000$serverPhoto?t=${DateTime.now().millisecondsSinceEpoch}"
              : null;
        });
        // print("✅ userId loaded: $userId");
      } else {
        // print("❌ Failed to load student data: ${response.statusCode}");
      }
    } catch (e) {
      // print("⚠️ Error fetching user data: $e");
    }
  }

  Future<void> _fetchUnreadMessagesCount() async {
    try {
      if (userId == null) return;
      final url =
          Uri.parse("http://$serverIP:5000/api/messages/unread-count/$userId");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newCount = (data['unread_count'] is int)
            ? data['unread_count'] as int
            : int.tryParse('${data['unread_count']}') ?? 0;

        if (newCount > _previousUnreadCount) {
          try {
            await _audioPlayer.play(AssetSource('sounds/message_alert.mp3'));
          } catch (_) {}
        }

        setState(() {
          unreadMessageCount = newCount;
        });

        _previousUnreadCount = newCount;
      }
    } catch (e) {
      // print("Error fetching unread messages count: $e");
    }
  }

  Future<void> _fetchUnreadNotificationsCount() async {
    try {
      final token = await storage.read(key: 'authToken');
      final url =
          Uri.parse("http://$serverIP:5000/api/notifications/unread-count");

      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final cnt = (data['unread'] is int)
            ? data['unread'] as int
            : int.tryParse('${data['unread']}') ?? 0;

        setState(() => unreadNotifCount = cnt);
      }
    } catch (e) {
      // print("Error fetching unread notifications count: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _messageTimer?.cancel();
    _notifTimer?.cancel();
    _audioPlayer.stop();
    super.dispose();
  }

  void _onItemTapped(int index) async {
    if (index == 2) {
      _scaffoldKey.currentState?.openEndDrawer();
      return;
    }

    if (index == 1) {
      // بدنا نفتح صفحة المسجات كصفحة مستقلة
      if (userId != null && serviceCenterId != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentMessagesScreen(
              studentId: widget.studentId,
              serviceCenterId: serviceCenterId!,
            ),
          ),
        );

        // Update unread count when returning
        _fetchUnreadMessagesCount();
      }
      return; // مهم جداً
    }

    // Home
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openNotificationsPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StudentNotificationsScreen(serverIP: serverIP),
      ),
    );
    _fetchUnreadNotificationsCount();
  }

  void _showRequestsOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.add, color: Color(0xFF7B1FA2)),
                  title: const Text('Add Request'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddRequestScreen(studentId: widget.studentId),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.view_list, color: Color(0xFF7B1FA2)),
                  title: const Text('View My Requests'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ViewRequestsScreen(studentId: widget.studentId),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: const Color(0xFF7B1FA2)),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF7B1FA2),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureCardNew({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: Colors.deepPurple),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6A1B9A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) return;

    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: 0.2,
    );

    // ننتظر شوي قبل الخطوة التالية
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      controller: _scrollController, // ✅ مهم

      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(top: 30, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الهيدر البنفسجي
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9C2bb0), Color(0xFF9C27B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // النصوص
                  Column(
                    key: _welcomeCardKey, // ✅ المفتاح صار هنا بدل البطاقة كلها

                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Welcome!",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  // أيقونات: رسائل + إشعارات + صورة بروفايل
                  Row(
                    children: [
                      // رسائل
                      Stack(
                        key: _calendarIconKey, // ✅ مفتاح الجولة

                        children: [
                          IconButton(
                            icon: const Icon(Icons.calendar_today_outlined,
                                color: Colors.white),
                            tooltip: 'Calendar',
                            onPressed: _openCalendarPage,
                          ),
                          if (calendarCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: _buildBadge(calendarCount),
                            ),
                        ],
                      ),

                      // إشعارات (تفتح الصفحة)
                      Stack(
                        key: _notifIconKey, // ✅ مفتاح الجولة

                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_none,
                                color: Colors.white),
                            onPressed: _openNotificationsPage,
                          ),
                          if (unreadNotifCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: _buildBadge(unreadNotifCount),
                            ),
                        ],
                      ),

                      // صورة بروفايل
                      GestureDetector(
                        key: _profilePicKey, // ✅ مفتاح الجولة

                        onTap: () async {
                          if (email.isNotEmpty) {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentProfileScreen(
                                  studentId: widget.studentId,
                                  email: email,
                                  onProfileUpdated: () async {
                                    await _fetchUserData();
                                  },
                                ),
                              ),
                            );
                            await _fetchUserData();
                          }
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withOpacity(0.9),
                          backgroundImage: (photoUrl != null)
                              ? NetworkImage(photoUrl!)
                              : null,
                          child: (photoUrl == null)
                              ? const Icon(Icons.person,
                                  color: Color(0xFF7B1FA2), size: 22)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // شريط بحث نيوومورفيك
            // 🔍 شريط بحث نيوومورفيك (يفتح نافذة البحث)

            Center(
              child: GestureDetector(
                key: _searchBarKey, // ⭐⭐⭐ هذا هو الحل

                onTap: _openSearchSheet, // ← هي أهم خطوة
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // مستطيل search
                    SizedBox(
                      width: 220,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 12,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            "search",
                            style: TextStyle(
                              color: Colors.purple,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // الدائرة فوق
                    Positioned(
                      left: 1,
                      top: 1,
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.purple.withOpacity(0.9),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.search,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // بطاقة الأنشطة

            const SizedBox(height: 20),

            // الشبكة (My Activities / My Progress / Requests)
            SizedBox(
              height: 110, // ارتفاع أقل ليتوازن مع الصفحة
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _circleFeature(
                    key: _submissionsKey,
                    icon: Icons.upload_file,
                    label: "Submissions",
                    colors: [Color(0xFFFFB6C1), Color(0xFFFF8DA1)],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentSubmissionScreen(
                            studentId: widget.studentId,
                          ),
                        ),
                      );
                    },
                  ),
                  _circleFeature(
                    key: _progressKey,
                    icon: Icons.bar_chart,
                    label: "Progress",
                    colors: [Color(0xFF9C4DFF), Color(0xFF7A28F2)],
                    onTap: () async {
                      final studentUniId = await _extractStudentUniId();
                      if (!mounted || studentUniId == null) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              MyProgressScreen(studentUniId: studentUniId),
                        ),
                      );
                    },
                  ),
                  _circleFeature(
                    key: _serviceKey,
                    icon: Icons.edit_document,
                    label: "Service",
                    colors: [Color(0xFF4DEB8A), Color(0xFF2CC76A)],
                    onTap: _showRequestsOptions,
                  ),
                  _circleFeature(
                    key: _helpKey,
                    icon: Icons.help_center_outlined,
                    label: "Help",
                    colors: [Color(0xFF4DB6FF), Color(0xFF1E88E5)],
                    onTap: () {
                      if (serviceCenterId != null && userId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HelpScreen(
                              studentId: widget.studentId,
                              serviceCenterId: serviceCenterId!,
                              userId: userId!,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            // ⭐⭐⭐ CARD: All Activities + Recent Activities
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(35), // 🔥 مدور من الجوانب
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ----------------------------------
                  // 🔮 زر ALL ACTIVITIES داخل نفس الكرت
                  // ----------------------------------
                  GestureDetector(
                    key: _allActivitiesKey,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const ViewActivitiesScreen(isStudent: true),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "All activities available!",
                                  style: TextStyle(
                                    color: Colors.purple,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  "Explore available opportunities",
                                  style: TextStyle(
                                    color: Colors.purple,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(
                              Icons.volunteer_activism,
                              color: Colors.purple,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ----------------------------------
                  // ⭐ Recent Activities داخل نفس الكرت
                  // ----------------------------------

                  // 🔮 عنوان Recent Activities + زر التوسيع
                  // ----------------------------------
                  // ⭐ Recent Activities داخل نفس الكرت
                  // ----------------------------------

                  GestureDetector(
                    key: _recentActivitiesKey,
                    onTap: () {
                      setState(() => _expanded = !_expanded);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          "Recent Activities",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6A1B9A),
                          ),
                        ),
                        Icon(Icons.expand_more, color: Colors.purple),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  (_recentActivities.isEmpty)
                      ? const Text("No recent activities yet.",
                          style: TextStyle(color: Colors.grey))
                      : _buildPreviewActivities(),
                ],
              ),
            ),

            //-----------------------------------------------------------------------
            // ===========================
            // ⭐ RECOMMENDATIONS SECTION
            // ===========================
            const SizedBox(height: 10),
            Text(
              key: _recommendationsKey,
              "Recommended for you",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6A1B9A),
              ),
            ),
            const SizedBox(height: 10),
            _buildRecommendationsSection(),

            //-----------------------------------------------------------------------
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewActivities() {
    final items = _recentActivities.take(3).toList();

    // إذا القائمة فاضية
    if (items.isEmpty) {
      return const Text(
        "No recent activities yet.",
        style: TextStyle(color: Colors.grey),
      );
    }

    // -------------------------
    // ⭐ وضع Expanded
    // -------------------------
    if (_expanded) {
      return Column(
        children: items.map((item) {
          final title = item["activity_title"] ?? "Activity";
          final status = item["status"] ?? "pending";

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ViewActivitiesScreen(isStudent: true),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.event, color: Colors.deepPurple, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6A1B9A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Status: $status",
                          style: TextStyle(
                            color: ["approved", "submitted"].contains(status)
                                ? Colors.green
                                : Colors.orange,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }
    print("🔥 recent count = ${items.length}");

// -------------------------
    return SizedBox(
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final title = item["activity_title"] ?? "Activity";
          final status = item["status"] ?? "pending";

          bool isMain = index == 0;

          // ⭐ Premium Offsets (نفس أسلوب Google Tasks)
          double topOffset = index * 20; // يزحف لتحت ناعم
          double leftOffset = index * 0; // يزحف يمين ناعم

          // ⭐ اختلاف عرض الكروت (layer effect)
          // ارتفاع الكروت
          double cardHeight = isMain ? 55 : (index == 1 ? 44 : 36);

// عرض الكروت
          double cardWidth = MediaQuery.of(context).size.width *
              (isMain ? 0.82 : (index == 1 ? 0.76 : 0.72));

          // ⭐ شفافية الكروت الخلفية (فقط تلميح)
          double opacity = isMain ? 1.0 : (0.20 + index * 0.13);

          return Positioned(
            top: topOffset,
            left: leftOffset,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: cardWidth,
              height: cardHeight,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(opacity),
                borderRadius: BorderRadius.circular(isMain ? 20 : 16),

                // ⭐ Premium Shadow (لكل طبقة شكل مختلف)
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isMain ? 0.15 : 0.21),
                    blurRadius: isMain ? 10 : 6,
                    offset: Offset(0, isMain ? 4 : 2),
                  ),
                ],
              ),

              // ⭐ محتوى الكرت الأساسي فقط
              child: isMain
                  ? Row(
                      children: [
                        const Icon(Icons.event,
                            color: Colors.deepPurple, size: 26),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6A1B9A),
                            ),
                          ),
                        ),
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 13,
                            color: ["approved", "submitted"].contains(status)
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          );
        }).reversed.toList(),
      ),
    );
  }

  //-----------------------------------------------------------------------------
  Widget _buildRecommendationsSection() {
    if (_recommendations.isEmpty) {
      return const Text(
        "No recommendations yet.",
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _recommendations.map((item) {
        final name = item["service_title"] ?? item["title"] ?? "Service";
        final desc = item["description"] ?? "";

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ViewActivitiesScreen(isStudent: true),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.recommend, color: Colors.deepPurple, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7B1FA2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  //-----------------------------------------------------------------------------

  Widget _circleFeature({
    Key? key, // ✅ هذا هو الحل

    required IconData icon,
    required String label,
    required List<Color> colors, // ← رح نتجاهل الـ colors
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key, // ⭐⭐⭐ هذا السطر هو المهم

      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ✨ دائرة بنفسجية موحدة
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.purple, // 💜 بنفسجي ثابت
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B1FA2).withOpacity(0.7),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: 26,
                color: Colors.white, // 🤍 أبيض
              ),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A148C), // بنفسجي غامق للنص
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await storage.delete(key: 'authToken');
      await storage.delete(key: 'jwt_token');
      await storage.delete(key: 'studentUniId');

      _messageTimer?.cancel();
      _notifTimer?.cancel();
      await _audioPlayer.stop();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => SigninScreen(),
        ), // عدّلي الاسم لو مختلف
        (route) => false,
      );
    } catch (e) {
      debugPrint("Logout error: $e");
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.purple),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                if (email.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentProfileScreen(
                        studentId: widget.studentId,
                        email: email,
                      ),
                    ),
                  ).then((_) async {
                    await _fetchUserData();
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Profile information not loaded yet"),
                    ),
                  );
                }
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        (photoUrl != null) ? NetworkImage(photoUrl!) : null,
                    child: (photoUrl == null)
                        ? const Icon(Icons.person,
                            color: Colors.deepPurple, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fullName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text(email,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.deepPurple),
            title:
                const Text("Home", style: TextStyle(color: Colors.deepPurple)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.deepPurple),
            title:
                const Text("Help", style: TextStyle(color: Colors.deepPurple)),
            onTap: () {
              Navigator.pop(context);
              if (serviceCenterId != null) {
                if (serviceCenterId != null && userId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HelpScreen(
                        studentId: widget.studentId,
                        serviceCenterId: serviceCenterId!,
                        userId: userId!, // ✅ تم التحقق مسبقًا من null
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("⚠️ Missing data, try again later.")),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.tour, color: Colors.deepPurple),
            title:
                const Text("Guide", style: TextStyle(color: Colors.deepPurple)),
            onTap: () {
              Navigator.pop(context); // يغلق الدرج أولاً
              // ننتظر لحظة صغيرة بعد الإغلاق قبل تشغيل الجولة
              Future.delayed(const Duration(milliseconds: 300), () {
                _showTutorial(); // ✅ يشغل الجولة
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.upload_file, color: Colors.deepPurple),
            title: const Text("My Submissions",
                style: TextStyle(color: Colors.deepPurple)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      StudentSubmissionScreen(studentId: widget.studentId),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart, color: Colors.deepPurple),
            title: const Text("My Progress",
                style: TextStyle(color: Colors.deepPurple)),
            onTap: () async {
              Navigator.pop(context);
              final studentUniId = await _extractStudentUniId();
              if (studentUniId == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyProgressScreen(studentUniId: studentUniId),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_document, color: Colors.deepPurple),
            title: const Text("My Requests",
                style: TextStyle(color: Colors.deepPurple)),
            onTap: () {
              Navigator.pop(context);
              _showRequestsOptions();
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.message_outlined, color: Colors.deepPurple),
            title: const Text("Messages",
                style: TextStyle(color: Colors.deepPurple)),
            onTap: () {
              Navigator.pop(context);
              if (serviceCenterId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentMessagesScreen(
                      studentId: widget.studentId,
                      serviceCenterId: serviceCenterId!,
                    ),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today, color: Colors.deepPurple),
            title: const Text("Calendar",
                style: TextStyle(color: Colors.deepPurple)),
            onTap: () {
              Navigator.pop(context);
              _openCalendarPage();
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.notifications_none, color: Colors.deepPurple),
            title: const Text("Notifications",
                style: TextStyle(color: Colors.deepPurple)),
            onTap: () {
              Navigator.pop(context);
              _openNotificationsPage();
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.deepPurple),
            title: const Text(
              "Logout",
              style: TextStyle(color: Colors.deepPurple),
            ),
            onTap: () async {
              Navigator.pop(context); // يغلق الدرج أولاً

              // 🔹 افتحي مربع التأكيد
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
                          Navigator.pop(context); // إلغاء
                        },
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context); // إغلاق مربع الحوار
                          await _logout(); // تنفيذ تسجيل الخروج
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
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey,
      items: [
        // 🏠 الصفحة الرئيسية
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),

        // 💬 الرسائل
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.message_outlined),
              if (unreadMessageCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: _buildBadge(unreadMessageCount),
                ),
            ],
          ),
          label: 'Messages',
        ),

        // ☰ القائمة الجانبية (Drawer)
        const BottomNavigationBarItem(
          icon: Icon(Icons.menu),
          label: 'Menu',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomeContent(), // 0 → Home
      userId == null || serviceCenterId == null
          ? const Center(child: CircularProgressIndicator())
          : StudentMessagesScreen(
              studentId: widget.studentId,
              serviceCenterId: serviceCenterId!,
            ),

      const SizedBox.shrink(), // 2 → Placeholder (Menu)
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: _buildDrawer(),
      body: SafeArea(
        // ✅ يمنع التصاق المحتوى بالأعلى
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration:
          const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      child: Text('$count',
          style: const TextStyle(color: Colors.white, fontSize: 10)),
    );
  }

  Future<String?> _extractStudentUniId() async {
    final storage = const FlutterSecureStorage();

    // 1️⃣ من التوكن
    final token = await storage.read(key: 'authToken') ??
        await storage.read(key: 'jwt_token');
    if (token != null && token.split('.').length == 3) {
      try {
        final payload = utf8
            .decode(base64Url.decode(base64Url.normalize(token.split('.')[1])));
        final data = jsonDecode(payload);

        final candidates = [
          data['student_id'],
          data['studentId'],
          data['university_id'],
          data['universityId'],
          data['sid'],
          (data['user'] is Map)
              ? (data['user']['student_id'] ?? data['user']['studentId'])
              : null,
        ].where((v) => v != null && v.toString().trim().isNotEmpty).toList();

        if (candidates.isNotEmpty) return candidates.first.toString();
      } catch (e) {
        debugPrint("JWT decode error: $e");
      }
    }

    // 2️⃣ من التخزين الآمن (لو محفوظ مسبقاً)
    final saved = await storage.read(key: 'studentUniId');
    if (saved != null && saved.trim().isNotEmpty) return saved;

    // 3️⃣ من الإيميل (اختياري)
    try {
      final emailRegex = RegExp(r'(\d{6,})');
      final m = emailRegex.firstMatch(email ?? '');
      if (m != null) return m.group(1);
    } catch (_) {}

    return null;
  }

  void _openCalendarPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentCalendarScreen(studentId: widget.studentId),
      ),
    );
    // ممكن لاحقاً نعمل refresh لعدد الديدلاينز:
    // await _fetchCalendarDueCount();
  }

  Future<void> _handleStudentNotificationTap(Map<String, dynamic> n) async {
    final type = n['type'];

    if (!mounted) return;

    switch (type) {
      // 💬 رسالة
      case 'message':
        if (serviceCenterId != null) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentMessagesScreen(
                studentId: widget.studentId,
                serviceCenterId: serviceCenterId!,
              ),
            ),
          );
          _fetchUnreadMessagesCount();
        }
        break;

      // 📝 طلب (Request approved / rejected)
      case 'request':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViewRequestsScreen(
              studentId: widget.studentId,
            ),
          ),
        );
        break;

      // 📢 نشاط
      case 'activity':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ViewActivitiesScreen(isStudent: true),
          ),
        );
        break;

      // ❓ افتراضي
      default:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const StudentNotificationsScreen(serverIP: serverIP),
          ),
        );
        break;
    }
  }
}

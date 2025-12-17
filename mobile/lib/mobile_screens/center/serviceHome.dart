import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../shared/activity_details_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'editCenterProfileScreen.dart';
import '../student/showProfileScreen.dart';
import 'selectUserScreen.dart';
import '../student/all_students_page.dart';
import 'viewActivitiesScreen.dart';
import 'addActivityScreen.dart';
import 'package:mobile/services/api_service.dart';
import 'studentQuestionsScreen.dart';
import 'requests_page.dart';
import 'approvals_page.dart';
import 'center_submissions_screen.dart';
import '../../shared_screens/signin_screen.dart';
import 'calendar_activities.dart';

class ServiceHomeScreen extends StatefulWidget {
  const ServiceHomeScreen({super.key});

  @override
  State<ServiceHomeScreen> createState() => _ServiceHomeScreenState();
}

class _ServiceHomeScreenState extends State<ServiceHomeScreen> {
  int _selectedIndex = 0;
  List<Widget> _pages = [];
  final storage = const FlutterSecureStorage();
  int? serviceCenterId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<dynamic> recentRequests = [];
  bool loadingRecent = true;

  String fullName = "Service Center";
  String email = "Loading...";
  String? photoUrl;

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  String _selectedFilter = "all";
  Map<int, String> _aiSummaries = {};

  static const String serverIP = "10.0.2.2";
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadServiceCenter();
    _fetchRecentRequests();
    _pages = [
      _buildHomePage(),
      if (serviceCenterId != null)
        SelectUserScreen(currentUserId: serviceCenterId!)
      else
        const Center(child: CircularProgressIndicator()),
      const StudentQuestionsScreen(),
    ];
  }

  Future<void> _loadAiForRequest(int requestId) async {
    if (_aiSummaries.containsKey(requestId)) return;

    try {
      final response = await ApiService.getCustomRequestSimilarity(requestId);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List matches = data['matches'] ?? [];
        String summary;

        if (matches.isEmpty) {
          summary = "No similarity found with any existing service.";
        } else {
          final best = matches[0];
          final double sim = (best['similarity'] ?? 0.0) * 100;
          final String level = best['level'] ?? "low";

          summary =
              "Closest service: ${best['title']} (${sim.toStringAsFixed(0)}% similarity - $level)";
        }

        setState(() {
          _aiSummaries[requestId] = summary;
        });
      } else {
        setState(() {
          _aiSummaries[requestId] =
              "AI analysis failed (${response.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        _aiSummaries[requestId] = "There is no similarity to any service";
      });
    }
  }

  Future<void> _loadServiceCenter() async {
    bool ok = await _fetchServiceData();

    if (ok && mounted) setState(() {});
  }

  Future<void> _fetchRecentRequests() async {
    try {
      final volunteerRes = await ApiService.getVolunteerRequests();
      final customRes = await ApiService.getCustomRequests();

      List all = [];

      if (volunteerRes.statusCode == 200) {
        final v = json.decode(volunteerRes.body);
        for (var item in v) {
          all.add({
            "student_name": item["student_name"],
            "student_photo": item["student_photo"] != null
                ? "http://10.0.2.2:5000${item["student_photo"]}"
                : null,
            "title": item["activity_title"],
            "created_at": item["created_at"],
            "status": item["status"],
          });
        }
      }

      if (customRes.statusCode == 200) {
        final c = json.decode(customRes.body);
        for (var item in c) {
          all.add({
            "request_id": item["request_id"],
            "student_name": item["student_name"],
            "student_photo": item["student_photo"] != null
                ? "http://10.0.2.2:5000${item["student_photo"]}"
                : null,
            "title": item["title"],
            "created_at": item["created_at"],
            "status": item["status"],
          });
        }
      }

      all.sort((a, b) => DateTime.parse(b["created_at"])
          .compareTo(DateTime.parse(a["created_at"])));

      recentRequests = all.take(3).toList();
    } catch (e) {
      print("❌ Error loading recent requests: $e");
    }

    setState(() => loadingRecent = false);
  }

  Future<void> _logout() async {
    try {
      await storage.delete(key: 'authToken');
      await storage.delete(key: 'jwt_token');
      await storage.delete(key: 'userId');
      await storage.delete(key: 'userRole');

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SigninScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint("Logout error (service center): $e");
    }
  }

  Widget _buildRecentRequestsCard() {
    if (loadingRecent) {
      return const Center(child: CircularProgressIndicator());
    }

    if (recentRequests.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text("No recent requests", style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: recentRequests.map((req) {
        final requestId = req["request_id"];

        if (requestId != null) _loadAiForRequest(requestId);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 3,
          child: ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: req["student_photo"] != null
                  ? NetworkImage(req["student_photo"])
                  : null,
              backgroundColor: Colors.grey[300],
            ),
            title: Text(req["student_name"] ?? "Unknown",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(req["title"] ?? ""),
                const SizedBox(height: 6),
                if (requestId != null)
                  Text(
                    _aiSummaries[requestId] ?? "AI analyzing...",
                    style: const TextStyle(
                      color: Colors.deepPurple,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            trailing: _statusBadge(req["status"]),
          ),
        );
      }).toList(),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    if (status == "accepted")
      color = Colors.green;
    else if (status == "rejected")
      color = Colors.red;
    else
      color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Future<bool> _fetchServiceData() async {
    try {
      final token = await storage.read(key: 'authToken');
      final url = Uri.parse('http://$serverIP:5000/api/service/profile');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        final data = decoded is Map && decoded.containsKey('profile')
            ? decoded['profile']
            : decoded;

        setState(() {
          fullName = data['full_name'] ?? "Service Admin";
          email = data['email'] ?? "unknown@uniserve.com";
          serviceCenterId = data['id'];

          final serverPhoto = data['photo_url'];
          photoUrl = (serverPhoto != null && serverPhoto.isNotEmpty)
              ? "http://$serverIP:5000$serverPhoto?t=${DateTime.now().millisecondsSinceEpoch}"
              : null;
        });

        return true;
      } else {
        print("❌ Failed to load service data: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("⚠️ Error fetching service data: $e");
      return false;
    }
  }

  Future<void> _search(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
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
        final url =
            Uri.parse("http://$serverIP:5000/api/search?q=$query&role=service");
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() {
            _searchResults = data;
          });
        }
      } catch (e) {
        print("❌ Error searching: $e");
      }

      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> _askAI(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchResults.clear();
    });

    try {
      final token = await storage.read(key: 'authToken');

      if (token == null) {
        print("⚠️ No token found!");
        setState(() => _isLoading = false);
        return;
      }

      final url = Uri.parse("http://$serverIP:5000/api/ai/query");
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode({"q": query}),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> results = [];

        if (decoded is Map && decoded['matches'] is List) {
          results = decoded['matches'].map((e) {
            return {
              "id": e["id"],
              "name": e["title"],
              "description": e["description"],
              "image_url": e["image_url"],
              "type": e["type"],
            };
          }).toList();
        } else if (decoded is List) {
          results = decoded;
        } else {
          results = [
            {
              "name": decoded["message"] ?? "No AI results found",
              "type": "ai_suggestion",
            }
          ];
        }

        setState(() {
          _searchResults = results;
        });
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
                  Navigator.pop(context);
                  setStateSheet(() => _isLoading = true);
                  await _askAI(query);
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
                          hintText: "Search activities, students, centers...",
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.purple),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Colors.purple),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.smart_toy_outlined,
                          color: Colors.deepPurple),
                      onPressed: () => _showAIDialog(context, setStateSheet),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.purple),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // FILTER BAR
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 10),
                  height: 45,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        _buildFilterChip(
                            setStateSheet, "all", "All", Icons.all_inclusive),
                        const SizedBox(width: 10),
                        _buildFilterChip(
                            setStateSheet, "student", "Students", Icons.school),
                        const SizedBox(width: 10),
                        _buildFilterChip(setStateSheet, "activity",
                            "Activities", Icons.event_note),
                        const SizedBox(width: 10),
                        _buildFilterChip(setStateSheet, "doctor", "Doctors",
                            Icons.medical_information),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: _isLoading
                      ? const Center(
                          child:
                              CircularProgressIndicator(color: Colors.purple))
                      : _searchResults.isEmpty
                          ? const Center(
                              child: Text("No results found.",
                                  style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final item = _searchResults[index];

                                if (_selectedFilter != "all" &&
                                    item["type"] != _selectedFilter) {
                                  return const SizedBox.shrink();
                                }

                                final type = item["type"];
                                final imageUrl = item["image_url"] != null
                                    ? "http://10.0.2.2:5000/${item["image_url"]}"
                                    : "http://10.0.2.2:5000/uploads/default.jpg";

                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        imageUrl,
                                        width: 55,
                                        height: 55,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.image,
                                              color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      item["name"],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF7B1FA2)),
                                    ),
                                    subtitle: Text(
                                      type.toUpperCase(),
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),
                                    trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.purple,
                                        size: 18),
                                    onTap: () {
                                      if (type == "activity") {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ActivityDetailsScreen(
                                                    activityId: item["id"]),
                                          ),
                                        );
                                      } else if (type == "student") {
                                        final sid =
                                            item["student_id"]?.toString() ??
                                                item["id"]?.toString();

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ShowProfileScreen(
                                              studentId: sid!,
                                              email: item["email"] ?? '',
                                              fullName: item["full_name"] ??
                                                  item["name"],
                                              photoUrl: item["photo_url"] !=
                                                      null
                                                  ? "http://10.0.2.2:5000${item["photo_url"]}"
                                                  : null,
                                              showEditButton: false,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        });
      },
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
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18, color: isSelected ? Colors.purple : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.purple : Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
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
            const SizedBox(height: 20),
            Container(
              width: 360,
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
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Welcome!",
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Service Center",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const CalendarActivitiesScreen()));
                        },
                        icon: const Icon(Icons.calendar_month,
                            color: Colors.white),
                      ),
                      _ServiceBell(
                          onNotificationsUpdated: _fetchRecentRequests),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.of(context).push(PageRouteBuilder(
                            transitionDuration:
                                const Duration(milliseconds: 350),
                            pageBuilder: (_, __, ___) => ServiceProfileScreen(
                              email: email,
                              onProfileUpdated: _fetchServiceData,
                            ),
                            transitionsBuilder: (_, animation, __, child) =>
                                FadeTransition(
                                    opacity: animation, child: child),
                          ));

                          await _fetchServiceData();
                        },
                        child: Hero(
                          tag: "serviceAvatar",
                          child: CircleAvatar(
                            radius: 22,
                            backgroundImage: photoUrl != null
                                ? NetworkImage(photoUrl!)
                                : const AssetImage(
                                        'assets/images/uniserve_logo.jpeg')
                                    as ImageProvider,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _prettySearchBar(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 3,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildFeatureButton(Icons.upload_file, "Submissions"),
                  _buildFeatureButton(Icons.people_alt, "Students"),
                  _buildFeatureButton(Icons.list_alt, "Activities"),
                  _buildFeatureButton(Icons.verified_outlined, "Approvals"),
                  _buildFeatureButton(Icons.assignment_turned_in, "Requests"),
                  _buildFeatureButton(Icons.add_circle, "Add Activity"),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Requests",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RequestsPage()),
                      );
                    },
                    child: const Text("See All",
                        style: TextStyle(color: Colors.purple, fontSize: 14)),
                  ),
                ],
              ),
            ),
            _buildRecentRequestsCard(),
          ],
        ),
      ),
    );
  }

  // FEATURE BUTTON
  Widget _buildFeatureButton(IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (label == "Students") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StudentsPage()),
            );
          } else if (label == "Activities") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ViewActivitiesScreen()),
            );
          } else if (label == "Add Activity") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddActivityScreen()),
            );
          } else if (label == "Requests") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RequestsPage()),
            );
          } else if (label == "Approvals") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ApprovalsPage()),
            );
          } else if (label == "Submissions") {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CenterSubmissionsScreen()),
            );
          } else {
            print("$label tapped");
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.purple, size: 30),
            const SizedBox(height: 10),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.purple)),
          ],
        ),
      ),
    );
  }

  Widget _prettySearchBar() {
    return GestureDetector(
      onTap: _openSearchSheet,
      child: Container(
        height: 50,
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.purple,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 15),
            const Text(
              "search",
              style: TextStyle(
                color: Colors.purple,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 3) {
      _scaffoldKey.currentState?.openEndDrawer();
    } else {
      setState(() {
        _selectedIndex = index;
      });
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
              ? (serviceCenterId != null
                  ? SelectUserScreen(currentUserId: serviceCenterId!)
                  : const Center(child: CircularProgressIndicator()))
              : const StudentQuestionsScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF7B1FA2),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.message_outlined), label: 'Messages'),
          BottomNavigationBarItem(
              icon: Icon(Icons.question_answer), label: 'Questions'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
        ],
      ),
    );
  }

  // DRAWER
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceProfileScreen(
                    email: email,
                    onProfileUpdated: _fetchServiceData,
                  ),
                ),
              );
            },
            child: UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              accountName: Text(fullName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              accountEmail: Text(email),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage:
                    (photoUrl != null) ? NetworkImage(photoUrl!) : null,
                child: (photoUrl == null)
                    ? const Icon(Icons.person, color: Colors.purple, size: 30)
                    : null,
              ),
            ),
          ),
          _buildDrawerItem(Icons.upload_file, "Submissions"),
          _buildDrawerItem(Icons.add_circle, "Add Activity"),
          _buildDrawerItem(Icons.list_alt, "Activities"),
          _buildDrawerItem(Icons.notifications, "Notifications"),
          const SizedBox(height: 1),
          SizedBox(height: MediaQuery.of(context).size.height * 0.45),
          _buildDrawerItem(Icons.logout, "Logout"),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.purple),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context);

        if (title == "Submissions") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CenterSubmissionsScreen(),
            ),
          );
          return;
        }
        if (title == "Add Activity") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddActivityScreen()),
          );
          return;
        }
        if (title == "Activities") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ViewActivitiesScreen()),
          );
          return;
        }

        if (title == "Notifications") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ServiceCenterNotificationsScreen(),
            ),
          );
          return;
        }

        if (title == "Logout") {
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
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _logout();
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
          return;
        }
      },
    );
  }
}

/* ==========================================
   🔔 SERVICE CENTER NOTIFICATIONS SCREEN
========================================== */

const Color uniPurple = Color(0xFF7B1FA2);

class ServiceCenterNotificationsScreen extends StatefulWidget {
  const ServiceCenterNotificationsScreen({super.key});

  @override
  State<ServiceCenterNotificationsScreen> createState() =>
      _ServiceCenterNotificationsScreenState();
}

class _ServiceCenterNotificationsScreenState
    extends State<ServiceCenterNotificationsScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];

  Future<void> _load() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final data = await ApiService.getMyNotifications();
      setState(() {
        _items = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error: $e";
        _loading = false;
      });
    }
  }

  Future<void> _markRead(int id) async {
    try {
      await ApiService.markNotificationRead(id);

      setState(() {
        final idx = _items.indexWhere((e) => e['id'] == id);
        if (idx != -1) {
          _items[idx]['status'] = 'read';
          _items[idx]['is_read'] = 1;
        }
      });
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: uniPurple,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF5F5F7),
              Color(0xFFE5E5E8),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 70),
            Text(
              "Notifications",
              style: TextStyle(
                fontFamily: "Baloo",
                fontSize: 44,
                fontWeight: FontWeight.w700,
                color: uniPurple,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 1.8),
                    blurRadius: 5,
                    color: uniPurple.withOpacity(0.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: uniPurple),
                    )
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _items.isEmpty
                          ? const Center(
                              child: Text(
                                "No notifications yet!",
                                style: TextStyle(
                                  fontFamily: "Baloo",
                                  fontSize: 20,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 18),
                                itemCount: _items.length,
                                itemBuilder: (_, i) {
                                  final n = _items[i];
                                  final isRead = (n['is_read'] ?? 0) == 1 ||
                                      n['status'] == 'read';

                                  return AnimatedOpacity(
                                    duration: const Duration(milliseconds: 250),
                                    opacity: isRead ? 0.55 : 1,
                                    child: Column(
                                      children: [
                                        _notificationItem(n, isRead),
                                        const Divider(
                                          height: 18,
                                          thickness: 0.6,
                                          color: Colors.black12,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationItem(dynamic n, bool isRead) {
    final title = n['title'] ?? 'Notification';
    final body = n['body'] ?? '';
    final type =
        (n['type'] ?? "").toString().replaceAll("_", " ").toUpperCase();
    final createdAt = n['created_at'] ?? "";

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isRead ? 0.8 : 0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.08),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isRead ? Colors.grey.shade300 : uniPurple.withOpacity(0.20),
            ),
            child: Icon(
              Icons.notifications,
              size: 24,
              color: isRead ? Colors.grey.shade600 : uniPurple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: "Baloo",
                    fontSize: 17,
                    fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                    color: isRead ? Colors.black87 : uniPurple,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      createdAt,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          isRead
              ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
              : InkWell(
                  onTap: () => _markRead(n['id']),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Text(
                      "Mark",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

/* =============================
   🔔 جرس الإشعارات مع البادج
============================= */

class _ServiceBell extends StatefulWidget {
  final Function() onNotificationsUpdated;

  const _ServiceBell({required this.onNotificationsUpdated});

  @override
  State<_ServiceBell> createState() => _ServiceBellState();
}

class _ServiceBellState extends State<_ServiceBell> {
  int unread = 0;

  @override
  void initState() {
    super.initState();
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    try {
      final data = await ApiService.getMyNotifications();
      final count = data.where((n) => n['is_read'] == 0).length;
      setState(() => unread = count);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ServiceCenterNotificationsScreen(),
              ),
            );
            widget.onNotificationsUpdated();
            _loadUnread();
          },
        ),
        if (unread > 0)
          Positioned(
            right: 0,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
              ),
              child: Text(
                unread.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }
}

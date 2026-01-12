// lib/screens/student/student_notifications_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// NEW
import 'myProgressScreen.dart';

class StudentNotificationsScreen extends StatefulWidget {
  final String serverIP;
  const StudentNotificationsScreen({super.key, required this.serverIP});

  @override
  State<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

const Color uniPurple = Color(0xFF7B1FA2);

class _StudentNotificationsScreenState extends State<StudentNotificationsScreen>
    with SingleTickerProviderStateMixin {
  final storage = const FlutterSecureStorage();
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];

  // =========================
  // Tabs
  // =========================
  late TabController _tabController;
  final List<String> _tabs = ["all", "activity", "request", "course"];

  // =========================
  // Load notifications
  // =========================
  Future<void> _load() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final token = await storage.read(key: 'authToken');
      final url =
          Uri.parse('http://${widget.serverIP}:5000/api/notifications/my');

      final res = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (res.statusCode != 200) {
        setState(() {
          _error = 'Failed to load notifications (${res.statusCode})';
          _loading = false;
        });
        return;
      }

      final body = json.decode(res.body);
      final data = (body['data'] as List?) ?? [];

      setState(() {
        _items = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  // =========================
  // Mark as read
  // =========================
  Future<void> _markRead(int id) async {
    try {
      final token = await storage.read(key: 'authToken');
      final url = Uri.parse(
          'http://${widget.serverIP}:5000/api/notifications/$id/read');

      final res = await http.patch(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (res.statusCode == 200) {
        final idx = _items.indexWhere((e) => e['id'] == id);
        if (idx != -1) {
          setState(() {
            _items[idx]['status'] = 'read';
            _items[idx]['is_read'] = 1;
            _items[idx]['read_at'] = DateTime.now().toIso8601String();
          });
        }
      }
    } catch (_) {}
  }

  // =========================
  // Handle notification tap (NEW)
  // =========================
  Future<void> _handleNotificationTap(dynamic n) async {
    await _markRead(n['id']);

    final type = n['type'];
    final payload = n['payload'] ?? {};
    final reqType = payload['request_type'];

    // Volunteer accepted → Progress
    if (type == 'request_accepted' && reqType == 'volunteer') {
      final studentId = payload['student_user_id']?.toString();
      if (studentId != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MyProgressScreen(studentUniId: studentId),
          ),
        );
      }
      return;
    }

    // باقي الحالات: إشعار فقط (no navigation)
  }

  // =========================
  // Filter by tab
  // =========================
  List<dynamic> _filteredItems(String tab) {
    if (tab == "all") return _items;

    return _items.where((n) {
      final payload = n['payload'] ?? {};
      final reqType = payload['request_type'];
      final type = n['type'];

      if (tab == "activity") {
        return reqType == 'volunteer' ||
            type == 'volunteer_request' ||
            type == 'request_accepted' ||
            type == 'request_rejected';
      }

      if (tab == "request") {
        return reqType == 'custom';
      }

      if (tab == "course") {
        return type == 'academic_result';
      }

      return false;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: uniPurple),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F5F7), Color(0xFFE5E5E8)],
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
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              labelColor: uniPurple,
              unselectedLabelColor: Colors.grey,
              indicatorColor: uniPurple,
              tabs: const [
                Tab(text: "All"),
                Tab(text: "Activities"),
                Tab(text: "Requests"),
                Tab(text: "Course Results"),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: uniPurple),
                    )
                  : _error != null
                      ? Center(child: Text(_error!))
                      : TabBarView(
                          controller: _tabController,
                          children: _tabs.map((tab) {
                            final list = _filteredItems(tab);

                            if (list.isEmpty) {
                              return const Center(
                                child: Text(
                                  "No notifications yet!",
                                  style: TextStyle(
                                    fontFamily: "Baloo",
                                    fontSize: 20,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            }

                            return RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 18),
                                itemCount: list.length,
                                itemBuilder: (_, i) {
                                  final n = list[i];
                                  final isRead = (n['is_read'] ?? 0) == 1 ||
                                      n['status'] == 'read';

                                  return AnimatedOpacity(
                                    duration: const Duration(milliseconds: 250),
                                    opacity: isRead ? 0.55 : 1,
                                    child: GestureDetector(
                                      onTap: () =>
                                          _handleNotificationTap(n), // NEW
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
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Notification item (UNCHANGED)
  // =========================
  Widget _notificationItem(dynamic n, bool isRead) {
    if (n['type'] == 'academic_result') {
      return _courseResultItem(n, isRead);
    }
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

  Widget _courseResultItem(dynamic n, bool isRead) {
    final payload = n['payload'] ?? {};
    final result = payload['result'] ?? 'fail';
    final hours = payload['total_hours'] ?? 0;

    final isPass = result == 'pass';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isPass ? Colors.green : Colors.red,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPass ? Icons.emoji_events : Icons.cancel,
            size: 36,
            color: isPass ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPass ? "Course Passed 🎉" : "Course Failed ❌",
                  style: TextStyle(
                    fontFamily: "Baloo",
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isPass ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Completed Hours: $hours",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (!isRead) const Icon(Icons.fiber_new, color: uniPurple, size: 22),
        ],
      ),
    );
  }
}

// lib/screens/student/student_notifications_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StudentNotificationsScreen extends StatefulWidget {
  final String serverIP;
  const StudentNotificationsScreen({super.key, required this.serverIP});

  @override
  State<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

const Color uniPurple = Color(0xFF7B1FA2);

class _StudentNotificationsScreenState
    extends State<StudentNotificationsScreen> {
  final storage = const FlutterSecureStorage();
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];

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
        setState(() {
          final idx = _items.indexWhere((e) => e['id'] == id);
          if (idx != -1) {
            _items[idx]['status'] = 'read';
            _items[idx]['is_read'] = 1;
            _items[idx]['read_at'] = DateTime.now().toIso8601String();
          }
        });
      }
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

      // خلفية gradient ناعمة وراقية
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

            // عنوان Notifications مع ظل بسيط
            Text(
              "Notifications",
              style: TextStyle(
                fontFamily: "Baloo",
                fontSize: 44,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF7B1FA2),
                shadows: [
                  Shadow(
                    offset: const Offset(0, 1.8),
                    blurRadius: 5,
                    color: const Color(0xFF7B1FA2).withOpacity(0.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7B1FA2),
                      ),
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

  // تصميم إشعار عصري بدون كروت مزعجة
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
              color: isRead
                  ? Colors.grey.shade300
                  : const Color(0xFF7B1FA2).withOpacity(0.20),
            ),
            child: Icon(
              Icons.notifications,
              size: 24,
              color: isRead ? Colors.grey.shade600 : const Color(0xFF7B1FA2),
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
                    color: isRead ? Colors.black87 : const Color(0xFF7B1FA2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(fontSize: 14),
                ),
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
                )
        ],
      ),
    );
  }
}

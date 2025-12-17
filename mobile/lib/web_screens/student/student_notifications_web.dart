import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:mobile/services/token_service.dart';

class StudentNotificationsWeb extends StatefulWidget {
  final String serverIP;

  const StudentNotificationsWeb({
    super.key,
    required this.serverIP,
  });

  @override
  State<StudentNotificationsWeb> createState() =>
      _StudentNotificationsWebState();
}

class _StudentNotificationsWebState extends State<StudentNotificationsWeb> {
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];

  Color get purple => const Color(0xFF7B1FA2);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // =========================================================
  //     GET TOKEN (الموبايل = SecureStorage / الويب = SharedPrefs)
  // =========================================================
  Future<String?> _getToken() async {
    final token = await TokenService.getToken();
    debugPrint("🔑 TOKEN USED = $token");
    return token;
  }


  // =========================================================
  //                    LOAD NOTIFICATIONS
  // =========================================================
  Future<void> _load() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final token = await _getToken();

      if (token == null) {
        setState(() {
          _error = "No auth token found (user not logged in)";
          _loading = false;
        });
        return;
      }

      final url =
          Uri.parse("http://${widget.serverIP}:5000/api/notifications/my");

      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode != 200) {
        setState(() {
          _error = "Failed to load notifications (${res.statusCode})";
          _loading = false;
        });
        return;
      }

      final body = jsonDecode(res.body);

      if (body is List) {
        _items = body;
      } else if (body is Map && body["data"] is List) {
        _items = body["data"];
      } else {
        _items = [];
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = "Error: $e";
        _loading = false;
      });
    }
  }

  // =========================================================
  //                    MARK AS READ
  // =========================================================
  Future<void> _markRead(int id) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final url =
          Uri.parse("http://${widget.serverIP}:5000/api/notifications/$id/read");

      final res = await http.patch(
        url,
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        setState(() {
          final idx = _items.indexWhere((e) => e["id"] == id);
          if (idx != -1) _items[idx]["is_read"] = 1;
        });
      }
    } catch (_) {}
  }

  // =========================================================
  //                    UI
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Notifications",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7B1FA2),
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: Color(0xFF7B1FA2)),
                  )
                : _error != null
                    ? Center(child: Text(_error!))
                    : _items.isEmpty
                        ? const Center(
                            child: Text(
                              "No notifications yet!",
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          )
                        : Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            child: ListView.builder(
                              controller: _scrollController,
                              primary: false, // 🔑 مهم جداً
                              padding:
                                  const EdgeInsets.only(bottom: 20),
                              itemCount: _items.length,
                              itemBuilder: (_, i) {
                                final n = _items[i];
                                final isRead = n["is_read"] == 1;
                                return _notificationCard(n, isRead);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  //                NOTIFICATION CARD
  // =========================================================
  Widget _notificationCard(dynamic n, bool isRead) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isRead ? Colors.grey.shade300 : purple.withOpacity(0.35),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 6,
          )
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications,
            size: 28,
            color: isRead ? Colors.grey : purple,
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n["title"] ?? "Notification",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        isRead ? FontWeight.w500 : FontWeight.w700,
                    color: isRead ? Colors.black87 : purple,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  n["body"] ?? "",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  n["created_at"] ?? "",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          isRead
              ? const Icon(Icons.check_circle,
                  color: Colors.green, size: 20)
              : TextButton(
                  onPressed: () => _markRead(n["id"]),
                  child: const Text(
                    "Mark",
                    style:
                        TextStyle(fontSize: 13, color: Colors.blueGrey),
                  ),
                )
        ],
      ),
    );
  }
}

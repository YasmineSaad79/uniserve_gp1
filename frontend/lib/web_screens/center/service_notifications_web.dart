import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:mobile/services/token_service.dart';

class ServiceNotificationsWeb extends StatefulWidget {
  final String serverIP;

  const ServiceNotificationsWeb({
    super.key,
    required this.serverIP,
  });

  @override
  State<ServiceNotificationsWeb> createState() =>
      _ServiceNotificationsWebState();
}

class _ServiceNotificationsWebState extends State<ServiceNotificationsWeb> {
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
  // TOKEN
  // =========================================================
  Future<String?> _getToken() async {
    return await TokenService.getToken();
  }

  // =========================================================
  // LOAD NOTIFICATIONS
  // =========================================================
  Future<void> _load() async {
    try {
      resetState();
      final token = await _getToken();

      if (token == null) {
        _setError("No auth token found");
        return;
      }

      final url = Uri.parse(
        "http://${widget.serverIP}:5000/api/notifications/my",
      );

      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode != 200) {
        _setError("Failed to load (${res.statusCode})");
        return;
      }

      final body = jsonDecode(res.body);

      setState(() {
        _items = body is List ? body : (body["data"] ?? []);
        _loading = false;
      });
    } catch (e) {
      _setError("Error: $e");
    }
  }

  void _setError(String msg) {
    setState(() {
      _error = msg;
      _loading = false;
    });
  }

  void resetState() {
    setState(() {
      _loading = true;
      _error = null;
    });
  }

  // =========================================================
  // MARK AS READ
  // =========================================================
  Future<void> _markRead(int id) async {
    final token = await _getToken();
    if (token == null) return;

    await http.patch(
      Uri.parse(
        "http://${widget.serverIP}:5000/api/notifications/$id/read",
      ),
      headers: {"Authorization": "Bearer $token"},
    );

    _load();
  }

  // =========================================================
  // ACCEPT / REJECT
  // =========================================================
  Future<void> _act(int id, String action) async {
    final token = await _getToken();
    if (token == null) return;

    await http.post(
      Uri.parse(
        "http://${widget.serverIP}:5000/api/notifications/$id/act",
      ),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"action": action}),
    );

    _load();
  }

  // =========================================================
  // UI
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return Padding(
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
                    child: CircularProgressIndicator(
                      color: Color(0xFF7B1FA2),
                    ),
                  )
                : _error != null
                    ? Center(child: Text(_error!))
                    : _items.isEmpty
                        ? const Center(
                            child: Text(
                              "No notifications yet",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: _items.length,
                              itemBuilder: (_, i) =>
                                  _notificationCard(_items[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CARD
  // =========================================================
  Widget _notificationCard(dynamic n) {
    final bool isRead = n["is_read"] == 1;
    final bool isVolunteerRequest =
        n["type"] == "volunteer_request" &&
        n["status"] == "unread";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRead ? Colors.grey.shade300 : purple.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            n["title"] ?? "Notification",
            style: TextStyle(
              fontSize: 16,
              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
              color: isRead ? Colors.black87 : purple,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            n["body"] ?? "",
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                n["created_at"] ?? "",
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),

              if (isVolunteerRequest)
                Row(
                  children: [
                    _actionBtn("Accept", Colors.green,
                        () => _act(n["id"], "accept")),
                    const SizedBox(width: 8),
                    _actionBtn("Reject", Colors.red,
                        () => _act(n["id"], "reject")),
                  ],
                )
              else if (!isRead)
                TextButton(
                  onPressed: () => _markRead(n["id"]),
                  child: const Text("Mark as read"),
                )
              else
                const Icon(Icons.check_circle,
                    color: Colors.green, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
      String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }
}

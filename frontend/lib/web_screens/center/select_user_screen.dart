import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/mobile_screens/shared/chatScreen.dart';
import 'package:mobile/web_screens/student/chat_screen_web.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter/services.dart';


class SelectUserScreen extends StatefulWidget {
  final int currentUserId;

  const SelectUserScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<SelectUserScreen> createState() => _SelectUserScreenState();
}

class _SelectUserScreenState extends State<SelectUserScreen> {
  // =============================
  // PLATFORM-AWARE CONFIG
  // =============================
  String get serverIP => kIsWeb ? "localhost" : "10.0.2.2";

  Future<String?> _getToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString("authToken");
    }
    return const FlutterSecureStorage().read(key: "authToken");
  }

  // =============================
  // STATE
  // =============================
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _refreshTimer;

  // =============================
  // LIFECYCLE
  // =============================
  @override
  void initState() {
    super.initState();
    _fetchUsers();

    _refreshTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _fetchUsers());

    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // =============================
  // DATA FETCH
  // =============================
  Future<void> _fetchUsers() async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final usersUrl =
          Uri.parse("http://$serverIP:5000/api/users");

      final unreadUrl = Uri.parse(
        "http://$serverIP:5000/api/messages/unread-grouped/${widget.currentUserId}",
      );

      final headers = {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      };

      final usersRes = await http.get(usersUrl, headers: headers);
      final unreadRes = await http.get(unreadUrl, headers: headers);

      if (usersRes.statusCode != 200 || unreadRes.statusCode != 200) {
        throw Exception("API error");
      }

      final usersData = jsonDecode(usersRes.body);
      final unreadData = jsonDecode(unreadRes.body);

      final List users =
          usersData is List ? usersData : (usersData['data'] ?? []);
      final List unread =
          unreadData is List ? unreadData : (unreadData['data'] ?? []);

      final Map<int, Map<String, dynamic>> unreadMap = {};

      for (var r in unread) {
        unreadMap[r['sender_id']] = {
          "count": r['unreadCount'] ?? 0,
          "time": r['lastMessageTime'],
          "text": r['lastMessageContent'],
        };
      }

      final merged = users.map((u) {
        final id = u['id'] ?? u['user_id'];
        final meta = unreadMap[id] ?? {};
        return {
          ...u,
          "id": id,
          "unreadCount": meta["count"] ?? 0,
          "lastMessageAt": meta["time"],
          "lastMessageText": meta["text"],
        };
      }).toList();

      merged.sort((a, b) {
        final ta = DateTime.tryParse(a["lastMessageAt"] ?? "");
        final tb = DateTime.tryParse(b["lastMessageAt"] ?? "");
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return tb.compareTo(ta);
      });

      setState(() {
        _users = merged;
        _filteredUsers = merged;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ fetch users error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users
          .where((u) =>
              (u['full_name'] ?? "")
                  .toString()
                  .toLowerCase()
                  .contains(q))
          .toList();
    });
  }

  // =============================
  // NAVIGATION (SMART)
  // =============================
  void _openChat(Map user) {
    final page = kIsWeb
        ? ChatScreenWeb(
            myId: widget.currentUserId,
            otherId: user['id'],
            otherName: user['full_name'] ?? "User",
          )
        : ChatScreen(
            senderId: widget.currentUserId,
            receiverId: user['id'],
          );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((_) => _fetchUsers());
  }

  // =============================
  // UI COMPONENT
  // =============================
  Widget _glassTile(Map user) {
    final unread = user['unreadCount'] ?? 0;
    final imageUrl = user['photo_url'] != null
        ? "http://$serverIP:5000${user['photo_url']}"
        : null;

    String subtitle = "";
    if (user['lastMessageAt'] != null) {
      final t = DateTime.tryParse(user['lastMessageAt']);
      final rel = t != null ? timeago.format(t) : "";
      final msg = user['lastMessageText'] ?? "";
      subtitle = "${msg.split(" ").take(5).join(" ")} • $rel";
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _openChat(user);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(22),
                border:
                    Border.all(color: Colors.white.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage:
                        imageUrl != null ? NetworkImage(imageUrl) : null,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: imageUrl == null
                        ? const Icon(Icons.person,
                            color: Colors.white, size: 28)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['full_name'] ?? "Unknown",
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54),
                          ),
                      ],
                    ),
                  ),
                  if (unread > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        unread.toString(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =============================
  // BUILD
  // =============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Search student...",
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (_, i) =>
                        _glassTile(_filteredUsers[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

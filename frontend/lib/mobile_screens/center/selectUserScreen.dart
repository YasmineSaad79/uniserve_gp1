// 📁 select_user_screen.dart (FULL FILE - WITH GLASS UI)
// -----------------------------------------------------

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter/services.dart';
import 'dart:ui';
import '../shared/chatScreen.dart';

class SelectUserScreen extends StatefulWidget {
  final int currentUserId;

  const SelectUserScreen({super.key, required this.currentUserId});

  @override
  State<SelectUserScreen> createState() => _SelectUserScreenState();
}

class _SelectUserScreenState extends State<SelectUserScreen> {
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final storage = const FlutterSecureStorage();
  Timer? _refreshTimer;

  static const String serverIP = "10.0.2.2";
  final AudioPlayer _audioPlayer = AudioPlayer();
  Map<int, int> _previousUnreadMap = {};

  @override
  void initState() {
    super.initState();
    _fetchUsers();

    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchUsers();
    });

    _searchController.addListener(() => _filterUsers());
  }

  // ✅ جلب قائمة الطلاب المرتبطين بالمركز مع unread count
  Future<void> _fetchUsers() async {
    try {
      final token = await storage.read(key: 'authToken');
      if (token == null) {
        print("🚫 No token found!");
        return;
      }

      final usersUrl = Uri.parse("http://$serverIP:5000/api/users");

      final unreadUrl = Uri.parse(
          "http://$serverIP:5000/api/messages/unread-grouped/${widget.currentUserId}");

      final usersRes = await http.get(usersUrl, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      final unreadRes = await http.get(unreadUrl, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (usersRes.statusCode == 200 && unreadRes.statusCode == 200) {
        final decodedUnread = json.decode(unreadRes.body);
        final decodedUsers = json.decode(usersRes.body);

        final List unreadData = decodedUnread is List
            ? decodedUnread
            : (decodedUnread['data'] ?? []);
        final List usersData =
            decodedUsers is List ? decodedUsers : (decodedUsers['data'] ?? []);

        final Map<int, int> unreadMap = {};
        final Map<int, String?> lastTimes = {};
        final Map<int, String?> lastMessages = {};

        for (var row in unreadData) {
          unreadMap[row['sender_id']] = row['unreadCount'];
          lastTimes[row['sender_id']] = row['lastMessageTime']?.toString();
          lastMessages[row['sender_id']] =
              row['lastMessageContent']?.toString();
        }

        final filtered = usersData.map((u) {
          final id = u['id'] ?? u['user_id'];
          return {
            ...u,
            'id': id,
            'unreadCount': unreadMap[id] ?? 0,
            'lastMessageAt': lastTimes[id],
            'lastMessageText': lastMessages[id],
          };
        }).toList();

        filtered.sort((a, b) {
          final aTime = a['lastMessageAt'] != null
              ? DateTime.tryParse(a['lastMessageAt'])
              : null;
          final bTime = b['lastMessageAt'] != null
              ? DateTime.tryParse(b['lastMessageAt'])
              : null;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        setState(() {
          _users = filtered;
          _filteredUsers = filtered;
          _isLoading = false;
          _previousUnreadMap = {
            for (var u in filtered) u['id']: u['unreadCount'] ?? 0,
          };
        });
      } else {
        print("❌ Failed to load users/unread: "
            "${usersRes.statusCode}/${unreadRes.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("⚠️ Error fetching users: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users
          .where((u) =>
              (u['full_name'] ?? '').toString().toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ⭐⭐⭐ NEW GLASS DESIGN TILE ⭐⭐⭐
  Widget _glassUserTile(Map user) {
    final imageUrl =
        (user['photo_url'] != null && user['photo_url'].toString().isNotEmpty)
            ? "http://$serverIP:5000${user['photo_url']}"
            : null;

    final unread = user['unreadCount'] ?? 0;

    String subtitle = "";
    if (user['lastMessageAt'] != null) {
      final time = DateTime.tryParse(user['lastMessageAt']);
      final rel = time != null ? timeago.format(time) : "";
      final msg = user['lastMessageText'] ?? "";
      subtitle = "${msg.split(" ").take(5).join(" ")} • $rel";
    }

    return GestureDetector(
      onTapDown: (_) => HapticFeedback.lightImpact(),
      onTap: () async {
        setState(() => user['unreadCount'] = 0);

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              senderId: widget.currentUserId,
              receiverId: user['id'],
            ),
          ),
        );
        _fetchUsers();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                  width: 0.9,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.6), width: 1),
                    ),
                    child: CircleAvatar(
                      backgroundImage:
                          imageUrl != null ? NetworkImage(imageUrl) : null,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      child: imageUrl == null
                          ? const Icon(Icons.person,
                              size: 28, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['full_name'] ?? "Unknown",
                          style: const TextStyle(
                            fontFamily: "Baloo",
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.55),
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unread > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purpleAccent.withOpacity(0.4),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: Text(
                        unread.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
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

  // ⭐⭐⭐ FULL NEW UI ⭐⭐⭐
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEDE3F8),
              Color(0xFFFDFBFF),
              Color(0xFFEFE7FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
// 🔙 Back + Refresh (بدون خلفية)
            Padding(
              padding:
                  const EdgeInsets.only(top: 45, left: 8, right: 8, bottom: 5),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.purple,
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.purple,
                      size: 26,
                    ),
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      setState(() => _isLoading = true);
                      await _fetchUsers();
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: "Search student...",
                        border: InputBorder.none,
                        prefixIcon:
                            Icon(Icons.search, color: Colors.purple, size: 26),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: RefreshIndicator(
                color: Colors.deepPurple,
                onRefresh: _fetchUsers,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.purple),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 40),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (_, i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          child: _glassUserTile(_filteredUsers[i]),
                        ),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

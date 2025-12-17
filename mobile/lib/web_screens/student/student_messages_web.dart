import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import 'chat_screen_web.dart';

class StudentMessagesWeb extends StatefulWidget {
  final int userId;

  const StudentMessagesWeb({
    super.key,
    required this.userId,
  });

  @override
  State<StudentMessagesWeb> createState() => _StudentMessagesWebState();
}

class _StudentMessagesWebState extends State<StudentMessagesWeb> {
  Map<String, dynamic>? serviceCenterChat;
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadChat();

    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadChat(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadChat() async {
    try {
      final res =
          await ApiService.getUnreadGroupedUnified(widget.userId);

      if (!mounted) return;

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List list =
            decoded is List ? decoded : decoded['data'] ?? [];

        final sc = list.firstWhere(
          (e) =>
              (e['full_name'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains('service'),
          orElse: () => null,
        );

        setState(() {
          serviceCenterChat = sc;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= HEADER =================
          const Text(
            "Messages",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // ================= CONTENT =================
          if (serviceCenterChat == null)
            const Text(
              "No messages with Service Center yet",
              style: TextStyle(color: Colors.grey),
            )
          else
            _buildServiceCenterTile(context),
        ],
      ),
    );
  }

  Widget _buildServiceCenterTile(BuildContext context) {
    final chat = serviceCenterChat!;

    final int otherUserId =
        chat["sender_id"] == widget.userId
            ? chat["receiver_id"]
            : chat["sender_id"];

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreenWeb(
              myId: widget.userId,
              otherId: otherUserId,
              otherName: "Service Center",
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            const CircleAvatar(
              radius: 26,
              backgroundColor: Colors.deepPurple,
              child: Icon(
                Icons.support_agent,
                color: Colors.white,
              ),
            ),

            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Service Center",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat["lastMessageContent"] ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

            // Unread
            if ((chat["unreadCount"] ?? 0) > 0)
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.red,
                child: Text(
                  "${chat["unreadCount"]}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

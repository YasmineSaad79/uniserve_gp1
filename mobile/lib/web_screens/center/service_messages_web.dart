import 'package:flutter/material.dart';
import 'package:mobile/web_screens/student/chat_screen_web.dart';
import '../../services/api_service.dart';


class StudentMessagesWeb extends StatefulWidget {
  final int myId;

  const StudentMessagesWeb({super.key, required this.myId});

  @override
  State<StudentMessagesWeb> createState() => _StudentMessagesWebState();
}

class _StudentMessagesWebState extends State<StudentMessagesWeb> {
  bool _loading = true;
  List<dynamic> conversations = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data =
          await ApiService.getServiceConversations(widget.myId);

      setState(() {
        conversations = data;
        _loading = false;
      });
    } catch (e) {
      debugPrint("❌ load conversations error: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (conversations.isEmpty) {
      return const Center(child: Text("No messages yet"));
    }

    // 🟣 ترتيب: اللي عندهم رسائل أولاً
    conversations.sort((a, b) {
      final t1 = a['lastMessageTime'];
      final t2 = b['lastMessageTime'];
      if (t1 == null) return 1;
      if (t2 == null) return -1;
      return DateTime.parse(t2).compareTo(DateTime.parse(t1));
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: conversations.length,
      itemBuilder: (_, i) {
        final c = conversations[i];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: c['photo_url'] != null
                  ? NetworkImage(
                      "http://localhost:5000${c['photo_url']}")
                  : null,
              child: c['photo_url'] == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(c['full_name'] ?? "Student"),
            subtitle: Text(
              c['lastMessageContent'] ?? "No messages yet",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: c['unreadCount'] > 0
                ? CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.red,
                    child: Text(
                      c['unreadCount'].toString(),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12),
                    ),
                  )
                : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreenWeb(
                    myId: widget.myId,
                    otherId: c['sender_id'],
                    otherName: c['full_name'],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

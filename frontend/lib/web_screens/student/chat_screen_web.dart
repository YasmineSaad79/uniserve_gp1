import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:convert';

class ChatScreenWeb extends StatefulWidget {
  final int myId;        // user_id
  final int otherId;     // user_id
  final String otherName;

  const ChatScreenWeb({
    super.key,
    required this.myId,
    required this.otherId,
    required this.otherName,
  });

  @override
  State<ChatScreenWeb> createState() => _ChatScreenWebState();
}

class _ChatScreenWebState extends State<ChatScreenWeb> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  List<Map<String, dynamic>> messages = [];
  Timer? _timer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();

    // 🔄 polling كل 5 ثواني
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadMessages(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // =========================
  // LOAD CONVERSATION
  // =========================
  Future<void> _loadMessages() async {
    try {
      final res = await ApiService.getConversationUnified(
        widget.myId,
        widget.otherId,
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);

        if (mounted) {
          setState(() {
            messages = List<Map<String, dynamic>>.from(data);
            _loading = false;
          });

          // ⬇️ انزل لآخر رسالة
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollCtrl.hasClients) {
              _scrollCtrl.jumpTo(
                _scrollCtrl.position.maxScrollExtent,
              );
            }
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Load chat error: $e");
    }
  }

  // =========================
  // SEND MESSAGE
  // =========================
  Future<void> _sendMessage() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    try {
      await ApiService.sendMessageUnified(
        senderId: widget.myId,
        receiverId: widget.otherId,
        content: text,
      );

      _ctrl.clear();
      _loadMessages();
    } catch (e) {
      debugPrint("❌ Send message error: $e");
    }
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherName),
        backgroundColor: const Color(0xFF7B1FA2),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final m = messages[i];
                      final isMe =
                          m["sender_id"] == widget.myId;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin:
                              const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.6,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xFFD1A7F2)
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            m["content"] ?? "",
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // =========================
          // INPUT
          // =========================
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, -2),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send,
                      color: Color(0xFF7B1FA2)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import '../../main.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/services/api_service.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class ChatScreen extends StatefulWidget {
  final int senderId;
  final int receiverId;
  final storage = const FlutterSecureStorage();

  const ChatScreen({
    super.key,
    required this.senderId,
    required this.receiverId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final storage = const FlutterSecureStorage();
  File? _selectedFile;

  List<dynamic> _messages = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  static const String serverIP = "10.0.2.2";

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchMessages(autoRefresh: true);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ======================= LOGIC ==========================

  Future<void> _fetchMessages({bool autoRefresh = false}) async {
    try {
      final response =
          await ApiService.getConversation(widget.senderId, widget.receiverId);

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);

        if (_messages.isEmpty) {
          setState(() {
            _messages = data.reversed.toList();
            _isLoading = false;
          });
        } else {
          final oldLast =
              _messages.isNotEmpty ? _messages.last['content'] : null;
          final newLast = data.isNotEmpty ? data.last['content'] : null;

          if (newLast != null && oldLast != newLast) {
            setState(() {
              _messages = data.reversed.toList();
              _isLoading = false;
            });
          }
        }
      } else {
        print("⚠️ Failed to retrieve messages: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Error fetching messages: $e");
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty && _selectedFile == null) return;

    try {
      final response = await ApiService.sendMessage(
        senderId: widget.senderId,
        receiverId: widget.receiverId,
        content: message.isEmpty ? null : message,
        attachment: _selectedFile,
      );

      _selectedFile = null;

      if (response.statusCode == 201) {
        setState(() {
          _messages.insert(0, {
            "sender_id": widget.senderId,
            "receiver_id": widget.receiverId,
            "content": message,
            "sent_at": DateTime.now().toString(),
          });
          _messageController.clear();
        });
      } else {
        print("⚠️ Failed to send message: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Error sending message: $e");
    }
  }

  String _formatDayLabel(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return "Today";
    if (diff == 1) return "Yesterday";
    return "${date.day}/${date.month}/${date.year}";
  }

  // ======================= UI ==========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // الخلفية العامة – نفس روح باقي الشاشات
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEEDAFB),
              Color(0xFFF5E8FF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Stack(
                  children: [
                    _buildBubblesBackground(),
                    _buildMessagesList(),
                  ],
                ),
              ),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  // --------- الهيدر الفخم ---------
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0), // 🔥 إزالة أي خلفية
      ),
      child: Row(
        children: [
          // -------- زر الرجوع --------
          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25), // زجاجي
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF7B1FA2),
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),

          const SizedBox(width: 14),

          // -------- زر التحديث --------
          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => _fetchMessages(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25), // زجاجي
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.refresh,
                color: Color(0xFF7B1FA2),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------- فقاعات الخلفية (ديكور) ---------
  Widget _buildBubblesBackground() {
    return IgnorePointer(
      ignoring: true,
      child: Stack(
        children: [
          Positioned(
            top: -40,
            left: -30,
            child: _blurCircle(120, const Color(0xFFF3E5F5)),
          ),
          Positioned(
            top: 120,
            right: -40,
            child: _blurCircle(160, const Color(0xFFFFE0F7)),
          ),
          Positioned(
            bottom: -40,
            left: -20,
            child: _blurCircle(140, const Color(0xFFE1BEE7)),
          ),
        ],
      ),
    );
  }

  Widget _blurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.45),
        shape: BoxShape.circle,
      ),
    );
  }

  // --------- قائمة الرسائل ---------
  Widget _buildMessagesList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7B1FA2)),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMe = msg['sender_id'] == widget.senderId;

        DateTime msgDate =
            DateTime.tryParse(msg['sent_at'] ?? '') ?? DateTime.now();
        String msgDay = "${msgDate.year}-${msgDate.month}-${msgDate.day}";

        bool showDateDivider = false;
        if (index == _messages.length - 1) {
          showDateDivider = true;
        } else {
          DateTime nextDate =
              DateTime.tryParse(_messages[index + 1]['sent_at'] ?? '') ??
                  DateTime.now();
          String nextDay = "${nextDate.year}-${nextDate.month}-${nextDate.day}";
          if (msgDay != nextDay) showDateDivider = true;
        }

        return Column(
          children: [
            if (showDateDivider) _buildDayDivider(msgDate),
            Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: _buildMessageBubble(msg, isMe),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDayDivider(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Expanded(
            child: Divider(thickness: 0.8, color: Colors.black26),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatDayLabel(date),
              style: const TextStyle(
                color: Color(0xFF7B1FA2),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const Expanded(
            child: Divider(thickness: 0.8, color: Colors.black26),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map msg, bool isMe) {
    final String? content = msg['content'];
    final String? attachmentUrl = msg['attachment_url'];

    final bubbleColor = isMe
        ? const LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFFE040FB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        gradient: bubbleColor,
        color: bubbleColor == null ? Colors.white : null,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft:
              isMe ? const Radius.circular(20) : const Radius.circular(6),
          bottomRight:
              isMe ? const Radius.circular(6) : const Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: attachmentUrl != null
          ? _buildAttachmentBubble(attachmentUrl, isMe: isMe)
          : Text(
              content ?? '',
              style: TextStyle(
                fontSize: 15,
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
    );
  }

  // --------- منطقة الإدخال ---------
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedFile != null) _buildSelectedFilePreview(),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Color(0xFF7B1FA2)),
                  onPressed: () async {
                    final picker = await FilePicker.platform.pickFiles(
                      type: FileType.any,
                    );
                    if (picker != null && picker.files.first.path != null) {
                      setState(() {
                        _selectedFile = File(picker.files.first.path!);
                      });
                    }
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF9C27B0), Color(0xFFE040FB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child:
                        const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFilePreview() {
    final path = _selectedFile!.path.toLowerCase();
    final isImage = path.endsWith(".jpg") ||
        path.endsWith(".jpeg") ||
        path.endsWith(".png");
    final isPdf = path.endsWith(".pdf");

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          if (isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _selectedFile!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            )
          else if (isPdf)
            Row(
              children: const [
                Icon(Icons.picture_as_pdf, color: Colors.red),
                SizedBox(width: 6),
                Text(
                  "Selected PDF",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            )
          else
            const Text("Attachment selected"),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () {
              setState(() {
                _selectedFile = null;
              });
            },
          ),
        ],
      ),
    );
  }

  // --------- الـ Attachment داخل الفقاعة ---------
  Widget _buildAttachmentBubble(String url, {bool isMe = false}) {
    if (url.endsWith(".jpg") || url.endsWith(".png") || url.endsWith(".jpeg")) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          "http://$serverIP:5000$url",
          width: 200,
          fit: BoxFit.cover,
        ),
      );
    }

    if (url.endsWith(".pdf")) {
      return InkWell(
        onTap: () {
          // TODO: افتحي PDF Viewer
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: (isMe ? Colors.white : const Color(0xFFEEE0FF))
                .withOpacity(0.95),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf,
                  color: Colors.redAccent, size: 20),
              const SizedBox(width: 6),
              Text(
                "View PDF",
                style: TextStyle(
                  color: isMe ? const Color(0xFF7B1FA2) : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Text(
      "Attachment received",
      style: TextStyle(color: isMe ? Colors.white : Colors.black87),
    );
  }
}

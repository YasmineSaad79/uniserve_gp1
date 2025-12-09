import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:timeago/timeago.dart' as timeago;
import '../shared/chatScreen.dart';
import 'package:mobile/services/api_service.dart';

class DoctorMessagesScreen extends StatefulWidget {
  final int doctorId;
  final int serviceCenterId;

  const DoctorMessagesScreen({
    super.key,
    required this.doctorId,
    required this.serviceCenterId,
  });

  @override
  State<DoctorMessagesScreen> createState() => _DoctorMessagesScreenState();
}

class _DoctorMessagesScreenState extends State<DoctorMessagesScreen> {
  int unreadCount = 0;
  String? lastMessageTime;
  String? lastMessageText;
  String? serviceName;
  String? servicePhotoUrl;
  bool _isLoading = true;
  int? _senderUserId;

  static const String serverIP = "10.0.2.2";

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    print("🔍 Using doctorId as senderUserId: ${widget.doctorId}");

    setState(() => _senderUserId = widget.doctorId);

    await _fetchServiceProfile();
    await _fetchMessagesInfo();
  }

  Future<void> _fetchServiceProfile() async {
    try {
      final url = Uri.parse("http://$serverIP:5000/api/service/profile");
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final profile = body["profile"];

        setState(() {
          serviceName = profile["full_name"] ?? "Service Center";
          final photo = profile["photo_url"];
          if (photo != null && photo.isNotEmpty) {
            servicePhotoUrl = "http://$serverIP:5000$photo";
          }
        });
      } else {
        print("⚠ Failed to fetch service profile: ${res.statusCode}");
      }
    } catch (e) {
      print("⚠️ Error fetching service profile: $e");
    }
  }

  Future<void> _fetchMessagesInfo() async {
    if (_senderUserId == null) return;

    try {
      final res = await ApiService.getUnreadGrouped(_senderUserId!);

      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        final List data = decoded is List ? decoded : (decoded['data'] ?? []);

        if (data.isNotEmpty) {
          final msgFromService = data.firstWhere(
            (e) => e['sender_id'] == widget.serviceCenterId,
            orElse: () => {},
          );

          if (msgFromService.isNotEmpty) {
            setState(() {
              unreadCount = msgFromService['unreadCount'] ?? 0;
              final rawTime = msgFromService['lastMessageTime'];
              if (rawTime != null) {
                final parsed = DateTime.tryParse(rawTime);
                if (parsed != null) {
                  lastMessageTime = timeago.format(parsed, allowFromNow: true);
                }
              }
              lastMessageText = msgFromService['lastMessageContent'] ?? '';
              _isLoading = false;
            });
            return;
          }
        }
      }
    } catch (e) {
      print("⚠ Error: $e");
    }

    _resetMessageInfo();
  }

  void _resetMessageInfo() {
    setState(() {
      unreadCount = 0;
      lastMessageTime = null;
      lastMessageText = null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FB),
      appBar: AppBar(
        automaticallyImplyLeading: false, // 🚀 يمنع ظهور سهم الرجوع
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text(
          "Messages",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchMessagesInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 10),

                // 🟣 Card مثل تبعة الطالب بالضبط
                InkWell(
                  onTap: () async {
                    if (_senderUserId == null) return;

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          senderId: _senderUserId!,
                          receiverId: widget.serviceCenterId,
                        ),
                      ),
                    );

                    _fetchMessagesInfo();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // الصورة
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: servicePhotoUrl != null
                              ? NetworkImage(servicePhotoUrl!)
                              : const AssetImage(
                                      "assets/images/uniserve_logo.jpeg")
                                  as ImageProvider,
                        ),

                        const SizedBox(width: 14),

                        // الاسم + آخر رسالة
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                serviceName ?? "Service Center",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                lastMessageText?.isNotEmpty == true
                                    ? lastMessageText!
                                    : "No messages yet",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // الوقت + عدد غير مقروءة
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              lastMessageTime ?? "",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            if (unreadCount > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "$unreadCount",
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // 🔽 النص الرمادي تحت الكرت (تمامًا مثل واجهة الطالب)
                const Text(
                  "Tap to open your chat with the service center",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
    );
  }
}

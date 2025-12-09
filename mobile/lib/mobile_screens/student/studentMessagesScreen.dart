import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:timeago/timeago.dart' as timeago;
import '../shared/chatScreen.dart';
import 'package:mobile/services/api_service.dart';
import 'dart:ui'; // 👈 مهم لـ BackdropFilter (الزجاج)

// لون البنفسجي الأساسي للمشروع
const Color uniPurple = Color(0xFF7B1FA2);

class StudentMessagesScreen extends StatefulWidget {
  final String studentId;
  final int serviceCenterId;

  const StudentMessagesScreen({
    super.key,
    required this.studentId,
    required this.serviceCenterId,
  });

  @override
  State<StudentMessagesScreen> createState() => _StudentMessagesScreenState();
}

class _StudentMessagesScreenState extends State<StudentMessagesScreen> {
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
    _fetchServiceProfile();
    _fetchMessagesInfo();
  }

  Future<void> _initializeData() async {
    print("🔍 Fetching user_id for studentId: ${widget.studentId}");
    final userId = await ApiService.getUserIdByStudentId(widget.studentId);

    if (userId != null) {
      setState(() {
        _senderUserId = userId;
      });
      print("✅ senderUserId fetched: $_senderUserId");

      await _fetchServiceProfile();
      await _fetchMessagesInfo();
    } else {
      print("⚠️ Failed to load user_id for student ${widget.studentId}");
    }
  }

  // 🟣 أولاً: نجيب بيانات السنتر (الاسم والصورة)
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
        print("⚠️ Failed to fetch service profile: ${res.statusCode}");
      }
    } catch (e) {
      print("⚠️ Error fetching service profile: $e");
    }
  }

  // 🔵 ثانياً: نجيب آخر رسالة وعدد الرسائل غير المقروءة
  Future<void> _fetchMessagesInfo() async {
    try {
      if (_senderUserId == null) return;

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
          } else {
            _resetMessageInfo();
          }
        } else {
          _resetMessageInfo();
        }
      } else {
        print("⚠️ Failed to load messages info: ${res.statusCode}");
        _resetMessageInfo();
      }
    } catch (e) {
      print("⚠️ Error fetching message info: $e");
      _resetMessageInfo();
    }
  }

  void _resetMessageInfo() {
    setState(() {
      unreadCount = 0;
      lastMessageTime = null;
      lastMessageText = null;
      _isLoading = false;
    });
  }

  Future<void> _handleRefresh() async {
    await _fetchMessagesInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // خلفية الصفحة كاملة — Gradient ناعم مودرن
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF7F1FF),
              Color(0xFFFFFFFF),
              Color(0xFFFFF5FB),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // دوائر مضيئة في الخلفية (Glow)
            Positioned(
              top: -40,
              left: -30,
              child: _glowCircle(140, const Color(0xFFEDD9FF)),
            ),
            Positioned(
              top: 120,
              right: -40,
              child: _glowCircle(160, const Color(0xFFFFD1F2)),
            ),
            Positioned(
              bottom: -60,
              left: -10,
              child: _glowCircle(180, const Color(0xFFD6C3FF)),
            ),

            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // AppBar مخصص – شفاف مع عنوان بالنص
                  // ---------------------- Custom AppBar ----------------------
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 🔹 Back Button (بدون خلفية)
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: uniPurple,
                            size: 24,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),

                        // 🔹 Title
                        const Text(
                          "Messages",
                          style: TextStyle(
                            fontFamily: "Baloo",
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: uniPurple,
                          ),
                        ),

                        // 🔹 Refresh Button (بدون خلفية)
                        IconButton(
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: uniPurple,
                            size: 24,
                          ),
                          onPressed: _fetchMessagesInfo,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // الجسم الرئيسي (الكرت الزجاجي)
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                            color: uniPurple,
                            onRefresh: _handleRefresh,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              children: [
                                _buildChatCard(context),
                                const SizedBox(height: 26),
                                Center(
                                  child: Text(
                                    "Tap the card to open your chat with the service center",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================== Widgets المساعدة ======================

  // دائرة مضيئة للخلفية
  Widget _glowCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.55),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 40,
            spreadRadius: 5,
          )
        ],
      ),
    );
  }

  // الكرت الزجاجي للمحادثة
  Widget _buildChatCard(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () async {
        if (_senderUserId == null) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              senderId: _senderUserId!,
              receiverId: widget.serviceCenterId,
            ),
          ),
        );
        _fetchMessagesInfo();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: Colors.white.withOpacity(0.78),
              border: Border.all(
                color: Colors.white.withOpacity(0.8),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: uniPurple.withOpacity(0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Row(
              children: [
                // صورة السنتر مع Glow
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFB388FF),
                        Color(0xFFE1BEE7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: uniPurple.withOpacity(0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: servicePhotoUrl != null
                          ? NetworkImage(servicePhotoUrl!)
                          : const AssetImage("assets/images/uniserve_logo.jpeg")
                              as ImageProvider,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // النصوص (الاسم + آخر رسالة)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الاسم + الوقت
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              serviceName ?? "Service Center",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: "Baloo",
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (lastMessageTime != null &&
                              lastMessageTime!.isNotEmpty)
                            Text(
                              lastMessageTime!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11.5,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // آخر رسالة
                      Text(
                        lastMessageText?.isNotEmpty == true
                            ? lastMessageText!
                            : "No messages yet — say hello 👋",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // خط موجي بسيط + Badge الرسائل
                      Row(
                        children: [
                          // خط ديكوري بسيط
                          Expanded(
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                gradient: LinearGradient(
                                  colors: [
                                    uniPurple.withOpacity(0.15),
                                    uniPurple.withOpacity(0.45),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // badge عدد الرسائل
                          if (unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7C4DFF),
                                    Color(0xFFE040FB),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purpleAccent.withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Text(
                                "$unreadCount",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // أيقونة سهم الرسائل
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: uniPurple.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: uniPurple,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

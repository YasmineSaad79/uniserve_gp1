import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:mobile/mobile_screens/shared/chatScreen.dart';
import 'package:mobile/web_screens/student/chat_screen_web.dart';

class ChatScreenRouter extends StatelessWidget {
  const ChatScreenRouter({super.key});
/*
  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    // ✅ لازم يكونوا user_id (من جدول users)
    final int myId = args['senderId'];
    final int otherId = args['receiverId'];

    // اسم الطرف الآخر (اختياري – للعنوان)
    final String otherName =
        args['otherName'] ?? 'Chat';

    // 🌐 WEB
    if (kIsWeb) {
      return ChatScreenWeb(
        myId: myId,
        otherId: otherId,
        otherName: otherName,
      );
    }

    // 📱 MOBILE
    return ChatScreen(
      senderId: myId,
      receiverId: otherId,
    );
  }*/

 @override
Widget build(BuildContext context) {
  final route = ModalRoute.of(context);
  final args = route?.settings.arguments;

  // 🚫 Web refresh / direct access
  if (args == null || args is! Map<String, dynamic>) {
    // رجّعي المستخدم للـ Help
    Future.microtask(() {
      Navigator.of(context).pop();
    });

    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  final int myId = args['senderId'];
  final int otherId = args['receiverId'];
  final String otherName = args['otherName'] ?? 'Chat';

  if (kIsWeb) {
    return ChatScreenWeb(
      myId: myId,
      otherId: otherId,
      otherName: otherName,
    );
  }

  return ChatScreen(
    senderId: myId,
    receiverId: otherId,
  );
}

}

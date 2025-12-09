import 'dart:async';
import 'package:flutter/material.dart';

// إشعارات محلية
import 'services/notifications.dart';
import 'mobile_screens/shared/chatScreen.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
// شاشاتك
import 'mobile_screens/start_screen.dart';
import 'mobile_screens/signup_screen.dart';
import 'mobile_screens/signin_screen.dart';
import 'mobile_screens/shared/resetPassword.dart';
import 'mobile_screens/welcome_screen.dart';
import 'mobile_screens/center/addActivityScreen.dart';
import 'mobile_screens/center/viewActivitiesScreen.dart';
import 'mobile_screens/center/serviceHome.dart';
import 'mobile_screens/admin/adminHomeScreen.dart';
import 'mobile_screens/admin/selectDoctorScreen.dart';
import 'mobile_screens/admin/assignStudentScreen.dart';
import 'mobile_screens/admin/doctorStudentsScreen.dart';
import 'mobile_screens/student/all_students_page.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'web_screens/start_screen.dart';

// API (لتسجيل الـ FCM Token)
import 'services/api_service.dart';

const FirebaseOptions firebaseWebOptions = FirebaseOptions(
  apiKey: "AIzaSyBFWs4Q-00AjNt32EGivL6i_tRuIqDOFkI",
  authDomain: "uniserve-67027.firebaseapp.com",
  projectId: "uniserve-67027",
  storageBucket: "uniserve-67027.firebasestorage.app",
  messagingSenderId: "575576735035",
  appId: "1:575576735035:web:b646786ff7de30a14c8b1e",
  measurementId: "G-SHSN7Y3Y1X",
);
// المفتاح العام للـ Navigator (نحتاجه لفتح الصفحات من أي مكان)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 🟣 الهاندلر للخلفية
@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  // ممكن تضيفي لوج لو بدك
  // debugPrint('BG: ${message.data}');
}

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(const MyApp());
  }, (error, stack) {
    // debugPrint('Error: $error');
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    unawaited(_safeInit());
  }

  Future<void> _safeInit() async {
    try {
      await Notifications.initLocal();
      await _initFirebaseAndFCM();
    } catch (e) {
      debugPrint("⚠️ Init error: $e");
    }
  }

  Future<void> _initFirebaseAndFCM() async {
    if (kIsWeb) {
      await Firebase.initializeApp(options: firebaseWebOptions);
    } else {
      await Firebase.initializeApp();
    }

    FirebaseMessaging.onBackgroundMessage(_bgHandler);

    // 🟡 إذا الإشعار فتح التطبيق من الخلفية أو بعد إغلاقه
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageNavigation(initialMessage);
    }

    final fm = FirebaseMessaging.instance;
    await fm.requestPermission();

    // 🔹 تسجيل التوكن
    final token = await fm.getToken();
    if (token != null) {
      await ApiService.registerFcmToken(token);
    }

    fm.onTokenRefresh.listen((t) async {
      await ApiService.registerFcmToken(t);
    });

    // 🔹 أثناء عمل التطبيق (Foreground)
    FirebaseMessaging.onMessage.listen((msg) async {
      final data = msg.data;

      final title = msg.notification?.title ?? data['title'] ?? 'New Message';

      final body = msg.notification?.body ??
          data['body'] ??
          (data['type'] == 'chat' ? 'New message received' : '');

      await Notifications.showSimple(
        title,
        body,
        payload: data.isNotEmpty ? data.toString() : null,
      );
    });

    // 🔹 لما المستخدم يضغط على الإشعار
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);
  }

  /// 🔹 دالة موحدة للتعامل مع الضغط على الإشعار وفتح الصفحة المناسبة
  void _handleMessageNavigation(RemoteMessage msg) {
    final data = msg.data;

    if (data['type'] == 'chat') {
      final senderId = int.tryParse(data['sender_id'] ?? '0') ?? 0;
      final receiverId = int.tryParse(data['receiver_id'] ?? '0') ?? 0;

      if (senderId > 0 && receiverId > 0) {
        // ⚠️ اعكسيهم صحّ:
        // senderId = الشخص اللي بعت الرسالة
        // receiverId = الشخص اللي استقبل الرسالة (أنا)
        // لازم أفتح الشات بيني وبين اللي بعتلي: شخص يرسل ↔ أنا
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              senderId: senderId, // المرسل الحقيقي
              receiverId: receiverId, // المستقبِل الحقيقي
            ),
          ),
        );
        return;
      }
    }

    // إشعارات أخرى
    navigatorKey.currentState?.pushNamed('/service-home');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniServe',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          primary: Colors.purple,
        ),
        useMaterial3: false,
      ),

      // ⭐ هنا أضفنا الاختبار بين الويب والموبايل
      home: kIsWeb ? const WebStartScreen() : const StartScreen(),

      // ❗ احذفي initialRoute لأنه يتعارض مع home
      // initialRoute: '/start',

      routes: {
        '/start': (context) => const StartScreen(),
        '/welcome': (context) => const WelcomeScreen(role: 'student'),
        '/signin': (context) => const SigninScreen(),
        '/signup': (context) => const SignupScreen(),
        '/reset': (context) => const ResetPasswordScreen(),
        '/service-home': (context) => const ServiceHomeScreen(),
        '/add-activity': (context) => const AddActivityScreen(),
        '/view-activities': (context) => const ViewActivitiesScreen(),
        // Admin Routes
        '/admin-home': (context) => const AdminHomeScreen(),
        '/selectDoctor': (context) => const SelectDoctorScreen(),
        '/assignStudent': (context) => const AssignStudentScreen(),
        '/doctorStudents': (context) => const DoctorStudentsScreen(),
        '/viewAllStudents': (context) => const StudentsPage(),
      },
    );
  }
}

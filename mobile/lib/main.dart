import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mobile/web_screens/doctor/doctor_home_web.dart';

// إشعارات محلية
import 'services/notifications.dart';

// API
import 'services/api_service.dart';

// شاشات عامة
import 'shared_screens/start_screen.dart';
import 'shared_screens/signup_screen.dart';
import 'shared_screens/signin_screen.dart';
import 'mobile_screens/shared/resetPassword.dart';
import 'shared_screens/welcome_screen.dart';

// شاشات مركز الخدمة
import 'mobile_screens/center/addActivityScreen.dart';
import 'mobile_screens/center/viewActivitiesScreen.dart';
import 'mobile_screens/center/serviceHome.dart';

// شاشات الأدمن
import 'mobile_screens/admin/adminHomeScreen.dart';
import 'mobile_screens/admin/selectDoctorScreen.dart';
import 'mobile_screens/admin/assignStudentScreen.dart';
import 'mobile_screens/admin/doctorStudentsScreen.dart';
import 'mobile_screens/student/all_students_page.dart';

//  CHAT ROUTER (المهم)
import 'web_screens/student/ChatScreenRouter.dart';
import 'web_screens/student/student_suggest_activity_web.dart';
import 'web_screens/student/view_my_suggestions.dart';

// Firebase Web Config
const FirebaseOptions firebaseWebOptions = FirebaseOptions(
  apiKey: "AIzaSyBFWs4Q-00AjNt32EGivL6i_tRuIqDOFkI",
  authDomain: "uniserve-67027.firebaseapp.com",
  projectId: "uniserve-67027",
  storageBucket: "uniserve-67027.firebasestorage.app",
  messagingSenderId: "575576735035",
  appId: "1:575576735035:web:b646786ff7de30a14c8b1e",
  measurementId: "G-SHSN7Y3Y1X",
);

// NAVIGATOR GLOBAL KEY
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {
  if (!kIsWeb) {
    await Firebase.initializeApp();
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
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
      if (!kIsWeb) {
        await Notifications.initLocal();
      }
      await _initFirebaseAndFCM();
    } catch (e) {
      debugPrint(" Init error: $e");
    }
  }

  Future<void> _initFirebaseAndFCM() async {
    if (kIsWeb) {
      await Firebase.initializeApp(options: firebaseWebOptions);
      return; //  لا FCM listeners على الويب
    }

    // ===== MOBILE ONLY =====
    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(_bgHandler);

    final fm = FirebaseMessaging.instance;
    await fm.requestPermission();

    final token = await fm.getToken();
    if (token != null) {
      await ApiService.registerFcmToken(token);
    }

    fm.onTokenRefresh.listen(ApiService.registerFcmToken);

    FirebaseMessaging.onMessage.listen((msg) async {
      final title = msg.notification?.title ?? 'New Notification';
      final body = msg.notification?.body ?? 'You have a new message';

      await Notifications.showSimple(title, body);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniServe',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: false,
      ),
      home: const StartScreen(),

      routes: {
        '/start': (_) => const StartScreen(),
        '/welcome': (_) => const WelcomeScreen(role: 'student'),
        '/signin': (_) => const SigninScreen(),
        '/signup': (_) => const SignupScreen(),
        '/reset': (_) => const ResetPasswordScreen(),

        // CENTER
        '/service-home': (_) => const ServiceHomeScreen(),
        '/add-activity': (_) => const AddActivityScreen(),
        '/view-activities': (_) => const ViewActivitiesScreen(),

        // ADMIN
        '/admin-home': (_) => const AdminHomeScreen(),
        '/selectDoctor': (_) => const SelectDoctorScreen(),
        '/assignStudent': (_) => const AssignStudentScreen(),
        '/doctorStudents': (_) => const DoctorStudentsScreen(),
        '/viewAllStudents': (_) => const StudentsPage(),

        // CHAT (Router يقرر Web / Mobile)
        '/chat': (_) => const ChatScreenRouter(),
        '/doctor/web': (_) => const DoctorHomeWeb(),
      },
    );
  }
}

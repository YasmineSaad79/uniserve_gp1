import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../mobile_screens/shared/resetPassword.dart';
import 'welcome_screen.dart';

// Mobile Screens
import '../mobile_screens/student/student_home.dart';
import '../mobile_screens/doctor/doctor_home.dart';
import '../mobile_screens/center/serviceHome.dart';
import '../mobile_screens/admin/adminHomeScreen.dart';

// Web Screen (مهم!)
import '../web_screens/student/student_home_web.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../web_screens/center/service_home_web.dart';
import '../web_screens/doctor/doctor_home_web.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class WavyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(0, 0);
    path.lineTo(0, size.height - 100);

    final firstControl = Offset(size.width * 0.25, size.height - 10);
    final firstEnd = Offset(size.width * 0.55, size.height - 40);

    final secondControl = Offset(size.width * 0.85, size.height - 70);
    final secondEnd = Offset(size.width, size.height - 20);

    path.quadraticBezierTo(
        firstControl.dx, firstControl.dy, firstEnd.dx, firstEnd.dy);
    path.quadraticBezierTo(
        secondControl.dx, secondControl.dy, secondEnd.dx, secondEnd.dy);

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(oldClipper) => true;
}

class _SigninScreenState extends State<SigninScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FlutterSecureStorage storage = FlutterSecureStorage();

  bool isLoading = false;
  bool showPassword = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ===========================================================
  // 🔥🔥 LOGIN FUNCTION WITH WEB/MOBILE REDIRECTION ADDED HERE
  // ===========================================================
  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields ❌")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await storage.deleteAll();

      final response =
          await ApiService.signIn(email: email, password: password);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = data['user'];

        if (user == null || user['id'] == null || user['role'] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User data missing ❌")),
          );
          return;
        }

        final String userIdString = user['id'].toString();
        final String role = user['role'].toString();
        final String? token = data['token'];

        // ⬇⬇ Save JWT Token
        if (token != null) {
          if (kIsWeb) {
            // ⭐ WEB VERSION — SharedPreferences ⭐
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString("jwt_token", token);
            await prefs.setString("authToken", token);
            await prefs.setString("userId", userIdString);
            await prefs.setString("userRole", role);

            print("🌐 Saved WEB token = $token");
          } else {
            // 📱 MOBILE VERSION — FlutterSecureStorage 📱
            await storage.write(key: 'jwt_token', value: token);
            await storage.write(key: 'authToken', value: token);
            await storage.write(key: 'userId', value: userIdString);
            await storage.write(key: 'userRole', value: role);

            print("📱 Saved MOBILE token = $token");
          }
        }

        // 🔥 Register FCM Token
        try {
          final fcm = FirebaseMessaging.instance;
          final fcmToken = await fcm.getToken();
          final serverIP = kIsWeb ? "localhost" : "10.0.2.2";

          if (fcmToken != null && token != null) {
            final url = Uri.parse(
              "http://$serverIP:5000/api/notifications/register-token",
            );

            await http.post(
              url,
              headers: {
                "Authorization": "Bearer $token",
                "Content-Type": "application/json",
              },
              body: jsonEncode({
                "token": fcmToken,
                "platform": kIsWeb ? "web" : "android",
              }),
            );
          }
        } catch (e) {
          print("FCM error: $e");
        }

        emailController.clear();
        passwordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Login successful ✅'),
            backgroundColor: Colors.purple,
          ),
        );

        // ===========================================================
        // 🔥🔥 PLATFORM CHECK FOR STUDENT ONLY
        // ===========================================================
        if (role == 'student') {
          final String? studentId = user['student_id']?.toString();

          if (studentId != null) {
            if (kIsWeb) {
              // 🚀 فتح واجهة الويب
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentHomeWeb(studentId: studentId),
                ),
              );
            } else {
              // 📱 فتح واجهة الموبايل
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentHome(studentId: studentId),
                ),
              );
            }
          }
          return;
        }

        // ===========================================================
        // 🔥🔥 OTHER ROLES (Doctor / Center / Admin)
        // ===========================================================
        if (role == 'doctor') {
          if (kIsWeb) {
            // 🌐 WEB → Doctor Dashboard (Web)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const DoctorHomeWeb(),
              ),
            );
          } else {
            // 📱 MOBILE → Doctor Home (Mobile)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DoctorHome(
                  doctorId: int.parse(userIdString),
                ),
              ),
            );
          }
        } else if (role == 'service_center') {
          if (kIsWeb) {
            // 🌐 WEB → صفحة مركز الخدمة (Web)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const ServiceHomeWeb(),
              ),
            );
          } else {
            // 📱 MOBILE → صفحة مركز الخدمة (Mobile)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const ServiceHomeScreen(),
              ),
            );
          }
        } else if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
          );
        }
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error['message'] ?? 'Login failed ❌'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection error: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ===============================================================
  // 🔥🔥 UI BUILD
  // ===============================================================
  @override
  Widget build(BuildContext context) {
    final Color primary = Colors.purple;

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // HEADER
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipPath(
                  clipper: WavyClipper(),
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primary.withOpacity(0.9),
                          primary.withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 30,
                left: 1,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 25),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WelcomeScreen(role: "")),
                    );
                  },
                ),
              ),

              Positioned(
                top: 55,
                left: 70,
                child: Text(
                  "Login to your account",
                  style: GoogleFonts.baloo2(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              // FORM
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 30),
                    child: Column(
                      children: [
                        const SizedBox(height: 80),
                        Image.asset('assets/images/uniserve_logo.jpeg',
                            height: 160),
                        const SizedBox(height: 20),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: passwordController,
                          obscureText: !showPassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() => showPassword = !showPassword);
                              },
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ResetPasswordScreen()),
                              );
                            },
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: isLoading ? null : loginUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white),
                                )
                              : const Text(
                                  "Sign In",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.white),
                                ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account? "),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacementNamed(
                                    context, '/signup');
                              },
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(color: Colors.purple),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

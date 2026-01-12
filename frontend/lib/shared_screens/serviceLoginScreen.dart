/*
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../shared_screens/welcome_screen.dart';
import 'serviceHome.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

// ====================== تموج الهيدر ======================
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

// ====================== MAIN SCREEN ======================
class ServiceLoginScreen extends StatefulWidget {
  const ServiceLoginScreen({super.key});

  @override
  State<ServiceLoginScreen> createState() => _ServiceLoginScreenState();
}

class _ServiceLoginScreenState extends State<ServiceLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPass = false;
  bool _loading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    const storage = FlutterSecureStorage();
    await storage.deleteAll();

    try {
      final url = Uri.parse("http://10.0.2.2:5000/api/users/signIn");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'email': _email.text.trim(),
          'password': _password.text.trim(),
        }),
      );

      setState(() => _loading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data["user"];
        final token = data["token"];

        if (user["role"] != "service_center") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Access denied ❌"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // حفظ البيانات
        await storage.write(key: "jwt_token", value: token);
        await storage.write(key: "authToken", value: token);
        await storage.write(key: "userId", value: user["id"].toString());
        await storage.write(key: "userRole", value: "service_center");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ServiceHomeScreen()),
        );
      } else {
        final msg = jsonDecode(response.body)["message"] ?? "Login failed ❌";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connection error: $e"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ====================== HEADER ======================
            SizedBox(
              height: 170,
              width: double.infinity,
              child: Stack(
                children: [
                  ClipPath(
                    clipper: WavyClipper(),
                    child: Container(
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

                  // ← Back button
                  Positioned(
                    top: 10,
                    left: 1,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          size: 25, color: Colors.white),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WelcomeScreen(role: ""),
                          ),
                        );
                      },
                    ),
                  ),

                  // Title
                  Positioned(
                    top: 55,
                    left: 70,
                    child: Text(
                      "Service Center Login",
                      style: GoogleFonts.baloo2(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ====================== BODY ======================
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/uniserve_logo.jpeg',
                      width: 250,
                      height: 250,
                    ),
                    const SizedBox(height: 15),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _email,
                            decoration: const InputDecoration(
                              labelText: "Email",
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? "Enter email" : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _password,
                            obscureText: !_showPass,
                            decoration: InputDecoration(
                              labelText: "Password",
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_showPass
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () {
                                  setState(() => _showPass = !_showPass);
                                },
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? "Enter password" : null,
                          ),
                          const SizedBox(height: 25),
                          _loading
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    minimumSize:
                                        const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "Login",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.white),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'welcome_screen.dart';
import '../mobile_screens/center/serviceHome.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

// WEB HOME
import '../web_screens/center/service_home_web.dart';

// ====================== Wavy Header ======================
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

// ====================== MAIN SCREEN ======================
class ServiceLoginScreen extends StatefulWidget {
  const ServiceLoginScreen({super.key});

  @override
  State<ServiceLoginScreen> createState() => _ServiceLoginScreenState();
}

class _ServiceLoginScreenState extends State<ServiceLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _showPass = false;
  bool _loading = false;

  final secureStorage = const FlutterSecureStorage();

  // =====================================================
  // LOGIN (WEB + MOBILE)
  // =====================================================
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // 🧹 Clear old tokens
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      } else {
        await secureStorage.deleteAll();
      }

      final serverIP = kIsWeb ? "localhost" : "10.0.2.2";
      final url = Uri.parse("http://$serverIP:5000/api/users/signIn");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'email': _email.text.trim(),
          'password': _password.text.trim(),
        }),
      );

      setState(() => _loading = false);

      if (response.statusCode != 200) {
        final msg = jsonDecode(response.body)["message"] ?? "Login failed ❌";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
        return;
      }

      final data = jsonDecode(response.body);
      final user = data["user"];
      final token = data["token"];

      if (user["role"] != "service_center") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Access denied ❌"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 💾 Save token
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("jwt_token", token);
        await prefs.setString("authToken", token);
        await prefs.setString("userId", user["id"].toString());
        await prefs.setString("userRole", "service_center");
      } else {
        await secureStorage.write(key: "jwt_token", value: token);
        await secureStorage.write(key: "authToken", value: token);
        await secureStorage.write(key: "userId", value: user["id"].toString());
        await secureStorage.write(key: "userRole", value: "service_center");
      }

      // 🚀 Navigate
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              kIsWeb ? const ServiceHomeWeb() : const ServiceHomeScreen(),
        ),
      );
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connection error: $e"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // =====================================================
  // UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    final Color primary = Colors.purple;

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWebWide = kIsWeb && constraints.maxWidth > 700;

          // ===========================
          // WEB LAYOUT
          // ===========================
          if (isWebWide) {
            return Center(
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: SizedBox(
                  width: 460,
                  child: _buildContent(primary, isWeb: true),
                ),
              ),
            );
          }

          // ===========================
          // MOBILE LAYOUT (UNCHANGED)
          // ===========================
          return SafeArea(
            child: _buildContent(primary, isWeb: false),
          );
        },
      ),
    );
  }

  // =====================================================
  // SHARED CONTENT
  // =====================================================
  Widget _buildContent(Color primary, {required bool isWeb}) {
    return Column(
      children: [
        // ====================== HEADER ======================
        SizedBox(
          height: 170,
          width: double.infinity,
          child: Stack(
            children: [
              ClipPath(
                clipper: WavyClipper(),
                child: Container(
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
              Positioned(
                top: 10,
                left: 1,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      size: 25, color: Colors.white),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WelcomeScreen(role: ""),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 55,
                left: 70,
                child: Text(
                  "Service Center Login",
                  style: GoogleFonts.baloo2(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ====================== BODY ======================
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/uniserve_logo.jpeg',
                  width: 220,
                  height: 220,
                ),
                const SizedBox(height: 15),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? "Enter email" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        obscureText: !_showPass,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_showPass
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () {
                              setState(() => _showPass = !_showPass);
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? "Enter password" : null,
                      ),
                      const SizedBox(height: 25),
                      _loading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

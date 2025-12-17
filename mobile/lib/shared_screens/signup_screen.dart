import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'signin_screen.dart';
import '../mobile_screens/shared/uploadPhotoScreen.dart';
import 'welcome_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class WavyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(0, 0);
    path.lineTo(0, size.height - 100);

    final c1 = Offset(size.width * 0.25, size.height - 10);
    final e1 = Offset(size.width * 0.55, size.height - 40);

    final c2 = Offset(size.width * 0.85, size.height - 70);
    final e2 = Offset(size.width, size.height - 20);

    path.quadraticBezierTo(c1.dx, c1.dy, e1.dx, e1.dy);
    path.quadraticBezierTo(c2.dx, c2.dy, e2.dx, e2.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(oldClipper) => false;
}

class _SignupScreenState extends State<SignupScreen> {
  String selectedRole = '';

  final TextEditingController fullName = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();

  bool showPassword = false;
  bool showConfirmPassword = false;
  bool isLoading = false;

  Future<void> registerUser() async {
    if (selectedRole.isEmpty ||
        fullName.text.isEmpty ||
        email.text.isEmpty ||
        password.text.isEmpty ||
        confirmPassword.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Fill all fields ❌")));
      return;
    }

    if (password.text != confirmPassword.text) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Passwords don't match ❌")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await ApiService.signUp(
        fullName: fullName.text.trim(),
        email: email.text.trim(),
        password: password.text.trim(),
        role: selectedRole,
      );

      if (res.statusCode == 201) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => UploadPhotoScreen(userEmail: email.text.trim())),
        );
      } else {
        final error = jsonDecode(res.body);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error["message"] ?? "Error")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget roleButton(String label, String value) {
    final isSelected = selectedRole == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedRole = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.purple : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.purple, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.purple,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration field(String title, IconData icon) {
    return InputDecoration(
      labelText: title,
      prefixIcon: Icon(icon, color: Colors.purple),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Colors.purple;

    return Scaffold(
      backgroundColor: Colors.white,

      /// ⭐⭐⭐ Scrollbar added HERE so it appears ONLY on the right
      body: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // ---------------- HEADER ----------------
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

                // Back Button
                Positioned(
                  top: 30,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 26),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const WelcomeScreen(role: "")),
                      );
                    },
                  ),
                ),

                // Page Title
                Positioned(
                  top: 55,
                  left: 70,
                  child: Text(
                    "Create your account",
                    style: GoogleFonts.baloo2(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                // ---------------- CONTENT ----------------
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 40),
                      child: Column(
                        children: [
                          const SizedBox(height: 60),

                          Image.asset("assets/images/uniserve_logo.jpeg",
                              height: 150),

                          const SizedBox(height: 20),

                          const Text("Please select your category",
                              style: TextStyle(color: Colors.purple)),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              roleButton("Student", "student"),
                              const SizedBox(width: 10),
                              roleButton("Doctor", "doctor"),
                            ],
                          ),

                          const SizedBox(height: 25),

                          TextField(
                            controller: fullName,
                            decoration: field(
                                "Full Name (First Middle Last)", Icons.person),
                          ),
                          const SizedBox(height: 15),

                          TextField(
                            controller: email,
                            decoration: field("Email Address", Icons.email),
                          ),
                          const SizedBox(height: 15),

                          TextField(
                            controller: password,
                            obscureText: !showPassword,
                            decoration:
                                field("Password", Icons.lock).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () => setState(
                                    () => showPassword = !showPassword),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          TextField(
                            controller: confirmPassword,
                            obscureText: !showConfirmPassword,
                            decoration:
                                field("Confirm Password", Icons.lock).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(showConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () => setState(() =>
                                    showConfirmPassword = !showConfirmPassword),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          ElevatedButton(
                            onPressed: isLoading ? null : registerUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25)),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text("Sign Up",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16)),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Already have an account? "),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const SigninScreen()));
                                },
                                child: const Text("Sign In",
                                    style: TextStyle(color: Colors.purple)),
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

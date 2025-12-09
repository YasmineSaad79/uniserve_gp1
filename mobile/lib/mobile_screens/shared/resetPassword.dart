import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../signin_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
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
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPassController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();

  bool isLoading = false;
  bool codeSent = false;

  Future<void> sendResetCode() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      showSnack('Please enter your email');
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await ApiService.sendResetCode(email: email);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        showSnack(body['message'] ?? 'Reset code sent');
        setState(() => codeSent = true);
      } else {
        showSnack(body['message'] ?? 'Failed to send code');
      }
    } catch (e) {
      showSnack('Connection error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    final code = codeController.text.trim();
    final pass = newPassController.text.trim();
    final conf = confirmPassController.text.trim();

    if (email.isEmpty || code.isEmpty || pass.isEmpty || conf.isEmpty) {
      showSnack('Please fill all fields');
      return;
    }
    if (pass != conf) {
      showSnack('Passwords do not match');
      return;
    }
    if (pass.length < 6) {
      showSnack('Password must be at least 6 characters');
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await ApiService.resetPassword(
        email: email,
        code: code,
        newPassword: pass,
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        showSnack(body['message'] ?? 'Password reset successfully');
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacementNamed(context, '/signin');
        });
      } else {
        showSnack(body['message'] ?? 'Reset failed');
      }
    } catch (e) {
      showSnack('Connection error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  InputDecoration inputStyle(String label, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade100,
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14),
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ==================== الهيدر بالموجة + السهم ====================
            SizedBox(
              height: 170,
              width: double.infinity,
              child: Stack(
                children: [
                  ClipPath(
                    clipper: WavyClipper(),
                    child: Container(
                      width: double.infinity,
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
                          color: Colors.white, size: 25),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  Positioned(
                    top: 55,
                    left: 70,
                    child: Text(
                      "Reset Password",
                      style: GoogleFonts.baloo2(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==================== البودي ====================
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    Text(
                      "Enter your email to receive a verification code",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.baloo2(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: emailController,
                      decoration:
                          inputStyle("Email Address", Icons.email_outlined),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : sendResetCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                "Send Verification Code",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white, // ← هنا الصح
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    if (codeSent) ...[
                      TextField(
                        controller: codeController,
                        decoration: inputStyle(
                            "Verification Code", Icons.verified_outlined),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: newPassController,
                        obscureText: true,
                        decoration: inputStyle(
                            "New Password", Icons.lock_outline_rounded),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: confirmPassController,
                        obscureText: true,
                        decoration: inputStyle(
                            "Confirm Password", Icons.lock_reset_rounded),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : resetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            "Reset Password",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
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

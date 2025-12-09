import 'package:flutter/material.dart';
import 'signin_screen.dart';
import 'signup_screen.dart';
import 'center/serviceLoginScreen.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  final String role;
  const WelcomeScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 80), // 🔹 بدل Spacer لرفع كل المحتوى شوي

            // 🔹 شعار UniServe
            Image.asset(
              'assets/images/uniserve_logo.jpeg',
              width: 250,
              height: 250,
            ),
            const SizedBox(height: 15),

            // 🔹 كلمة Welcome
            Text(
              'Welcome',
              style: GoogleFonts.baloo2(
                fontSize: 50,
                fontWeight: FontWeight.w700,
                color: Colors.purple,
              ),
            ),

            const SizedBox(height: 15),
            const Text(
              'Please choose an action:',
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 35),

            // 🔹 زر تسجيل الدخول
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SigninScreen()),
                );
              },
              child: const Text('Login'),
            ),
            const SizedBox(height: 20),

            // 🔹 زر التسجيل
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.purple, width: 2),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                );
              },
              child: const Text(
                'Register',
                style: TextStyle(color: Colors.purple),
              ),
            ),

            const Spacer(), // يبقي الرابط بأسفل الصفحة

            // 🔹 رابط مركز الخدمة
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ServiceLoginScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      "Service Center Login",
                      style: TextStyle(
                        color: Colors.purple,
                        fontSize: 17,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

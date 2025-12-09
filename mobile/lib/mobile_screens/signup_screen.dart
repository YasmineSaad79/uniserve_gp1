import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'signin_screen.dart';
import 'shared/uploadPhotoScreen.dart';
import 'welcome_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  String selectedRole = ''; // doctor or student
  bool hasLetters = false;
  bool hasNumbers = false;
  bool hasMinLength = false;
  bool showPasswordRules = false;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  void validatePassword(String value) {
    setState(() {
      showPasswordRules = value.isNotEmpty; // ⭐ تظهر فقط عند الكتابة
      hasLetters = RegExp(r'[A-Za-z]').hasMatch(value);
      hasNumbers = RegExp(r'\d').hasMatch(value);
      hasMinLength = value.length >= 8;
    });
  }

  Future<void> registerUser() async {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (selectedRole.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your role ❌')),
      );
      return;
    }

    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields ❌')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match ❌')),
      );
      return;
    }

    if (selectedRole == 'student' && !email.endsWith('@stu.najah.edu')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please use your university email (@stu.najah.edu) ❌'),
        ),
      );
      return;
    }

    if (password.length < 8 ||
        !RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Password must be at least 8 characters and include letters & numbers ❌'),
        ),
      );
      return;
    }

    try {
      final response = await ApiService.signUp(
        fullName: fullName,
        email: email,
        password: password,
        role: selectedRole,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Account created ✅')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => UploadPhotoScreen(userEmail: email),
          ),
        );
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['message'] ?? 'Error signing up ❌')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
      );
    }
  }

  Widget roleCard(String roleName, String value) {
    final bool isSelected = selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() => selectedRole = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.white,
          border: Border.all(
            color: Colors.purple,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          roleName,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.purple,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  InputDecoration ovalDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      prefixIcon: Icon(icon, color: Colors.purple),
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: const BorderSide(color: Colors.purple, width: 2),
      ),
    );
  }

  Widget _buildCheckItem(String text, bool active) {
    return Row(
      children: [
        Icon(
          active ? Icons.check_circle : Icons.circle_outlined,
          color: active ? Colors.green : Colors.grey,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? Colors.green : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 🌊 رأس الصفحة + عنوان "Create your account"
            Stack(
              children: [
                ClipPath(
                  clipper: WavyClipper(),
                  child: Container(
                    height: 180,
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
                  top: 30,
                  left: 1,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white, size: 25),
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
                    "Create your account",
                    style: GoogleFonts.baloo2(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            // 🌟 الشعار + باقي المحتوى
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  24, 0, 24, 0), // حذف الفراغ من الأعلى
              child: Column(
                children: [
                  Image.asset('assets/images/uniserve_logo.jpeg', height: 160),

                  const SizedBox(height: 10),
                  Text(
                    'Please select your category',
                    style: TextStyle(
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 🟣 باقي المحتوى كما هو (الأزرار والحقول)
                  Row(
                    children: [
                      Expanded(
                        child: roleCard('Student', 'student'),
                      ),
                      const SizedBox(width: 12), // مسافة بسيطة بين البطاقتين
                      Expanded(
                        child: roleCard('Doctor', 'doctor'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),
                  TextField(
                    controller: fullNameController,
                    decoration: ovalDecoration(
                        'Full Name (First Middle Last)', Icons.person),
                  ),

                  const SizedBox(height: 15),
                  TextField(
                    controller: emailController,
                    decoration: ovalDecoration('Email Address', Icons.email),
                  ),

                  const SizedBox(height: 15),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    onChanged: validatePassword, // ⭐ مهم جداً
                    decoration: ovalDecoration('Password', Icons.lock).copyWith(
                      suffixIcon: const Icon(Icons.visibility),
                    ),
                  ),

                  const SizedBox(height: 15),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration:
                        ovalDecoration('Confirm Password', Icons.lock).copyWith(
                      suffixIcon: const Icon(Icons.visibility),
                    ),
                  ),

                  // 🔐 شروط كلمة السر
                  if (showPasswordRules)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _buildCheckItem("Must include letters", hasLetters),
                        const SizedBox(height: 6),
                        _buildCheckItem("Must include numbers", hasNumbers),
                        const SizedBox(height: 6),
                        _buildCheckItem("Minimum 8 characters", hasMinLength),
                      ],
                    ),

                  const SizedBox(
                      height: 20), // ⭐ ثابت دائماً سواء ظهرت الشروط أو لا

                  ElevatedButton(
                    onPressed: registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SigninScreen()),
                          );
                        },
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: Colors.purple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

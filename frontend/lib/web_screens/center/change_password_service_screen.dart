// File: lib/screens/center/change_password_service_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const Color uniPurple = Color(0xFF7B1FA2);

// --------------------------------------------------------------
//   API REQUEST (Web + Mobile)
// --------------------------------------------------------------
Future<Map<String, dynamic>> changeServiceCenterPassword({
  required String email,
  required String oldPassword,
  required String newPassword,
  required String confirmPassword,
}) async {
  try {
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: "authToken");

    final serverIP = kIsWeb ? "localhost" : "10.0.2.2";
    final url = Uri.parse("http://$serverIP:5000/api/change-password");

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'email': email,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );

    final Map<String, dynamic> responseBody = json.decode(response.body);

    if (response.statusCode == 200) {
      return {'success': true, 'message': responseBody['message']};
    } else {
      return {
        'success': false,
        'message': responseBody['message'] ?? 'Unknown error occurred',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Network error: cannot connect.',
    };
  }
}

// --------------------------------------------------------------
//   UI — Web + Mobile
// --------------------------------------------------------------
class ChangePasswordServiceScreen extends StatefulWidget {
  final String email;

  const ChangePasswordServiceScreen({
    super.key,
    required this.email,
  });

  @override
  State<ChangePasswordServiceScreen> createState() =>
      _ChangePasswordServiceScreenState();
}

class _ChangePasswordServiceScreenState
    extends State<ChangePasswordServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool loading = false;
  bool showOld = false;
  bool showNew = false;
  bool showConfirm = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final res = await changeServiceCenterPassword(
      email: widget.email,
      oldPassword: _oldPassword.text.trim(),
      newPassword: _newPassword.text.trim(),
      confirmPassword: _confirmPassword.text.trim(),
    );

    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message']),
        backgroundColor: res['success'] ? Colors.green : Colors.red,
      ),
    );

    if (res['success']) {
      _oldPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
    }
  }

  // ------------------ FIELD ------------------
  Widget _field({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    IconData icon = Icons.lock_outline,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: uniPurple,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.12),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            obscureText: obscure,
            validator: (v) => v!.isEmpty ? "This field is required" : null,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: uniPurple),
              suffixIcon: readOnly
                  ? null
                  : IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                        color: uniPurple,
                      ),
                      onPressed: onToggle,
                    ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // --------------------------- BUILD ---------------------------
  @override
  Widget build(BuildContext context) {
    final form = Form(
      key: _formKey,
      child: Column(
        children: [
          const Text(
            "Update Your Password",
            style: TextStyle(
              fontFamily: "Baloo",
              fontSize: 26,
              color: uniPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25),

          _field(
            label: "Email Address",
            controller: _emailController,
            obscure: false,
            onToggle: () {},
            icon: Icons.email_outlined,
            readOnly: true,
          ),

          _field(
            label: "Current Password",
            controller: _oldPassword,
            obscure: !showOld,
            onToggle: () => setState(() => showOld = !showOld),
          ),

          _field(
            label: "New Password",
            controller: _newPassword,
            obscure: !showNew,
            onToggle: () => setState(() => showNew = !showNew),
          ),

          _field(
            label: "Confirm Password",
            controller: _confirmPassword,
            obscure: !showConfirm,
            onToggle: () => setState(() => showConfirm = !showConfirm),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: uniPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: loading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                  : const Text(
                      "Change Password",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "Baloo",
                        fontSize: 18,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: !kIsWeb,
        iconTheme: const IconThemeData(color: uniPurple),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEEDAFB), Color(0xFFF5E8FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: kIsWeb ? 520 : double.infinity),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: Colors.white.withOpacity(0.85),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.15),
                      blurRadius: 25,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: form,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:ui';

class AddRequestScreen extends StatefulWidget {
  final String studentId;

  const AddRequestScreen({super.key, required this.studentId});

  @override
  State<AddRequestScreen> createState() => _AddRequestScreenState();
}

const Color uniPurple = Color(0xFF7B1FA2);

class _AddRequestScreenState extends State<AddRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final body = {
      'student_id': widget.studentId,
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
    };

    try {
      final res = await ApiService.postCustomRequest(body);
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request submitted!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${res['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      // -------- APPBAR --------
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: uniPurple,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // -------- BACKGROUND --------
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEEDAFB),
              Color(0xFFF5E8FF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // ===== الخلفية + ScrollView ممتدة على الشاشة =====
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 250),
                    _buildCard(),
                    const SizedBox(height: 40), // مساحة تحت الكارد
                  ],
                ),
              ),
            ),

            // ===== العنوان =====
            Positioned(
              top: 100,
              child: const Text(
                "Add Request",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "Baloo",
                  fontSize: 50,
                  color: Color(0xFF7B1FA2),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------- Modern Field ---------
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w400,
            color: Colors.black54,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? "This field is required" : null,
      ),
    );
  }

  // --------- Glow Submit Button ---------
  Widget _glowSubmitButton() {
    return Container(
      height: 55,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF9C27B0),
            Color(0xFF7B1FA2),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
        ),
        child: _loading
            ? const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              )
            : const Text(
                "Submit",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // ----------- Build Glass Card -----------
  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.85),
            Colors.white.withOpacity(0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.6),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.18),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _inputField(
                    controller: _titleCtrl,
                    label: "Request Title",
                  ),
                  const SizedBox(height: 18),
                  _inputField(
                    controller: _descCtrl,
                    label: "Request Description",
                    maxLines: 5,
                  ),
                  const SizedBox(height: 28),
                  _glowSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

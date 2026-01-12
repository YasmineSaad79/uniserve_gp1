import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/services/token_service.dart';

class StudentSuggestActivityWeb extends StatefulWidget {
  final String studentId;
  final String serverIP;

  const StudentSuggestActivityWeb({
    super.key,
    required this.studentId,
    required this.serverIP,
  });

  @override
  State<StudentSuggestActivityWeb> createState() =>
      _StudentSuggestActivityWebState();
}

class _StudentSuggestActivityWebState extends State<StudentSuggestActivityWeb> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // =========================================================
  //                    SUBMIT REQUEST
  // =========================================================
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final token = await TokenService.getToken();
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Session expired, please login again"),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _loading = true);

    final body = {
      "student_id": widget.studentId,
      "title": _titleCtrl.text.trim(),
      "description": _descCtrl.text.trim(),
    };

    final url =
        Uri.parse("http://${widget.serverIP}:5000/api/student/requests");

    try {
      final res = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);

      if (!mounted) return;

      if (res.statusCode == 200 && data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request submitted successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        _titleCtrl.clear();
        _descCtrl.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "Request failed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  // =========================================================
  //                           UI
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          width: 650,
          margin: const EdgeInsets.only(top: 20),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.07),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- Title ----------
              Text(
                "Suggest New Activity",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF7B1FA2),
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1.6),
                      blurRadius: 3,
                      color: const Color(0xFF7B1FA2).withOpacity(0.25),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ---------- Title Field ----------
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: _fieldStyle("Activity Title"),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 20),

                    // ---------- Description Field ----------
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 5,
                      decoration: _fieldStyle("Activity Description"),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 30),

                    // ---------- Submit Button ----------
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7B1FA2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Submit Request",
                                style: TextStyle(
                                    fontSize: 17, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ----------------- INPUT DECORATION -----------------
  InputDecoration _fieldStyle(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade100,
      labelStyle: const TextStyle(fontSize: 15, color: Colors.black54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }
}

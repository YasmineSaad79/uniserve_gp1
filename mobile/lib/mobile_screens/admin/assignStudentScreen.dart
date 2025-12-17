import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';

class AssignStudentScreen extends StatefulWidget {
  const AssignStudentScreen({super.key});

  @override
  State<AssignStudentScreen> createState() => _AssignStudentScreenState();
}

class _AssignStudentScreenState extends State<AssignStudentScreen> {
  final TextEditingController controller = TextEditingController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final doctorId = args?["doctorId"];
    final doctorName = args?["doctorName"];

    return Scaffold(
      appBar: AppBar(
        title: Text("Assign to $doctorName"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Text(
              "Enter student university ID:",
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "12112345",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: loading ? null : () => _assign(doctorId),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Assign",
                      style: TextStyle(fontSize: 18, color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _assign(int doctorId) async {
    final uniId = controller.text.trim();
    if (uniId.isEmpty) return _msg("Enter student ID");

    setState(() => loading = true);

    try {
      final userId = await ApiService.getUserIdFromUniId(uniId);

      if (userId == null) {
        return _msg("Student not found");
      }

      final res = await http.post(
        Uri.parse("http://10.0.2.2:5000/api/users/admin/assign-student"),
        headers: {
          "Authorization": "Bearer ${await ApiService.getToken()}",
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "studentId": userId,
          "doctorId": doctorId,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        controller.clear();
        _msg("Student assigned successfully", ok: true);
      } else {
        _msg(data["message"] ?? "Error");
      }
    } catch (e) {
      _msg("Connection error: $e");
    }

    setState(() => loading = false);
  }

  void _msg(String text, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }
}

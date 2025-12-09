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
  final TextEditingController studentController = TextEditingController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final doctorId = args?["doctorId"];
    final doctorName = args?["doctorName"];

    return Scaffold(
      appBar: AppBar(
        title: Text("ربط طالب مع $doctorName"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("أدخل رقم الطالب:"),
            const SizedBox(height: 10),
            TextField(
              controller: studentController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "مثال: 12112347",
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: loading ? null : () => _assignStudent(doctorId),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("إتمام الربط"),
            )
          ],
        ),
      ),
    );
  }

  void showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _assignStudent(int doctorId) async {
    final studentUniId = studentController.text.trim();

    if (studentUniId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ الرجاء إدخال رقم الطالب الجامعي"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // 🔍 1) جلب user_id الحقيقي بناءً على student_id
      final studentUserId = await ApiService.getUserIdFromUniId(studentUniId);

      if (studentUserId == null) {
        showSnack("رقم الطالب غير موجود");
        return;
      }

      final res = await http.post(
        Uri.parse("http://10.0.2.2:5000/api/users/admin/assign-student"),
        headers: {
          "Authorization": "Bearer ${await ApiService.getToken()}",
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "doctorId": doctorId,
          "studentId": studentUserId,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✔ تم ربط الطالب مع الدكتور بنجاح"),
            backgroundColor: Colors.green,
          ),
        );
        studentController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "❌ فشل في العملية"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ خطأ في الاتصال: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => loading = false);
  }
}

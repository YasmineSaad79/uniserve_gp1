import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';

class DoctorStudentsScreen extends StatefulWidget {
  const DoctorStudentsScreen({super.key});

  @override
  State<DoctorStudentsScreen> createState() => _DoctorStudentsScreenState();
}

class _DoctorStudentsScreenState extends State<DoctorStudentsScreen> {
  List students = [];
  bool loading = true;
  String? doctorName;
  int? doctorId;

  @override
  void didChangeDependencies() {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    doctorId = args?["doctorId"];
    doctorName = args?["doctorName"];

    if (doctorId != null) {
      _loadStudents();
    }
    super.didChangeDependencies();
  }

  Future<void> _loadStudents() async {
    try {
      final token = await ApiService.getToken();

      final res = await http.get(
        Uri.parse(
          "http://10.0.2.2:5000/api/users/admin/doctor/$doctorId/students",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      final data = jsonDecode(res.body);

      setState(() {
        students = data["data"] ?? [];
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("طلاب الدكتور $doctorName"),
        backgroundColor: Colors.indigo,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? const Center(
                  child: Text(
                  "لا يوجد طلاب مرتبطين",
                  style: TextStyle(fontSize: 18),
                ))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final s = students[index];
                    return Card(
                      child: ListTile(
                        title: Text(s["full_name"] ?? ""),
                        subtitle: Text("رقم الطالب: ${s["student_id"]}"),
                      ),
                    );
                  },
                ),
    );
  }
}

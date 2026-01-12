import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // أضف هذا لـ kIsWeb
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';

class DoctorStudentsScreenForDoctor extends StatefulWidget {
  final String doctorName;

  const DoctorStudentsScreenForDoctor({
    super.key,
    required this.doctorName,
  });

  @override
  State<DoctorStudentsScreenForDoctor> createState() =>
      _DoctorStudentsScreenForDoctorState();
}

class _DoctorStudentsScreenForDoctorState
    extends State<DoctorStudentsScreenForDoctor> {
  List students = [];
  bool loading = true;

  // ديناميكي للويب والموبايل
  String get serverIP => kIsWeb ? "localhost" : "10.0.2.2";

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final token = await ApiService.getToken();

      final res = await http.get(
        Uri.parse("http://$serverIP:5000/api/doctor/my-students"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        setState(() {
          students = data["data"] ?? [];
          loading = false;
        });
      } else {
        setState(() => loading = false);
        print("❌ Error: ${data["message"]}");
      }
    } catch (e) {
      setState(() => loading = false);
      print("❌ Exception: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Students Doctor ${widget.doctorName}"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? const Center(
                  child: Text(
                    " There is no students connected with you",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final s = students[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple[100],
                          child: Text(
                            s['full_name'][0].toUpperCase(),
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        title: Text(s['full_name'] ?? ""),
                        subtitle: Text(" Student Number : ${s['student_id']}"),
                      ),
                    );
                  },
                ),
    );
  }
}
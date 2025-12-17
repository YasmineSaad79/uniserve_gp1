import 'package:flutter/material.dart';
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

  @override
  void didChangeDependencies() {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    doctorName = args?["doctorName"];
    int? doctorId = args?["doctorId"];

    if (doctorId != null) {
      _load(doctorId);
    }

    super.didChangeDependencies();
  }

  Future<void> _load(int doctorId) async {
    final data = await ApiService.getDoctorStudents(doctorId);

    setState(() {
      students = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Students of $doctorName"),
        backgroundColor: Colors.deepPurple,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? const Center(child: Text("No students assigned"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (context, i) {
                    final s = students[i];
                    return Card(
                      child: ListTile(
                        title: Text(s["full_name"]),
                        subtitle: Text("ID: ${s["student_id"]}"),
                      ),
                    );
                  },
                ),
    );
  }
}

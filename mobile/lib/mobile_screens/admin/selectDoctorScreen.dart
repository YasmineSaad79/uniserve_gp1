import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SelectDoctorScreen extends StatefulWidget {
  const SelectDoctorScreen({super.key});

  @override
  State<SelectDoctorScreen> createState() => _SelectDoctorScreenState();
}

class _SelectDoctorScreenState extends State<SelectDoctorScreen> {
  List<dynamic> doctors = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadDoctors();
  }

  Future<void> loadDoctors() async {
    final all = await ApiService.getAllUsers();
    setState(() {
      doctors = all.where((u) => u['role'] == 'doctor').toList();
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("اختيار دكتور"),
        backgroundColor: Colors.deepPurple,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: doctors.length,
              itemBuilder: (context, i) {
                final doc = doctors[i];
                return Card(
                  child: ListTile(
                    title: Text(doc['full_name']),
                    subtitle: Text(doc['email']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // عرض طلاب الدكتور
                        IconButton(
                          icon: const Icon(Icons.group),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              "/doctorStudents",
                              arguments: {
                                "doctorId": doc['id'],
                                "doctorName": doc['full_name'],
                              },
                            );
                          },
                        ),
                        // ربط طالب
                        IconButton(
                          icon: const Icon(Icons.link),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              "/assignStudent",
                              arguments: {
                                "doctorId": doc['id'],
                                "doctorName": doc['full_name'],
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

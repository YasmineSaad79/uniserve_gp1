import 'package:flutter/material.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("لوحة التحكم - الأدمن"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildButton(
              title: "عرض الدكاترة",
              color: Colors.deepPurple,
              onPressed: () {
                Navigator.pushNamed(context, "/selectDoctor");
              },
            ),
            const SizedBox(height: 20),
            _buildButton(
              title: "عرض الطلاب",
              color: Colors.indigo,
              onPressed: () {
                Navigator.pushNamed(context, "/viewAllStudents");
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String title,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}

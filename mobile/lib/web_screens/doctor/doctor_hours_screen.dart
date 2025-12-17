import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import '../../services/api_service.dart';

const Color uniPurple = Color(0xFF7B1FA2);

class DoctorHoursScreen extends StatefulWidget {
  const DoctorHoursScreen({super.key});

  @override
  State<DoctorHoursScreen> createState() => _DoctorHoursScreenState();
}

class _DoctorHoursScreenState extends State<DoctorHoursScreen> {
  bool _loading = true;
  List<dynamic> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchHoursSummary();
  }

  Future<void> _fetchHoursSummary() async {
    try {
      setState(() => _loading = true);
      final data = await ApiService.getDoctorSummary();
      setState(() {
        _students = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load summary")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Students Summary",
          style: TextStyle(
            fontFamily: "Baloo",
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: uniPurple,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: uniPurple),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: uniPurple))
          : RefreshIndicator(
              onRefresh: _fetchHoursSummary,
              color: uniPurple,
              child: kIsWeb ? _buildWebLayout() : _buildMobileLayout(),
            ),
    );
  }

  // ===========================================================
  // 📱 MOBILE LAYOUT (نفس شغلك 100%)
  // ===========================================================
  Widget _buildMobileLayout() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _students.length,
      itemBuilder: (_, index) {
        final s = _students[index];
        return _studentCard(s);
      },
    );
  }

  // ===========================================================
  // 🌐 WEB LAYOUT (Responsive Grid)
  // ===========================================================
  Widget _buildWebLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 1200
            ? 3
            : width > 800
                ? 2
                : 1;

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 3.2,
          ),
          itemCount: _students.length,
          itemBuilder: (_, index) {
            final s = _students[index];
            return _studentCard(s, web: true);
          },
        );
      },
    );
  }

  // ===========================================================
  // 🎨 SHARED CARD (Mobile + Web)
  // ===========================================================
  Widget _studentCard(dynamic s, {bool web = false}) {
    final name = s["full_name"] ?? "Unknown";
    final studentId = s["student_id"] ?? "";
    final hours = s["total_hours"] ?? 0;
    final result = s["result"] ?? "pending";
    final isPass = result == "pass";

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.person,
            size: web ? 46 : 40,
            color: isPass ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment:
                  web ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Baloo",
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "ID: $studentId",
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Text(
                  "Hours: $hours",
                  style: const TextStyle(
                    fontSize: 14,
                    color: uniPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isPass
                  ? Colors.green.withOpacity(0.15)
                  : Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              isPass ? "PASS" : "FAIL",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPass ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

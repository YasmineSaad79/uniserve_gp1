import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'package:file_picker/file_picker.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with TickerProviderStateMixin {
  bool loading = true;

  // Dashboard Data
  int totalStudents = 0;
  int totalDoctors = 0;
  int totalServices = 0;
  int totalRequests = 0;
  int requestsGrowth = 0;

  List<dynamic> studentsPerService = [];
  Map<String, dynamic> requestStatus = {};
  List<dynamic> messagesDaily = [];
  List<dynamic> topDoctors = [];
  List<dynamic> activityLog = [];

  String selectedFilter = "30d";

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    try {
      setState(() => loading = true);

      final data = await ApiService.getAdminDashboard(range: selectedFilter);

      setState(() {
        totalStudents = data["total_students"] ?? 0;
        totalDoctors = data["total_doctors"] ?? 0;
        totalServices = data["total_services"] ?? 0;
        totalRequests = data["total_requests"] ?? 0;

        requestsGrowth = data["requests_growth"] ?? 0;

        studentsPerService = data["students_per_service"] ?? [];
        requestStatus = data["request_status"] ?? {};
        messagesDaily = data["messages_daily"] ?? [];
        topDoctors = data["top_doctors"] ?? [];
        activityLog = data["activity_log"] ?? [];

        loading = false;
      });
    } catch (e) {
      print("Dashboard Error: $e");

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load dashboard data"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // FILTER BAR
  Widget _buildFilterBar() {
    final filters = {
      "today": "Today",
      "7d": "Last 7 Days",
      "30d": "Last 30 Days",
      "year": "This Year"
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: filters.entries.map((f) {
        final isActive = selectedFilter == f.key;
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedFilter = f.key;
              loading = true;
            });
            loadDashboardData();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? Colors.purple : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              f.value,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // KPI CARD
  // =====================================
//  KPI CARD (نسخة ثابتة غير قابلة للضغط)
// =====================================
  Widget _kpi(String title, int value, IconData icon, Color color, int growth) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.45),
        border: Border.all(color: Colors.white.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // دائرة الأيقونة
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),

          const SizedBox(height: 12),

          Text(
            "$value",
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),

          SizedBox(height: 12), // مسافة صغيرة بدل Spacer
          Row(
            children: [
              Icon(Icons.arrow_upward, size: 16, color: color.withOpacity(0.9)),
              const SizedBox(width: 4),
              Text(
                "$growth%",
                style: TextStyle(
                  color: color.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // DONUT CHART
  PieChartData _donutChart() {
    final pending = requestStatus["pending"] ?? 0;
    final accepted = requestStatus["accepted"] ?? 0;
    final rejected = requestStatus["rejected"] ?? 0;

    return PieChartData(
      sectionsSpace: 2,
      centerSpaceRadius: 50,
      sections: [
        PieChartSectionData(
          color: Colors.orange,
          value: pending.toDouble(),
          title: "$pending Pending",
        ),
        PieChartSectionData(
          color: Colors.green,
          value: accepted.toDouble(),
          title: "$accepted Accepted",
        ),
        PieChartSectionData(
          color: Colors.red,
          value: rejected.toDouble(),
          title: "$rejected Rejected",
        ),
      ],
    );
  }

  // BAR CHART
  BarChartData _barChart() {
    return BarChartData(
      barGroups: studentsPerService.map((item) {
        int index = studentsPerService.indexOf(item);
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: item["total"].toDouble(),
              width: 18,
              color: Colors.purple,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        );
      }).toList(),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              int index = value.toInt();
              if (index >= studentsPerService.length) return Container();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  studentsPerService[index]["service"],
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // LINE CHART
  LineChartData _lineChart() {
    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          isCurved: true,
          barWidth: 3,
          color: Colors.blue,
          dotData: const FlDotData(show: true),
          spots: messagesDaily.map((e) {
            int i = messagesDaily.indexOf(e);
            return FlSpot(i.toDouble(), e["total"].toDouble());
          }).toList(),
        ),
      ],
    );
  }

  Widget _quickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _action(
          "Assign Students",
          Icons.people,
          () {
            Navigator.pushNamed(context, "/selectDoctor");
          },
        ),
        const SizedBox(width: 12),

        _action(
          "Import Students",
          Icons.upload_file,
          () {
            _importExcel();
          },
        ),
        const SizedBox(width: 12),

        // ⭐ Manage Users
        _action(
          "Manage Users",
          Icons.admin_panel_settings,
          () {
            Navigator.pushNamed(context, "/adminUsers");
          },
        ),
        const SizedBox(width: 12),

        // ⭐⭐ NEW: Manage Roles
        _action(
          "Manage Roles",
          Icons.security, // أو Icons.rule / Icons.lock
          () {
            Navigator.pushNamed(context, "/adminRoles");
          },
        ),
      ],
    );
  }

  Future<void> _importExcel() async {
    try {
      // 1️⃣ اختيار ملف Excel
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true, // ⭐ مهم للويب
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;

      // 2️⃣ إرسال الملف للباك-إند
      final response = await ApiService.importStudentsExcel(
        fileBytes: file.bytes!,
        filename: file.name,
      );

      // 3️⃣ نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${response['message']} (Count: ${response['count']})",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // ❌ خطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Import failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// Action Button
  Widget _action(String name, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.purple,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // COLLAPSIBLE SECTION
  Widget _collapsible(String title, Widget child) {
    return ExpansionTile(
      title: Text(title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
      children: [child],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,

        // ⭐ هذا هو البديل الصحيح للـ decoration
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF9F5F0),
                Color(0xFFF3ECE5),
                Color(0xFFF7F2ED),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        title: const Text(
          "Admin Dashboard",
          style: TextStyle(
            color: Colors.purple,
            fontFamily: "Baloo",
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              // 🎨 خلفية NUDE خرافية
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF9F5F0),
                    Color(0xFFF3ECE5),
                    Color(0xFFF7F2ED),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),

              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 1100), // 💜 نفس السلوك
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ⭐ زر Assign Students
                          _quickActions(),
                          const SizedBox(height: 25),

                          // ⭐ الفلاتر
                          _buildFilterBar(),
                          const SizedBox(height: 30),

                          // ⭐ KPI GRID
                          _kpiGrid(),
                          const SizedBox(height: 40),

                          // ⭐ Pie Chart Section
                          _section(
                            "Volunteer Requests Status",
                            Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                height: 260,
                                child: PieChart(_donutChart()),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // ⭐ Bar Chart Section
                          _section(
                            "Students per Service",
                            Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                height: 350,
                                child: BarChart(_barChart()),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // ⭐ Line Chart Section
                          _section(
                            "Messages per Day",
                            Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                height: 280,
                                child: LineChart(_lineChart()),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // ⭐ Top Doctors
                          _collapsible(
                            "Top Doctors",
                            Column(
                              children: topDoctors
                                  .map(
                                    (e) => ListTile(
                                      leading: const Icon(Icons.star,
                                          color: Colors.purple),
                                      title: Text(e["doctor"]),
                                      trailing:
                                          Text("${e["students"]} Students"),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ⭐ Activity Log
                          _collapsible(
                            "Recent Activity",
                            Column(
                              children: activityLog
                                  .map(
                                    (e) => ListTile(
                                      leading: const Icon(Icons.history),
                                      title: Text(e["text"]),
                                      subtitle: Text(
                                        DateFormat("yyyy-MM-dd HH:mm")
                                            .format(DateTime.parse(e["time"])),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),

                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _kpiGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;

        // تحديد عدد الأعمدة حسب حجم الشاشة
        int crossAxisCount = width > 900
            ? 4
            : width > 600
                ? 3
                : 2; // موبايل = 2، تابلت = 3، لابتوب = 4

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: width > 900
              ? 1.4 // شاشات كبيرة
              : width > 600
                  ? 1.2 // تابلت
                  : 0.85, // موبايل — أهم قيمة
          children: [
            _kpi("Students", totalStudents, Icons.people, Colors.blue, 12),
            _kpi("Doctors", totalDoctors, Icons.medical_services, Colors.green,
                4),
            _kpi("Services", totalServices, Icons.home_repair_service,
                Colors.orange, 3),
            _kpi("Requests", totalRequests, Icons.receipt_long, Colors.red,
                requestsGrowth),
          ],
        );
      },
    );
  }

  Widget _section(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple)),
        const SizedBox(height: 10),
        child
      ],
    );
  }
}

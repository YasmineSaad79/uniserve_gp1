import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mobile/services/api_service.dart';

const Color uniPurple = Color(0xFF7B1FA2);

class StudentProgressWeb extends StatefulWidget {
  final String studentUniId;

  const StudentProgressWeb({
    super.key,
    required this.studentUniId,
  });

  @override
  State<StudentProgressWeb> createState() => _StudentProgressWebState();
}

class _StudentProgressWebState extends State<StudentProgressWeb> {
  bool loading = true;
  String? error;
  double totalPercent = 0;
  List<_ProgressItem> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data =
          await ApiService.getStudentProgress(widget.studentUniId);

      final tp = (data['total_percent'] is num)
          ? (data['total_percent'] as num).toDouble()
          : 0.0;

      final rawItems =
          (data['items'] is List) ? data['items'] as List : const [];

      final parsed = rawItems.map<_ProgressItem>((e) {
        return _ProgressItem(
          serviceId: (e['service_id'] ?? 0) as int,
          title: (e['title'] ?? '').toString(),
          points: ((e['points'] ?? 0) as num).toDouble().clamp(0, 100),
          acceptedAt: e['accepted_at']?.toString(),
        );
      }).toList();

      setState(() {
        totalPercent = tp.clamp(0, 100);
        items = parsed;
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: uniPurple),
      );
    }

    if (error != null) {
      return Center(
        child: Text(
          "Error: $error",
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "My Progress",
                style: TextStyle(
                  fontSize: 32,
                  fontFamily: "Baloo",
                  fontWeight: FontWeight.w700,
                  color: uniPurple,
                ),
              ),

              const SizedBox(height: 24),

              // ================= SUMMARY + CHART =================
              isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _TotalCard(total: totalPercent)),
                        const SizedBox(width: 20),
                        Expanded(child: _BarChartCard(items: items)),
                      ],
                    )
                  : Column(
                      children: [
                        _TotalCard(total: totalPercent),
                        const SizedBox(height: 16),
                        _BarChartCard(items: items),
                      ],
                    ),

              const SizedBox(height: 24),

              _ItemsList(items: items),
            ],
          ),
        );
      },
    );
  }
}

/* =========================================================
   Models
========================================================= */

class _ProgressItem {
  final int serviceId;
  final String title;
  final double points;
  final String? acceptedAt;

  _ProgressItem({
    required this.serviceId,
    required this.title,
    required this.points,
    this.acceptedAt,
  });
}

/* =========================================================
   UI Widgets
========================================================= */

class _TotalCard extends StatelessWidget {
  final double total;
  const _TotalCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return _glass(
      child: Row(
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: total / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.purple.shade100,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(uniPurple),
                ),
                Text(
                  "${total.toStringAsFixed(0)}%",
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: "Baloo",
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "Overall completion based on approved activities (max 50 hours)",
              style: TextStyle(
                fontSize: 16,
                fontFamily: "Baloo",
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChartCard extends StatelessWidget {
  final List<_ProgressItem> items;
  const _BarChartCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final bars = items.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.points,
            width: 18,
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ],
      );
    }).toList();

    return _glass(
      child: Column(
        children: [
          const Text(
            "Approved Activities (Hours)",
            style: TextStyle(
              fontSize: 18,
              fontFamily: "Baloo",
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                maxY: 50,
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 10,
                      reservedSize: 32,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) =>
                          Text("${v.toInt() + 1}"),
                    ),
                  ),
                ),
                barGroups: bars,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsList extends StatelessWidget {
  final List<_ProgressItem> items;
  const _ItemsList({required this.items});

  @override
  Widget build(BuildContext context) {
    return _glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Approved Activities",
            style: TextStyle(
              fontSize: 18,
              fontFamily: "Baloo",
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text("No approved activities yet."),
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "${i + 1}. ${items[i].title}",
                      style: const TextStyle(
                        fontFamily: "Baloo",
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: uniPurple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "+${items[i].points.toStringAsFixed(0)} h",
                      style: const TextStyle(
                        color: uniPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/* =========================================================
   Glass Container
========================================================= */

Widget _glass({required Widget child}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.85),
          Colors.white.withOpacity(0.55),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.purple.withOpacity(0.18),
          blurRadius: 30,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ),
    ),
  );
}

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mobile/services/api_service.dart';

class MyProgressScreen extends StatefulWidget {
  final String studentUniId;
  const MyProgressScreen({super.key, required this.studentUniId});

  @override
  State<MyProgressScreen> createState() => _MyProgressScreenState();
}

const Color uniPurple = Color(0xFF7B1FA2);

class _MyProgressScreenState extends State<MyProgressScreen> {
  bool loading = true;
  String? error;
  double totalPercent = 0;
  List<_ProgressItem> items = [];

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await ApiService.getStudentProgress(widget.studentUniId);

      final tp = (data['total_percent'] is num)
          ? (data['total_percent'] as num).toDouble()
          : 0.0;

      final rawItems =
          (data['items'] is List) ? data['items'] as List : const [];

      final parsed = rawItems.map<_ProgressItem>((e) {
        final title = (e['title'] ?? '').toString();
        final serviceId =
            (e['service_id'] is num) ? (e['service_id'] as num).toInt() : 0;

        final pointsNum =
            (e['points'] is num) ? (e['points'] as num).toDouble() : 0.0;
        final points = pointsNum.clamp(0.0, 100.0);

        final acceptedAt = (e['accepted_at']?.toString().trim().isEmpty ?? true)
            ? null
            : e['accepted_at'].toString();

        return _ProgressItem(
          serviceId: serviceId,
          title: title,
          points: points,
          acceptedAt: acceptedAt,
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
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: uniPurple,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEEDAFB), Color(0xFFF5E8FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: 90,
              child: const Text(
                "My Progress",
                style: TextStyle(
                  fontFamily: "Baloo",
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7B1FA2),
                ),
              ),
            ),
            Positioned.fill(
              child: RefreshIndicator(
                color: const Color(0xFF7B1FA2),
                onRefresh: _load,
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : error != null
                        ? _ErrorView(message: error!, onRetry: _load)
                        : _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 170, 16, 30),
      children: [
        _TotalCard(total: totalPercent),
        const SizedBox(height: 16),
        _BarChartCard(items: items),
        const SizedBox(height: 16),
        _ItemsList(items: items),
      ],
    );
  }
}

/* =======================================
   Models + Widgets (UI Only)
======================================= */

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

class _TotalCard extends StatelessWidget {
  final double total;
  const _TotalCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return _glassContainer(
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 75,
                width: 75,
                child: CircularProgressIndicator(
                  value: total / 100.0,
                  strokeWidth: 8,
                  backgroundColor: Colors.purple.shade100.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF7B1FA2)),
                ),
              ),
              Text(
                "${total.toStringAsFixed(0)}%",
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: "Baloo",
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "Overall completion based on approved activities",
              style: TextStyle(
                fontSize: 16,
                fontFamily: "Baloo",
                color: Colors.black87,
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
    final groups = items.asMap().entries.map((e) {
      final idx = e.key;
      final it = e.value;

      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: it.points,
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

    return _glassContainer(
      child: Column(
        children: [
          const Text(
            "Approved Activities (points)",
            style: TextStyle(
              fontFamily: "Baloo",
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: 100,
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      reservedSize: 30,
                      getTitlesWidget: (value, _) => Text(
                        "${value.toInt()}",
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: "Baloo",
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= items.length) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            "${idx + 1}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: "Baloo",
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7B1FA2),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: groups,
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
    return _glassContainer(
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle, color: Color(0xFF7B1FA2)),
              SizedBox(width: 8),
              Text(
                "Approved activities",
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: "Baloo",
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final it in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "${items.indexOf(it) + 1}. ${it.title}",
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: "Baloo",
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B1FA2).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "+${it.points.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: Color(0xFF7B1FA2),
                        fontFamily: "Baloo",
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

Widget _glassContainer({required Widget child}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.85),
          Colors.white.withOpacity(0.55),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(
        color: Colors.white.withOpacity(0.6),
        width: 1.4,
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
          padding: const EdgeInsets.all(18),
          child: child,
        ),
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Error: $message"),
    );
  }
}

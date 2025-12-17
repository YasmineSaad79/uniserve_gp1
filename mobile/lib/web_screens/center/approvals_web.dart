import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

const Color purple = Color(0xFF7B1FA2);

class ApprovalsWeb extends StatefulWidget {
  const ApprovalsWeb({super.key});

  @override
  State<ApprovalsWeb> createState() => _ApprovalsWebState();
}

class _ApprovalsWebState extends State<ApprovalsWeb> {
  List approvedVolunteer = [];
  List approvedCustom = [];
  bool isLoading = true;

  final TextEditingController _searchCtrl = TextEditingController();

  Map<String, List> filteredVolunteer = {};
  Map<String, List> filteredCustom = {};

  int selectedTab = 0; // 0 = volunteer, 1 = custom

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ======================================================
  // LOAD DATA
  // ======================================================
  Future<void> loadData() async {
    setState(() => isLoading = true);

    final vRes = await ApiService.getApprovedVolunteer();
    final cRes = await ApiService.getApprovedCustom();

    if (vRes.statusCode == 200) {
      approvedVolunteer = json.decode(vRes.body);
    }
    if (cRes.statusCode == 200) {
      approvedCustom = json.decode(cRes.body);
    }

    setState(() {
      isLoading = false;
      filteredVolunteer = groupByStudent(approvedVolunteer);
      filteredCustom = groupByStudent(approvedCustom);
    });
  }

  // ======================================================
  // GROUP BY STUDENT
  // ======================================================
  Map<String, List> groupByStudent(List data) {
    final Map<String, List> grouped = {};
    for (var r in data) {
      final name = r["student_name"] ?? "Unknown";
      grouped.putIfAbsent(name, () => []);
      grouped[name]!.add(r);
    }
    return grouped;
  }

  // ======================================================
  // SEARCH
  // ======================================================
  void _filter(String query) {
    final lower = query.toLowerCase();

    Map<String, List> filterMap(Map<String, List> original) {
      final Map<String, List> result = {};
      original.forEach((student, reqs) {
        final matched = reqs.where((r) {
          final title =
              (r["activity_title"] ?? r["title"] ?? "").toLowerCase();
          final desc = (r["description"] ?? "").toLowerCase();
          return student.toLowerCase().contains(lower) ||
              title.contains(lower) ||
              desc.contains(lower);
        }).toList();

        if (matched.isNotEmpty) {
          result[student] = matched;
        }
      });
      return result;
    }

    setState(() {
      if (query.isEmpty) {
        filteredVolunteer = groupByStudent(approvedVolunteer);
        filteredCustom = groupByStudent(approvedCustom);
      } else {
        filteredVolunteer = filterMap(groupByStudent(approvedVolunteer));
        filteredCustom = filterMap(groupByStudent(approvedCustom));
      }
    });
  }

  // ======================================================
  // UI
  // ======================================================
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Approvals",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: purple,
          ),
        ),
        const SizedBox(height: 20),

        _tabs(),
        const SizedBox(height: 20),

        _search(),
        const SizedBox(height: 20),

        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildList(
                  selectedTab == 0
                      ? filteredVolunteer
                      : filteredCustom,
                ),
        ),
      ],
    );
  }

  // ======================================================
  // TABS
  // ======================================================
  Widget _tabs() {
    return Row(
      children: [
        _tab("Volunteer", 0),
        _tab("Custom", 1),
      ],
    );
  }

  Widget _tab(String text, int index) {
    final active = selectedTab == index;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ChoiceChip(
        label: Text(text),
        selected: active,
        onSelected: (_) => setState(() => selectedTab = index),
        selectedColor: purple.withOpacity(0.25),
        labelStyle: TextStyle(
          color: active ? purple : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ======================================================
  // SEARCH FIELD
  // ======================================================
  Widget _search() {
    return TextField(
      controller: _searchCtrl,
      onChanged: _filter,
      decoration: InputDecoration(
        hintText: "Search approvals...",
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ======================================================
  // LIST
  // ======================================================
  Widget _buildList(Map<String, List> grouped) {
    if (grouped.isEmpty) {
      return const Center(
        child: Text(
          "No approvals found",
          style: TextStyle(color: Colors.grey, fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 40),
      itemCount: grouped.keys.length,
      itemBuilder: (_, i) {
        final name = grouped.keys.elementAt(i);
        final reqs = grouped[name]!;

        final rawPhoto = reqs.first["student_photo"];
        final photoUrl = rawPhoto != null
            ? "${ApiService.baseUrl}$rawPhoto"
            : null;

        return _groupedCard(name, photoUrl, reqs);
      },
    );
  }

  // ======================================================
  // CARD
  // ======================================================
  Widget _groupedCard(String name, String? photoUrl, List reqs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage:
                    photoUrl != null ? NetworkImage(photoUrl) : null,
                backgroundColor: purple.withOpacity(0.2),
                child: photoUrl == null
                    ? Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: purple,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: purple,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${reqs.length} Approved",
                  style: const TextStyle(
                    color: purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Column(
            children: reqs.map((r) {
              final title = r["activity_title"] ?? r["title"];
              final desc = r["description"];

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A0E78),
                      ),
                    ),
                    if (desc != null && desc.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          desc,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

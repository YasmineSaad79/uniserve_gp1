import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:ui';
import '../../services/api_service.dart';

class ApprovalsPage extends StatefulWidget {
  const ApprovalsPage({super.key});

  @override
  State<ApprovalsPage> createState() => _ApprovalsPageState();
}

class _ApprovalsPageState extends State<ApprovalsPage> {
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

  void _filter(String query) {
    final lower = query.toLowerCase();

    Map<String, List> filterMap(Map<String, List> original) {
      final Map<String, List> result = {};

      original.forEach((student, reqs) {
        // فلترة الطلبات داخل الطالب
        final matched = reqs.where((r) {
          final name = student.toLowerCase();
          final title = (r["activity_title"] ?? r["title"] ?? "").toLowerCase();
          final desc = (r["description"] ?? "").toLowerCase();

          return name.contains(lower) ||
              title.contains(lower) ||
              desc.contains(lower);
        }).toList();

        // إذا الطالب عنده نتائج → ضيفه
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

  // ---------------------- GROUPING LOGIC ----------------------
  Map<String, List> groupByStudent(List data) {
    final Map<String, List> grouped = {};

    for (var req in data) {
      final name = req["student_name"];
      if (!grouped.containsKey(name)) {
        grouped[name] = [];
      }
      grouped[name]!.add(req);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final volunteerGrouped = groupByStudent(approvedVolunteer);
    final customGrouped = groupByStudent(approvedCustom);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.only(top: 14), // 🔥 ينزل العنوان شوي لتحت
          child: Text(
            "Approvals",
            style: TextStyle(
              fontFamily: "Baloo",
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true, // ❤️ يخلي العنوان بالوسط تماماً
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          _background(),
          SafeArea(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : Column(
                    children: [
                      const SizedBox(height: 20),
                      _tabSwitcher(),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                                0.65), // ← خلفية بيضاء بشفافية حلوة
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.9)),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: _filter,
                            style: const TextStyle(
                              color: Colors.purple, // ← النص بنفسجي
                              fontFamily: "Baloo",
                              fontSize: 16,
                            ),
                            decoration: const InputDecoration(
                              icon: Icon(
                                Icons.search,
                                color: Colors.purple, // ← الأيقونة بنفسجية
                              ),
                              hintText: "Search approvals...",
                              hintStyle: TextStyle(
                                color:
                                    Colors.purple, // ← الـ placeholder بنفسجي
                                fontFamily: "Baloo",
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: _buildList(
                          selectedTab == 0 ? filteredVolunteer : filteredCustom,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------------- BACKGROUND ----------------------
  Widget _background() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFfb78fFF),
            Color(0xFFF7F2FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  // ---------------------- TABS ----------------------
  Widget _tabSwitcher() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          _tabButton("Volunteer", 0),
          _tabButton("Custom", 1),
        ],
      ),
    );
  }

  Widget _tabButton(String text, int index) {
    final selected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: "Baloo",
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: selected ? const Color(0xFF7B1FA2) : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------- LIST OF CARDS ----------------------
  Widget _buildList(Map<String, List> grouped) {
    final keys = grouped.keys.toList();

    if (keys.isEmpty) {
      return const Center(
        child: Text(
          "No approvals found",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final name = keys[index];
        final reqList = grouped[name]!;
        final rawPhoto = reqList.first["student_photo"];

        final photoUrl = rawPhoto != null
            ? "http://10.0.2.2:5000$rawPhoto?t=${DateTime.now().millisecondsSinceEpoch}"
            : null;

        return _groupedCard(name, photoUrl, reqList);
      },
    );
  }

  // ---------------------- BEAUTIFUL GROUPED CARD ----------------------
  Widget _groupedCard(String name, String? photoUrl, List requests) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.38),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(0.35)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 22,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -----------------------------------
                // HEADER (photo + name + count badge)
                // -----------------------------------
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7B1FA2).withOpacity(0.28),
                            blurRadius: 18,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage:
                            photoUrl != null ? NetworkImage(photoUrl) : null,
                        backgroundColor:
                            const Color(0xFF7B1FA2).withOpacity(0.20),
                        child: photoUrl == null
                            ? Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: "Baloo",
                                  fontSize: 22,
                                  color: Color(0xFF7B1FA2),
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontFamily: "Baloo",
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${requests.length} Approved",
                        style: const TextStyle(
                          fontFamily: "Baloo",
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // -----------------------------------
                // LIST OF APPROVED REQUESTS
                // -----------------------------------
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: requests.map((r) {
                    final title = r["activity_title"] ?? r["title"];
                    final desc = r["description"];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.65), // 🔥 أوضح وأشيك
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: "Baloo",
                              fontSize: 16,
                              color: Color(
                                  0xFF4A0E78), // 🔥 Purple داكن جميل وواضح
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (desc != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                desc,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54, // 🔥 وضوح تام
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

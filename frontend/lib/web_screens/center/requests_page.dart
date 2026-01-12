import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile/services/api_service.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  // =====================================================
  // CONFIG
  // =====================================================
  String get serverIP => kIsWeb ? "localhost" : "10.0.2.2";

  List volunteerRequests = [];
  List customRequests = [];
  List filteredRequests = [];

  bool isLoading = true;

  final TextEditingController _searchCtrl = TextEditingController();
  final PageController _pageCtrl = PageController(viewportFraction: 0.82);

  int selectedTab = 0; // 0 volunteer | 1 custom
  final Map<int, String> _aiSummaries = {};

  // =====================================================
  // INIT
  // =====================================================
  @override
  void initState() {
    super.initState();
    loadRequests();
  }

  // =====================================================
  // LOAD DATA
  // =====================================================
  Future<void> loadRequests() async {
    setState(() => isLoading = true);

    final v = await ApiService.getVolunteerRequests();
    final c = await ApiService.getCustomRequests();

    if (v.statusCode == 200) volunteerRequests = json.decode(v.body);
    if (c.statusCode == 200) customRequests = json.decode(c.body);

    setState(() {
      filteredRequests =
          selectedTab == 0 ? volunteerRequests : customRequests;
      isLoading = false;
    });
  }

  // =====================================================
  // SEARCH
  // =====================================================
  void _filterRequests(String query) {
    final list = selectedTab == 0 ? volunteerRequests : customRequests;

    if (query.isEmpty) {
      setState(() => filteredRequests = list);
      return;
    }

    final lower = query.toLowerCase();

    setState(() {
      filteredRequests = list.where((req) {
        final name = (req["student_name"] ?? "").toLowerCase();
        final title =
            (req["title"] ?? req["activity_title"] ?? "").toLowerCase();
        return name.contains(lower) || title.contains(lower);
      }).toList();
    });
  }

  // =====================================================
  // AI
  // =====================================================
  Future<void> _loadAiForRequest(int id) async {
    if (_aiSummaries.containsKey(id)) return;

    try {
      final res = await ApiService.getCustomRequestSimilarity(id);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final matches = data['matches'] ?? [];

        _aiSummaries[id] = matches.isEmpty
            ? "No similarity found"
            : "Closest match: ${matches[0]['title']}";
      }
    } catch (_) {
      _aiSummaries[id] = "AI unavailable";
    }

    setState(() {});
  }

  // =====================================================
  // UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,

      // -------------------- APPBAR --------------------
      appBar: AppBar(
        automaticallyImplyLeading: !kIsWeb,
        leading: kIsWeb
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Color(0xFF7B1FA2),
                  size: 22,
                ),
                onPressed: () => Navigator.pop(context),
              ),
        title: const Text(
          "Requests",
          style: TextStyle(
            fontFamily: "Baloo",
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      // -------------------- BODY --------------------
      body: Stack(
        children: [
          _background(),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 25),
                _tabs(),
                const SizedBox(height: 25),
                _searchBar(),
                const SizedBox(height: 20),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : PageView.builder(
                          controller: _pageCtrl,
                          itemCount: filteredRequests.length,
                          itemBuilder: (_, i) =>
                              _pageItem(filteredRequests[i], i),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // WIDGETS
  // =====================================================
  Widget _background() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/reqbackground.jpg"),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(30),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: _filterRequests,
          style: const TextStyle(color: Colors.purple, fontFamily: "Baloo"),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: "Search...",
            hintStyle: TextStyle(color: Colors.purple),
            icon: Icon(Icons.search, color: Colors.purple),
          ),
        ),
      ),
    );
  }

  Widget _tabs() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          _tab("Volunteer", 0),
          _tab("Custom", 1),
        ],
      ),
    );
  }

  Widget _tab(String text, int index) {
    final selected = selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedTab = index;
            filteredRequests =
                selectedTab == 0 ? volunteerRequests : customRequests;
            if (_searchCtrl.text.isNotEmpty) {
              _filterRequests(_searchCtrl.text);
            }
          });
        },
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: "Baloo",
              fontSize: selected ? 20 : 18,
              color: Colors.purple,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _pageItem(dynamic req, int index) {
    return AnimatedBuilder(
      animation: _pageCtrl,
      builder: (_, child) {
        double scale = 1;
        if (_pageCtrl.position.haveDimensions) {
          scale = (1 -
                  (_pageCtrl.page! - index).abs() * 0.25)
              .clamp(0.9, 1.0);
        }
        return Transform.scale(scale: scale, child: child);
      },
      child: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.88,
          height: 490,
          child: _glassCard(req),
        ),
      ),
    );
  }

  Widget _glassCard(dynamic req) {
    final bool isVolunteer = req["activity_title"] != null;
    final int? requestId = req["request_id"];

    if (!isVolunteer && requestId != null) {
      _loadAiForRequest(requestId);
    }

    final String name = req["student_name"] ?? "Unknown";
    final String? rawPhoto = req["student_photo"];
    final String? photoUrl =
        rawPhoto != null ? "http://$serverIP:5000$rawPhoto" : null;

    final String status = req["status"] ?? "pending";
    final String title =
        isVolunteer ? req["activity_title"] ?? "" : req["title"] ?? "";
    final String? desc = isVolunteer ? null : req["description"];

    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null ? Text(name[0]) : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontFamily: "Baloo",
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
                _statusBadge(status),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontFamily: "Baloo",
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.purple,
              ),
            ),
            if (desc != null) ...[
              const SizedBox(height: 10),
              Text(desc),
            ],
            if (!isVolunteer && requestId != null) ...[
              const SizedBox(height: 14),
              Text(
                _aiSummaries[requestId] ?? "Analyzing with AI...",
                style: const TextStyle(color: Colors.purple),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = status == "approved"
        ? Colors.green
        : status == "rejected"
            ? Colors.red
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontFamily: "Baloo",
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

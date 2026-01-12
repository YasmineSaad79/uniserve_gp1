import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';

class RequestsPage extends StatefulWidget {
  final int? initialStudentId;
  final int? initialActivityId;
  final int? initialCustomRequestId;
  final int? initialNotificationId;

  const RequestsPage({
    super.key,
    this.initialStudentId,
    this.initialActivityId,
    this.initialCustomRequestId,
    this.initialNotificationId,
  });

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  List volunteerRequests = [];
  List customRequests = [];
  bool isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();
  List filteredRequests = [];

  int selectedTab = 0;
  Map<int, String> _aiSummaries = {};
  final PageController _pageCtrl = PageController(viewportFraction: 0.82);

  @override
  void initState() {
    super.initState();
    loadRequests();
  }

  Future<void> loadRequests() async {
    setState(() => isLoading = true);

    try {
      final volunteerRes = await ApiService.getVolunteerRequests();
      final customRes = await ApiService.getCustomRequests();

      if (volunteerRes.statusCode == 200) {
        volunteerRequests = json.decode(volunteerRes.body);
      }

      if (customRes.statusCode == 200) {
        customRequests = json.decode(customRes.body);
      }

      // 👇👇👇 هذا هو المكان الصح
      if (widget.initialCustomRequestId != null) {
        selectedTab = 1;
        filteredRequests = customRequests;
      } else {
        selectedTab = 0;
        filteredRequests = volunteerRequests;
      }
    } catch (e) {
      print("Error loading requests: $e");
    }

    setState(() => isLoading = false);

    // بعد ما تتحدد القائمة → نروح للكارد الصح
    _jumpToRequestedCard();
  }

  void _jumpToRequestedCard() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pageCtrl.hasClients) return;

      List list = selectedTab == 0 ? volunteerRequests : customRequests;
      int index = -1;

      if (selectedTab == 0 && widget.initialActivityId != null) {
        index = list.indexWhere(
          (r) => r['activity_id'] == widget.initialActivityId,
        );
      }

      if (selectedTab == 1 && widget.initialCustomRequestId != null) {
        index = list.indexWhere(
          (r) => r['request_id'] == widget.initialCustomRequestId,
        );
      }

      if (index != -1) {
        _pageCtrl.jumpToPage(index);
      }
    });
  }

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

  Future<void> _loadAiForRequest(int id) async {
    if (_aiSummaries.containsKey(id)) return;

    try {
      final res = await ApiService.getCustomRequestSimilarity(id);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final matches = data['matches'] ?? [];
        if (matches.isEmpty) {
          _aiSummaries[id] = "No similarity found";
        } else {
          final best = matches[0];
          _aiSummaries[id] =
              "Closest match: ${best['title']} (${(best['similarity'] * 100).toStringAsFixed(0)}%)";
        }
      }
    } catch (_) {
      _aiSummaries[id] = "AI unavailable";
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final list = selectedTab == 0 ? volunteerRequests : customRequests;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF7B1FA2), // uniPurple
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
            shadows: [
              Shadow(color: Colors.black26, blurRadius: 8),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          _background(),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 25),
                _tabs(),
                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.50),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _filterRequests,
                      style: const TextStyle(
                          color: Colors.purple, fontFamily: "Baloo"),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Search...",
                        hintStyle: TextStyle(color: Colors.purple),
                        icon: Icon(Icons.search, color: Colors.purple),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : PageView.builder(
                          controller: _pageCtrl,
                          itemCount: filteredRequests.length,
                          itemBuilder: (_, i) => AnimatedBuilder(
                            animation: _pageCtrl,
                            builder: (_, child) {
                              double value = 1;
                              if (_pageCtrl.position.haveDimensions) {
                                value = _pageCtrl.page! - i;
                                value =
                                    (1 - (value.abs() * 0.25)).clamp(0.90, 1.0);
                              }
                              return Transform.scale(
                                scale: value,
                                child: child,
                              );
                            },
                            child: Center(
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.88,
                                height: 490,
                                child: _glassCard(filteredRequests[i]),
                              ),
                            ),
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

  Widget _tabs() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.50),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment:
                selectedTab == 0 ? Alignment.centerLeft : Alignment.centerRight,
            duration: const Duration(milliseconds: 260),
            child: Container(
              width: MediaQuery.of(context).size.width * .40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.90),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.purple, // اللون البنفسجي
                  width: 1.2, // سُمك الحواف (اعمليه 0.8 لو بدك أرفع)
                ),
              ),
            ),
          ),
          Row(
            children: [
              _tab("Volunteer", 0),
              _tab("Custom", 1),
            ],
          ),
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

          // 🔥 هذا هو المفتاح
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageCtrl.hasClients && filteredRequests.isNotEmpty) {
              _pageCtrl.jumpToPage(0);
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

  Widget _glassCard(dynamic req) {
    final bool isVolunteer = req["activity_title"] != null;

    String resolveStudentName(dynamic req) {
      if (req["student_name"] != null) return req["student_name"];
      if (req["full_name"] != null) return req["full_name"];
      if (req["student"]?["full_name"] != null)
        return req["student"]["full_name"];
      return "Unknown";
    }

    final String name = resolveStudentName(req);

    final String? rawPhoto = req["student_photo"];
    final String? photoUrl = rawPhoto != null
        ? "http://10.0.2.2:5000$rawPhoto?t=${DateTime.now().millisecondsSinceEpoch}"
        : null;

    final String status = req["status"] ?? "pending";
    final String createdAt =
        req["created_at"]?.toString().substring(0, 10) ?? "";
    final String title =
        isVolunteer ? req["activity_title"] ?? "" : req["title"] ?? "";
    final String? desc = isVolunteer ? null : req["description"];
    final int? requestId = req["request_id"];

    if (!isVolunteer && requestId != null) {
      _loadAiForRequest(requestId);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 55, right: 10, left: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.62),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.30),
                      width: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 35),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontFamily: "Baloo",
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                          _statusBadge(status),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isVolunteer ? "Volunteer Request" : "Custom Request",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: "Baloo",
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple,
                        ),
                      ),
                      if (desc != null && desc.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          desc,
                          style: TextStyle(
                            color: Colors.purple.withOpacity(0.85),
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      if (!isVolunteer && requestId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.38),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _aiSummaries[requestId] ?? "Analyzing with AI...",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        "Sent on: $createdAt",
                        style: TextStyle(
                          color: Colors.purple.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      if (status == "pending") ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _updateRequestStatus(
                                    req["request_id"],
                                    "approved",
                                    isVolunteer, // هون مكانها الصحيح
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text(
                                  "Accept",
                                  style: TextStyle(
                                    fontFamily: "Baloo",
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _updateRequestStatus(
                                    req["request_id"],
                                    "rejected",
                                    isVolunteer,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text(
                                  "Reject",
                                  style: TextStyle(
                                    fontFamily: "Baloo",
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 30,
          child: CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 36,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              backgroundColor: Colors.white,
              child: photoUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0] : "?",
                      style: const TextStyle(
                        fontFamily: "Baloo",
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateRequestStatus(
      int id, String newStatus, bool isVolunteer) async {
    try {
      if (isVolunteer) {
        if (newStatus == "approved") {
          await ApiService.acceptVolunteerRequest(id);
        } else {
          await ApiService.rejectVolunteerRequest(id);
        }
      } else {
        // معالجة طلب Custom
        await ApiService.updateCenterCustomRequestStatus(
          requestId: id,
          status: newStatus,
        );
      }

      // حمّلي الطلبات الجديدة
      await loadRequests();
      Navigator.pop(context, true); // 🔥 إشعار أنه صار تحديث

      // جدّدي الواجهة
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Request $newStatus")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Widget _statusBadge(String status) {
    Color color = status == "accepted" || status == "approved"
        ? const Color(0xFF2ECC71) // أخضر واضح وجميل
        : status == "rejected"
            ? Colors.red
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
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

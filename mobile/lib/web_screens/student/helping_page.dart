import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/web_screens/student/chat_screen_web.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

const Color uniPurple = Color(0xFF7B1FA2);

class HelpScreenWeb extends StatefulWidget {
  final String studentId;
  final int userId;
  final int serviceCenterUserId;

  const HelpScreenWeb({
    super.key,
    required this.studentId,
    required this.userId,
    required this.serviceCenterUserId,
  });

  @override
  State<HelpScreenWeb> createState() => _HelpScreenWebState();
  
}

class _HelpScreenWebState extends State<HelpScreenWeb>
    with SingleTickerProviderStateMixin {
  bool loadingFaqs = true;
  bool loadingQuestions = true;
  bool contactLoading = false;

  List<Map<String, dynamic>> faqs = [];
  List<Map<String, dynamic>> myQuestions = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchFaqs();
    _fetchMyQuestions();
  }

@override
void dispose() {
  _tabController.dispose();
  super.dispose();
}

  // ======================== FETCH FAQ ========================
  Future<void> _fetchFaqs() async {
    try {
      final data = await ApiService.getFaqs();
      setState(() {
        if (data is List) {
          faqs = data;
        }
        loadingFaqs = false;
      });
    } catch (_) {
      loadingFaqs = false;
    }
  }

  // ======================== FETCH QUESTIONS ========================
  Future<void> _fetchMyQuestions() async {
  try {
    final res = await ApiService.authGet(
      Uri.parse(
          "http://localhost:5000/api/help/my-questions/${widget.studentId}"),
    );

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final decoded = jsonDecode(res.body);

      if (decoded is List) {
        setState(() {
          myQuestions = List<Map<String, dynamic>>.from(decoded);
          loadingQuestions = false;
        });
      } else {
        setState(() {
          myQuestions = [];
          loadingQuestions = false;
        });
      }
    }
  } catch (e) {
    debugPrint("❌ Error loading questions: $e");
    loadingQuestions = false;
  }
}


  // ======================== ASK QUESTION ========================
  void _showAskDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Ask a New Question"),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Type your question here...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: uniPurple),
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;

              Navigator.pop(context);
        final token = await ApiService.getUnifiedToken();

        final res = await http.post(
          Uri.parse("http://localhost:5000/api/help/student-question"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({
            "student_id": widget.studentId,
            "user_id": widget.userId,
            "question": controller.text.trim(),
          }),
        );


              if (res.statusCode == 201) {
                _fetchMyQuestions();
              }
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  // ======================== CONTACT CENTER ========================
  void _contactCenter() {
    setState(() => contactLoading = true);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreenWeb(
          myId: widget.userId,
          otherId: widget.serviceCenterUserId,
          otherName: "Service Center", // أو الاسم الحقيقي
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => contactLoading = false);
    });

  }

  // ======================== UI ========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6ECFF),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildHeader(),
          const SizedBox(height: 20),
          _buildTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFaqTab(),
                _buildMyQuestionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ======================== HEADER ========================
  Widget _buildHeader() {
    return const Text(
      "Help & Support",
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: uniPurple,
      ),
    );
  }

  // ======================== TABS ========================
  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white,
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: uniPurple,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.black,
        tabs: const [
          Tab(text: "FAQs"),
          Tab(text: "My Questions"),
        ],
      ),
    );
  }

  // ======================== FAQ TAB ========================
  Widget _buildFaqTab() {
    if (loadingFaqs) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(30),
      itemCount: faqs.length,
      itemBuilder: (_, i) {
        final faq = faqs[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: ExpansionTile(
            leading: const Icon(Icons.help_outline, color: uniPurple),
            title: Text(
              faq['question'],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(faq['answer']),
              ),
            ],
          ),
        );
      },
    );
  }

  // ======================== QUESTIONS TAB ========================
  Widget _buildMyQuestionsTab() {
    if (loadingQuestions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (myQuestions.isEmpty) {
      return const Center(child: Text("No questions yet"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(30),
      itemCount: myQuestions.length,
      itemBuilder: (_, i) {
        final q = myQuestions[i];
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading:
                const Icon(Icons.question_answer, color: uniPurple),
            title: Text(q['question']),
            subtitle: q['reply'] == null
                ? const Text("Waiting for reply...",
                    style: TextStyle(color: Colors.orange))
                : Text(
                    "Reply: ${q['reply']}",
                    style: const TextStyle(color: Colors.green),
                  ),
          ),
        );
      },
    );
  }
}

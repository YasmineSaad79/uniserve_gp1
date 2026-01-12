
import 'package:flutter/material.dart';
import 'package:mobile/mobile_screens/shared/chatScreen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile/services/token_service.dart'; // ✅ مهم

class HelpScreen extends StatefulWidget {
  final String studentId;
  final int serviceCenterId;
  final int userId;

  const HelpScreen({
    super.key,
    required this.studentId,
    required this.serviceCenterId,
    required this.userId,
  });

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

const Color uniPurple = Color(0xFF7B1FA2);

class _HelpScreenState extends State<HelpScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ✅ BASE URL ذكي
  String get _baseUrl {
    if (kIsWeb) {
      return "http://localhost:5000";
    } else {
      return "http://10.0.2.2:5000";
    }
  }

  bool _contactLoading = false;
  bool _isLoadingQuestions = true;
  bool _isLoadingFaqs = true;

  List<Map<String, dynamic>> _myQuestions = [];
  List<Map<String, dynamic>> _faqs = [];

  @override
  void initState() {
    super.initState();
    _fetchFaqs();
    _fetchMyQuestions();
  }

  // ================= FAQs =================
  Future<void> _fetchFaqs() async {
    try {
      final res = await http.get(
        Uri.parse("$_baseUrl/api/help/faqs"),
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _faqs = data.map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoadingFaqs = false;
        });
      } else {
        throw Exception("Failed to load FAQs");
      }
    } catch (e) {
      _isLoadingFaqs = false;
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("FAQ Error: $e")));
      }
    }
  }

  // ================= MY QUESTIONS =================
  Future<void> _fetchMyQuestions() async {
    try {
      final token = await TokenService.getToken(); // ✅ موحّد

      final res = await http.get(
        Uri.parse("$_baseUrl/api/help/my-questions/${widget.studentId}"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        final List data = decoded is List
            ? decoded
            : decoded['data'] ?? [];

        setState(() {
          _myQuestions =
              data.map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoadingQuestions = false;
        });
      } else {
        throw Exception("Status ${res.statusCode}");
      }
    } catch (e) {
      _isLoadingQuestions = false;
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Questions Error: $e")),
        );
      }
    }
  }

  // ================= SEND QUESTION =================
  void _showQuestionDialog() {
    String question = '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ask a New Question"),
        content: TextField(
          maxLines: 3,
          onChanged: (v) => question = v,
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
            onPressed: () async {
              if (question.trim().isEmpty) return;
              Navigator.pop(context);

              final token = await TokenService.getToken();

              final res = await http.post(
                Uri.parse("$_baseUrl/api/help/student-question"),
                headers: {
                  "Content-Type": "application/json",
                  "Authorization": "Bearer $token", // ✅ مهم
                },
                body: jsonEncode({
                  "user_id": widget.userId,
                  "student_id": widget.studentId,
                  "question": question,
                }),
              );

              if (res.statusCode == 201) {
                await Future.delayed(const Duration(milliseconds: 300));
                _fetchMyQuestions();
              }

            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  // ================= CHAT =================
  Future<void> _contactServiceCenter() async {
    setState(() => _contactLoading = true);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          senderId: widget.userId,
          receiverId: widget.serviceCenterId,
        ),
      ),
    );
    if (mounted) setState(() => _contactLoading = false);
  }

  // ================= UI (غير معدل) =================
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: uniPurple),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Help & Support",
            style: TextStyle(color: uniPurple, fontSize: 26),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            TabBar(
              labelColor: uniPurple, // 💜 لون التاب المختار
              unselectedLabelColor: uniPurple.withOpacity(0.5), // 💜 لون غير المختار
              indicatorColor: uniPurple, // 💜 الخط تحت التاب
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
              ),
              tabs: const [
                Tab(text: "FAQs"),
                Tab(text: "My Questions"),
              ],
            ),

            Expanded(
              child: TabBarView(
                children: [
                  _isLoadingFaqs
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          children: _faqs
                              .map((f) => ListTile(
                                    title: Text(f['question']),
                                    subtitle: Text(f['answer']),
                                  ))
                              .toList(),
                        ),
                  _isLoadingQuestions
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          children: _myQuestions
                              .map((q) => ListTile(
                                    title: Text(q['question']),
                                    subtitle: Text(q['reply'] ?? "No reply"),
                                  ))
                              .toList(),
                        ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _contactServiceCenter,
              child: const Text("Contact Service Center"),
            ),
            TextButton(
              onPressed: _showQuestionDialog,
              child: const Text("Ask a new question"),
            ),
          ],
        ),
      ),
    );
  }
}

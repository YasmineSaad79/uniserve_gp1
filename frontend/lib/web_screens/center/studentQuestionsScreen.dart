import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/services/token_service.dart';

class StudentQuestionsScreen extends StatefulWidget {
  const StudentQuestionsScreen({super.key});

  @override
  State<StudentQuestionsScreen> createState() =>
      _StudentQuestionsScreenState();
}

class _StudentQuestionsScreenState extends State<StudentQuestionsScreen> {
  String? _token;
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;

  // 🌍 Server حسب المنصة
  String get serverIP => kIsWeb ? "localhost" : "10.0.2.2";

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _token = await TokenService.getToken();
    await _fetchQuestions();
  }

  // =====================================================
  // FETCH QUESTIONS
  // =====================================================
  Future<void> _fetchQuestions() async {
    try {
      final res = await http.get(
        Uri.parse("http://$serverIP:5000/api/help/student-questions"),
        headers: {
          if (_token != null) "Authorization": "Bearer $_token",
        },
      );

      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        setState(() {
          _questions = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        throw Exception(res.body);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load questions")),
      );
    }
  }

  // =====================================================
  // REPLY
  // =====================================================
  void _showReplyDialog(int questionId) {
    String reply = "";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Reply to Question"),
        content: TextField(
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: "Type reply...",
            filled: true,
          ),
          onChanged: (v) => reply = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sendReply(questionId, reply);
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  Future<void> _sendReply(int id, String reply) async {
    final res = await http.put(
      Uri.parse("http://$serverIP:5000/api/help/student-questions/$id/reply"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: json.encode({"reply": reply}),
    );

    if (res.statusCode == 200) {
      await _fetchQuestions();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Reply sent ✔")));
    }
  }

  // =====================================================
  // ADD FAQ
  // =====================================================
  void _showAddFaqDialog() {
    String q = "", a = "";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Add FAQ"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Question"),
              onChanged: (v) => q = v,
            ),
            const SizedBox(height: 10),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Answer"),
              onChanged: (v) => a = v,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _addFaq(q, a);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _addFaq(String q, String a) async {
    final res = await http.post(
      Uri.parse("http://$serverIP:5000/api/help/faqs"),
      headers: {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      },
      body: json.encode({"question": q, "answer": a}),
    );

    if (res.statusCode == 201) {
      await _fetchQuestions();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("FAQ added ✔")));
    }
  }

  // =====================================================
  // QUESTION CARD
  // =====================================================
  Widget _questionCard(Map q) {
    final reply = q["reply"];
    final date = q["created_at"]?.substring(0, 10) ?? "";

    return Container(
      width: kIsWeb ? 720 : null,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                q["question"],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A148C),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Student ID: ${q["student_id"]}",
                style: const TextStyle(color: Colors.grey),
              ),
              if (reply != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    reply,
                    style: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(date, style: const TextStyle(color: Colors.grey)),
                  if (reply == null)
                    TextButton.icon(
                      onPressed: () => _showReplyDialog(q["id"]),
                      icon: const Icon(Icons.reply),
                      label: const Text("Reply"),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // BUILD
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !kIsWeb,
        title: const Text(
          "Student Questions",
          style: TextStyle(
            fontFamily: "Baloo",
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        alignment: kIsWeb ? Alignment.topCenter : null,
        padding: EdgeInsets.symmetric(
          horizontal: kIsWeb ? 40 : 0,
          vertical: 12,
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _questions.isEmpty
                ? const Center(child: Text("No questions yet"))
                : ListView.builder(
                    itemCount: _questions.length,
                    itemBuilder: (_, i) => _questionCard(_questions[i]),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFaqDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

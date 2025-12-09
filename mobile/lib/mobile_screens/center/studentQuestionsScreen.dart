import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StudentQuestionsScreen extends StatefulWidget {
  const StudentQuestionsScreen({super.key});

  @override
  State<StudentQuestionsScreen> createState() => _StudentQuestionsScreenState();
}

class _StudentQuestionsScreenState extends State<StudentQuestionsScreen> {
  final storage = FlutterSecureStorage();
  String? _token;
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;

  static const String serverIP = "10.0.2.2";

  @override
  void initState() {
    super.initState();
    _loadToken().then((_) => _fetchQuestions());
  }

  Future<void> _loadToken() async {
    _token = await storage.read(key: "authToken");
  }

  Future<void> _fetchQuestions() async {
    try {
      final response = await http.get(
        Uri.parse("http://$serverIP:5000/api/help/student-questions"),
        headers: {
          if (_token != null) "Authorization": "Bearer $_token",
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _questions = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load questions');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showReplyDialog(int questionId) {
    String reply = "";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Reply to Question",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "Type reply...",
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (v) => reply = v,
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Send Reply"),
            onPressed: () async {
              Navigator.pop(context);
              await _sendReply(questionId, reply);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sendReply(int id, String reply) async {
    try {
      final response = await http.put(
        Uri.parse("http://$serverIP:5000/api/help/student-questions/$id/reply"),
        headers: {
          "Content-Type": "application/json",
          if (_token != null) "Authorization": "Bearer $_token",
        },
        body: json.encode({"reply": reply}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reply sent successfully ✔")),
        );
        _fetchQuestions();
      } else {
        throw Exception("Failed to send reply");
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showAddFaqDialog() {
    String question = "";
    String answer = "";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Add New FAQ",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: "Question",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) => question = v,
              ),
              const SizedBox(height: 12),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Answer",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) => answer = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text("Add FAQ"),
            onPressed: () async {
              if (question.trim().isEmpty || answer.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill all fields ❗")));
                return;
              }

              Navigator.pop(context);
              await _addFaq(question, answer);
            },
          )
        ],
      ),
    );
  }

  Future<void> _addFaq(String q, String a) async {
    try {
      final token = await storage.read(key: "authToken");
      final response = await http.post(
        Uri.parse("http://$serverIP:5000/api/help/faqs"),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: json.encode({"question": q, "answer": a}),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("FAQ added successfully ✔")),
        );
        _fetchQuestions();
      } else {
        throw Exception("Failed to add FAQ");
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --------------------------------------------------------
  // ⭐ Beautiful Hybrid Card (Glass + Shadow + Gradient Edge)
  // --------------------------------------------------------

  Widget _buildQuestionCard(Map q) {
    final String? reply = q["reply"];
    final String date = q["created_at"]?.substring(0, 10) ?? "";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.12),
            blurRadius: 18,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.55),
              border:
                  Border.all(color: Colors.white.withOpacity(0.65), width: 1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER ROW
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        q["question"],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4A148C),
                        ),
                      ),
                    ),

                    // Reply button or date
                    reply == null
                        ? InkWell(
                            onTap: () => _showReplyDialog(q["id"]),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.purple,
                              ),
                              child: const Icon(Icons.reply,
                                  color: Colors.white, size: 20),
                            ),
                          )
                        : Text(
                            date,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  "Asked by student ID: ${q['student_id']}",
                  style: TextStyle(
                      color: Colors.black.withOpacity(0.55), fontSize: 14),
                ),

                if (reply != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reply,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // UI BUILD
  // --------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🌈 Beautiful Gradient AppBar
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8E24AA), Color(0xFF8E24AA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // 🔙 زر الرجوع
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          "Student Questions",
          style: TextStyle(
            fontSize: 27,
            fontFamily: "Baloo",
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      // BACKGROUND
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF3E8FF),
              Color(0xFFFFFFFF),
              Color(0xFFEDE3FF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.purple))
            : _questions.isEmpty
                ? const Center(
                    child: Text(
                      "No questions submitted yet.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 12, bottom: 90),
                    itemCount: _questions.length,
                    itemBuilder: (c, i) => _buildQuestionCard(_questions[i]),
                  ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple.shade700,
        onPressed: _showAddFaqDialog,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../shared/chatScreen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  bool _contactLoading = false;
  bool _isLoadingQuestions = true;
  List<Map<String, dynamic>> _myQuestions = [];
  List<Map<String, dynamic>> _faqs = [];
  bool _isLoadingFaqs = true;

  @override
  void initState() {
    super.initState();
    _fetchFaqs();
    _fetchMyQuestions();
  }

  Future<void> _fetchFaqs() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/help/faqs'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _faqs = List<Map<String, dynamic>>.from(data);
          _isLoadingFaqs = false;
        });
      } else {
        throw Exception("Failed to load FAQs");
      }
    } catch (e) {
      setState(() => _isLoadingFaqs = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading FAQs: $e")),
      );
    }
  }

  Future<void> _fetchMyQuestions() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:5000/api/help/my-questions/${widget.studentId}'),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _myQuestions = List<Map<String, dynamic>>.from(data);
          _isLoadingQuestions = false;
        });
      } else {
        throw Exception("Failed to load questions");
      }
    } catch (e) {
      setState(() => _isLoadingQuestions = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading questions: $e")),
      );
    }
  }

  void _showQuestionDialog() {
    String question = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Ask a New Question"),
        content: TextField(
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Type your question here...",
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => question = value,
        ),
        actions: [
          TextButton(
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.purple),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text("Send"),
            onPressed: () async {
              if (question.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please type your question first ❗"),
                  ),
                );
                return;
              }

              Navigator.pop(context);

              try {
                final response = await http.post(
                  Uri.parse('http://10.0.2.2:5000/api/help/student-question'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    "user_id": widget.userId,
                    "student_id": widget.studentId,
                    "question": question,
                  }),
                );

                if (response.statusCode == 201) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Your question has been sent ✅")),
                  );
                  _fetchMyQuestions();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Failed to send your question ❌")),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _contactServiceCenter() async {
    setState(() => _contactLoading = true);
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            senderId: widget.userId,
            receiverId: widget.serviceCenterId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open chat: $e')),
      );
    } finally {
      if (mounted) setState(() => _contactLoading = false);
    }
  }

  Widget _buildFaqTab() {
    if (_isLoadingFaqs) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _faqs.length,
            itemBuilder: (context, index) {
              final faq = _faqs[index];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ExpansionTile(
                  leading:
                      const Icon(Icons.help_outline, color: Colors.deepPurple),
                  iconColor: Colors.deepPurple,
                  collapsedIconColor: Colors.deepPurple,
                  title: Text(
                    faq['question'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        faq['answer'],
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        _buildActions(),
      ],
    );
  }

  Widget _buildMyQuestionsTab() {
    if (_isLoadingQuestions) {
      return const Center(child: CircularProgressIndicator());
    }
    return _myQuestions.isEmpty
        ? const Center(child: Text("You haven’t asked any questions yet."))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _myQuestions.length,
            itemBuilder: (context, index) {
              final q = _myQuestions[index];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.question_answer,
                      color: Colors.deepPurple),
                  title: Text(
                    q['question'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Asked at: ${q['created_at'].substring(0, 10)}"),
                      if (q['reply'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "Reply: ${q['reply']}",
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildActions() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: _contactLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.support_agent),
              label: Text(_contactLoading
                  ? 'Opening chat...'
                  : 'Contact Service Center'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _contactLoading ? null : _contactServiceCenter,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _showQuestionDialog,
              icon: const Icon(Icons.add_comment, color: Colors.deepPurple),
              label: const Text(
                "Didn’t find your answer? Ask a new question",
                style: TextStyle(color: Colors.deepPurple),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,

        // ===== APPBAR بنفس ستايل المشروع =====
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false, // مهم جداً عشان نعمل زر رجوع مخصص
          toolbarHeight: 85,

          // ← سهم الرجوع البنفسجي بنفس الستايل
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: uniPurple,
              size: 22,
            ),
            onPressed: () => Navigator.pop(context),
          ),

          // عنوان الشاشة
          title: const Text(
            "Help & Support",
            style: TextStyle(
              fontFamily: "Baloo",
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: uniPurple,
            ),
          ),
        ),

        // ===== BACKGROUND =====
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFEEDAFB),
                Color(0xFFF5E8FF),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 120),

              // ===== TAB BAR GLASS EFFECT =====
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.white.withOpacity(0.25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.15),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                    ),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.black87,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(text: "FAQs"),
                    Tab(text: "My Questions"),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ===== TAB CONTENT =====
              Expanded(
                child: TabBarView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _modernFaqTab(),
                    _modernMyQuestionsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modernFaqTab() {
    if (_isLoadingFaqs) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _faqs.length,
            itemBuilder: (context, index) {
              final faq = _faqs[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.help_outline, color: Colors.purple),
                    ),
                    title: Text(
                      faq['question'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          faq['answer'],
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        _modernActions(),
      ],
    );
  }

  Widget _modernMyQuestionsTab() {
    if (_isLoadingQuestions)
      return const Center(child: CircularProgressIndicator());

    return _myQuestions.isEmpty
        ? const Center(
            child: Text(
              "You haven’t asked any questions yet.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _myQuestions.length,
            itemBuilder: (context, index) {
              final q = _myQuestions[index];

              return Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.75),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q['question'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Asked at: ${q['created_at'].substring(0, 10)}",
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    if (q['reply'] != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        "Reply: ${q['reply']}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
  }

  Widget _modernActions() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              height: 55,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.purple,
                    Colors.purple.shade700,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                icon: _contactLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.support_agent, color: Colors.white),
                label: Text(
                  _contactLoading
                      ? "Opening chat..."
                      : "Contact Service Center",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                onPressed: _contactLoading ? null : _contactServiceCenter,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showQuestionDialog,
              child: Text(
                "Didn't find your answer? Ask a new question",
                style: TextStyle(
                  color: Colors.purple.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

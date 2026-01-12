import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/services/token_service.dart';

class StudentViewRequestsWeb extends StatefulWidget {
  final String studentId;
  final String serverIP;

  const StudentViewRequestsWeb({
    super.key,
    required this.studentId,
    required this.serverIP,
  });

  @override
  State<StudentViewRequestsWeb> createState() => _StudentViewRequestsWebState();
}

class _StudentViewRequestsWebState extends State<StudentViewRequestsWeb> {
  bool _loading = true;
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  // ======================================================
  //                  LOAD REQUESTS
  // ======================================================
  Future<void> _loadRequests() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final token = await TokenService.getToken();
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Session expired, please login again"),
          ),
        );
        return;
      }

      final url = Uri.parse(
        "http://${widget.serverIP}:5000/api/student/requests/${widget.studentId}",
      );

      final res = await http.get(url, headers: {
        "Authorization": "Bearer $token",
      });

      final decoded = jsonDecode(res.body);

      if (!mounted) return;

      // السيرفر يرجّع List مباشرة
      if (res.statusCode == 200 && decoded is List) {
        setState(() {
          _requests = decoded;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unexpected response format")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  // ======================================================
  //                    COLORS
  // ======================================================
  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.orange; // pending
    }
  }

  // ======================================================
  //                    UI BUILD
  // ======================================================
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          width: 900,
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- PAGE TITLE ----------
              Text(
                "My Suggestions",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF7B1FA2),
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1.5),
                      blurRadius: 3,
                      color: const Color(0xFF7B1FA2).withOpacity(0.25),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // ---------- CONTENT ----------
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_requests.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text(
                      "No suggestions found.",
                      style: TextStyle(color: Colors.grey, fontSize: 18),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _requests.length,
                  itemBuilder: (_, i) {
                    final r = _requests[i];
                    final title = r["title"] ?? "";
                    final desc = r["description"] ?? "";
                    final status = r["status"] ?? "pending";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4A148C),
                                  ),
                                ),
                              ),
                              Text(
                                status,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _statusColor(status),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            desc,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

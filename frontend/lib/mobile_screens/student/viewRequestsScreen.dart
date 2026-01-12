import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:ui';

class ViewRequestsScreen extends StatefulWidget {
  final String studentId;
  const ViewRequestsScreen({super.key, required this.studentId});

  @override
  State<ViewRequestsScreen> createState() => _ViewRequestsScreenState();
}

const Color uniPurple = Color(0xFF7B1FA2);

class _ViewRequestsScreenState extends State<ViewRequestsScreen> {
  bool _loading = true;
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getMyRequests(widget.studentId);
      if (res['success'] == true) {
        setState(() {
          _requests = res['data'] ?? [];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: ${res['message'] ?? ''}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: uniPurple,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // ===== المحتوى =====
            Positioned.fill(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _requests.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 160),
                                Center(
                                  child: Text(
                                    "No requests yet",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 180, 20, 20),
                              itemCount: _requests.length,
                              itemBuilder: (_, i) {
                                final r = _requests[i];
                                final title = r['title'] ?? '';
                                final desc = r['description'] ?? '';
                                final status = r['status'] ?? 'pending';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 18),
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.85),
                                        Colors.white.withOpacity(0.55),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.5),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purple.withOpacity(0.12),
                                        blurRadius: 22,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontFamily: "Baloo",
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF4A148C),
                                            ),
                                          ),
                                          Text(
                                            status,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontFamily: "Baloo",
                                              color: _statusColor(status),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        desc,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
            ),

            // ===== العنوان الثابت =====
            Positioned(
              top: 90,
              child: const Text(
                "My Requests",
                style: TextStyle(
                  fontFamily: "Baloo",
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7B1FA2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

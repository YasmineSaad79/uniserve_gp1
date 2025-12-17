import 'dart:convert';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentSubmissionsWeb extends StatefulWidget {
  final String studentId;

  const StudentSubmissionsWeb({super.key, required this.studentId});

  @override
  State<StudentSubmissionsWeb> createState() =>
      _StudentSubmissionsWebState();
}

const Color uniPurple = Color(0xFF7B1FA2);

class _StudentSubmissionsWebState extends State<StudentSubmissionsWeb> {
  bool _loading = true;
  bool _uploading = false;
  List<dynamic> submissions = [];
  int? realUserId;

  static const serverIP = "localhost";

  @override
  void initState() {
    super.initState();
    _resolveUserIdAndLoad();
  }

  Future<void> _resolveUserIdAndLoad() async {
    realUserId = await ApiService.getUserIdByStudentId(widget.studentId);

    if (realUserId == null) {
      setState(() => _loading = false);
      return;
    }

    await _loadAllSubmissions(realUserId!);
  }

  Future<void> _loadAllSubmissions(int userId) async {
    try {
      final data =
          await ApiService.getStudentAllSubmissions(userId.toString());

      setState(() {
        submissions = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // ================= DOWNLOAD (WEB) =================
  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open file")),
      );
    }
  }

  // ================= UPLOAD (WEB) =================
  Future<void> _uploadSubmission(Map item) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null) return;

      setState(() => _uploading = true);

      final bytes = result.files.single.bytes!;
      final filename = result.files.single.name;

      final resp = await ApiService.uploadSubmissionWeb(
        fileBytes: bytes,
        filename: filename,
        studentId: item["student_id"].toString(),
        activityId: item["activity_id"].toString(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resp["message"])),
      );

      await _loadAllSubmissions(realUserId!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      setState(() => _uploading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEEDAFB), Color(0xFFF5E8FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: uniPurple),
            )
          : submissions.isEmpty
              ? const Center(
                  child: Text(
                    "No approved requests yet.",
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                  itemCount: submissions.length,
                  itemBuilder: (context, index) {
                    final item = submissions[index];
                    final status = item["status"];
                    final template = item["template_path"];
                    final submitted = item["submitted_file_path"];

                    return _glassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item["activity_title"] ?? "Activity",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: uniPurple,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            "Status: $status",
                            style: TextStyle(
                              color: status == "approved"
                                  ? Colors.green
                                  : status == "rejected"
                                      ? Colors.red
                                      : Colors.orange,
                            ),
                          ),

                          const SizedBox(height: 12),

                          if (template != null)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.picture_as_pdf,
                                  color: Colors.red),
                              title: const Text("Activity Form"),
                              onTap: () => _openFile(
                                "http://$serverIP:5000/$template",
                              ),
                            ),

                          if (status == "pending")
                            _uploadButton(
                                () => _uploadSubmission(item)),

                          if (submitted != null)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.picture_as_pdf,
                                  color: Colors.green),
                              title: const Text("Submitted File"),
                              onTap: () => _openFile(
                                "http://$serverIP:5000$submitted",
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  // ================= GLASS CARD =================
  Widget _glassCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.85),
            Colors.white.withOpacity(0.55),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.2),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: child,
          ),
        ),
      ),
    );
  }

  // ================= UPLOAD BUTTON =================
  Widget _uploadButton(VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      height: 48,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
        ),
      ),
      child: ElevatedButton.icon(
        onPressed: _uploading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
        ),
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: Text(
          _uploading ? "Uploading..." : "Upload PDF",
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

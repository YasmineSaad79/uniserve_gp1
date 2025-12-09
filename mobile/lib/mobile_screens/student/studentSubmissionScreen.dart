import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/services/api_service.dart';
import 'package:open_filex/open_filex.dart';

class StudentSubmissionScreen extends StatefulWidget {
  final String studentId;

  const StudentSubmissionScreen({super.key, required this.studentId});

  @override
  State<StudentSubmissionScreen> createState() =>
      _StudentSubmissionScreenState();
}

const Color uniPurple = Color(0xFF7B1FA2);

class _StudentSubmissionScreenState extends State<StudentSubmissionScreen> {
  bool _loading = true;
  bool _uploading = false;
  List<dynamic> submissions = [];
  int? realUserId;

  static const serverIP = "10.0.2.2";

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
      final data = await ApiService.getStudentAllSubmissions(userId.toString());

      setState(() {
        submissions = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _downloadFile(String url, String filename) async {
    try {
      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;

      final path = "/storage/emulated/0/Download/$filename";
      final file = File(path);
      await file.writeAsBytes(bytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Downloaded to $path")),
      );

      OpenFilex.open(path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _uploadSubmission(Map item) async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (res == null) return;

      setState(() => _uploading = true);

      final file = File(res.files.single.path!);

      final resp = await ApiService.uploadSubmission(
        file: file,
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

  // ------------------------ UI ------------------------

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
            colors: [Color(0xFFEEDAFB), Color(0xFFF5E8FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // ------- Title -------
            Positioned(
              top: 90,
              child: const Text(
                "My Submissions",
                style: TextStyle(
                  fontFamily: "Baloo",
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7B1FA2),
                ),
              ),
            ),

            // ------- Content -------
            Positioned.fill(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7B1FA2),
                      ),
                    )
                  : submissions.isEmpty
                      ? const Center(
                          child: Text(
                            "No approved requests yet.",
                            style:
                                TextStyle(fontSize: 18, color: Colors.black54),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 170, 16, 30),
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
                                  // Title
                                  Text(
                                    item["activity_title"] ?? "Activity",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontFamily: "Baloo",
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF7B1FA2),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Status
                                  Text(
                                    "Status: $status",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: "Baloo",
                                      color: status == "approved"
                                          ? Colors.green
                                          : status == "rejected"
                                              ? Colors.red
                                              : status == "submitted"
                                                  ? Colors.blue
                                                  : Colors.orange,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  if (template != null)
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(
                                        Icons.picture_as_pdf,
                                        color: Colors.red,
                                      ),
                                      title: const Text(
                                        "Activity Form",
                                        style: TextStyle(fontFamily: "Baloo"),
                                      ),
                                      subtitle: const Text("Tap to download"),
                                      onTap: () => _downloadFile(
                                        "http://$serverIP:5000/$template",
                                        "activity_form.pdf",
                                      ),
                                    ),

                                  if (status == "pending")
                                    const SizedBox(height: 10),

                                  // Upload Button
                                  if (status == "pending")
                                    _uploadButton(
                                        () => _uploadSubmission(item)),

                                  // Submitted File
                                  if (submitted != null)
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(
                                        Icons.picture_as_pdf,
                                        color: Colors.green,
                                      ),
                                      title: const Text(
                                        "Submitted File",
                                        style: TextStyle(fontFamily: "Baloo"),
                                      ),
                                      subtitle: const Text("Tap to open"),
                                      onTap: () => _downloadFile(
                                        "http://$serverIP:5000$submitted",
                                        "submitted.pdf",
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // --------- Glass Card (مثل Add Request) ---------

  Widget _glassCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.85),
            Colors.white.withOpacity(0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.6),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.18),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
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

  // --------- Upload Button (نفس Add Request Style) ---------

  Widget _uploadButton(VoidCallback onPressed) {
    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.4),
            blurRadius: 25,
            offset: Offset(0, 10),
          ),
        ],
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
          style: const TextStyle(
            color: Colors.white,
            fontFamily: "Baloo",
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

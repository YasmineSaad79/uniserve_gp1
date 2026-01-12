import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/services/api_service.dart';

class StudentActivitiesWeb extends StatefulWidget {
  final String studentId;
  const StudentActivitiesWeb({super.key, required this.studentId});

  @override
  State<StudentActivitiesWeb> createState() => _StudentActivitiesWebState();
}

class _StudentActivitiesWebState extends State<StudentActivitiesWeb> {
  static const String serverIP = "localhost"; // WEB

  List activities = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  // =========================================================
  //                  LOAD ACTIVITIES
  // =========================================================
  Future<void> _loadActivities() async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) {
        debugPrint("⚠️ No token found (web)");
        setState(() => isLoading = false);
        return;
      }

      final url = Uri.parse("http://$serverIP:5000/api/activities");

      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          activities = data["data"] ?? [];
          isLoading = false;
        });
      } else {
        debugPrint("⚠️ Failed to load activities: ${response.body}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("⚠️ Error loading activities: $e");
      setState(() => isLoading = false);
    }
  }

  // =========================================================
  //                           UI
  // =========================================================
  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7B1FA2);

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.deepPurple),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "All Activities",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: purple,
            ),
          ),
          const SizedBox(height: 25),

          activities.isEmpty
              ? const Text(
                  "No activities available.",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                )
              : Wrap(
                  spacing: 25,
                  runSpacing: 25,
                  children:
                      activities.map((a) => _activityCard(a)).toList(),
                ),
        ],
      ),
    );
  }

  // =========================================================
  //                     ACTIVITY CARD
  // =========================================================
  Widget _activityCard(dynamic a) {
    const purple = Color(0xFF7B1FA2);

    final String img = (a["image_url"] != null && a["image_url"].isNotEmpty)
        ? "http://$serverIP:5000/${a["image_url"]}"
        : "";

    String formatDate(dynamic v) {
      if (v == null) return "-";
      final s = v.toString();
      return s.length >= 10 ? s.substring(0, 10) : s;
    }

    return Container(
      width: 350,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              img,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 160,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image, size: 60, color: Colors.grey),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            a["title"] ?? "Activity",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: purple,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.place, color: purple, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  a["location"] ?? "",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            "Start: ${formatDate(a["start_date"])}",
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            "End:   ${formatDate(a["end_date"])}",
            style: const TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _submitVolunteerRequest(a["id"]),
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                "I want to volunteer",
                style: TextStyle(color: Colors.white),
              ),
            ),
          )
        ],
      ),
    );
  }

  // =========================================================
  //              SUBMIT VOLUNTEER REQUEST
  // =========================================================
  Future<void> _submitVolunteerRequest(int activityId) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) return;

      final url =
          Uri.parse("http://$serverIP:5000/api/notifications/volunteer-request");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "studentId": widget.studentId,
          "activityId": activityId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request submitted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("⚠️ Error sending volunteer request: $e");
    }
  }
}

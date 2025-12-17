
// view_activities_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/mobile_screens/center/updateActivityScreen.dart';
import '../../models/activity.dart';

const String _BASE_IMAGE_URL = "http://10.0.2.2:5000/";

const Color purple1 = Color(0xFF7F00FF);
const Color purple2 = Color(0xFFE100FF);

// =========================================================
// MAIN SCREEN
// =========================================================
class ViewActivitiesScreen extends StatefulWidget {
  final bool isStudent;

  const ViewActivitiesScreen({super.key, this.isStudent = false});

  @override
  State<ViewActivitiesScreen> createState() => _ViewActivitiesScreenState();
}

class _ViewActivitiesScreenState extends State<ViewActivitiesScreen> {
  List<Activity> _activities = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final fetchedActivities = await ApiService.getAllActivities();
      setState(() {
        _activities = fetchedActivities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch activities.\nError: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteActivity(int id) async {
    try {
      await ApiService.deleteActivityWithAuth(id);
      setState(() {
        _activities.removeWhere((a) => a.id == id);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Deleted successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _navigateToUpdate(Activity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpdateActivityScreen(activity: activity),
      ),
    ).then((value) {
      if (value == true) _fetchActivities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Volunteer Activities'),
        centerTitle: true,
        backgroundColor: purple1,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchActivities,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchActivities,
        color: purple1,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: purple1),
              )
            : _error.isNotEmpty
                ? Center(
                    child: Text(
                      _error,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  )
                : _activities.isEmpty
                    ? const Center(
                        child: Text(
                          'No activities found.',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _activities.length,
                        itemBuilder: (_, i) {
                          return ActivityCard(
                            activity: _activities[i],
                            onDelete: _deleteActivity,
                            onUpdate: _navigateToUpdate,
                            isStudent: widget.isStudent,
                          );
                        },
                      ),
      ),
    );
  }
}

// =========================================================
// CARD (with purple gradient redesign)
// =========================================================
class ActivityCard extends StatefulWidget {
  final Activity activity;
  final Function(int) onDelete;
  final Function(Activity) onUpdate;
  final bool isStudent;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.onDelete,
    required this.onUpdate,
    this.isStudent = false,
  });

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  bool _sending = false;

  // OPEN PDF
  Future<void> _openPdf(String url) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = url.split('/').last;
      final savePath = "${dir.path}/$fileName";

      await Dio().download(url, savePath);
      await OpenFilex.open(savePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF saved: $fileName')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _format(DateTime d) =>
      DateFormat('yyyy-MM-dd | hh:mm a').format(d.toLocal());

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;
    final imgUrl = '$_BASE_IMAGE_URL${a.imageUrl}';
    final pdfUrl =
        (a.formTemplatePath != null && a.formTemplatePath!.isNotEmpty)
            ? Uri.parse(_BASE_IMAGE_URL).resolve(a.formTemplatePath!).toString()
            : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [purple1, purple2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.25),
            offset: const Offset(0, 4),
            blurRadius: 10,
          )
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                imgUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.image, size: 50)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(a.title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: purple1)),

            const SizedBox(height: 6),
            Text("Description: ${a.description}"),
            Text("Location: ${a.location}"),
            Text("Created By: ${a.createdBy}"),

            const Divider(),

            Text("Start: ${_format(a.startDate)}"),
            Text("End: ${_format(a.endDate)}"),
            Text("Status: ${a.status}"),

            const Divider(),

            Text("Created: ${DateFormat('yyyy-MM-dd').format(a.createdAt)}"),
            Text("Updated: ${DateFormat('yyyy-MM-dd').format(a.updatedAt)}"),

            const SizedBox(height: 14),

            // PDF FILE
            if (!widget.isStudent && pdfUrl != null)
              GestureDetector(
                onTap: () => _openPdf(pdfUrl),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    border: Border.all(color: purple1.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
                      SizedBox(width: 10),
                      Text("Service Form (PDF)",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 10),

            // CENTER BUTTONS
            if (!widget.isStudent)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                      icon: const Icon(Icons.delete_forever,
                          color: Colors.red, size: 28),
                      onPressed: () => widget.onDelete(a.id)),
                  const SizedBox(width: 10),
                  IconButton(
                      icon: const Icon(Icons.edit, color: purple1, size: 26),
                      onPressed: () => widget.onUpdate(a)),
                ],
              ),

            // STUDENT BUTTON
            if (widget.isStudent)
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.volunteer_activism),
                  label: Text(
                    _sending ? "Sending..." : "I want to volunteer",
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  onPressed: _sending
                      ? null
                      : () async {
                          setState(() => _sending = true);
                          try {
                            await ApiService.sendVolunteerRequest(a.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          "Request sent for '${a.title}'")));
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e")));
                          } finally {
                            if (mounted) setState(() => _sending = false);
                          }
                        },
                ),
              ),

            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}


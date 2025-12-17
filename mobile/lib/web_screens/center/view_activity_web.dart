import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mobile/models/activity.dart';
import 'package:mobile/services/api_service.dart';

const Color purple1 = Color(0xFF7B1FA2);
const Color purple2 = Color(0xFFE100FF);

const String BASE_URL = "http://localhost:5000/";

class ViewActivityWeb extends StatefulWidget {
  final Function(Activity) onEdit;

  const ViewActivityWeb({
    super.key,
    required this.onEdit,
  });

  @override
  State<ViewActivityWeb> createState() => _ViewActivityWebState();
}

class _ViewActivityWebState extends State<ViewActivityWeb> {
  bool loading = true;
  String error = '';
  List<Activity> activities = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getAllActivities();
      setState(() {
        activities = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _delete(int id) async {
    await ApiService.deleteActivityWithAuth(id);
    setState(() => activities.removeWhere((a) => a.id == id));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: purple1));
    }

    if (error.isNotEmpty) {
      return Center(child: Text(error, style: const TextStyle(color: Colors.red)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Volunteer Activities",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: purple1),
        ),
        const SizedBox(height: 20),

        Expanded(
          child: GridView.builder(
            itemCount: activities.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (_, i) {
              return _ActivityWebCard(
                activity: activities[i],
                onDelete: _delete,
                onEdit: widget.onEdit,
              );
            },
          ),
        ),
      ],
    );
  }
}

// =======================================================
// CARD
// =======================================================

class _ActivityWebCard extends StatelessWidget {
  final Activity activity;
  final Function(int) onDelete;
  final Function(Activity) onEdit;


  const _ActivityWebCard({
    required this.activity,
    required this.onDelete,
    required this.onEdit,
  });

  String _fmt(DateTime d) =>
      DateFormat("yyyy-MM-dd").format(d.toLocal());

  @override
  Widget build(BuildContext context) {
    final imageUrl = BASE_URL + activity.imageUrl;
    final pdfUrl = activity.formTemplatePath != null
        ? Uri.parse(BASE_URL).resolve(activity.formTemplatePath!).toString()
        : null;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [purple1, purple2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image, size: 80),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              activity.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: purple1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),
            Text(activity.description,
                maxLines: 3, overflow: TextOverflow.ellipsis),

            const Divider(),

            Text("📍 ${activity.location}"),
            Text("🕒 ${_fmt(activity.startDate)} → ${_fmt(activity.endDate)}"),
            Text("📌 Status: ${activity.status}"),

            const Spacer(),

            if (pdfUrl != null)
              TextButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(pdfUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                label: const Text("Open Form"),
              ),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDelete(activity.id),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: purple1),
                  onPressed: () => onEdit(activity),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

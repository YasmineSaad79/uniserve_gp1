import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/mobile_screens/center/updateActivityScreen.dart';
import '../../models/activity.dart';

const String _BASE_IMAGE_URL = "http://10.0.2.2:5000/";
const Color primaryColor = Color(0xFF5B2D8B);

enum ActivityFilter { all, active, endingSoon }

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

  bool _showSearch = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  ActivityFilter _filter = ActivityFilter.all;

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
      fetchedActivities.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );
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
    await ApiService.deleteActivityWithAuth(id);
    setState(() {
      _activities.removeWhere((a) => a.id == id);
    });
  }

  void _navigateToUpdate(Activity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpdateActivityScreen(activity: activity),
      ),
    ).then((v) {
      if (v == true) _fetchActivities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'All Volunteer Activities',
          style: TextStyle(
            fontFamily: 'Baloo',
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E2E2E),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2E2E2E)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchActivities,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFDFBFF),
              Color(0xFFF1ECFA),
              Color(0xFFF7F9FC),
            ],
          ),
        ),
        child: Column(
          children: [
            // SEARCH
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  decoration: const InputDecoration(
                    hintText: "Search activities...",
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // FILTER CHIPS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _chip("All", ActivityFilter.all),
                  const SizedBox(width: 8),
                  _chip("Active", ActivityFilter.active),
                  const SizedBox(width: 8),
                  _chip("Ending Soon", ActivityFilter.endingSoon),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchActivities,
                color: primaryColor,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error.isNotEmpty
                        ? Center(child: Text(_error))
                        : _buildTimelineList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, ActivityFilter value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: primaryColor.withOpacity(0.15),
      labelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: selected ? primaryColor : Colors.grey[700],
      ),
      onSelected: (_) => setState(() => _filter = value),
    );
  }

  Widget _buildTimelineList() {
    List<Activity> visible = _activities.where((a) {
      if (_query.isNotEmpty &&
          !a.title.toLowerCase().contains(_query) &&
          !a.description.toLowerCase().contains(_query) &&
          !a.location.toLowerCase().contains(_query)) {
        return false;
      }
      if (_filter == ActivityFilter.active) {
        return a.status.toLowerCase() == "active";
      }
      if (_filter == ActivityFilter.endingSoon) {
        final days = a.endDate.difference(DateTime.now()).inDays;
        return a.status.toLowerCase() == "active" && days >= 0 && days <= 7;
      }

      return true;
    }).toList();

    final grouped = <String, List<Activity>>{};
    for (final a in visible) {
      final key = DateFormat('MMMM yyyy').format(a.startDate);
      grouped.putIfAbsent(key, () => []).add(a);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                entry.key.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: primaryColor.withOpacity(0.6),
                ),
              ),
            ),
            ...entry.value.asMap().entries.map((e) {
              final isLast = e.key == entry.value.length - 1;
              return ActivityRow(
                activity: e.value,
                onDelete: _deleteActivity,
                onUpdate: _navigateToUpdate,
                isStudent: widget.isStudent,
                showLine: !isLast,
              );
            }),
          ],
        );
      }).toList(),
    );
  }
}

// =========================================================
// ACTIVITY ROW
// =========================================================
class ActivityRow extends StatefulWidget {
  final Activity activity;
  final Function(int) onDelete;
  final Function(Activity) onUpdate;
  final bool isStudent;
  final bool showLine;

  const ActivityRow({
    super.key,
    required this.activity,
    required this.onDelete,
    required this.onUpdate,
    required this.isStudent,
    required this.showLine,
  });

  @override
  State<ActivityRow> createState() => _ActivityRowState();
}

class _ActivityRowState extends State<ActivityRow> {
  bool _expanded = false;
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;
    final imgUrl = '$_BASE_IMAGE_URL${a.imageUrl}';
    final badgeColor = _deadlineColor(a.endDate, a.status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _timeBadge(
            start: a.startDate,
            end: a.endDate,
            status: a.status,
            color: badgeColor,
            showLine: widget.showLine,
          ),
          const SizedBox(width: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imgUrl,
              width: 64,
              height: 64,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 64,
                height: 64,
                color: Colors.grey[200],
                child: const Icon(Icons.image),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  style: const TextStyle(
                    fontFamily: 'Baloo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: _progressValue(a.startDate, a.endDate),
                  color: badgeColor,
                  backgroundColor: Colors.grey.shade300,
                  minHeight: 4,
                ),

                // ✅ LOCATION (دائمًا ظاهر)
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 16, color: primaryColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        a.location,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),

                // ✅ DESCRIPTION (دائمًا ظاهر)
                const SizedBox(height: 6),
                Text(
                  a.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
// ===============================
// ⭐ STUDENT VOLUNTEER BUTTON
// ===============================
                if (widget.isStudent)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        side: const BorderSide(
                          color: primaryColor,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primaryColor,
                              ),
                            )
                          : const Icon(
                              Icons.volunteer_activism,
                              color: primaryColor,
                            ),
                      label: Text(
                        _sending ? "Sending..." : "I want to volunteer",
                        style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
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
                                        "Request sent for '${a.title}'",
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error: $e")),
                                );
                              } finally {
                                if (mounted) setState(() => _sending = false);
                              }
                            },
                    ),
                  ),

                const SizedBox(height: 6),
                Row(
                  children: [
                    const Spacer(),
                    if (!widget.isStudent)
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: primaryColor, size: 22),
                        onPressed: () => widget.onUpdate(a),
                      ),
                    if (!widget.isStudent)
                      IconButton(
                        icon: const Icon(Icons.delete_forever,
                            color: Colors.redAccent),
                        onPressed: () => widget.onDelete(a.id),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// HELPERS
// =========================================================
Widget _timeBadge({
  required DateTime start,
  required DateTime end,
  required String status,
  required Color color,
  required bool showLine,
}) {
  return SizedBox(
    width: 64,
    child: Column(
      children: [
        Text(DateFormat('MMM').format(start).toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        Text(
          '${start.day}-${end.day}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: primaryColor.withOpacity(0.7),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(8)),
          child: Text(
            status.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

Color _deadlineColor(DateTime end, String status) {
  final days = end.difference(DateTime.now()).inDays;

  if (status.toLowerCase() != "active") return Colors.grey;
  if (days < 0) return Colors.grey;
  if (days <= 7) return Colors.redAccent;
  if (days <= 30) return Colors.orange;
  return primaryColor;
}

double _progressValue(DateTime start, DateTime end) {
  final total = end.difference(start).inDays;
  final passed = DateTime.now().difference(start).inDays;
  if (total <= 0) return 1;
  return (passed / total).clamp(0.0, 1.0);
}

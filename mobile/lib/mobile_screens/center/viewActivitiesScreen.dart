// view_activities_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/mobile_screens/center/updateaActivityScreen.dart';
import '../../models/activity.dart';
import 'dart:async';

const Color uniPurple = Color(0xFF7B1FA2);
const String _BASE_IMAGE_URL = "http://10.0.2.2:5000/";

class ViewActivitiesScreen extends StatefulWidget {
  final bool isStudent;

  const ViewActivitiesScreen({super.key, this.isStudent = false});

  @override
  State<ViewActivitiesScreen> createState() => _ViewActivitiesScreenState();
}

class _ViewActivitiesScreenState extends State<ViewActivitiesScreen> {
  List<Activity> _activities = [];
  bool _loading = true;
  String _error = "";
  final TextEditingController _searchController = TextEditingController();
  List<Activity> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _searchActivities(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.isEmpty) {
        setState(() {
          _isSearching = false;
          _searchResults.clear();
        });
        return;
      }

      final q = query.toLowerCase();
      final results = _activities
          .where((a) =>
              a.title.toLowerCase().contains(q) ||
              a.description.toLowerCase().contains(q) ||
              a.location.toLowerCase().contains(q))
          .toList();

      setState(() {
        _searchResults = results;
        _isSearching = true;
      });
    });
  }

  Future<void> _fetch() async {
    try {
      setState(() {
        _loading = true;
        _error = "";
      });

      final data = await ApiService.getAllActivities();
      setState(() {
        _activities = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load $e";
        _loading = false;
      });
    }
  }

  Future<void> _deleteActivity(int id) async {
    try {
      await ApiService.deleteActivityWithAuth(id);
      setState(() => _activities.removeWhere((a) => a.id == id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed: $e")));
    }
  }

  void _goUpdate(Activity a) {
    Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => UpdateActivityScreen(activity: a)))
        .then((r) => r == true ? _fetch() : null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F3FF), Color(0xFFF8F3FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 5),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: Colors.purple, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const Text("Activities",
                      style: TextStyle(
                          fontFamily: "Baloo",
                          fontSize: 31,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple)),
                  const Spacer(flex: 2),
                ],
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetch,
                  color: Colors.purple,
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F3FF),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.5),
                            blurRadius: 5,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Scrollbar(
                        thumbVisibility: true,
                        radius: const Radius.circular(50),
                        thickness: 6,
                        // ⬅ نقل السكرول لليمين 🔥
                        trackVisibility: true,
                        scrollbarOrientation: ScrollbarOrientation.right,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(
                              right: 15), // ← إزاحة الخط بعيد عن النص 🟣

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔍 Search is now inside container ✨
                              Container(
                                height: 55,
                                margin: const EdgeInsets.only(bottom: 15),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(40),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 55,
                                      height: 55,
                                      decoration: const BoxDecoration(
                                          color: Colors.purple,
                                          shape: BoxShape.circle),
                                      child: const Icon(Icons.search,
                                          color: Colors.white, size: 26),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        onChanged: _searchActivities,
                                        decoration: InputDecoration(
                                            hintText: "Search Activity...",
                                            border: InputBorder.none,
                                            hintStyle: TextStyle(
                                                color: Colors.purple
                                                    .withOpacity(0.6),
                                                fontSize: 16)),
                                      ),
                                    ),
                                    if (_isSearching)
                                      IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.purple),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _isSearching = false;
                                            _searchResults.clear();
                                          });
                                        },
                                      )
                                  ],
                                ),
                              ),

                              if (_loading)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Center(
                                      child: CircularProgressIndicator(
                                          color: uniPurple)),
                                )
                              else if (_error.isNotEmpty)
                                Center(
                                  child: Text(_error,
                                      style:
                                          const TextStyle(color: Colors.red)),
                                )
                              else
                                ...((_isSearching
                                        ? _searchResults
                                        : _activities)
                                    .map((a) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          child: ActivityRow(
                                            activity: a,
                                            isStudent: widget.isStudent,
                                            onDelete: _deleteActivity,
                                            onUpdate: _goUpdate,
                                          ),
                                        )))
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

/// 🟣 تصميم صف عرض Activity — بدون بطاقات منفصلة
class ActivityRow extends StatelessWidget {
  final Activity activity;
  final bool isStudent;
  final Function(int) onDelete;
  final Function(Activity) onUpdate;

  const ActivityRow({
    super.key,
    required this.activity,
    required this.isStudent,
    required this.onDelete,
    required this.onUpdate,
  });

  String fmt(DateTime d) =>
      DateFormat("yyyy-MM-dd | hh:mm a").format(d.toLocal());

  @override
  Widget build(BuildContext context) {
    final img = "$_BASE_IMAGE_URL${activity.imageUrl}";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(img,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, size: 32)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(activity.title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Baloo")),
              const SizedBox(height: 4),
              Text(activity.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: Colors.black87)),
              const SizedBox(height: 6),
              Text("📍 ${activity.location}"),
              Text("📅 ${fmt(activity.startDate)}"),
              Text("⏳ Status: ${activity.status}"),
              const SizedBox(height: 8),
              isStudent
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {},
                      child: const Text(
                        "Volunteer",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : Row(children: [
                      IconButton(
                          icon: const Icon(Icons.edit, color: uniPurple),
                          onPressed: () => onUpdate(activity)),
                      IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => onDelete(activity.id)),
                    ])
            ],
          ),
        )
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mobile/services/api_service.dart';

class CalendarActivitiesScreen extends StatefulWidget {
  const CalendarActivitiesScreen({super.key});

  @override
  State<CalendarActivitiesScreen> createState() =>
      _CalendarActivitiesScreenState();
}

class _CalendarActivitiesScreenState extends State<CalendarActivitiesScreen> {
  // نخزن: تاريخ -> لستة أحداث (كل حدث فيه label و activityId)
  Map<DateTime, List<Map<String, dynamic>>> events = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _loadActivities() async {
    try {
      final data = await ApiService.getCalendarActivities();
      print("📅 Calendar activities count = ${data.length}");

      final Map<DateTime, List<Map<String, dynamic>>> temp = {};

      for (var item in data) {
        print("Row from API: $item");

        final int activityId = item['activity_id'] ?? item['service_id'];
        final String title = item['title'] ?? '';

        final DateTime start =
            _normalize(DateTime.parse(item['start_date'].toString()));
        final DateTime end =
            _normalize(DateTime.parse(item['end_date'].toString()));

        temp[start] = [
          ...(temp[start] ?? []),
          {
            'label': 'Start: $title',
            'activityId': activityId,
          }
        ];

        temp[end] = [
          ...(temp[end] ?? []),
          {
            'label': 'End: $title',
            'activityId': activityId,
          }
        ];
      }

      setState(() => events = temp);
    } catch (e) {
      print("Calendar load error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load calendar activities")),
        );
      }
    }
  }

  // نبحث عن اليوم داخل الماب باستخدام isSameDay
  List<Map<String, dynamic>> _getEvents(DateTime day) {
    final d = _normalize(day);
    for (final key in events.keys) {
      if (isSameDay(key, d)) {
        return events[key]!;
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedDay ?? _focusedDay;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Activities Calendar"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
            eventLoader: (d) => _getEvents(d),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.purple.shade200,
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ------- عرض الأحداث لليوم المختار -------
          Expanded(
            child: ListView(
              children: _getEvents(selected).map((event) {
                final String label = event['label'] as String;
                final int activityId = event['activityId'] as int;
                final bool isStart = label.startsWith('Start');

                return ListTile(
                  leading: Icon(
                    isStart ? Icons.play_arrow : Icons.flag,
                    color: isStart ? Colors.green : Colors.red,
                  ),
                  title: Text(label),
                  trailing: IconButton(
                    icon: const Icon(Icons.alarm_add, color: Colors.deepPurple),
                    onPressed: () {
                      if (_selectedDay != null) {
                        _addReminder(
                          activityId: activityId,
                          date: _selectedDay!,
                          label: label,
                        );
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _addReminder({
    required int activityId,
    required DateTime date,
    required String label,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Reminder"),
        content: Text(
          "Set reminder for:\n$label\non ${date.toString().split(' ')[0]}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.addReminder(
                  activityId: activityId,
                  remindDate: DateTime(date.year, date.month, date.day),
                  note: "Reminder for $label",
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Reminder added ✅")),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Failed to add reminder: $e")),
                );
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}

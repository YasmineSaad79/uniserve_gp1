import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mobile/services/api_service.dart';

class CalendarActivitiesScreen extends StatefulWidget {
  const CalendarActivitiesScreen({super.key});

  @override
  State<CalendarActivitiesScreen> createState() =>
      _CalendarActivitiesScreenState();
}

class _CalendarActivitiesScreenState extends State<CalendarActivitiesScreen> {
  /// نخزن: تاريخ -> لستة أحداث
  Map<DateTime, List<Map<String, dynamic>>> events = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _loadActivities() async {
    try {
      final data = await ApiService.getCalendarActivities();

      final Map<DateTime, List<Map<String, dynamic>>> temp = {};

      for (var item in data) {
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

      setState(() {
        events = temp;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load calendar activities")),
        );
      }
    }
  }

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
    final bool isWeb = kIsWeb;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !isWeb,
        title: const Text(
          "Activities Calendar",
          style: TextStyle(
            fontFamily: "Baloo",
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Container(
                width: isWeb ? 1100 : double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isWeb ? 24 : 0,
                  vertical: 12,
                ),
                child: isWeb
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _calendar()),
                          const SizedBox(width: 20),
                          Expanded(flex: 3, child: _eventsList(selected)),
                        ],
                      )
                    : Column(
                        children: [
                          _calendar(),
                          const SizedBox(height: 8),
                          Expanded(child: _eventsList(selected)),
                        ],
                      ),
              ),
            ),
    );
  }

  // ===================== CALENDAR =====================
  Widget _calendar() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: TableCalendar(
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
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
        ),
      ),
    );
  }

  // ===================== EVENTS LIST =====================
  Widget _eventsList(DateTime selected) {
    final list = _getEvents(selected);

    if (list.isEmpty) {
      return const Center(
        child: Text(
          "No activities for this day",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (_, i) {
          final event = list[i];
          final String label = event['label'];
          final int activityId = event['activityId'];
          final bool isStart = label.startsWith("Start");

          return ListTile(
            leading: Icon(
              isStart ? Icons.play_arrow : Icons.flag,
              color: isStart ? Colors.green : Colors.red,
            ),
            title: Text(label),
            trailing: IconButton(
              icon: const Icon(Icons.alarm_add, color: Colors.deepPurple),
              onPressed: () {
                _addReminder(
                  activityId: activityId,
                  date: selected,
                  label: label,
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ===================== REMINDER =====================
  void _addReminder({
    required int activityId,
    required DateTime date,
    required String label,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                  SnackBar(content: Text("Failed to add reminder")),
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

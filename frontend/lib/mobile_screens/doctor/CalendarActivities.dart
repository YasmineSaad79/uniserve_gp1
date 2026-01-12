import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mobile/services/api_service.dart';

const Color uniPurple = Color(0xFF7B1FA2);

class CalendarActivitiesScreenMobile extends StatefulWidget {
  const CalendarActivitiesScreenMobile({super.key});

  @override
  State<CalendarActivitiesScreenMobile> createState() =>
      _CalendarActivitiesScreenMobileState();
}

class _CalendarActivitiesScreenMobileState
    extends State<CalendarActivitiesScreenMobile> {
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
          {'label': 'Start: $title', 'activityId': activityId}
        ];

        temp[end] = [
          ...(temp[end] ?? []),
          {'label': 'End: $title', 'activityId': activityId}
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
      if (isSameDay(key, d)) return events[key]!;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedDay ?? _focusedDay;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: uniPurple),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF9F4FF), Color(0xFFFFF9FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 90),

            // 🟣 TITLE
            const Text(
              "My Calendar",
              style: TextStyle(
                fontFamily: "Baloo",
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: uniPurple,
              ),
            ),

            const SizedBox(height: 14),

            // 🔴🟢 LEGEND
            _legend(),

            const SizedBox(height: 18),

            // 📅 CALENDAR CARD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: _buildCalendar(),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Tap on any red day to view due submissions.',
              style: TextStyle(color: Colors.grey),
            ),

            // 📝 EVENTS
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: _getEvents(selected).map((event) {
                  final label = event['label'];
                  final isStart = label.startsWith('Start');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isStart ? Icons.play_arrow : Icons.flag,
                          color: isStart ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(label)),
                        IconButton(
                          icon: const Icon(Icons.alarm_add, color: uniPurple),
                          onPressed: () {
                            if (_selectedDay != null) {
                              _addReminder(
                                activityId: event['activityId'],
                                date: _selectedDay!,
                                label: label,
                              );
                            }
                          },
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= CALENDAR =================
  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2035, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
      onDaySelected: (selected, focused) {
        setState(() {
          _selectedDay = selected;
          _focusedDay = focused;
        });
      },
      eventLoader: (day) => _getEvents(day),
      headerStyle: const HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, _) {
          final hasDue = _getEvents(day).isNotEmpty;
          return _dayCell(day, hasDue);
        },
        todayBuilder: (context, day, _) {
          final hasDue = _getEvents(day).isNotEmpty;
          return _dayCell(day, hasDue, isToday: true);
        },
        selectedBuilder: (context, day, _) {
          final hasDue = _getEvents(day).isNotEmpty;
          return _dayCell(day, hasDue, isSelected: true);
        },
      ),
    );
  }

  Widget _dayCell(
    DateTime day,
    bool hasDue, {
    bool isToday = false,
    bool isSelected = false,
  }) {
    final bgColor = isSelected
        ? uniPurple.withOpacity(0.25)
        : hasDue
            ? Colors.red.withOpacity(0.15)
            : Colors.green.withOpacity(0.12);

    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday ? uniPurple : Colors.transparent,
          width: 1.4,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(
          fontFamily: "Baloo",
          fontWeight: FontWeight.bold,
          color: hasDue ? Colors.red : uniPurple,
        ),
      ),
    );
  }

  Widget _legend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _LegendDot(color: Colors.red, text: "Due day"),
        SizedBox(width: 20),
        _LegendDot(color: Colors.green, text: "No due"),
      ],
    );
  }

  // ================= REMINDER =================
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
                  const SnackBar(content: Text("Failed to add reminder")),
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

// ================= LEGEND DOT =================
class _LegendDot extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendDot({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}

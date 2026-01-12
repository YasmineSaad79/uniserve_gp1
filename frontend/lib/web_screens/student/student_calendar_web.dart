import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/services/api_service.dart';
import 'package:table_calendar/table_calendar.dart';

const Color uniPurple = Color(0xFF7B1FA2);

class StudentCalendarScreen extends StatefulWidget {
  final String? studentId;
  const StudentCalendarScreen({super.key, this.studentId});

  @override
  State<StudentCalendarScreen> createState() => _StudentCalendarScreenState();
}

class _StudentCalendarScreenState extends State<StudentCalendarScreen> {
  final _secure = const FlutterSecureStorage();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _loading = true;
  String? _error;
  String? _uniId;

  final Map<String, List<Map<String, dynamic>>> _itemsByDay = {};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      _uniId = widget.studentId ?? await _extractStudentUniId();
      if (_uniId == null || _uniId!.isEmpty) {
        _error = "Student ID not found";
        return;
      }
      await _loadMonth(_focusedDay.year, _focusedDay.month);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _extractStudentUniId() async {
    final token = await ApiService.getAuthToken();
    if (token != null && token.split('.').length == 3) {
      try {
        final payload = utf8.decode(
          base64Url.decode(base64Url.normalize(token.split('.')[1])),
        );
        return jsonDecode(payload)['student_id']?.toString();
      } catch (_) {}
    }
    return await _secure.read(key: 'studentUniId');
  }

  Future<void> _loadMonth(int year, int month) async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getCalendarMonth(
        studentUniId: _uniId!,
        year: year,
        month: month,
      );

      _itemsByDay.clear();
      final raw = Map<String, dynamic>.from(data['items_by_day'] ?? {});
      raw.forEach((k, v) {
        _itemsByDay[k] = List<Map<String, dynamic>>.from(v);
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _eventsOfDay(DateTime day) =>
      _itemsByDay[_ymd(day)] ?? [];

  String _ymd(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  void _openDueList(DateTime day) {
    final items = _eventsOfDay(day);
    if (items.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Due on ${_ymd(day)}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: uniPurple,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (it) => ListTile(
                leading: const Icon(Icons.assignment, color: uniPurple),
                title: Text(it['title'] ?? 'Untitled'),
                subtitle: Text("Points: ${it['points'] ?? 0}"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: uniPurple))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: () {})
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 30),
                      children: [
                        const Center(
                          child: Text(
                            "My Calendar",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: uniPurple,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _calendarCard(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _calendarCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020),
        lastDay: DateTime.utc(2035),
        focusedDay: _focusedDay,
        rowHeight: 48,
        daysOfWeekHeight: 32,
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle:
              TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(fontSize: 12),
          weekendStyle: TextStyle(fontSize: 12),
        ),
        selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
          if (_eventsOfDay(selected).isNotEmpty) {
            _openDueList(selected);
          }
        },
        onPageChanged: (focused) {
          _focusedDay = focused;
          _loadMonth(focused.year, focused.month);
        },
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (_, day, __) =>
              _dayCell(day, _eventsOfDay(day).isNotEmpty),
          todayBuilder: (_, day, __) =>
              _dayCell(day, _eventsOfDay(day).isNotEmpty, today: true),
          selectedBuilder: (_, day, __) =>
              _dayCell(day, _eventsOfDay(day).isNotEmpty, selected: true),
        ),
      ),
    );
  }

  Widget _dayCell(DateTime day, bool hasDue,
      {bool today = false, bool selected = false}) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: selected
            ? uniPurple.withOpacity(0.22)
            : hasDue
                ? Colors.red.withOpacity(0.12)
                : Colors.green.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: today ? uniPurple : Colors.transparent,
          width: today ? 1.5 : 0,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: hasDue ? Colors.red.shade700 : uniPurple,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.red),
          const SizedBox(height: 10),
          Text(message),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
            style: ElevatedButton.styleFrom(backgroundColor: uniPurple),
          ),
        ],
      ),
    );
  }
}

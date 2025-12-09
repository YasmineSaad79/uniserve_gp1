import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/services/api_service.dart';

class StudentCalendarScreen extends StatefulWidget {
  final String? studentId;
  const StudentCalendarScreen({super.key, this.studentId});

  @override
  State<StudentCalendarScreen> createState() => _StudentCalendarScreenState();
}

const Color uniPurple = Color(0xFF7B1FA2);

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _uniId = widget.studentId ?? await _extractStudentUniId();
      if (_uniId == null || _uniId!.trim().isEmpty) {
        setState(() {
          _error = "Couldn't find student ID";
          _loading = false;
        });
        return;
      }

      await _loadMonth(_focusedDay.year, _focusedDay.month);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _extractStudentUniId() async {
    final token = await _secure.read(key: 'authToken') ??
        await _secure.read(key: 'jwt_token');

    if (token != null && token.split('.').length == 3) {
      try {
        final payload = utf8.decode(
          base64Url.decode(base64Url.normalize(token.split('.')[1])),
        );
        final data = jsonDecode(payload);

        final candidates = [
          data['student_id'],
          data['studentId'],
          data['university_id'],
          data['universityId'],
          data['sid'],
          (data['user'] is Map)
              ? (data['user']['student_id'] ?? data['user']['studentId'])
              : null,
        ].where((v) => v != null && v.toString().trim().isNotEmpty).toList();

        if (candidates.isNotEmpty) return candidates.first.toString();
      } catch (_) {}
    }

    final saved = await _secure.read(key: 'studentUniId');
    if (saved != null && saved.trim().isNotEmpty) return saved;

    final email = await _secure.read(key: 'email') ?? '';
    final m = RegExp(r'(\d{6,})').firstMatch(email);
    if (m != null) return m.group(1);

    return null;
  }

  Future<void> _loadMonth(int year, int month) async {
    if (_uniId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getCalendarMonth(
        studentUniId: _uniId!,
        year: year,
        month: month,
      );

      final respYear = (data['year'] is int)
          ? data['year'] as int
          : int.tryParse('${data['year']}') ?? year;

      final respMonth = (data['month'] is int)
          ? data['month'] as int
          : int.tryParse('${data['month']}') ?? month;

      final raw = Map<String, dynamic>.from(data['items_by_day'] ?? {});
      _itemsByDay.clear();

      raw.forEach((k, v) {
        String key;
        if (k.contains('-')) {
          key = k;
        } else {
          final d = int.tryParse(k) ?? 1;
          final mm = respMonth.toString().padLeft(2, '0');
          final dd = d.toString().padLeft(2, '0');
          key = '${respYear}-$mm-$dd';
        }
        final list = List<Map<String, dynamic>>.from(v as List);
        _itemsByDay[key] = list;
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _eventsOfDay(DateTime day) {
    final key = _ymd(day);
    return _itemsByDay[key] ?? const [];
  }

  String _ymd(DateTime d) {
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }

  void _openDueList(DateTime day) {
    final items = _eventsOfDay(day);
    if (items.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 5,
                  width: 45,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Text(
                  "Due on ${_ymd(day)}",
                  style: const TextStyle(
                    fontFamily: "Baloo",
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF7B1FA2),
                  ),
                ),
                const SizedBox(height: 16),

                /// ITEMS
                for (final it in items)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B1FA2).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.assignment_outlined,
                            color: Color(0xFF7B1FA2),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                it['title'] ?? 'Untitled',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF4A148C),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Points: ${it['points'] ?? 0}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: Color(0xFF7B1FA2))
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

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
            colors: [
              Color(0xFFF9F4FF),
              Color(0xFFFFF9FF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 90),

            /// 🔥 عنوان ثابت مثل باقي الصفحات
            const Text(
              "My Calendar",
              style: TextStyle(
                fontFamily: "Baloo",
                fontSize: 44,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7B1FA2),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7B1FA2),
                      ),
                    )
                  : _error != null
                      ? _ErrorView(
                          message: _error!,
                          onRetry: () =>
                              _loadMonth(_focusedDay.year, _focusedDay.month),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _legend(),
                            const SizedBox(height: 16),
                            _calendarCard(),
                            const SizedBox(height: 14),
                            _dayHint(),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _calendarCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.92),
            Colors.white.withOpacity(0.68),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: _buildCalendar(),
    );
  }

  Widget _legend() {
    return Row(
      children: [
        _dot(color: Colors.red),
        const SizedBox(width: 6),
        const Text('Due day'),
        const SizedBox(width: 18),
        _dot(color: Colors.green),
        const SizedBox(width: 6),
        const Text('No due'),
      ],
    );
  }

  Widget _dot({required Color color}) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _dayHint() {
    return const Text(
      'Tap on any red day to view due submissions.',
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.grey),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar<Map<String, dynamic>>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2035, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.month,
// ⛔️ إلغاء الأنيميشن نهائياً
      pageAnimationEnabled: true,
      pageAnimationDuration: Duration(milliseconds: 500),
      pageAnimationCurve: Curves.easeInOut,

      headerStyle: const HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
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
      eventLoader: (day) => _eventsOfDay(day),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, _) {
          final hasDue = _eventsOfDay(day).isNotEmpty;
          return _dayCell(day, hasDue);
        },
        todayBuilder: (context, day, _) {
          final hasDue = _eventsOfDay(day).isNotEmpty;
          return _dayCell(day, hasDue, isToday: true);
        },
        selectedBuilder: (context, day, _) {
          final hasDue = _eventsOfDay(day).isNotEmpty;
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
        ? const Color(0xFF7B1FA2).withOpacity(0.25)
        : hasDue
            ? Colors.red.withOpacity(0.15)
            : Colors.green.withOpacity(0.10);

    final borderColor = isToday
        ? const Color(0xFF7B1FA2)
        : hasDue
            ? Colors.red
            : Colors.transparent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: hasDue ? 1.3 : 1),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: const Color(0xFF7B1FA2).withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
              fontFamily: "Baloo",
              fontSize: 16,
              color: hasDue ? Colors.red.shade800 : const Color(0xFF4A148C),
            ),
          ),
          if (hasDue)
            Container(
              margin: const EdgeInsets.only(top: 3),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            )
        ],
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
      child: Padding(
        padding: const EdgeInsets.all(26.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 55, color: Colors.redAccent),
            const SizedBox(height: 10),
            const Text(
              'Failed to load calendar',
              style: TextStyle(
                fontFamily: "Baloo",
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B1FA2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

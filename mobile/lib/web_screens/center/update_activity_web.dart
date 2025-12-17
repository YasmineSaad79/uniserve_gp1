import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:mobile/models/activity.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/token_service.dart';


const Color primaryColor = Color.fromARGB(255, 145, 48, 129);
const Color bgSoft = Color(0xFFF4FAFA);

class UpdateActivityWeb extends StatefulWidget {
  final Activity activity;
  final VoidCallback onSuccess;

  const UpdateActivityWeb({
    super.key,
    required this.activity,
    required this.onSuccess,
  });

  @override
  State<UpdateActivityWeb> createState() => _UpdateActivityWebState();
}

class _UpdateActivityWebState extends State<UpdateActivityWeb> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _desc;
  late final TextEditingController _location;
  late final TextEditingController _createdBy;
  late final TextEditingController _status;

  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  int? _userId;

  bool _submitting = false;

Future<void> _loadUserId() async {
  final id = await TokenService.getUserId();
  if (id == null) return;

  setState(() {
    _userId = id;
    _createdBy.text = id.toString(); // ثابت
  });
}


  @override
  void initState() {
    super.initState();

    _title = TextEditingController(text: widget.activity.title);
    _desc = TextEditingController(text: widget.activity.description);
    _location = TextEditingController(text: widget.activity.location);
    _status = TextEditingController(text: widget.activity.status);

    _createdBy = TextEditingController(); // سيتم تعبئته لاحقًا

    _startDate = widget.activity.startDate;
    _startTime = TimeOfDay.fromDateTime(widget.activity.startDate);
    _endDate = widget.activity.endDate;
    _endTime = TimeOfDay.fromDateTime(widget.activity.endDate);

    _loadUserId();
  }


  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _location.dispose();
    _createdBy.dispose();
    _status.dispose();
    super.dispose();
  }

  // ===================================================
  // DATE & TIME
  // ===================================================

  Future<void> _pickDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      if (isStart) {
        _startDate = date;
        _startTime = time;
      } else {
        _endDate = date;
        _endTime = time;
      }
    });
  }

  // ===================================================
  // SUBMIT
  // ===================================================

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _startDate == null ||
        _startTime == null ||
        _endDate == null ||
        _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }

  
    final start = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final end = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    if (end.isBefore(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End date must be after start date")),
      );
      return;
    }

    try {
      setState(() => _submitting = true);

      await ApiService.updateActivityWithFiles(
        id: widget.activity.id,
        title: _title.text,
        description: _desc.text,
        location: _location.text,
        createdBy: _userId ?? widget.activity.createdBy,
        startDate: start.toIso8601String(),
        endDate: end.toIso8601String(),
        status: _status.text,
        imageFile: null,
        formFile: null,
      );


      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Activity updated successfully ✅")),
      );

      // ✅ رجوع ذكي للـ View Activities
      widget.onSuccess();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update error: $e")),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ===================================================
  // UI
  // ===================================================

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40), // مهم
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Update Activity #${widget.activity.id}",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),

            _card(
              Column(
                children: [
                  _field(_title, "Title"),
                  _field(_desc, "Description", maxLines: 3),
                  _field(_location, "Location"),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          _createdBy,
                          "Created By",
                          readOnly: true,
                          enableValidation: false,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _field(_status, "Status")),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _dateTile("Start Date & Time", true),
                  const SizedBox(height: 10),
                  _dateTile("End Date & Time", false),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Save Changes"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  // ===================================================
  // COMPONENTS
  // ===================================================

  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgSoft,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10),
        ],
      ),
      child: child,
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    int maxLines = 1,
    bool readOnly = false,
    bool enableValidation = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        readOnly: readOnly,
        validator: enableValidation
            ? (v) => v == null || v.isEmpty ? "Required" : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: readOnly ? Colors.grey[100] : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }


  Widget _dateTile(String label, bool isStart) {
    final date = isStart ? _startDate : _endDate;
    final time = isStart ? _startTime : _endTime;

    final text = date == null
        ? label
        : "${DateFormat('yyyy-MM-dd').format(date)}  ${time?.format(context)}";

    return InkWell(
      onTap: _submitting ? null : () => _pickDateTime(isStart),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: primaryColor),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}

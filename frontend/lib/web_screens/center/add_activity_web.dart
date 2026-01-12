import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/token_service.dart';

const Color purple1 = Color(0xFF7B1FA2);
const Color purple2 = Color(0xFFE16EFF);
const Color bgSoft = Color(0xFFF8F3FF);

class AddActivityWeb extends StatefulWidget {
  final VoidCallback onSuccess;

  const AddActivityWeb({
    super.key,
    required this.onSuccess,
  });

  @override
  State<AddActivityWeb> createState() => _AddActivityWebState();
}

class _AddActivityWebState extends State<AddActivityWeb> {
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _location = TextEditingController();
  final _createdBy = TextEditingController(); // 🔒 ثابت
  final _status = TextEditingController(text: "active");

  Uint8List? _imageBytes;
  String? _imageName;

  Uint8List? _pdfBytes;
  String? _pdfName;

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  int _step = 0;
  bool _submitting = false;

  int? _userId; // ✅ user_id الحقيقي

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  // ===================================================
  // LOAD USER ID (FROM LOGIN)
  // ===================================================

  Future<void> _loadUserId() async {
    final id = await TokenService.getUserId();
    if (id == null) return;

    setState(() {
      _userId = id;
      _createdBy.text = id.toString(); // تعبئة تلقائية
    });
  }

  // ===================================================
  // FILE PICKERS
  // ===================================================

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      setState(() {
        _imageBytes = result.files.single.bytes;
        _imageName = result.files.single.name;
      });
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _pdfBytes = result.files.single.bytes;
        _pdfName = result.files.single.name;
      });
    }
  }

  // ===================================================
  // DATE & TIME
  // ===================================================

  Future<void> _pickDateTime(bool isStart) async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
    );
    if (d == null) return;

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t == null) return;

    setState(() {
      if (isStart) {
        _startDate = d;
        _startTime = t;
      } else {
        _endDate = d;
        _endTime = t;
      }
    });
  }

  // ===================================================
  // SUBMIT
  // ===================================================

  Future<void> _submit() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not authenticated")),
      );
      return;
    }

    if (!_formKey.currentState!.validate() ||
        _imageBytes == null ||
        _startDate == null ||
        _endDate == null ||
        _startTime == null ||
        _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all required fields")),
      );
      return;
    }

    final start = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    ).toIso8601String();

    final end = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    ).toIso8601String();

    try {
      setState(() => _submitting = true);

      await ApiService.addActivityWeb(
        title: _title.text,
        description: _desc.text,
        location: _location.text,
        createdBy: _userId!, // ✅ من التوكن فقط
        startDate: start,
        endDate: end,
        status: _status.text,
        imageBytes: _imageBytes!,
        imageName: _imageName!,
        pdfBytes: _pdfBytes,
        pdfName: _pdfName,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Activity added successfully 🎉")),
      );

      widget.onSuccess();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Create New Activity",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: purple1,
            ),
          ),
          const SizedBox(height: 20),

          _stepHeader(),
          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              child: _stepContent(),
            ),
          ),

          const SizedBox(height: 20),
          _bottomBar(),
        ],
      ),
    );
  }

  // ===================================================
  // STEPS
  // ===================================================

  Widget _stepHeader() {
    final labels = ["Details", "Media", "Schedule"];
    return Row(
      children: List.generate(3, (i) {
        final active = i == _step;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? purple1 : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                labels[i],
                style: TextStyle(
                  color: active ? Colors.white : purple1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _stepContent() {
    switch (_step) {
      case 0:
        return _detailsStep();
      case 1:
        return _mediaStep();
      default:
        return _scheduleStep();
    }
  }

  Widget _detailsStep() {
    return _card(
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
                  "Created By (ID)",
                  readOnly: true, // 🔒
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _field(_status, "Status")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mediaStep() {
    return _card(
      Column(
        children: [
          _uploadTile(
            label: _imageName ?? "Upload Activity Image",
            icon: Icons.image,
            onTap: _pickImage,
          ),
          const SizedBox(height: 12),
          _uploadTile(
            label: _pdfName ?? "Upload PDF Form (optional)",
            icon: Icons.picture_as_pdf,
            onTap: _pickPdf,
          ),
        ],
      ),
    );
  }

  Widget _scheduleStep() {
    return _card(
      Column(
        children: [
          _dateTile("Start Date & Time", true),
          const SizedBox(height: 10),
          _dateTile("End Date & Time", false),
        ],
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 12),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        readOnly: readOnly,
        validator: readOnly ? null : (v) => v == null || v.isEmpty ? "Required" : null,
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

  Widget _uploadTile({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: purple1),
            const SizedBox(width: 12),
            Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
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

    return _uploadTile(
      label: text,
      icon: Icons.calendar_today,
      onTap: () => _pickDateTime(isStart),
    );
  }

  Widget _bottomBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_step > 0)
          TextButton(
            onPressed: () => setState(() => _step--),
            child: const Text("Back"),
          ),
        ElevatedButton(
          onPressed: _submitting
              ? null
              : () {
                  if (_step < 2) {
                    setState(() => _step++);
                  } else {
                    _submit();
                  }
                },
          style: ElevatedButton.styleFrom(backgroundColor: purple1),
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_step == 2 ? "Publish" : "Next"),
        ),
      ],
    );
  }
}

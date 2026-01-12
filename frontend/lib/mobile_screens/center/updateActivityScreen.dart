import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/activity.dart';
import '../../services/api_service.dart';

class UpdateActivityScreen extends StatefulWidget {
  final Activity activity;
  const UpdateActivityScreen({super.key, required this.activity});

  @override
  State<UpdateActivityScreen> createState() => _UpdateActivityScreenState();
}

class _UpdateActivityScreenState extends State<UpdateActivityScreen> {
  final Color primaryColor = const Color(0xFF2563EB);

  final _formKey = GlobalKey<FormState>();
  File? _imageFile;

  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _createdByController;
  late final TextEditingController _statusController;

  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    _titleController = TextEditingController(text: widget.activity.title);
    _descriptionController =
        TextEditingController(text: widget.activity.description);
    _locationController = TextEditingController(text: widget.activity.location);
    _createdByController =
        TextEditingController(text: widget.activity.createdBy.toString());
    _statusController = TextEditingController(text: widget.activity.status);

    _startDate = widget.activity.startDate;
    _startTime = TimeOfDay.fromDateTime(widget.activity.startDate);
    _endDate = widget.activity.endDate;
    _endTime = TimeOfDay.fromDateTime(widget.activity.endDate);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _createdByController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF2FF),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Update Activity',
          style: TextStyle(
            fontFamily: "Baloo",
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFEAF2FF),
                  Color(0xFFD6E6FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _glassCard(
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _imageSection(),
                      _field(_titleController, 'Title'),
                      _field(_descriptionController, 'Description',
                          maxLines: 2),
                      _field(_locationController, 'Location'),
                      _field(_statusController, 'Status'),
                      const SizedBox(height: 8),
                      _dateTimeRow(true),
                      const SizedBox(height: 8),
                      _dateTimeRow(false),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submitUpdate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Save',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== Helpers =====================

  Widget _imageSection() {
    final hasImage =
        _imageFile != null || (widget.activity.imageUrl?.isNotEmpty ?? false);

    return Column(
      children: [
        const Text(
          'Activity Image',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: hasImage
              ? Image(
                  image: _imageFile != null
                      ? FileImage(_imageFile!)
                      : NetworkImage(
                          _resolveImageUrl(widget.activity.imageUrl!),
                        ) as ImageProvider,
                  fit: BoxFit.contain,
                )
              : const Icon(Icons.image, size: 36),
        ),
        TextButton(
          onPressed: _pickImage,
          child: const Text('Change activity image'),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  String _resolveImageUrl(String path) {
    if (path.startsWith('http')) return path;
    if (!path.startsWith('/')) path = '/$path';
    return 'http://10.0.2.2:5000$path';
  }

  Widget _glassCard(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.8)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              )),
          const SizedBox(height: 4),
          TextFormField(
            controller: c,
            maxLines: maxLines,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ApiService.updateActivityWithFiles(
        id: widget.activity.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        createdBy: widget.activity.createdBy,
        status: _statusController.text.trim(),
        startDate: _combineDateTime(_startDate!, _startTime!).toIso8601String(),
        endDate: _combineDateTime(_endDate!, _endTime!).toIso8601String(),
        imageFile: _imageFile,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activity updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _dateTimeRow(bool isStart) {
    final date = isStart ? _startDate : _endDate;
    final time = isStart ? _startTime : _endTime;

    return Row(
      children: [
        Expanded(
          child: _chip(
            Icons.calendar_today,
            DateFormat('yyyy-MM-dd').format(date!),
            () => _selectDateTime(context, isStart),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _chip(
            Icons.access_time,
            time!.format(context),
            () => _selectDateTime(context, isStart),
          ),
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: primaryColor),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate! : _endDate!,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: isStart ? _startTime! : _endTime!,
      );

      if (pickedTime != null) {
        setState(() {
          if (isStart) {
            _startDate = pickedDate;
            _startTime = pickedTime;
          } else {
            _endDate = pickedDate;
            _endTime = pickedTime;
          }
        });
      }
    }
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
}

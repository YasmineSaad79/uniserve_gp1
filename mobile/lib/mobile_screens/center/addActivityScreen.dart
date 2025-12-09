// file: lib/screens/add_activity_screen.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile/mobile_screens/center/viewActivitiesScreen.dart';
import 'package:mobile/services/api_service.dart';

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  // ألوان الثيم الجديدة (بنفسجي فاخر)
  final Color primaryColor = const Color(0xFF7B1FA2);
  final Color secondaryColor = const Color(0xFFE16EFF);
  final Color bgSoft = const Color(0xFFF8F3FF);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _createdByController = TextEditingController();
  final TextEditingController _statusController =
      TextEditingController(text: 'Active');

  File? _imageFile;
  Uint8List? _imageBytes;
  File? _formFile; // PDF

  final ImagePicker _picker = ImagePicker();

  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  // stepper
  int _currentStep = 0; // 0: info, 1: media, 2: schedule

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _createdByController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  // ---------------------------- اختيار الصورة ----------------------------
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final cropped = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          compressQuality: 90,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Adjust your photo',
              toolbarColor: primaryColor,
              toolbarWidgetColor: Colors.white,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Adjust your photo',
              aspectRatioLockEnabled: true,
            ),
          ],
        );

        if (cropped != null) {
          setState(() {
            _imageFile = File(cropped.path);
            _imageBytes = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking or cropping image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking or cropping image: $e')),
      );
    }
  }

  // ---------------------------- اختيار ملف PDF ----------------------------
  Future<void> _pickFormFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _formFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      debugPrint('Error picking PDF file: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking PDF file: $e')),
      );
    }
  }

  // ---------------------------- اختيار التاريخ والوقت ----------------------------
  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final DateTime initialDate = DateTime.now();
    final TimeOfDay initialTime = TimeOfDay.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate:
          isStart ? (_startDate ?? initialDate) : (_endDate ?? initialDate),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime:
            isStart ? (_startTime ?? initialTime) : (_endTime ?? initialTime),
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

  // ---------------------------- إرسال البيانات ----------------------------
  void _submitActivity() async {
    final hasImage = kIsWeb ? (_imageBytes != null) : (_imageFile != null);

    if (_formKey.currentState!.validate() &&
        _startDate != null &&
        _endDate != null &&
        _startTime != null &&
        _endTime != null &&
        hasImage) {
      final startDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      ).toIso8601String();

      final endDateTime = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      ).toIso8601String();

      try {
        if (!kIsWeb && _imageFile != null) {
          await ApiService.addActivityWithFiles(
            title: _titleController.text,
            description: _descriptionController.text,
            location: _locationController.text,
            createdBy: int.tryParse(_createdByController.text) ?? 1,
            startDate: startDateTime,
            endDate: endDateTime,
            status: _statusController.text,
            imageFile: _imageFile!,
            formFile: _formFile,
          );
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity added successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission Error: $e')),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please fill all fields, select date/time, and upload image & form.'),
        ),
      );
    }
  }

  void _cancel() {
    Navigator.pop(context);
  }

  // ---------------------------- Stepper Actions ----------------------------
  void _goNextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _submitActivity();
    }
  }

  void _goPreviousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  // ---------------------------- واجهة الشاشة ----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Padding(
          padding: const EdgeInsets.only(top: 20), // ← نزّلتي العنوان
          child: const Text(
            'Create New Activity',
            style: TextStyle(
              fontFamily: 'Baloo',
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // خلفية Gradient + Blobs
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFB57DFF), // Lavender Purple — أفتح
                  Color(0xFFFAF7EF), // Warm cream,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -60,
            child: _softBlob(180, Colors.white.withOpacity(0.30)),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: _softBlob(200, Colors.white.withOpacity(0.2)),
          ),

          // المحتوى
          SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildHeaderCard(),
                  const SizedBox(height: 12),
                  _buildStepperHeader(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeIn,
                        child: _buildStepContent(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // شريط الإجراءات السفلي
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomActionBar(),
          ),
        ],
      ),
    );
  }

  // ---------------------------- Components ----------------------------

  Widget _softBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 40,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.white, bgSoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.volunteer_activism,
                color: primaryColor,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'New Community Service',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create a new volunteering opportunity. Add details, media, and schedule in 3 simple steps.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    final steps = [
      'Details',
      'Media',
      'Schedule',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: List.generate(3, (index) {
          final bool isActive = index == _currentStep;
          final bool isDone = index < _currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white
                    : Colors.white.withOpacity(isDone ? 0.30 : 0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isDone
                        ? Colors.green
                        : (isActive ? primaryColor : Colors.white24),
                    child: isDone
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isActive ? Colors.white : Colors.white70,
                            ),
                          ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    steps[index],
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? primaryColor : Colors.white,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStepDetails();
      case 1:
        return _buildStepMedia();
      case 2:
      default:
        return _buildStepSchedule();
    }
  }

  // --------- Step 1: Basic info ----------
  Widget _buildStepDetails() {
    return Container(
      key: const ValueKey('step-details'),
      decoration: BoxDecoration(
        color: bgSoft,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Basic Information'),
          const SizedBox(height: 8),
          _buildTextField(
            _titleController,
            'Title',
            'Please enter the activity title',
          ),
          _buildTextField(
            _descriptionController,
            'Description',
            'Please enter the activity description',
            maxLines: 3,
          ),
          _buildTextField(
            _locationController,
            'Location',
            'Please enter the activity location',
          ),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  _createdByController,
                  'Created by (User ID)',
                  'Please enter the responsible user ID',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  _statusController,
                  'Status',
                  'Please enter the status',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ViewActivitiesScreen(),
                  ),
                );
              },
              icon: Icon(Icons.list_alt, color: primaryColor, size: 18),
              label: Text(
                'View existing activities',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // --------- Step 2: Media ----------
  Widget _buildStepMedia() {
    final imageIsSelected =
        kIsWeb ? (_imageBytes != null) : (_imageFile != null);

    return Container(
      key: const ValueKey('step-media'),
      decoration: BoxDecoration(
        color: bgSoft,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Media & Documents'),
          const SizedBox(height: 12),

          // صورة
          const Text(
            'Activity Image',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.white.withOpacity(0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            padding: const EdgeInsets.all(10),
            child: !imageIsSelected
                ? SizedBox(
                    height: 120,
                    child: Center(
                      child: TextButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(
                          Icons.cloud_upload_rounded,
                          color: primaryColor,
                          size: 28,
                        ),
                        label: Text(
                          'Upload Activity Image',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: kIsWeb
                            ? Image.memory(
                                _imageBytes!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                height: 220,
                              )
                            : Image.file(
                                _imageFile!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                height: 220,
                              ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: primaryColor,
                                  size: 20,
                                ),
                                onPressed: _pickImage,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _imageFile = null;
                                    _imageBytes = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 18),

          // PDF
          const Text(
            'Service Form (PDF)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _formFile == null
                ? SizedBox(
                    height: 90,
                    child: Center(
                      child: TextButton.icon(
                        onPressed: _pickFormFile,
                        icon: Icon(
                          Icons.picture_as_pdf,
                          color: primaryColor,
                          size: 26,
                        ),
                        label: Text(
                          'Upload PDF Form',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                : ListTile(
                    leading: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                      size: 30,
                    ),
                    title: Text(
                      _formFile!.path.split('/').last,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: const Text(
                      'Tap the X icon to remove or upload another file.',
                      style: TextStyle(fontSize: 11),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => setState(() => _formFile = null),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --------- Step 3: Schedule ----------
  Widget _buildStepSchedule() {
    final dateTextStart = _startDate == null
        ? 'Select start date'
        : DateFormat('yyyy-MM-dd').format(_startDate!);
    final timeTextStart =
        _startTime == null ? 'Select time' : _startTime!.format(context);

    final dateTextEnd = _endDate == null
        ? 'Select end date'
        : DateFormat('yyyy-MM-dd').format(_endDate!);
    final timeTextEnd =
        _endTime == null ? 'Select time' : _endTime!.format(context);

    return Container(
      key: const ValueKey('step-schedule'),
      decoration: BoxDecoration(
        color: bgSoft,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Schedule & Timing'),
          const SizedBox(height: 12),
          const Text(
            'Start Date & Time',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _glassPickerCard(
                  icon: Icons.calendar_today,
                  label: dateTextStart,
                  onTap: () => _selectDateTime(context, true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _glassPickerCard(
                  icon: Icons.access_time,
                  label: timeTextStart,
                  onTap: () => _selectDateTime(context, true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'End Date & Time',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _glassPickerCard(
                  icon: Icons.calendar_today,
                  label: dateTextEnd,
                  onTap: () => _selectDateTime(context, false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _glassPickerCard(
                  icon: Icons.access_time,
                  label: timeTextEnd,
                  onTap: () => _selectDateTime(context, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Summary',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summaryRow(
                    'Title',
                    _titleController.text.isEmpty
                        ? 'Not set yet'
                        : _titleController.text),
                _summaryRow(
                    'Location',
                    _locationController.text.isEmpty
                        ? 'Not set yet'
                        : _locationController.text),
                _summaryRow('Status', _statusController.text),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        color: primaryColor,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassPickerCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade300),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ---------------------------- Bottom Bar ----------------------------
  Widget _buildBottomActionBar() {
    final isLast = _currentStep == 2;
    final buttonLabel = isLast ? 'Publish Activity' : 'Next Step';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.28),
              ),
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  IconButton(
                    onPressed: _goPreviousStep,
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.purple),
                  )
                else
                  IconButton(
                    onPressed: _cancel,
                    icon: const Icon(Icons.close, color: Colors.purple),
                  ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLast
                            ? 'Almost done!'
                            : 'Step ${_currentStep + 1} of 3',
                        style: const TextStyle(
                          color: Colors.purple,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: (_currentStep + 1) / 3,
                        backgroundColor: Colors.purple.withOpacity(0.25),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _goNextStep,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: primaryColor,
                    elevation: 0,
                  ),
                  child: Row(
                    children: [
                      Text(
                        buttonLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isLast
                            ? Icons.check_circle_rounded
                            : Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------- Inputs ----------------------------
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String validationMsg, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: primaryColor.withOpacity(0.7),
            fontSize: 13,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 1.6),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return validationMsg;
          }
          return null;
        },
      ),
    );
  }
}

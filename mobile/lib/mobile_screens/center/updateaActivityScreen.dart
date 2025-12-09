import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/activity.dart';
// 🆕 استيراد ApiService
import '../../services/api_service.dart';

class UpdateActivityScreen extends StatefulWidget {
  // استقبال بيانات النشاط المراد تعديله عبر constructor
  final Activity activity;

  const UpdateActivityScreen({super.key, required this.activity});
  @override
  State<UpdateActivityScreen> createState() => _UpdateActivityScreenState();
}

class _UpdateActivityScreenState extends State<UpdateActivityScreen> {
  // Required Color: 0xFF064F54 (Dark Teal/Green)
  final Color primaryColor = const Color(0xFF064F54);

  // Form Key for validation
  final _formKey = GlobalKey<FormState>();

  // Controllers for input fields
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _createdByController;
  late final TextEditingController _statusController;

  // For Date and Time fields
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  // 🆕 حالة تحميل لمنع النقر المتعدد أثناء إرسال البيانات
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // تهيئة المتحكمات بالقيم الحالية
    _titleController = TextEditingController(text: widget.activity.title);
    _descriptionController =
        TextEditingController(text: widget.activity.description);
    _locationController = TextEditingController(text: widget.activity.location);
    _createdByController =
        TextEditingController(text: widget.activity.createdBy.toString());
    _statusController = TextEditingController(text: widget.activity.status);

    // تهيئة حقول التاريخ والوقت
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

  // Function to select Date and Time
  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final DateTime initialDate = DateTime.now();
    final TimeOfDay initialTime = TimeOfDay.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate:
          isStart ? (_startDate ?? initialDate) : (_endDate ?? initialDate),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor, // لون الرأس
              onPrimary: Colors.white, // لون النص في الرأس
              onSurface: primaryColor, // لون النص على الخلفية
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor, // لون الأزرار (Cancel/OK)
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime:
            isStart ? (_startTime ?? initialTime) : (_endTime ?? initialTime),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
                colorScheme: ColorScheme.light(
                  primary: primaryColor,
                  onPrimary: Colors.white,
                  surface: Colors.grey[200]!,
                  onSurface: Colors.black,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                  ),
                )),
            child: child!,
          );
        },
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

  // Function to submit data (Update operation)
  void _submitUpdate() async {
    // Check validation and ensure dates are selected
    if (_formKey.currentState!.validate() &&
        _startDate != null &&
        _endDate != null &&
        _startTime != null &&
        _endTime != null) {
      // Combine date and time into DateTime objects
      final fullStartDateTime = DateTime(_startDate!.year, _startDate!.month,
          _startDate!.day, _startTime!.hour, _startTime!.minute);
      final fullEndDateTime = DateTime(_endDate!.year, _endDate!.month,
          _endDate!.day, _endTime!.hour, _endTime!.minute);

      // Simple validation: End date must be after Start date
      if (fullEndDateTime.isBefore(fullStartDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('End Date/Time must be after Start Date/Time.')),
        );
        return;
      }

      // Prepare data for API (ISO 8601 String)
      final startDateTimeIso = fullStartDateTime.toIso8601String();
      final endDateTimeIso = fullEndDateTime.toIso8601String();

      // 🆕 تفعيل حالة التحميل
      setState(() {
        _isLoading = true;
      });

      try {
        // 🚀 استدعاء دالة التحديث الحقيقية
        await ApiService.updateActivityWithFiles(
          id: widget.activity.id,
          title: _titleController.text,
          description: _descriptionController.text,
          location: _locationController.text,
          createdBy: int.tryParse(_createdByController.text) ??
              widget.activity.createdBy,
          startDate: startDateTimeIso,
          endDate: endDateTimeIso,
          status: _statusController.text,
          imageFile: null,
          formFile: null,
        );

        // ✅ عند النجاح
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Activity ${widget.activity.id} updated successfully!')),
        );
        // العودة إلى الشاشة السابقة وتمرير نتيجة لـ "إعادة التحميل"
        Navigator.pop(context, true);
      } catch (e) {
        // ❌ عند فشل الاتصال أو خطأ الخادم
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Update Error: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      } finally {
        // 🆕 إيقاف حالة التحميل
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please fill all required fields and select the date and time.')),
      );
    }
  }

  // Cancel function
  void _cancel() {
    Navigator.pop(context); // Go back to the previous screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar with the new dark color
      appBar: AppBar(
        title: Text('Update Activity ID: ${widget.activity.id}'),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Title Field
              _buildTextField(
                  _titleController, 'Title', 'Please enter the activity title'),
              // Description Field
              _buildTextField(_descriptionController, 'Description',
                  'Please enter the activity description',
                  maxLines: 3),
              // Location Field
              _buildTextField(_locationController, 'Location',
                  'Please enter the activity location'),
              // Created By (ID) Field
              _buildTextField(_createdByController, 'Created By (User ID)',
                  'Please enter the responsible user ID',
                  keyboardType: TextInputType.number, readOnly: true),

              // Date and Time Field
              const SizedBox(height: 15),
              _buildDateTimeRow(context, true, 'Start Date and Time'),
              const SizedBox(height: 15),
              _buildDateTimeRow(context, false, 'End Date and Time'),
              const SizedBox(height: 15),

              // Status Field
              _buildTextField(_statusController, 'Status',
                  'Please enter the activity status (e.g., Active, Completed)'),

              const SizedBox(height: 30),

              // Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel Button
                  TextButton(
                    onPressed:
                        _isLoading ? null : _cancel, // تعطيل الزر أثناء التحميل
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: primaryColor, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Save Button with the new color
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : _submitUpdate, // تعطيل الزر أثناء التحميل
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to build text fields
  Widget _buildTextField(
      TextEditingController controller, String label, String validationMsg,
      {int maxLines = 1,
      TextInputType keyboardType = TextInputType.text,
      bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly, // إضافة خاصية readOnly
        decoration: InputDecoration(
          labelText: label,
          fillColor: readOnly
              ? Colors.grey[100]
              : Colors.white, // لون خلفية رمادي إذا كان للقراءة فقط
          filled: true,
          border: const OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryColor, width: 2.0),
          ),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return validationMsg;
          }
          return null;
        },
      ),
    );
  }

  // Helper function to build date and time selection row
  Widget _buildDateTimeRow(BuildContext context, bool isStart, String label) {
    final date = isStart ? _startDate : _endDate;
    final time = isStart ? _startTime : _endTime;

    String dateText =
        date == null ? 'Select Date' : DateFormat('yyyy-MM-dd').format(date);
    String timeText = time == null ? 'Select Time' : time.format(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 5),
        Row(
          children: <Widget>[
            // Date Selection
            Expanded(
              child: OutlinedButton.icon(
                // استخدام OutlinedButton ليتناسب مع التصميم
                onPressed: _isLoading
                    ? null
                    : () => _selectDateTime(
                        context, isStart), // تعطيل أثناء التحميل
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(dateText,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Time Selection
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => _selectDateTime(
                        context, isStart), // تعطيل أثناء التحميل
                icon: const Icon(Icons.access_time, size: 18),
                label: Text(timeText,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
        // Conditional validation message (check if date/time are still null)
        if ((isStart && (_startDate == null || _startTime == null)) ||
            (!isStart && (_endDate == null || _endTime == null)))
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 12.0),
            child: Text(
              'Please select both date and time.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

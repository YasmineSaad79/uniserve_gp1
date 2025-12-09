// file: lib/models/activity.dart

class Activity {
  final int id;
  final String title;
  final String description;
  final String location;
  final int createdBy;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String imageUrl;
  final String? formTemplatePath; // 🟢 أضفنا هذا السطر

  Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.createdBy,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl = 'uploads/default.jpg',
    this.formTemplatePath, // 🟢 أضفنا هذا
  });

  // مصنع (Factory) لتحويل JSON إلى كائن Activity
  factory Activity.fromJson(Map<String, dynamic> json) {
    // ✅ دالة آمنة لقراءة الأرقام الصحيحة (int)
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // ✅ دالة آمنة لقراءة التاريخ والوقت (DateTime)
    DateTime safeDateTimeParse(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    // ✅ دالة آمنة لقراءة النصوص (String)
    String safeString(dynamic value,
        {String defaultValue = 'uploads/default.jpg'}) {
      if (value == null || value.toString().isEmpty) return defaultValue;

      String path = value.toString();

      final startIndex = path.indexOf('uploads/');
      if (startIndex != -1) {
        return path.substring(startIndex);
      }

      return path;
    }

    return Activity(
      id: safeInt(json['service_id'] ?? json['id']),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      createdBy: safeInt(json['created_by']),
      startDate: safeDateTimeParse(json['start_date']),
      endDate: safeDateTimeParse(json['end_date']),
      status: json['status'] ?? 'pending',
      createdAt: safeDateTimeParse(json['created_at']),
      updatedAt: safeDateTimeParse(json['updated_at']),
      imageUrl: safeString(json['image_url']),
      formTemplatePath: json['form_template_path'], // 🟢 أضفناها هنا
    );
  }
}

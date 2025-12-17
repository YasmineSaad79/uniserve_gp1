import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/services/api_service.dart';

class StudentEditProfileWeb extends StatefulWidget {
  final String studentId;
  final String fullName;
  final String email;
  final String? photoUrl;

  const StudentEditProfileWeb({
    super.key,
    required this.studentId,
    required this.fullName,
    required this.email,
    this.photoUrl,
  });

  @override
  State<StudentEditProfileWeb> createState() => _StudentEditProfileWebState();
}

class _StudentEditProfileWebState extends State<StudentEditProfileWeb> {
  static const String serverIP = "localhost";

  // Controllers
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final preferencesController = TextEditingController();
  final hobbiesController = TextEditingController();

  Uint8List? _imageBytes;
  String? networkPhotoUrl;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ================= LOAD PROFILE =================
  Future<void> _loadProfile() async {
    final token = await ApiService.getAuthToken();
    if (token == null) return;

    final url =
        Uri.parse("http://$serverIP:5000/api/student/profile/${widget.studentId}");

    final response = await http.get(url, headers: {
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        fullNameController.text = data["full_name"] ?? "";
        phoneController.text = data["phone_number"] ?? "";
        preferencesController.text = data["preferences"] ?? "";
        hobbiesController.text = data["hobbies"] ?? "";

        final p = data["photo_url"];
        if (p != null && p.isNotEmpty) {
          networkPhotoUrl = "http://$serverIP:5000$p";
        }
      });
    }
  }

  // ================= PICK IMAGE =================
  Future<void> pickImageWeb() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  // ================= SAVE PROFILE =================
  Future<void> saveProfile() async {
    setState(() => isSaving = true);

    final token = await ApiService.getAuthToken();
    if (token == null) return;

    final url =
        Uri.parse("http://$serverIP:5000/api/student/profile/${widget.studentId}");

    final request = http.MultipartRequest("PUT", url)
      ..headers["Authorization"] = "Bearer $token"
      ..fields["student_id"] = widget.studentId
      ..fields["full_name"] = fullNameController.text
      ..fields["email"] = widget.email
      ..fields["phone_number"] = phoneController.text
      ..fields["preferences"] = preferencesController.text
      ..fields["hobbies"] = hobbiesController.text;

    if (_imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          "photo",
          _imageBytes!,
          filename: "profile.jpg",
        ),
      );
    }

    final response = await request.send();
    setState(() => isSaving = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating profile (${response.statusCode})"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7B1FA2);

    ImageProvider? avatarImage;
    if (_imageBytes != null) {
      avatarImage = MemoryImage(_imageBytes!);
    } else if (networkPhotoUrl != null) {
      avatarImage = NetworkImage(networkPhotoUrl!);
    }

    return Padding(
      padding: const EdgeInsets.all(30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= LEFT CARD =================
          Container(
            width: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black12,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundColor: purple.withOpacity(0.15),
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? const Icon(Icons.person,
                          size: 70, color: purple)
                      : null,
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: pickImageWeb,
                  icon: const Icon(Icons.upload, color: Colors.white),
                  label: const Text("Change Photo"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 30),

          // ================= RIGHT FORM (FIXED) =================
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 10,
                      color: Colors.black12,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Edit Profile",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: purple,
                      ),
                    ),
                    const SizedBox(height: 25),

                    _field("Full Name", fullNameController),
                    _field("Phone Number", phoneController),
                    _field("Preferences", preferencesController),
                    _field("Hobbies", hobbiesController),

                    const SizedBox(height: 20),

                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: purple,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 28),
                        ),
                        child: isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                "Save Changes",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String title, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          )
        ],
      ),
    );
  }
}

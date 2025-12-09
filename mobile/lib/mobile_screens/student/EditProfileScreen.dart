import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../shared/changePasswordScreen.dart';
import '/services/api_service.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:ui';

class StudentProfileScreen extends StatefulWidget {
  final String studentId;
  final String email;
  final Function()? onProfileUpdated;

  const StudentProfileScreen({
    super.key,
    required this.studentId,
    required this.email,
    this.onProfileUpdated,
  });

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

const Color uniPurple = Color(0xFF7B1FA2);

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  File? _imageFile;
  String? networkPhotoUrl;

  bool isEditing = false;

  final ImagePicker _picker = ImagePicker();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController preferencesController = TextEditingController();
  final TextEditingController hobbiesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final response = await ApiService.fetchStudentProfile(widget.studentId);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        fullNameController.text = data['full_name'] ?? '';
        emailController.text = data['email'] ?? '';
        phoneController.text = data['phone_number'] ?? '';
        preferencesController.text = data['preferences'] ?? '';
        hobbiesController.text = data['hobbies'] ?? '';

        final serverPhoto = data['photo_url'];
        if (serverPhoto != null && serverPhoto.isNotEmpty) {
          networkPhotoUrl =
              "http://10.0.2.2:5000$serverPhoto?t=${DateTime.now().millisecondsSinceEpoch}";
        }
      });
    }
  }

  Future<void> updateProfile() async {
    final response = await ApiService.updateStudentProfile(
      studentId: widget.studentId,
      fullName: fullNameController.text,
      email: emailController.text,
      phone: phoneController.text,
      preferences: preferencesController.text,
      hobbies: hobbiesController.text,
      imageFile: _imageFile,
    );

    if (response.statusCode == 200) {
      await fetchProfile();
      setState(() => isEditing = false);
      widget.onProfileUpdated?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully ✅')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.body}')),
      );
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked != null) {
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Adjust your photo',
            toolbarColor: Colors.deepPurple,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Adjust your photo'),
        ],
      );

      if (cropped != null) {
        setState(() => _imageFile = File(cropped.path));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: uniPurple, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEEDAFB), Color(0xFFF5E8FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Text(
              isEditing ? "Edit Profile" : "Student Profile",
              style: const TextStyle(
                fontFamily: "Baloo",
                fontSize: 44,
                fontWeight: FontWeight.w700,
                color: uniPurple,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: _glassCard(
                  child: Column(
                    children: [
                      _profilePhoto(),
                      const SizedBox(height: 10),

                      /// ONLY SHOW TITLE IN VIEW MODE
                      if (!isEditing)
                        Column(
                          children: const [
                            Text(
                              "Personal Information",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A148C),
                              ),
                            ),
                            SizedBox(height: 10),
                          ],
                        ),

                      /// VIEW MODE (card)
                      if (!isEditing) _viewCard(),

                      /// EDIT MODE (fields only)
                      if (isEditing) ...[
                        const SizedBox(height: 12),
                        _editField("Full Name", fullNameController),
                        const SizedBox(height: 16),
                        Opacity(
                          opacity: 0.5,
                          child: IgnorePointer(
                            child: _editField(
                                "Email (not editable)", emailController),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _editField("Phone Number", phoneController),
                        const SizedBox(height: 16),
                        _editField("Preferences", preferencesController),
                        const SizedBox(height: 16),
                        _editField("Hobbies", hobbiesController),
                        const SizedBox(height: 12),
                      ],

                      const SizedBox(height: 20),
                      _actionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// VIEW MODE CARD
  Widget _viewCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: uniPurple.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: uniPurple.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _bioRow(Icons.person, "Full Name", fullNameController.text),
          _bioRow(Icons.mail, "Email", emailController.text),
          _bioRow(Icons.phone, "Phone Number", phoneController.text),
          _bioRow(
              Icons.favorite_border, "Preferences", preferencesController.text),
          _bioRow(Icons.star_border, "Hobbies", hobbiesController.text),
        ],
      ),
    );
  }

  /// EDIT TEXT FIELD
  Widget _editField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  /// PROFILE PHOTO
  Widget _profilePhoto() {
    return Column(
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: uniPurple, width: 4),
            image: DecorationImage(
              image: _imageFile != null
                  ? FileImage(_imageFile!)
                  : (networkPhotoUrl != null
                          ? NetworkImage(networkPhotoUrl!)
                          : const AssetImage("assets/images/default.png"))
                      as ImageProvider<Object>,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (isEditing)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _smallButton(
                  "Gallery", Icons.photo, () => pickImage(ImageSource.gallery)),
              const SizedBox(width: 12),
              _smallButton("Camera", Icons.camera_alt,
                  () => pickImage(ImageSource.camera)),
            ],
          ),
      ],
    );
  }

  /// BIO ROW
  Widget _bioRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: uniPurple, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: uniPurple,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : "Not provided",
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// SMALL BUTTON
  Widget _smallButton(String text, IconData icon, Function() onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: uniPurple),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: uniPurple,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// ACTION BUTTONS
  Widget _actionButtons() {
    if (isEditing) {
      return ElevatedButton(
        onPressed: updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: uniPurple,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          "Save Changes",
          style: TextStyle(
            color: Colors.white,
            fontFamily: "Baloo",
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangePasswordScreen(email: widget.email),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              "Update Password",
              style: TextStyle(fontFamily: "Baloo"),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => setState(() => isEditing = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: uniPurple,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              "Edit Profile",
              style: TextStyle(color: Colors.white, fontFamily: "Baloo"),
            ),
          ),
        ),
      ],
    );
  }

  /// GLASS CARD
  Widget _glassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.85),
            Colors.white.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: child,
          ),
        ),
      ),
    );
  }
}

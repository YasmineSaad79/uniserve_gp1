// File: lib/screens/center/service_profile_screen.dart

import 'dart:convert';
import 'dart:ui';
import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:mobile/web_screens/center/change_password_service_screen.dart';
import '/services/api_service.dart';

const Color uniPurple = Color(0xFF7B1FA2);

class ServiceProfileScreen extends StatefulWidget {
  final String email;
  final Function()? onProfileUpdated;

  const ServiceProfileScreen({
    super.key,
    required this.email,
    this.onProfileUpdated,
  });

  @override
  State<ServiceProfileScreen> createState() => _ServiceProfileScreenState();
}

class _ServiceProfileScreenState extends State<ServiceProfileScreen> {
  File? _imageFile;
  String? networkPhotoUrl;

  bool isEditing = false;
  bool _loading = true;

  final ImagePicker _picker = ImagePicker();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController roleController = TextEditingController();

  // 🌍 server حسب المنصة
  String get serverIP => kIsWeb ? "localhost" : "10.0.2.2";

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  // =====================================================
  // FETCH PROFILE
  // =====================================================
  Future<void> fetchProfile() async {
    try {
      final url = Uri.parse("http://$serverIP:5000/api/service/profile");
      final response = await ApiService.authGet(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)["profile"];

        setState(() {
          fullNameController.text = data["full_name"] ?? '';
          emailController.text = data["email"] ?? '';
          roleController.text = data["role"] ?? '';

          final serverPhoto = data["photo_url"];
          if (serverPhoto != null && serverPhoto.isNotEmpty) {
            networkPhotoUrl =
                "http://$serverIP:5000$serverPhoto?t=${DateTime.now().millisecondsSinceEpoch}";
          }

          _loading = false;
        });
      } else {
        _loading = false;
      }
    } catch (_) {
      _loading = false;
    }
  }

  // =====================================================
  // UPDATE PROFILE
  // =====================================================
  Future<void> updateProfile() async {
    final url = Uri.parse("http://$serverIP:5000/api/service/profile");

    final response = await ApiService.authMultipartPut(
      url,
      fields: {
        'full_name': fullNameController.text,
        'email': emailController.text,
      },
      fileField: 'photo',
      file: kIsWeb ? null : _imageFile, // ⛔ Web بدون File
    );

    if (response.statusCode == 200) {
      await fetchProfile();
      setState(() => isEditing = false);
      widget.onProfileUpdated?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully ✔')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.body}')),
      );
    }
  }

  // =====================================================
  // IMAGE PICKER (Mobile only)
  // =====================================================
  Future<void> pickImage(ImageSource source) async {
    if (kIsWeb) return;

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
        ],
      );

      if (cropped != null) {
        setState(() => _imageFile = File(cropped.path));
      }
    }
  }

  // =====================================================
  // BUILD
  // =====================================================
  @override
  Widget build(BuildContext context) {
    final bodyContent = _loading
        ? const Center(child: CircularProgressIndicator(color: uniPurple))
        : Column(
            children: [
              const SizedBox(height: 60),
              Text(
                isEditing ? "Edit Profile" : "Service Center Profile",
                style: const TextStyle(
                  fontFamily: "Baloo",
                  fontSize: 38,
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
                        const SizedBox(height: 16),

                        if (!isEditing) _viewCard(),

                        if (isEditing) ...[
                          _editField("Full Name", fullNameController),
                          const SizedBox(height: 16),
                          IgnorePointer(
                            child: Opacity(
                              opacity: 0.5,
                              child: _editField(
                                  "Email (not editable)", emailController),
                            ),
                          ),
                          const SizedBox(height: 16),
                          IgnorePointer(
                            child: Opacity(
                              opacity: 0.5,
                              child: _editField(
                                  "Role (cannot be changed)", roleController),
                            ),
                          ),
                        ],

                        const SizedBox(height: 26),
                        _actionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: !kIsWeb,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: uniPurple),
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
        child: kIsWeb
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: bodyContent,
                ),
              )
            : bodyContent,
      ),
    );
  }

  // =====================================================
  // UI COMPONENTS
  // =====================================================
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
                  as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 📱 فقط موبايل
        if (isEditing && !kIsWeb)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _smallButton(
                "Gallery",
                Icons.photo,
                () => pickImage(ImageSource.gallery),
              ),
              const SizedBox(width: 12),
              _smallButton(
                "Camera",
                Icons.camera_alt,
                () => pickImage(ImageSource.camera),
              ),
            ],
          ),
      ],
    );
  }

  Widget _viewCard() {
    return Column(
      children: [
        _bioRow(Icons.person, "Full Name", fullNameController.text),
        _bioRow(Icons.mail, "Email", emailController.text),
        _bioRow(Icons.badge, "Role", roleController.text),
      ],
    );
  }

  Widget _editField(String label, TextEditingController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _bioRow(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: uniPurple),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value.isNotEmpty ? value : "Not provided"),
    );
  }

  Widget _smallButton(String text, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: uniPurple),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: uniPurple,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _actionButtons() {
    if (isEditing) {
      return ElevatedButton(
        onPressed: updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: uniPurple,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text(
          "Save Changes",
          style: TextStyle(color: Colors.white),
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
                  builder: (_) =>
                      ChangePasswordServiceScreen(email: widget.email),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black,
            ),
            child: const Text("Update Password"),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => setState(() => isEditing = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: uniPurple,
            ),
            child: const Text(
              "Edit Profile",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

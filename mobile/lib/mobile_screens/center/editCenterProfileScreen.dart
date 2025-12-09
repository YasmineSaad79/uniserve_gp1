// File: lib/screens/center/service_profile_screen.dart

import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '/services/api_service.dart';
import 'changePasswordServiceScreen.dart';

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

  static const String serverIP = "10.0.2.2";

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

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
    } catch (e) {
      _loading = false;
    }
  }

  Future<void> updateProfile() async {
    final url = Uri.parse("http://$serverIP:5000/api/service/profile");

    final response = await ApiService.authMultipartPut(
      url,
      fields: {
        'full_name': fullNameController.text,
        'email': emailController.text,
      },
      fileField: 'photo',
      file: _imageFile,
    );

    if (response.statusCode == 200) {
      await fetchProfile();
      setState(() => isEditing = false);
      widget.onProfileUpdated?.call();

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully ✔')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: uniPurple))
          : Container(
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
                    isEditing ? "Edit Profile" : "Service Center Profile",
                    style: const TextStyle(
                      fontFamily: "Baloo",
                      fontSize: 40,
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
                            if (!isEditing)
                              const Column(
                                children: [
                                  Text(
                                    "Profile Information",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4A148C),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                ],
                              ),
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
                                  child: _editField("Role (cannot be changed)",
                                      roleController),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            const SizedBox(height: 22),
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

  // ---------------------- VIEW MODE CARD ----------------------
  Widget _viewCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: uniPurple.withOpacity(0.4), width: 2),
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
          _bioRow(Icons.badge, "Role", roleController.text),
        ],
      ),
    );
  }

  // ---------------------- EDIT FIELD ----------------------
  Widget _editField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(16)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------- PHOTO ----------------------
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

  // ---------------------- BIO ROW ----------------------
  Widget _bioRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: uniPurple, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: uniPurple)),
                const SizedBox(height: 4),
                Text(value.isNotEmpty ? value : "Not provided",
                    style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------- BUTTONS ----------------------
  Widget _smallButton(String text, IconData icon, Function() onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: uniPurple),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: uniPurple,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          style: TextStyle(
            color: Colors.white,
            fontFamily: "Baloo",
            fontSize: 16,
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
                  builder: (_) =>
                      ChangePasswordServiceScreen(email: widget.email),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
                  borderRadius: BorderRadius.circular(16)),
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

  // ---------------------- GLASS CARD ----------------------
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

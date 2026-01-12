import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class DoctorProfileScreen extends StatefulWidget {
  final String doctorId;
  final String email;

  const DoctorProfileScreen(
      {super.key, required this.doctorId, required this.email});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  Map<String, dynamic>? doctorData;
  bool isLoading = true;
  bool isUpdating = false;
  XFile? _imageFile;
  Uint8List? _imageBytes; // لتخزين بايتات الصورة للويب
  final ImagePicker _picker = ImagePicker();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // حفظ URL الصورة القديم لتحسين العرض
  String? currentPhotoUrl;

  // ديناميكي للويب والموبايل
  String get serverIP => kIsWeb ? "localhost" : "10.0.2.2";

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  @override
  void dispose() {
    // مهم جداً للتخلص من الـ Controllers
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> fetchProfile() async {
    setState(() => isLoading = true);
    final url =
        Uri.parse('http://$serverIP:5000/api/doctor/profile/${widget.doctorId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        doctorData = data;
        fullNameController.text = data['full_name'] ?? '';
        emailController.text = data['email'] ?? '';
        phoneController.text = data['phone_number'] ?? '';
        currentPhotoUrl = data['photo_url']; // تحديث رابط الصورة الحالي
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Failed to load profile: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> updateProfile() async {
    setState(() => isUpdating = true);
    final url =
        Uri.parse('http://$serverIP:5000/api/doctor/profile/${widget.doctorId}');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "full_name": fullNameController.text,
          "email": emailController.text,
          "phone_number": phoneController.text,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully ✅')),
          );
        }
        await fetchProfile(); // إعادة جلب البيانات
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isUpdating = false);
      }
    }
  }

  Future<void> changePassword() async {
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match ❌')),
        );
      }
      return;
    }

    // تحقق من الحد الأدنى لطول كلمة المرور
    if (newPassword.length < 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password must be at least 6 characters ❌')),
        );
      }
      return;
    }

    setState(() => isUpdating = true);
    final url = Uri.parse(
        'http://$serverIP:5000/api/doctor/profile/password/${widget.doctorId}');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"newPassword": newPassword}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password changed successfully ✅')),
          );
        }
        newPasswordController.clear();
        confirmPasswordController.clear();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to change password: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isUpdating = false);
      }
    }
  }

  Future<void> uploadPhoto() async {
    if (_imageBytes == null) return;
    setState(() => isUpdating = true);

    final url = Uri.parse(
        'http://$serverIP:5000/api/doctor/profile/photo/${widget.doctorId}');
    final request = http.MultipartRequest('PUT', url);
    // استخدام fromBytes للتوافق مع الويب والموبايل
    request.files.add(http.MultipartFile.fromBytes(
      'photo',
      _imageBytes!,
      filename: _imageFile!.name,
    ));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo uploaded successfully ✅')),
          );
        }
        await fetchProfile(); // إعادة جلب البيانات
        setState(() {
          _imageFile = null;
          _imageBytes = null;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload photo: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading photo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isUpdating = false);
      }
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageFile = picked;
        _imageBytes = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // تحديد مصدر الصورة بناءً على:
    // 1. بايتات جديدة تم اختيارها (_imageBytes)
    // 2. URL صورة سابقة موجودة (currentPhotoUrl)
    final ImageProvider<Object>? profileImage = _imageBytes != null
        ? MemoryImage(_imageBytes!)
        : (currentPhotoUrl != null && currentPhotoUrl != ""
            ? NetworkImage('http://$serverIP:5000$currentPhotoUrl')
            : null) as ImageProvider<Object>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Profile'),
        backgroundColor: Colors.blueAccent, // تجميل بسيط
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          // استخدام مصدر الصورة المحدد أعلاه
                          backgroundImage: profileImage,
                          backgroundColor: Colors.grey[200],
                          child: (profileImage == null)
                              ? const Icon(Icons.person,
                                  size: 60, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          doctorData!['full_name'] ?? 'Doctor Name',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          doctorData!['email'] ?? 'No Email',
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // قسم تغيير الصورة
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Profile Picture',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildImageButton(
                                icon: Icons.photo_library,
                                label: 'Gallery',
                                onPressed: () => pickImage(ImageSource.gallery),
                              ),
                              _buildImageButton(
                                icon: Icons.camera_alt,
                                label: 'Camera',
                                onPressed: () => pickImage(ImageSource.camera),
                              ),
                              if (_imageBytes != null)
                                _buildImageButton(
                                  icon: Icons.upload,
                                  label: 'Upload',
                                  onPressed: uploadPhoto,
                                  color: Colors.green,
                                ),
                            ],
                          ),
                          if (_imageFile != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                  'Selected: ${_imageFile!.name}',
                                  style: const TextStyle(
                                      fontStyle: FontStyle.italic)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // قسم تحديث البيانات
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Personal Information',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent)),
                          buildTextField('Full Name', fullNameController,
                              icon: Icons.person_outline),
                          buildTextField('Email', emailController,
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress),
                          buildTextField('Phone Number', phoneController,
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: isUpdating ? null : updateProfile,
                            child: isUpdating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text('Update Profile',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // قسم تغيير كلمة السر
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Security',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent)),
                          buildTextField('New Password', newPasswordController,
                              obscureText: true, icon: Icons.lock_outline),
                          buildTextField(
                              'Confirm Password', confirmPasswordController,
                              obscureText: true, icon: Icons.lock),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: isUpdating ? null : changePassword,
                            child: isUpdating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text('Change Password',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildImageButton(
      {required IconData icon,
      required String label,
      required VoidCallback onPressed,
      Color color = Colors.blue}) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: IconButton(
            icon: Icon(icon, color: color),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      {bool obscureText = false,
      IconData? icon,
      TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: Colors.blueGrey) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.blueGrey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
        ),
      ),
    );
  }
}

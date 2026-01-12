import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'package:mobile/services/token_service.dart';

class EditDoctorProfileScreen extends StatefulWidget {
  final int doctorId;
  final Function()? onUpdated;

  const EditDoctorProfileScreen({
    super.key,
    required this.doctorId,
    this.onUpdated,
  });

  @override
  State<EditDoctorProfileScreen> createState() => _EditDoctorProfileScreenState();
}

class _EditDoctorProfileScreenState extends State<EditDoctorProfileScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool loading = true;

  // صورة
  Uint8List? _pickedBytes;
  String? networkPhotoUrl;

  String get baseUrl => kIsWeb ? "http://localhost:5000" : "http://10.0.2.2:5000";

  @override
  void initState() {
    super.initState();
    _fetchDoctorInfo();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctorInfo() async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      final token = await TokenService.getToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No token found. Please sign in again.")),
        );
        Navigator.pop(context);
        return;
      }

      final url = Uri.parse("$baseUrl/api/doctor/profile/${widget.doctorId}");
      debugPrint("📌 GET EditProfile => $url");

      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode != 200) {
        debugPrint("❌ Edit profile GET failed ${res.statusCode}: ${res.body}");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load (${res.statusCode})")),
        );
        return;
      }

      final data = jsonDecode(res.body);

      final serverPhoto = data["photo_url"];
      final resolvedPhoto = (serverPhoto != null && serverPhoto.toString().isNotEmpty)
          ? "$baseUrl$serverPhoto?t=${DateTime.now().millisecondsSinceEpoch}"
          : null;

      if (!mounted) return;
      setState(() {
        fullNameController.text = data["full_name"] ?? "";
        emailController.text = data["email"] ?? "";
        networkPhotoUrl = resolvedPhoto;
      });
    } catch (e) {
      debugPrint("⚠ Error loading doctor profile: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error loading profile")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pickedBytes = bytes;
    });
  }

  ImageProvider _imageProvider() {
    if (_pickedBytes != null) return MemoryImage(_pickedBytes!);
    if (networkPhotoUrl != null && networkPhotoUrl!.isNotEmpty) {
      return NetworkImage(networkPhotoUrl!);
    }
    return const AssetImage("assets/images/default.png");
  }

  Future<void> _saveChanges() async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      final token = await TokenService.getToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No token found. Please sign in again.")),
        );
        return;
      }

      final url = Uri.parse("$baseUrl/api/doctor/profile/${widget.doctorId}");
      debugPrint("📌 PUT EditProfile => $url");

      final request = http.MultipartRequest("PUT", url);
      request.headers["Authorization"] = "Bearer $token";

      request.fields["full_name"] = fullNameController.text.trim();
      request.fields["email"] = emailController.text.trim();

      if (_pickedBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            _pickedBytes!,
            filename: 'profile_pic.jpg',
          ),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        widget.onUpdated?.call();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully ✅")),
        );
        Navigator.pop(context);
      } else {
        debugPrint("❌ Update failed ${response.statusCode}: ${response.body}");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update failed (${response.statusCode})")),
        );
      }
    } catch (e) {
      debugPrint("⚠ Error updating profile: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error updating profile")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: const Text(
          "My Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(width: double.infinity, height: 120, color: Colors.purple),
                  Transform.translate(
                    offset: const Offset(0, -50),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _imageProvider(),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: _pickImage,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7D9FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.photo, color: Colors.purple),
                                SizedBox(width: 6),
                                Text("Gallery", style: TextStyle(color: Colors.purple)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _input("Full Name", fullNameController, Icons.person),
                          const SizedBox(height: 18),
                          _disabledInput("Email", emailController.text, Icons.email),
                          const SizedBox(height: 18),
                          _disabledInput("Role", "doctor", Icons.badge),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text("Save Changes", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _saveChanges,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _input(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.purple),
            filled: true,
            fillColor: const Color(0xFFF8F5FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _disabledInput(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: value),
          enabled: false,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.purple),
            filled: true,
            fillColor: const Color(0xFFF0F0F0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

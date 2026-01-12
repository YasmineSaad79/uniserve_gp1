import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EditDoctorProfileScreen extends StatefulWidget {
  final int doctorId;
  final Function()? onUpdated;

  const EditDoctorProfileScreen({
    super.key,
    required this.doctorId,
    this.onUpdated,
  });

  @override
  State<EditDoctorProfileScreen> createState() =>
      _EditDoctorProfileScreenState();
}

class _EditDoctorProfileScreenState extends State<EditDoctorProfileScreen> {
  final storage = const FlutterSecureStorage();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  File? _imageFile;
  String? networkPhotoUrl;

  bool loading = true;
  static const String serverIP = "10.0.2.2";

  @override
  void initState() {
    super.initState();
    _fetchDoctorInfo();
  }

  Future<void> _fetchDoctorInfo() async {
    try {
      final token = await storage.read(key: 'authToken');

      final url = Uri.parse(
          "http://$serverIP:5000/api/doctor/profile/${widget.doctorId}");

      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final data = jsonDecode(res.body);

      setState(() {
        fullNameController.text = data["full_name"] ?? "";
        emailController.text = data["email"] ?? "";

        final serverPhoto = data["photo_url"];
        networkPhotoUrl = (serverPhoto != null && serverPhoto.isNotEmpty)
            ? "http://$serverIP:5000$serverPhoto"
            : null;

        loading = false;
      });
    } catch (e) {
      print("⚠ Error loading doctor profile: $e");
      loading = false;
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    await _crop(picked.path);
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    await _crop(picked.path);
  }

  Future<void> _crop(String path) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 90,
    );

    if (cropped != null) {
      setState(() => _imageFile = File(cropped.path));
    }
  }

  Future<void> _saveChanges() async {
    try {
      final token = await storage.read(key: 'authToken');

      final url = Uri.parse(
          "http://$serverIP:5000/api/doctor/profile/${widget.doctorId}");

      final request = http.MultipartRequest("PUT", url);

      request.headers["Authorization"] = "Bearer $token";

      request.fields["full_name"] = fullNameController.text;
      request.fields["email"] = emailController.text;

      if (_imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          _imageFile!.path,
        ));
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        widget.onUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
        Navigator.pop(context);
      } else {
        print("❌ Error: $respStr");
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $respStr")));
      }
    } catch (e) {
      print("⚠ Error updating profile: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
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
                  Container(
                    width: double.infinity,
                    height: 120,
                    color: Colors.purple,
                  ),
                  Transform.translate(
                    offset: const Offset(0, -50),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 55,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (networkPhotoUrl != null
                                    ? NetworkImage(networkPhotoUrl!)
                                    : const AssetImage(
                                        "assets/images/default.png"))
                                as ImageProvider,
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _photoButton(
                          icon: Icons.photo,
                          text: "Gallery",
                          onTap: _pickFromGallery,
                        ),
                        const SizedBox(width: 15),
                        _photoButton(
                          icon: Icons.camera_alt,
                          text: "Camera",
                          onTap: _pickFromCamera,
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
                          _disabledInput(
                              "Email", emailController.text, Icons.email),
                          const SizedBox(height: 18),
                          _disabledInput("Role", "doctor", Icons.badge),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Flexible(
                          flex: 1,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.lock, color: Colors.black87),
                            label: const Text(
                              "Change Password",
                              style: TextStyle(color: Colors.black87),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 12),

                        /// زر Save Changes أعرض
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.save, color: Colors.white),
                              label: const Text(
                                "Save Changes",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14, // ← حجم نص أفضل
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18, // ← يعطي مساحة أعلى وأسفل
                                  horizontal: 14, // ← يعطي مساحة يمين ويسار
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _saveChanges,
                            ),
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

  Widget _photoButton({
    required IconData icon,
    required String text,
    required Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFE7D9FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.purple),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(color: Colors.purple)),
          ],
        ),
      ),
    );
  }

  Widget _input(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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

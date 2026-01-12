import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<String?> _getToken() async {
  const storage = FlutterSecureStorage();
  return await storage.read(key: 'jwt_token'); // ✅ هذا هو الصحيح
}

class UploadPhotoScreen extends StatefulWidget {
  final String userEmail;
  const UploadPhotoScreen({super.key, required this.userEmail});

  @override
  State<UploadPhotoScreen> createState() => _UploadPhotoScreenState();
}

class _UploadPhotoScreenState extends State<UploadPhotoScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _photoUploaded = false;
  bool _isUploading = false;
  double _scale = 1.0;
  Offset _position = Offset.zero;

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked != null) {
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // 📸 قص مربع
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Adjust your photo',
            toolbarColor: Colors.deepPurple,
            toolbarWidgetColor: Colors.white,
            hideBottomControls: false,
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
          _photoUploaded = true;
        });
      }
    }
  }

  void _showAdjustDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Adjust your photo",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 250,
                height: 250,
                child: ClipOval(
                  child: Container(
                    color: Colors.black12,
                    child: InteractiveViewer(
                      boundaryMargin: const EdgeInsets.all(100),
                      minScale: 0.8,
                      maxScale: 4.0,
                      onInteractionUpdate: (details) {
                        setState(() {
                          _scale = details.scale;
                        });
                      },
                      child: _imageFile != null
                          ? Image.file(
                              _imageFile!,
                              fit: BoxFit.cover,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text("Cancel"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check),
                    label: const Text("Save"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
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

  Future<void> _continueToSignin() async {
    if (_imageFile == null) {
      Navigator.pushReplacementNamed(context, '/signin');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final token = await _getToken(); // 🟣 اجلب التوكن

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('http://10.0.2.2:5000/api/profile/photo'),
      );
      request.fields['email'] = widget.userEmail;
      request.files.add(
        await http.MultipartFile.fromPath('photo', _imageFile!.path),
      );

      var response = await request.send();
      final res = await http.Response.fromStream(response);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.15),
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Text(
                  'Photo uploaded successfully!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pushReplacementNamed(context, '/signin');
      } else {
        print("❌ Server says: ${res.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed (${res.statusCode})'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const buttonWidth = 300.0;
    const buttonHeight = 50.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8),
            child: GestureDetector(
              onTap: () => Navigator.pushReplacementNamed(context, '/signin'),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Skip",
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.deepPurple,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.deepPurple, width: 4),
                ),
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      _imageFile != null ? FileImage(_imageFile!) : null,
                  child: _imageFile == null
                      ? const Icon(Icons.person,
                          size: 70, color: Colors.deepPurple)
                      : null,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: buttonWidth,
                height: buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Upload from Gallery"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple[100],
                    foregroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: buttonWidth,
                height: buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Take a Photo"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple[100],
                    foregroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              if (_photoUploaded)
                SizedBox(
                  width: buttonWidth,
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _continueToSignin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isUploading ? Colors.grey : Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isUploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Done",
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

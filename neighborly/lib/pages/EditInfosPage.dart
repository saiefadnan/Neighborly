import 'package:flutter/material.dart';
import 'dart:io'; // Required for file handling (image picking)
import 'package:image_picker/image_picker.dart'; // ImagePicker package
import 'package:flutter/cupertino.dart'; // Add this import

class CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({super.key});

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  File? _imageFile;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(
          top: 250,
        ), // Adjust as needed for your layout
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 54,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    _imageFile != null
                        ? FileImage(_imageFile!)
                        : const AssetImage('assets/images/dummy.png')
                            as ImageProvider,
              ),
            ),
            Positioned(
              bottom: -6,
              right: -4,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(CupertinoIcons.camera, size: 22),
                  onPressed: _pickImage,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditInfosPage extends StatefulWidget {
  @override
  _EditInfosPageState createState() => _EditInfosPageState();
}

class _EditInfosPageState extends State<EditInfosPage> {
  final _usernameController = TextEditingController(text: "yANCHUI");
  final _emailController = TextEditingController(text: "yanchui@gmail.com");
  final _phoneController = TextEditingController(text: "+14987889999");
  final _passwordController = TextEditingController(text: "evFTbyVVCd");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header + Overlapping Avatar
            // Header + Overlapping Avatar (same as EditProfilePage)
            // Header + Overlapping Avatar (EXACTLY like EditProfilePage)
            Stack(
              alignment: Alignment.topCenter,
              children: [
                ClipPath(
                  clipper: CurvedHeaderClipper(),
                  child: Container(
                    height:
                        320, // Increased height for more coverage, just like editProfile.dart
                    color: const Color(0xFFEFF3F9),
                  ),
                ),
                ProfileAvatar(),
              ],
            ),
            const SizedBox(height: 80),
            // Form Fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 6),
                  Text("Username"),
                  SizedBox(height: 4),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 13,
                        horizontal: 12,
                      ),
                    ),
                  ),
                  SizedBox(height: 18),
                  Text("Email"),
                  SizedBox(height: 4),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 13,
                        horizontal: 12,
                      ),
                    ),
                  ),
                  SizedBox(height: 18),
                  Text("Phone Number"),
                  SizedBox(height: 4),
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 13,
                        horizontal: 12,
                      ),
                    ),
                  ),
                  SizedBox(height: 18),
                  Text("Password"),
                  SizedBox(height: 4),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 13,
                        horizontal: 12,
                      ),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 30),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        // Handle update
                      },
                      child: Text(
                        "Update",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

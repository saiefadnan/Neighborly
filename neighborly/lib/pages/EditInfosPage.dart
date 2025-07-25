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
          top: 220,
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
      backgroundColor: const Color(0xFFF7F7FA),
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
            // Form Fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card 1: Names, Email, Contact
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text("First Name"),
                          const SizedBox(height: 4),
                          TextField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text("Last Name"),
                          const SizedBox(height: 4),
                          TextField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text("E-mail"),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text("Contact Number"),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Card 2: Address Section
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Address",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(thickness: 1.1, height: 24),
                          const Text("Address Line 1"),
                          const SizedBox(height: 4),
                          TextField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text("Address Line 2 (optional)"),
                          const SizedBox(height: 4),
                          TextField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text("City"),
                          const SizedBox(height: 4),
                          TextField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text("Division"),
                          const SizedBox(height: 4),
                          TextField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text("ZIP/Postal Code"),
                          const SizedBox(height: 4),
                          TextField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
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
                      child: const Text(
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
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

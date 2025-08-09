import 'package:flutter/material.dart';
import 'dart:io'; // Required for file handling (image picking)
import 'package:image_picker/image_picker.dart'; // ImagePicker package
// Add this import
import '../components/profile_header.dart';

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

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 95, // Position it to sit right on the curve
      child: CircleAvatar(
        radius: 64,
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: 60,
          backgroundImage: const AssetImage('assets/images/dummy.png'),
        ),
      ),
    );
  }
}

class EditInfosPage extends StatefulWidget {
  const EditInfosPage({super.key});

  @override
  _EditInfosPageState createState() => _EditInfosPageState();
}

class _EditInfosPageState extends State<EditInfosPage> {
  final _usernameController = TextEditingController(text: "Mir Sayef");
  final _emailController = TextEditingController(text: "mirsayef@gmail.com");
  final _phoneController = TextEditingController(text: "01678998814");
  final _passwordController = TextEditingController(text: "evFTbyVVCd");
  File? _profileImage; // Add this line for image file

  // Add image picking method
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF71BB7B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Stack to overlay avatar and camera button on the curved header
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Base ProfileHeader from shared component (no avatar inside)
                ProfileHeader(showUserInfo: false),

                // Avatar (show picked image if available, else default)
                Positioned(
                  top: 95,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CircleAvatar(
                      radius: 64,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage:
                            _profileImage != null
                                ? FileImage(_profileImage!)
                                : const AssetImage('assets/images/dummy.png')
                                    as ImageProvider,
                      ),
                    ),
                  ),
                ),

                // Camera button positioned where the avatar is
                Positioned(
                  top: 190, // Avatar is at 95 + 64 radius
                  right:
                      MediaQuery.of(context).size.width / 2 -
                      20, // Center - half avatar width + camera button offset
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: _pickImage,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 80),

            // Rest of your form fields...
            // Form Fields
            // Form Fields
            // Form Fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card 1: User Information
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
                          Row(
                            children: [
                              Icon(Icons.person, color: Colors.black87),
                              const SizedBox(width: 8),
                              const Text(
                                "User Information",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(thickness: 1.1, height: 24),

                          // First Name field
                          const Text("First Name"),
                          const SizedBox(height: 4),
                          TextField(
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Color(0xFFF3F6FB),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: 12,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),
                          // Last Name field
                          const Text("Last Name"),
                          const SizedBox(height: 4),
                          TextField(
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Color(0xFFF3F6FB),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: 12,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),
                          // Email field
                          const Text("E-mail"),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Color(0xFFF3F6FB),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: 12,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),
                          // Contact Number field
                          const Text("Contact Number"),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Color(0xFFF3F6FB),
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
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: Colors.black87,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Address",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(thickness: 1.1, height: 24),

                          // Address Line 1
                          const Text("Address Line 1"),
                          const SizedBox(height: 4),
                          TextField(
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.home_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Color(0xFFF3F6FB),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: 12,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),
                          // Address Line 2
                          const Text("Address Line 2 (optional)"),
                          const SizedBox(height: 4),
                          TextField(
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.home_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Color(0xFFF3F6FB),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: 12,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),
                          // City
                          const Text("City"),
                          const SizedBox(height: 4),
                          TextField(
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.location_city),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Color(0xFFF3F6FB),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: 12,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),
                          // Division
                          const Text("Division"),
                          const SizedBox(height: 4),
                          TextField(
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.map_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Color(0xFFF3F6FB),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: 12,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),
                          // ZIP Code
                          const Text("ZIP/Postal Code"),
                          const SizedBox(height: 4),
                          TextField(
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.markunread_mailbox_outlined,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Color(0xFFF3F6FB),
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

                  // Keep your existing button code
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

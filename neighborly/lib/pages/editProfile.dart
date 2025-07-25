import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'EditNotifications.dart';
import 'PrivacyPolicyPage.dart';
import 'EditInfosPage.dart';

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

//for profile pic changing..........................................................................................
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
  Widget build(BuildContext context) {
    return Positioned(
      top: 115,
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
    );
  }
}
//for profile pic changing..........................................................................................

//profile page content.................................................................................................
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  bool notificationsOn = true; // Added for the switch
  bool isDarkMode = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEFF3F9), // Same as curved header color
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Curved header background
          // Curved header and avatar overlap using Stack and ClipPath
          Stack(
            alignment: Alignment.topCenter,
            children: [
              // Curved header background (Changed to match clipper color)
              ClipPath(
                clipper: CurvedHeaderClipper(),
                child: Container(
                  height: 220,
                  color: const Color(0xFFEFF3F9), // Keep this color
                ),
              ),
              // Profile avatar with edit icon, overlapping the curve
              ProfileAvatar(),
            ],
          ),
          // Name and info
          Transform.translate(
            offset: const Offset(0, 03), // Adjusted offset to prevent overlap
            child: Column(
              children: const [
                Text(
                  'Mir Sayef',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
                SizedBox(height: 6),
                Text(
                  'Welldone@gmail.com | +016789011',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
              ],
            ),
          ),
          // Main card sections
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _profileSection([
                  _profileTile(
                    CupertinoIcons.person_crop_circle,
                    'Edit profile information',
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditInfosPage(),
                        ),
                      );
                    },
                  ),

                  _profileTile(
                    CupertinoIcons.bell,
                    'Notifications',
                    trailing: Icon(
                      Icons.chevron_right,
                    ), // Default icon and color
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditNotificationsPage(),
                        ),
                      );
                    },
                  ),

                  _profileTile(
                    CupertinoIcons.globe,
                    'Language',
                    trailing: Text(
                      'English',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                _profileSection([
                  _profileTile(CupertinoIcons.lock, 'Security'),
                  _profileTile(
                    isDarkMode
                        ? CupertinoIcons.moon_stars
                        : CupertinoIcons.brightness, // Icon changes!
                    'Theme',
                    trailing: Transform.scale(
                      scale: 0.85,
                      child: CupertinoSwitch(
                        value: isDarkMode,
                        onChanged: (bool value) {
                          setState(() {
                            isDarkMode = value;
                            // Here, you can also trigger your theme change logic
                          });
                        },
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                _profileSection([
                  _profileTile(
                    CupertinoIcons.question_circle,
                    'Help & Support',
                  ),
                  _profileTile(CupertinoIcons.mail, 'Contact us'),
                  _profileTile(
                    CupertinoIcons.checkmark_shield,
                    'Privacy policy',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PrivacyPolicyPage(),
                        ),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
      // Bottom navigation bar (optional, add if you want)
      // bottomNavigationBar: ...
    );
  }

  Widget _profileSection(List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
      color: Colors.white,
      child: Column(children: children),
    );
  }

  Widget _profileTile(
    IconData icon,
    String title, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: trailing,
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      horizontalTitleGap: 10,
    );
  }
}

import 'package:flutter/material.dart';

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

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

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
              Positioned(
                top: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage('assets/images/dummy.png'),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: -4,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(Icons.edit, size: 22),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                    Icons.badge_outlined,
                    'Edit profile information',
                  ),
                  _profileTile(
                    Icons.notifications_none,
                    'Notifications',
                    trailing: Text(
                      'ON',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _profileTile(
                    Icons.language,
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
                  _profileTile(Icons.credit_card, 'Security'),
                  _profileTile(
                    Icons.brightness_6,
                    'Theme',
                    trailing: Text(
                      'Light mode',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                _profileSection([
                  _profileTile(Icons.help_outline, 'Help & Support'),
                  _profileTile(Icons.mail_outline, 'Contact us'),
                  _profileTile(Icons.privacy_tip_outlined, 'Privacy policy'),
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

  Widget _profileTile(IconData icon, String title, {Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black, size: 26),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      trailing:
          trailing ?? const Icon(Icons.chevron_right, color: Colors.black),
      onTap: () {},
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

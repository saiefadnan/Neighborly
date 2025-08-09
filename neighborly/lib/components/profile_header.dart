import 'package:flutter/material.dart';
// Add this import

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

class ProfileHeader extends StatelessWidget {
  final bool showUserInfo;
  final String name;
  final String contactInfo;

  const ProfileHeader({
    super.key,
    this.showUserInfo = false,
    this.name = 'Mir Sayef Ali',
    this.contactInfo = 'Welldone@gmail.com | +016789011',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            // Curved header background
            ClipPath(
              clipper: CurvedHeaderClipper(),
              child: Container(height: 220, color: const Color(0xFF71BB7B)),
            ),
            // Profile avatar
            Positioned(
              top: 95,
              child: CircleAvatar(
                radius: 64,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: const AssetImage('assets/images/dummy.png'),
                ),
              ),
            ),
          ],
        ),

        // Conditionally show user info
        if (showUserInfo) ...[
          Transform.translate(
            offset: const Offset(0, 3),
            child: Column(
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
                Text(
                  contactInfo,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

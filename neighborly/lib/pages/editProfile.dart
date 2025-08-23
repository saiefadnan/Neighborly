import 'package:flutter/material.dart';
//import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'EditNotifications.dart';
import 'PrivacyPolicyPage.dart';
import 'EditInfosPage.dart';
import 'SecurityPage.dart';
import '../components/profile_header.dart';
import 'aboutapp.dart';

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
        backgroundColor: const Color(0xFF71BB7B), // Same as curved header color
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
          // Curved header background
          // Using the shared header component
          ProfileHeader(),
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
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const EditInfosPage(),
                          transitionsBuilder: (
                            context,
                            animation,
                            secondaryAnimation,
                            child,
                          ) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.easeInOut;

                            var tween = Tween(
                              begin: begin,
                              end: end,
                            ).chain(CurveTween(curve: curve));
                            var offsetAnimation = animation.drive(tween);

                            return SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 300),
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
                  _profileTile(
                    CupertinoIcons.lock,
                    'Security',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SecurityPage(),
                        ),
                      );
                    },
                  ),
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
                const SizedBox(height: 16),
                _profileSection([
                  _profileTile(
                    CupertinoIcons.question_circle,
                    'Help & Support',
                  ),
                  _profileTile(CupertinoIcons.mail, 'Contact us'),
                  _profileTile(
                    CupertinoIcons.info,
                    'About App',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AppNavigationPage(),
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
      leading: Icon(icon, size: 28, color: Colors.black, weight: 800),
      title: Text(title),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      horizontalTitleGap: 10,
    );
  }
}

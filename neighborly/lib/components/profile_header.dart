import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this line only
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

class ProfileHeader extends StatefulWidget {
  final String? profileImageUrl;
  const ProfileHeader({super.key, this.profileImageUrl});

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  String? _name;
  String? _email;
  String? _phone;
  String? _profilePicUrl; // Add this line only
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    bool success = false;

    // 1. Try HTTP API first
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _loading = false;
        });
        return;
      }
      final token = await user.getIdToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.infosApiPath}');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          _name =
              ((data['firstName'] ?? '') + ' ' + (data['lastName'] ?? ''))
                  .trim();
          _email = data['email'] ?? '';
          _phone = data['contactNumber'] ?? '';
          _profilePicUrl = data['profilepicurl']; // Add this line only
          _loading = false;
        });
        success = true;
      }
    } catch (e) {
      print('API fetch failed, will try Firestore. Error: $e');
    }

    // 2. If API failed, try Firestore directly
    if (!success) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get();

          if (userDoc.exists) {
            final userData = userDoc.data()!;
            setState(() {
              _name =
                  ((userData['firstName'] ?? '') +
                          ' ' +
                          (userData['lastName'] ?? ''))
                      .trim();
              _email = userData['email'] ?? '';
              _phone = userData['contactNumber'] ?? '';
              _profilePicUrl = userData['profilepicurl']; // Add this line only
              _loading = false;
            });
          }
        }
      } catch (e) {
        print('Error fetching user info from Firestore: $e');
      }
    }

    if (!success) {
      setState(() {
        _loading = false;
      });
    }
  }

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
                  backgroundImage:
                      (_profilePicUrl != null && _profilePicUrl!.isNotEmpty)
                          ? NetworkImage(_profilePicUrl!)
                          : (widget.profileImageUrl != null &&
                              widget.profileImageUrl!.isNotEmpty)
                          ? NetworkImage(widget.profileImageUrl!)
                          : const AssetImage('assets/images/dummy.png')
                              as ImageProvider,
                ),
              ),
            ),
          ],
        ),
        Transform.translate(
          offset: const Offset(0, 3),
          child:
              _loading
                  ? const SizedBox(height: 60)
                  : Column(
                    children: [
                      Text(
                        _name ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                      Text(
                        (_email != null &&
                                _phone != null &&
                                _email!.isNotEmpty &&
                                _phone!.isNotEmpty)
                            ? '$_email | $_phone'
                            : (_email ?? _phone ?? ''),
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
    );
  }
}

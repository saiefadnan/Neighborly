import 'package:flutter/material.dart';
import 'dart:io'; // Required for file handling (image picking)
import 'package:image_picker/image_picker.dart'; // ImagePicker package
import '../components/profile_header.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';
import '../functions/pfp_uploader.dart';

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
  String? _profileImageUrl;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _divisionController = TextEditingController();
  final _postalcodeController = TextEditingController();
  File? _profileImage;
  bool _isLoading = false;
  // ...existing code...
  Future<String?> _uploadProfileImage(File file) async {
    print('[ProfileImage] Starting upload for file: \\${file.path}');
    try {
      final url = await uploadProfilePicture(file);
      print('[ProfileImage] Upload successful! URL: \\${url}');
      return url;
    } catch (e) {
      print('[ProfileImage] Image upload failed: $e');
      return null;
    }
  }

  Future<String?> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  // Fetch logged-in user's info from backend
  Future<void> fetchAndSetUserInfo() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final token = await _getAuthToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No auth token found.')));
        print('No auth token found.');
        return;
      }
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.infosApiPath}');
      print('Fetching user info from: $uri');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      print('GET status: \\${response.statusCode}, body: \\${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _usernameController.text = data['username'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['contactNumber'] ?? '';
          _addressLine1Controller.text = data['addressLine1'] ?? '';
          _addressLine2Controller.text = data['addressLine2'] ?? '';
          _cityController.text = data['city'] ?? '';
          _divisionController.text = data['division'] ?? '';
          _postalcodeController.text = data['postalcode'] ?? '';
          _profileImageUrl = data['profilepicurl'] ?? null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to fetch user info: Status \\${response.statusCode}',
            ),
          ),
        );
        print(
          'Failed to fetch user info: Status \\${response.statusCode}, body: \\${response.body}',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user info: \\${e.toString()}')),
      );
      print('Error fetching user info: \\${e.toString()}');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAndSetUserInfo();

    // Print Firebase ID token for Postman
    FirebaseAuth.instance.currentUser?.getIdToken(true).then((token) {
      print('Fresh Firebase ID token: $token');
    });
  }

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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // Stack to overlay avatar and camera button on the curved header
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Base ProfileHeader from shared component (no avatar inside)
                        ProfileHeader(),

                        // Avatar (show picked image if available, else default)
                        // Avatar (show picked image if available, else from backend, else default)
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
                                        : (_profileImageUrl != null &&
                                            _profileImageUrl!.isNotEmpty)
                                        ? NetworkImage(_profileImageUrl!)
                                        : const AssetImage(
                                              'assets/images/dummy.png',
                                            )
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
                                    controller: _firstNameController,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.person_outline),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(22),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Color(0xFFF3F6FB),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                    controller: _lastNameController,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.person_outline),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(22),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Color(0xFFF3F6FB),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                    controller: _addressLine1Controller,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.home_outlined),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(22),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Color(0xFFF3F6FB),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                    controller: _addressLine2Controller,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.home_outlined),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(22),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Color(0xFFF3F6FB),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                    controller: _cityController,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.location_city),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(22),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Color(0xFFF3F6FB),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                    controller: _divisionController,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.map_outlined),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(22),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Color(0xFFF3F6FB),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                    controller: _postalcodeController,
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                              onPressed: () async {
                                print('[ProfileImage] Update button pressed.');
                                final token = await _getAuthToken();
                                if (token == null) {
                                  print(
                                    '[ProfileImage] No auth token, aborting update.',
                                  );
                                  return;
                                }
                                String? uploadedUrl;
                                if (_profileImage != null) {
                                  print(
                                    '[ProfileImage] New image selected, uploading...',
                                  );
                                  uploadedUrl = await _uploadProfileImage(
                                    _profileImage!,
                                  );
                                } else {
                                  print(
                                    '[ProfileImage] No new image selected, using existing URL.',
                                  );
                                  uploadedUrl = _profileImageUrl;
                                }
                                print(
                                  '[ProfileImage] Using profilePicUrl: \\${uploadedUrl ?? "(null)"}',
                                );
                                final uri = Uri.parse(
                                  '${ApiConfig.baseUrl}${ApiConfig.infosApiPath}',
                                );
                                final response = await http.post(
                                  uri,
                                  headers: {
                                    'Authorization': 'Bearer $token',
                                    'Content-Type': 'application/json',
                                  },
                                  body: jsonEncode({
                                    'firstName': _firstNameController.text,
                                    'lastName': _lastNameController.text,
                                    'username': _usernameController.text,
                                    'addressLine1':
                                        _addressLine1Controller.text,
                                    'addressLine2':
                                        _addressLine2Controller.text,
                                    'city': _cityController.text,
                                    'contactNumber': _phoneController.text,
                                    'division': _divisionController.text,
                                    'postalcode': _postalcodeController.text,
                                    if (uploadedUrl != null)
                                      'profilepicurl': uploadedUrl,
                                  }),
                                );
                                print(
                                  '[ProfileImage] Backend response: status=\${response.statusCode}, body=\${response.body}',
                                );
                                if (response.statusCode == 200) {
                                  print(
                                    '[ProfileImage] User info updated successfully.',
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('User info updated!'),
                                    ),
                                  );
                                  fetchAndSetUserInfo(); // Refresh fields
                                } else {
                                  String errorMsg =
                                      'Failed to update user info';
                                  try {
                                    final resp = jsonDecode(response.body);
                                    if (resp['message'] != null) {
                                      errorMsg = resp['message'];
                                    }
                                  } catch (_) {}
                                  print(
                                    '[ProfileImage] Error updating user info: $errorMsg',
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(errorMsg)),
                                  );
                                }
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

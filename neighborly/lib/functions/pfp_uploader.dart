// lib/functions/pfp_uploader.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// Uploads the selected file directly to Cloudinary and returns the secure_url.
/// Requires your Cloudinary preset to be UNSIGNED.
/// Cloudinary (Settings → Upload → your preset):
/// - Signing mode: Unsigned
/// - Folder: pfp
/// - Unique filename: Off
/// - Overwrite: On
/// - Use filename or externally defined public ID: On
Future<String?> uploadProfilePicture(File file) async {
  const cloudName = 'dtfrojvrp'; // your cloud name
  const uploadPreset = 'pfp_signed'; // your unsigned preset

  final url = Uri.parse(
    'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
  );

  final request =
      http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

  final response = await request.send();

  if (response.statusCode == 200) {
    final responseData = await response.stream.toBytes();
    final responseString = String.fromCharCodes(responseData);
    final jsonMap = jsonDecode(responseString);
    final uploadedUrl = jsonMap['secure_url'];
    print('✅ Upload success: $uploadedUrl');
    return uploadedUrl;
  } else {
    print('❌ Upload failed: [31m${response.statusCode}[0m');
    return null;
  }
}

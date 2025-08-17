import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<String> uploadFile(File? file) async {
  final sigData = await getUploadSignature();

  print(sigData);

  final request = http.MultipartRequest(
    'POST',
    Uri.parse(
      'https://api.cloudinary.com/v1_1/${sigData["cloudName"]}/auto/upload',
    ),
  );

  request.files.add(await http.MultipartFile.fromPath('file', file!.path));
  if (sigData.containsKey('signature')) {
    request.fields['api_key'] = sigData['apiKey'];
    request.fields['timestamp'] = sigData['timestamp'].toString();
    request.fields['signature'] = sigData['signature'];
    request.fields['public_id'] = sigData['public_id'];
  } else {
    request.fields['upload_preset'] = sigData['upload_preset'];
  }
  final response = await request.send();
  final resBody = await response.stream.bytesToString();

  if (response.statusCode == 200) {
    final data = jsonDecode(resBody);
    return data['secure_url'];
  } else {
    throw Exception('Upload failed: $resBody');
  }
}

Future<Map<String, dynamic>> getUploadSignature() async {
  try {
    final url = Uri.parse(
      '${dotenv.env['BASE_URL']}/api/forum/upload/signature',
    );
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data;
    } else {
      print('Failed to get signature: ${res.statusCode}');
      return await backUpSignature();
    }
  } catch (e) {
    return await backUpSignature();
  }
}

Future<Map<String, dynamic>> backUpSignature() async {
  // fallback: unsigned preset (create in Cloudinary dashboard)
  final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
  final uploadPreset = dotenv.env['CLOUDINARY_UNSIGNED_PRESET'];

  if (cloudName == null || uploadPreset == null) {
    print('Missing Cloudinary backup config.');
    return {};
  }

  return {'cloudName': cloudName, 'upload_preset': uploadPreset};
}

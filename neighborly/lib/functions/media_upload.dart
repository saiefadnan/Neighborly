import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path/path.dart' as path;

Future<String> uploadFile(File? file) async {
  if (file == null) {
    throw Exception('No file provided');
  }

  // Compress the media file (image or video)
  final compressedFile = await compressMedia(file);
  final fileToUpload = compressedFile ?? file;

  // Check final file size after compression
  final finalSizeInBytes = await fileToUpload.length();
  final finalSizeInMB = finalSizeInBytes / (1024 * 1024);

  if (finalSizeInMB > 10) {
    throw Exception(
      'Image is too large (${finalSizeInMB.toStringAsFixed(1)}MB) even after compression. Please choose a different image.',
    );
  }

  final sigData = await getUploadSignature();

  print(sigData);

  final request = http.MultipartRequest(
    'POST',
    Uri.parse(
      'https://api.cloudinary.com/v1_1/${sigData["cloudName"]}/auto/upload',
    ),
  );

  request.files.add(
    await http.MultipartFile.fromPath('file', fileToUpload.path),
  );
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

Future<File?> compressMedia(File file) async {
  final fileExtension = path.extension(file.path).toLowerCase();

  // Check if it's a video file
  if (_isVideoFile(fileExtension)) {
    return await compressVideo(file);
  }
  // Check if it's an image file
  else if (_isImageFile(fileExtension)) {
    return await compressImage(file);
  }
  // Unsupported file type
  else {
    throw Exception(
      'Unsupported file type: $fileExtension. Only images and videos are allowed.',
    );
  }
}

bool _isVideoFile(String extension) {
  const videoExtensions = [
    '.mp4',
    '.mov',
    '.avi',
    '.mkv',
    '.flv',
    '.wmv',
    '.m4v',
    '.3gp',
  ];
  return videoExtensions.contains(extension);
}

bool _isImageFile(String extension) {
  const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
  return imageExtensions.contains(extension);
}

Future<File?> compressVideo(File file) async {
  try {
    final fileSizeInBytes = await file.length();
    final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

    print('Original video size: ${fileSizeInMB.toStringAsFixed(2)} MB');

    // If video is already small enough, return original
    if (fileSizeInMB <= 10) {
      print('Video is already under 10MB, no compression needed');
      return file;
    }

    // Choose compression quality based on file size
    VideoQuality quality;
    if (fileSizeInMB > 100) {
      quality = VideoQuality.LowQuality;
    } else if (fileSizeInMB > 50) {
      quality = VideoQuality.MediumQuality;
    } else {
      quality = VideoQuality.DefaultQuality;
    }

    print('Compressing video with quality: $quality');

    final compressedVideo = await VideoCompress.compressVideo(
      file.path,
      quality: quality,
      deleteOrigin: false, // Keep original file
      includeAudio: true,
    );

    if (compressedVideo != null) {
      final compressedSize = await File(compressedVideo.path!).length();
      final compressedSizeInMB = compressedSize / (1024 * 1024);

      print(
        'Compressed video size: ${compressedSizeInMB.toStringAsFixed(2)} MB',
      );

      return File(compressedVideo.path!);
    }

    return file;
  } catch (e) {
    print('Error compressing video: $e');
    return file; // Return original file if compression fails
  }
}

Future<File?> compressImage(File file) async {
  try {
    // Get file size in MB
    final fileSizeInBytes = await file.length();
    final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

    print('Original file size: ${fileSizeInMB.toStringAsFixed(2)} MB');

    // Always compress images to optimize size and quality
    // Create output path
    final dir = file.parent;
    final filename = path.basenameWithoutExtension(file.path);
    final extension = path.extension(file.path);
    final outputPath = path.join(dir.path, '${filename}_compressed$extension');

    // Calculate quality and dimensions based on file size
    int quality;
    int maxWidth;
    int maxHeight;

    if (fileSizeInMB > 100) {
      quality = 15;
      maxWidth = 1280;
      maxHeight = 720;
    } else if (fileSizeInMB > 50) {
      quality = 25;
      maxWidth = 1280;
      maxHeight = 720;
    } else if (fileSizeInMB > 30) {
      quality = 40;
      maxWidth = 1600;
      maxHeight = 900;
    } else if (fileSizeInMB > 20) {
      quality = 55;
      maxWidth = 1920;
      maxHeight = 1080;
    } else if (fileSizeInMB > 10) {
      quality = 70;
      maxWidth = 1920;
      maxHeight = 1080;
    } else {
      quality = 85;
      maxWidth = 1920;
      maxHeight = 1080;
    }

    // Compress the image
    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outputPath,
      quality: quality,
      minWidth: maxWidth,
      minHeight: maxHeight,
      format: CompressFormat.jpeg,
    );

    if (compressedFile != null) {
      // Check if compression was successful and file size is acceptable
      final compressedSize = await File(compressedFile.path).length();
      final compressedSizeInMB = compressedSize / (1024 * 1024);

      print('Original size: ${fileSizeInMB.toStringAsFixed(2)} MB');
      print('Compressed size: ${compressedSizeInMB.toStringAsFixed(2)} MB');

      // If still too large, compress more aggressively
      if (compressedSizeInMB > 10) {
        return await _aggressiveCompress(file, outputPath);
      }

      return File(compressedFile.path);
    }

    return file;
  } catch (e) {
    print('Error compressing image: $e');
    return file; // Return original file if compression fails
  }
}

Future<File?> _aggressiveCompress(File originalFile, String outputPath) async {
  try {
    // Very aggressive compression for large files
    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      originalFile.absolute.path,
      outputPath.replaceAll('.', '_aggressive.'),
      quality: 20, // Very low quality
      minWidth: 1280, // Smaller dimensions
      minHeight: 720,
      format: CompressFormat.jpeg,
    );

    if (compressedFile != null) {
      final size = await File(compressedFile.path).length();
      final sizeInMB = size / (1024 * 1024);
      print('Aggressively compressed size: ${sizeInMB.toStringAsFixed(2)} MB');

      return File(compressedFile.path);
    }

    return originalFile;
  } catch (e) {
    print('Error in aggressive compression: $e');
    return originalFile;
  }
}

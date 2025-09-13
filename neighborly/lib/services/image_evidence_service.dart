import 'dart:io';
// TODO: Enable when Firebase Storage is properly configured
// import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

/// Service for handling image evidence uploads with compression and content moderation
/// 
/// IMPORTANT: This service currently uses placeholder implementations for Firebase Storage
/// To enable full functionality:
/// 1. Uncomment the firebase_storage import above
/// 2. Replace placeholder implementations in _uploadSingleImage and deleteImages methods
/// 3. Test Firebase Storage configuration in your project
class ImageEvidenceService {
  static const uuid = Uuid();
  static const int maxImageSize = 2 * 1024 * 1024; // 2MB
  static const int maxImages = 5;
  static const int compressQuality = 70;
  
  // Content moderation keywords (basic implementation)
  static const List<String> _inappropriateKeywords = [
    // Add inappropriate content detection keywords here
    'inappropriate', 'offensive', 'explicit'
  ];
  
  /// Compress image file to reduce size and improve upload speed
  static Future<File?> _compressImage(File imageFile) async {
    try {
      final String targetPath = '${imageFile.path}_compressed.jpg';
      
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: compressQuality,
        minHeight: 1920,
        minWidth: 1080,
        format: CompressFormat.jpeg,
      );
      
      if (compressedFile != null) {
        final compressedSize = await File(compressedFile.path).length();
        
        // If compressed file is still too large, compress further
        if (compressedSize > maxImageSize) {
          final secondCompression = await FlutterImageCompress.compressAndGetFile(
            compressedFile.path,
            '${compressedFile.path}_final.jpg',
            quality: 50,
            minHeight: 1280,
            minWidth: 720,
            format: CompressFormat.jpeg,
          );
          
          if (secondCompression != null) {
            // Clean up intermediate file
            try {
              await File(compressedFile.path).delete();
            } catch (e) {
              print('Warning: Could not delete intermediate file: $e');
            }
            return File(secondCompression.path);
          }
        }
        
        return File(compressedFile.path);
      }
      
      return null;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }
  
  /// Basic content moderation check
  static Future<bool> _isContentAppropriate(File imageFile) async {
    try {
      // Basic filename and path check
      final fileName = path.basename(imageFile.path).toLowerCase();
      
      for (String keyword in _inappropriateKeywords) {
        if (fileName.contains(keyword)) {
          return false;
        }
      }
      
      // Additional checks could include:
      // - Image analysis using ML models
      // - Cloud-based content moderation APIs
      // - File size and format validation
      
      return true;
    } catch (e) {
      print('Error checking content appropriateness: $e');
      // If moderation check fails, err on the side of caution
      return false;
    }
  }
  
  /// Upload single image to Firebase Storage
  static Future<String?> _uploadSingleImage(
    File imageFile, 
    String userId, 
    Function(double) onProgress
  ) async {
    try {
      // Compress the image first
      final compressedImage = await _compressImage(imageFile);
      if (compressedImage == null) {
        throw Exception('Failed to compress image');
      }
      
      // Check content appropriateness
      final isAppropriate = await _isContentAppropriate(compressedImage);
      if (!isAppropriate) {
        throw Exception('Image content not appropriate');
      }
      
      // Generate unique filename
      final String fileName = '${uuid.v4()}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = 'report-evidence/$userId/$fileName';
      
      // TODO: Implement Firebase Storage upload when properly configured
      // For now, return a placeholder URL to maintain functionality
      print('Image would be uploaded to: $filePath');
      print('Compressed image size: ${(await compressedImage.length())} bytes');
      
      // Simulate upload progress
      for (int i = 0; i <= 100; i += 20) {
        onProgress(i / 100.0);
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // Clean up compressed file
      try {
        await compressedImage.delete();
      } catch (e) {
        print('Warning: Could not delete compressed file: $e');
      }
      
      // Return placeholder URL (in production, this would be the actual Firebase Storage URL)
      final String placeholderURL = 'placeholder://uploaded-image/$fileName';
      return placeholderURL;
      
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
  
  /// Upload multiple images with progress tracking
  static Future<ImageUploadResult> uploadImages(
    List<File> images, 
    String userId, 
    Function(int current, int total, double currentProgress) onProgress
  ) async {
    if (images.isEmpty) {
      return ImageUploadResult(
        success: true,
        uploadedUrls: [],
        failedCount: 0,
        errors: [],
      );
    }
    
    if (images.length > maxImages) {
      return ImageUploadResult(
        success: false,
        uploadedUrls: [],
        failedCount: images.length,
        errors: ['Maximum $maxImages images allowed'],
      );
    }
    
    List<String> uploadedUrls = [];
    List<String> errors = [];
    int failedCount = 0;
    
    for (int i = 0; i < images.length; i++) {
      final File image = images[i];
      
      try {
        // Check file size before upload
        final fileSize = await image.length();
        if (fileSize > maxImageSize * 2) { // Allow 2x max size before compression
          errors.add('Image ${i + 1}: File too large (${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB)');
          failedCount++;
          continue;
        }
        
        // Upload single image with progress callback
        final String? url = await _uploadSingleImage(
          image,
          userId,
          (progress) => onProgress(i + 1, images.length, progress),
        );
        
        if (url != null) {
          uploadedUrls.add(url);
        } else {
          errors.add('Image ${i + 1}: Upload failed');
          failedCount++;
        }
        
      } catch (e) {
        errors.add('Image ${i + 1}: ${e.toString()}');
        failedCount++;
      }
    }
    
    return ImageUploadResult(
      success: failedCount == 0,
      uploadedUrls: uploadedUrls,
      failedCount: failedCount,
      errors: errors,
    );
  }
  
  /// Delete images from Firebase Storage
  static Future<void> deleteImages(List<String> imageUrls) async {
    for (String url in imageUrls) {
      try {
        // TODO: Implement Firebase Storage deletion when properly configured
        print('Would delete image: $url');
        // In production, this would call: FirebaseStorage.instance.refFromURL(url).delete()
      } catch (e) {
        print('Error deleting image: $e');
        // Continue with other deletions even if one fails
      }
    }
  }
  
  /// Validate image file before processing
  static Future<ImageValidationResult> validateImage(File imageFile) async {
    try {
      final fileSize = await imageFile.length();
      final fileName = path.basename(imageFile.path);
      final fileExtension = path.extension(fileName).toLowerCase();
      
      // Check file extension
      const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
      if (!allowedExtensions.contains(fileExtension)) {
        return ImageValidationResult(
          isValid: false,
          error: 'Unsupported file format. Please use JPG, PNG, or WebP.',
        );
      }
      
      // Check file size (before compression)
      if (fileSize > maxImageSize * 3) { // Allow 3x max size before compression
        return ImageValidationResult(
          isValid: false,
          error: 'Image too large. Maximum size allowed: ${(maxImageSize * 3 / (1024 * 1024)).toInt()}MB',
        );
      }
      
      // Check if file exists and is readable
      if (!await imageFile.exists()) {
        return ImageValidationResult(
          isValid: false,
          error: 'Image file not found.',
        );
      }
      
      return ImageValidationResult(isValid: true);
      
    } catch (e) {
      return ImageValidationResult(
        isValid: false,
        error: 'Error validating image: ${e.toString()}',
      );
    }
  }
}

/// Result class for image upload operations
class ImageUploadResult {
  final bool success;
  final List<String> uploadedUrls;
  final int failedCount;
  final List<String> errors;
  
  ImageUploadResult({
    required this.success,
    required this.uploadedUrls,
    required this.failedCount,
    required this.errors,
  });
  
  bool get hasPartialSuccess => uploadedUrls.isNotEmpty && failedCount > 0;
  int get successCount => uploadedUrls.length;
  int get totalAttempted => successCount + failedCount;
}

/// Result class for image validation
class ImageValidationResult {
  final bool isValid;
  final String? error;
  
  ImageValidationResult({
    required this.isValid,
    this.error,
  });
}

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neighborly/models/feedback_models.dart';
import 'package:neighborly/config/api_config.dart';
import 'package:neighborly/services/image_evidence_service.dart';

class ReportFeedbackService {
  static String get baseUrl => '${ApiConfig.baseUrl}/api/report-feedback';

  // Get current user's auth token
  static Future<String?> _getAuthToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  // Submit a report with optional images and progress tracking
  static Future<Map<String, dynamic>> submitReport(
    ReportData report, {
    List<File>? images,
    Function(int current, int total, double progress)? onImageUploadProgress,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'error': 'Authentication required'};
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      // Upload images if provided
      List<String>? imageUrls;
      if (images != null && images.isNotEmpty) {
        // Validate all images first
        for (int i = 0; i < images.length; i++) {
          final validation = await ImageEvidenceService.validateImage(images[i]);
          if (!validation.isValid) {
            return {
              'success': false, 
              'error': 'Image ${i + 1}: ${validation.error}'
            };
          }
        }

        // Upload images with progress tracking
        final uploadResult = await ImageEvidenceService.uploadImages(
          images,
          user.uid,
          (current, total, progress) {
            onImageUploadProgress?.call(current, total, progress);
          },
        );

        if (!uploadResult.success && uploadResult.uploadedUrls.isEmpty) {
          return {
            'success': false,
            'error': 'Failed to upload images: ${uploadResult.errors.join(', ')}'
          };
        }

        imageUrls = uploadResult.uploadedUrls;
        
        // If some images failed but we have at least one, continue with partial success
        if (uploadResult.hasPartialSuccess) {
          // Could show a warning here, but continue with successful uploads
        }
      }

      // Create report with uploaded image URLs
      final reportWithImages = ReportData(
        id: report.id,
        reporterId: report.reporterId,
        reportedUserEmail: report.reportedUserEmail,
        reportedContentId: report.reportedContentId,
        reportType: report.reportType,
        severity: report.severity,
        description: report.description,
        textEvidence: report.textEvidence,
        imageEvidenceUrls: imageUrls ?? report.imageEvidenceUrls,
        createdAt: report.createdAt,
        status: report.status,
        isAnonymous: report.isAnonymous,
      );

      final response = await http.post(
        Uri.parse('$baseUrl/report'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(reportWithImages.toJson()),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        // If we had images, include upload info
        if (images != null && images.isNotEmpty) {
          result['imageUploadInfo'] = {
            'totalImages': images.length,
            'successfulUploads': imageUrls?.length ?? 0,
          };
        }
        
        return result;
      } else {
        // If API call fails but images were uploaded, clean them up
        if (imageUrls != null && imageUrls.isNotEmpty) {
          try {
            await ImageEvidenceService.deleteImages(imageUrls);
          } catch (e) {
            print('Warning: Could not clean up uploaded images: $e');
          }
        }
        
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to submit report'
        };
      }
    } catch (e) {
      print('Error submitting report: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Submit feedback
  static Future<Map<String, dynamic>> submitFeedback(FeedbackData feedback) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'error': 'Authentication required'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/feedback'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(feedback.toJson()),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to submit feedback'
        };
      }
    } catch (e) {
      print('Error submitting feedback: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get user ratings and trust score
  static Future<Map<String, dynamic>> getUserRatings(String userEmail) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'error': 'Authentication required'};
      }

      final encodedEmail = Uri.encodeComponent(userEmail);
      final response = await http.get(
        Uri.parse('$baseUrl/user-ratings/$encodedEmail'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to get user ratings'
        };
      }
    } catch (e) {
      print('Error getting user ratings: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}

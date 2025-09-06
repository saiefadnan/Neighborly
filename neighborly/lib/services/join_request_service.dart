import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

// Data model for join requests from API
class JoinRequestData {
  final String userEmail;
  final String username;
  final String profileImage;
  final String message;
  final DateTime requestDate;
  final String userId;

  JoinRequestData({
    required this.userEmail,
    required this.username,
    required this.profileImage,
    required this.message,
    required this.requestDate,
    required this.userId,
  });

  factory JoinRequestData.fromJson(Map<String, dynamic> json) {
    return JoinRequestData(
      userEmail: json['userEmail'] ?? '',
      username: json['username'] ?? '',
      profileImage: json['profileImage'] ?? '',
      message: json['message'] ?? '',
      requestDate: _parseDate(json['requestDate']),
      userId: json['userId'] ?? '',
    );
  }

  static DateTime _parseDate(dynamic dateData) {
    if (dateData == null) return DateTime.now();

    if (dateData is Map<String, dynamic>) {
      // Firebase Timestamp format
      final seconds = dateData['_seconds'] ?? 0;
      final nanoseconds = dateData['_nanoseconds'] ?? 0;
      return DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000 + (nanoseconds / 1000000).round(),
      );
    } else if (dateData is String) {
      return DateTime.tryParse(dateData) ?? DateTime.now();
    } else {
      return DateTime.now();
    }
  }
}

class JoinRequestService {
  static String get baseUrl => '${ApiConfig.baseUrl}/api/communities';

  // Submit a join request
  Future<Map<String, dynamic>> submitJoinRequest({
    required String userId,
    required String communityId,
    required String userEmail,
    required String username,
    String message = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/join'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'communityId': communityId,
          'userEmail': userEmail,
          'username': username,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to submit join request',
        };
      }
    } catch (e) {
      print('Error submitting join request: $e');
      return {
        'success': false,
        'message': 'Network error: Failed to submit join request',
      };
    }
  }

  // Get pending join requests for a community (admin only)
  Future<List<JoinRequestData>> getPendingJoinRequests(
    String communityId, {
    required String adminEmail,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$communityId/join-requests'),
        headers: {
          'Content-Type': 'application/json',
          'admin-email': adminEmail,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> requestsJson = data['data'] ?? [];
          return requestsJson
              .map((json) => JoinRequestData.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching join requests: $e');
      return [];
    }
  }

  // Approve a join request (admin only)
  Future<Map<String, dynamic>> approveJoinRequest({
    required String adminEmail,
    required String communityId,
    required String userEmail,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/approve-join'),
        headers: {
          'Content-Type': 'application/json',
          'admin-email': adminEmail,
        },
        body: json.encode({'communityId': communityId, 'userEmail': userEmail}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to approve join request',
        };
      }
    } catch (e) {
      print('Error approving join request: $e');
      return {
        'success': false,
        'message': 'Network error: Failed to approve join request',
      };
    }
  }

  // Reject a join request (admin only)
  Future<Map<String, dynamic>> rejectJoinRequest({
    required String adminEmail,
    required String communityId,
    required String userEmail,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reject-join'),
        headers: {
          'Content-Type': 'application/json',
          'admin-email': adminEmail,
        },
        body: json.encode({'communityId': communityId, 'userEmail': userEmail}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to reject join request',
        };
      }
    } catch (e) {
      print('Error rejecting join request: $e');
      return {
        'success': false,
        'message': 'Network error: Failed to reject join request',
      };
    }
  }
}

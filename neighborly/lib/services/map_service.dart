import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/api_config.dart';

class MapService {
  // Update this URL to match your backend deployment
  static String get baseUrl => '${ApiConfig.baseUrl}${ApiConfig.mapApiPath}';

  // Get the current user's Firebase ID token
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

  // Create a new help request
  static Future<Map<String, dynamic>> createHelpRequest({
    required String type,
    required String title,
    required String description,
    required LatLng location,
    required String address,
    String priority = 'medium',
    String? phone,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/requests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'type': type,
          'title': title,
          'description': description,
          'location': {
            'latitude': location.latitude,
            'longitude': location.longitude,
          },
          'address': address,
          'priority': priority,
          'phone': phone ?? '',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': data['data'],
          'requestId': data['requestId'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create help request',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get nearby help requests
  static Future<Map<String, dynamic>> getNearbyHelpRequests({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    String status = 'open',
  }) async {
    try {
      print('🌐 MapService: Getting nearby help requests...');
      print('🌐 Base URL: $baseUrl');
      
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final uri = Uri.parse('$baseUrl/requests/nearby').replace(
        queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'radiusKm': radiusKm.toString(),
          'status': status,
        },
      );

      print('🌐 Making nearby request to: ${uri.toString()}');

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      print('🌐 Nearby response status: ${response.statusCode}');
      print('🌐 Nearby response body: ${response.body}');

      /**print('Nearby API Request: ${uri.toString()}');
      print('Nearby Response status: ${response.statusCode}');
      print('Nearby Response body: ${response.body}');**/

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data'], 'count': data['count']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch help requests',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get all help requests (with optional filters)
  static Future<Map<String, dynamic>> getHelpRequests({
    String? status,
    String? type,
    String? userId,
    int limit = 50,
  }) async {
    try {
      print('🌐 MapService: Getting help requests...');
      print('🌐 Base URL: $baseUrl');
      
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final queryParams = <String, String>{'limit': limit.toString()};

      if (status != null) queryParams['status'] = status;
      if (type != null) queryParams['type'] = type;
      if (userId != null) queryParams['userId'] = userId;

      final uri = Uri.parse(
        '$baseUrl/requests',
      ).replace(queryParameters: queryParams);

      print('🌐 Making request to: ${uri.toString()}');

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      print('🌐 Response status: ${response.statusCode}');
      print('🌐 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data'], 'count': data['count']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch help requests',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Respond to a help request
  static Future<Map<String, dynamic>> respondToHelpRequest({
    required String requestId,
    String? message,
    String? phone,
    String? username,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/requests/$requestId/responses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': message ?? '',
          'phone': phone ?? '',
          'username': username ?? 'Anonymous',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'responseId': data['responseId']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to respond to help request',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Accept a responder
  static Future<Map<String, dynamic>> acceptResponder({
    required String requestId,
    required String responseId,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/requests/$requestId/responses/$responseId/accept'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to accept responder',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Update help request status
  static Future<Map<String, dynamic>> updateHelpRequestStatus({
    required String requestId,
    required String status,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/requests/$requestId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update help request status',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Delete help request
  static Future<Map<String, dynamic>> deleteHelpRequest({
    required String requestId,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/requests/$requestId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete help request',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Helper method to convert API response to the format expected by the UI
  static Map<String, dynamic> convertApiResponseToUIFormat(
    Map<String, dynamic> apiData,
  ) {
    //print('Converting API data: $apiData');

    // Check if location data exists and is valid
    if (apiData['location'] == null) {
      //print('Error: No location data found in API response');
      throw Exception('Invalid location data in API response');
    }

    final location = apiData['location'];
    if (location['latitude'] == null || location['longitude'] == null) {
      //print('Error: Invalid latitude/longitude in API response');
      throw Exception('Invalid latitude/longitude in API response');
    }

    final result = {
      'id': apiData['id'] ?? '',
      'type': apiData['type'] ?? 'General',
      'title': apiData['title'] ?? 'Help Request',
      'description': apiData['description'] ?? '',
      'location': LatLng(
        (location['latitude'] as num).toDouble(),
        (location['longitude'] as num).toDouble(),
      ),
      'address': apiData['address'] ?? '',
      'priority': apiData['priority'] ?? 'medium',
      'phone': apiData['phone'] ?? '',
      'status': apiData['status'] ?? 'open',
      'acceptedResponderId': apiData['acceptedResponderId'],
      'userId': apiData['userId'] ?? '',
      'username': apiData['username'] ?? 'Anonymous User',
      'time': _formatTime(apiData['createdAt']),
      'responders':
          (apiData['responses'] as List? ?? [])
              .map(
                (response) => {
                  'userId':
                      response['userId'] ??
                      response['id'] ??
                      '', // Use userId if available, fallback to id
                  'username': response['username'] ?? 'Anonymous',
                  'phone': response['phone'] ?? '',
                  'responseTime': _formatTime(response['createdAt']),
                  'status': response['status'] ?? 'pending',
                },
              )
              .toList(),
    };

    //print('Converted result: $result');
    return result;
  }

  // Helper method to format time from ISO string to relative time
  static String _formatTime(String? isoString) {
    if (isoString == null) return 'Just now';

    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} mins ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else {
        return '${difference.inDays} days ago';
      }
    } catch (e) {
      return 'Just now';
    }
  }

  // Create dummy help requests for testing (easily removable)
  static Future<Map<String, dynamic>> createDummyHelpRequests() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/test/create-dummy-data'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('Dummy data created successfully: ${responseData['message']}');
        return responseData;
      } else {
        print('Failed to create dummy data. Status: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to create dummy help requests');
      }
    } catch (e) {
      print('Error creating dummy help requests: $e');
      throw Exception('Error creating dummy help requests: $e');
    }
  }

  // Remove all dummy help requests
  static Future<Map<String, dynamic>> removeDummyHelpRequests() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/test/remove-dummy-data'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Dummy data removed successfully: ${responseData['message']}');
        return responseData;
      } else {
        print('Failed to remove dummy data. Status: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to remove dummy help requests');
      }
    } catch (e) {
      print('Error removing dummy help requests: $e');
      throw Exception('Error removing dummy help requests: $e');
    }
  }
}

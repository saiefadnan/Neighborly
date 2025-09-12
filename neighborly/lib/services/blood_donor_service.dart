import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class BloodDonorService {
  static String get baseUrl => '${ApiConfig.baseUrl}/api/blood-donor';

  // Check if user is already registered as a donor
  static Future<Map<String, dynamic>> checkDonorRegistration(
    String email,
  ) async {
    try {
      print('🩸 Checking donor registration for: $email');
      print('🩸 URL: $baseUrl/check/$email');
      
      final response = await http.get(
        Uri.parse('$baseUrl/check/$email'),
        headers: {'Content-Type': 'application/json'},
      );

      print('🩸 Check response status: ${response.statusCode}');
      print('🩸 Check response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'isRegistered': data['isRegistered'] ?? false,
          'donorData': data['donorData'],
        };
      } else {
        return {
          'success': false,
          'isRegistered': false,
          'message': 'Failed to check registration status',
        };
      }
    } catch (e) {
      print('Error checking donor registration: $e');
      return {
        'success': false,
        'isRegistered': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Register as a new blood donor
  static Future<Map<String, dynamic>> registerDonor({
    required String email,
    required String name,
    required String phone,
    required String location,
    required String bloodGroup,
    required bool isAvailable,
    String? emergencyContact,
    String? medicalNotes,
  }) async {
    try {
      print('🩸 Registering donor: $email');
      print('🩸 URL: $baseUrl/register');
      print('🩸 Base URL from config: ${ApiConfig.baseUrl}');
      
      final requestBody = {
        'email': email,
        'name': name,
        'phone': phone,
        'location': location,
        'bloodGroup': bloodGroup,
        'isAvailable': isAvailable,
        'emergencyContact': emergencyContact,
        'medicalNotes': medicalNotes,
      };
      
      print('🩸 Request body: $requestBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('🩸 Register response status: ${response.statusCode}');
      print('🩸 Register response headers: ${response.headers}');
      print('🩸 Register response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Successfully registered as donor',
          'donorData': data['donorData'],
        };
      } else {
        // Try to parse error response
        try {
          final data = json.decode(response.body);
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to register as donor',
          };
        } catch (parseError) {
          print('🩸 Failed to parse error response: $parseError');
          return {
            'success': false,
            'message': 'Server error: ${response.statusCode} - ${response.body}',
          };
        }
      }
    } catch (e) {
      print('🩸 Network error registering donor: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update existing donor profile
  static Future<Map<String, dynamic>> updateDonorProfile({
    required String email,
    String? name,
    String? phone,
    String? location,
    String? bloodGroup,
    bool? isAvailable,
    String? lastDonationDate,
    int? totalDonations,
    String? emergencyContact,
    String? medicalNotes,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (location != null) updateData['location'] = location;
      if (bloodGroup != null) updateData['bloodGroup'] = bloodGroup;
      if (isAvailable != null) updateData['isAvailable'] = isAvailable;
      if (lastDonationDate != null) {
        updateData['lastDonationDate'] = lastDonationDate;
      }
      if (totalDonations != null) updateData['totalDonations'] = totalDonations;
      if (emergencyContact != null) {
        updateData['emergencyContact'] = emergencyContact;
      }
      if (medicalNotes != null) updateData['medicalNotes'] = medicalNotes;

      print('🩸 Updating donor profile for: $email');
      print('🩸 URL: $baseUrl/update/$email');
      print('🩸 Update data: $updateData');

      final response = await http.put(
        Uri.parse('$baseUrl/update/$email'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updateData),
      );

      print('🩸 Update response status: ${response.statusCode}');
      print('🩸 Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Profile updated successfully',
          'donorData': data['donorData'],
        };
      } else {
        try {
          final data = json.decode(response.body);
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to update profile',
          };
        } catch (parseError) {
          return {
            'success': false,
            'message': 'Server error: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      print('Error updating donor profile: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get all donors with optional filters
  static Future<Map<String, dynamic>> getAllDonors({
    String? bloodGroup,
    String? location,
    bool? isAvailable,
    String? userEmail, // For community-based filtering
  }) async {
    try {
      final Map<String, String> queryParams = {};
      if (bloodGroup != null && bloodGroup != 'All') {
        queryParams['bloodGroup'] = bloodGroup;
      }
      if (location != null && location.isNotEmpty) {
        queryParams['location'] = location;
      }
      if (isAvailable != null) {
        queryParams['isAvailable'] = isAvailable.toString();
      }
      if (userEmail != null) queryParams['userEmail'] = userEmail;

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      
      print('🩸 Getting all donors');
      print('🩸 URL: ${uri.toString()}');
      
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      print('🩸 Get donors response status: ${response.statusCode}');
      print('🩸 Get donors response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'donors': data['donors'] ?? []};
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch donors',
          'donors': [],
        };
      }
    } catch (e) {
      print('Error fetching donors: $e');
      return {'success': false, 'message': 'Network error: $e', 'donors': []};
    }
  }

  // Update availability status
  static Future<Map<String, dynamic>> updateAvailability({
    required String email,
    required bool isAvailable,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/blood-donors/$email/availability'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'isAvailable': isAvailable}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Availability updated successfully',
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update availability',
        };
      }
    } catch (e) {
      print('Error updating availability: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update last donation date
  static Future<Map<String, dynamic>> updateLastDonation({
    required String email,
    required String lastDonationDate,
    int? totalDonations,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'lastDonationDate': lastDonationDate,
      };
      if (totalDonations != null) {
        updateData['totalDonations'] = totalDonations;
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/blood-donors/$email/donation'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Donation record updated successfully',
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update donation record',
        };
      }
    } catch (e) {
      print('Error updating donation record: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class BloodDonorService {
  static String get baseUrl => '${ApiConfig.baseUrl}/api';

  // Check if user is already registered as a donor
  static Future<Map<String, dynamic>> checkDonorRegistration(
    String email,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/blood-donors/check/$email'),
        headers: {'Content-Type': 'application/json'},
      );

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
    required String bloodGroup,
    required bool isAvailable,
    String? emergencyContact,
    String? medicalNotes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/blood-donors/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'bloodGroup': bloodGroup,
          'isAvailable': isAvailable,
          'emergencyContact': emergencyContact,
          'medicalNotes': medicalNotes,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Successfully registered as donor',
          'donorData': data['donorData'],
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to register as donor',
        };
      }
    } catch (e) {
      print('Error registering donor: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update existing donor profile
  static Future<Map<String, dynamic>> updateDonorProfile({
    required String email,
    String? bloodGroup,
    bool? isAvailable,
    String? lastDonationDate,
    int? totalDonations,
    String? emergencyContact,
    String? medicalNotes,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
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

      final response = await http.put(
        Uri.parse('$baseUrl/blood-donors/update/$email'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Profile updated successfully',
          'donorData': data['donorData'],
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update profile',
        };
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

      final uri = Uri.parse(
        '$baseUrl/blood-donors',
      ).replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

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

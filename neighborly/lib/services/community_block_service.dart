import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class CommunityBlockService {
  static String get baseUrl => '${ApiConfig.baseUrl}/api';

  // Block a user in a specific community
  Future<bool> blockUserInCommunity({
    required String communityId,
    required String userEmail,
    required String adminEmail,
    required String blockType, // 'temporary', 'indefinite', 'permanent'
    String? duration, // '1 day', '3 days', etc.
    required String reason,
    String? customReason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/communities/$communityId/members/$userEmail/block'),
        headers: {
          'Content-Type': 'application/json',
          'admin-email': adminEmail,
        },
        body: json.encode({
          'blockType': blockType,
          'duration': duration,
          'reason': reason,
          'customReason': customReason,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }

      return false;
    } catch (e) {
      print('Error blocking user: $e');
      return false;
    }
  }

  // Unblock a user in a specific community
  Future<bool> unblockUserInCommunity({
    required String communityId,
    required String userEmail,
    required String adminEmail,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/communities/$communityId/members/$userEmail/block'),
        headers: {
          'Content-Type': 'application/json',
          'admin-email': adminEmail,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }

      return false;
    } catch (e) {
      print('Error unblocking user: $e');
      return false;
    }
  }

  // Remove user from community (without blocking)
  Future<bool> removeUserFromCommunity({
    required String communityId,
    required String userEmail,
    required String adminEmail,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/communities/$communityId/members/$userEmail'),
        headers: {
          'Content-Type': 'application/json',
          'admin-email': adminEmail,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }

      return false;
    } catch (e) {
      print('Error removing user: $e');
      return false;
    }
  }

  // Check if user is blocked in a community
  Future<Map<String, dynamic>?> checkUserBlockStatus({
    required String communityId,
    required String userEmail,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/communities/$communityId/members/$userEmail/block-status',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }

      return null;
    } catch (e) {
      print('Error checking block status: $e');
      return null;
    }
  }

  // Get all active blocks for a community (admin only)
  Future<List<Map<String, dynamic>>> getCommunityBlocks({
    required String communityId,
    required String adminEmail,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/communities/$communityId/blocks'),
        headers: {
          'Content-Type': 'application/json',
          'admin-email': adminEmail,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }

      return [];
    } catch (e) {
      print('Error fetching community blocks: $e');
      return [];
    }
  }
}

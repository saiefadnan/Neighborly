import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/community_provider.dart';
import '../config/api_config.dart';

class CommunityService {
  static String get baseUrl =>
      '${ApiConfig.baseUrl}/api'; // Use ApiConfig instead of hardcoded URL

  // Get all communities
  Future<List<CommunityData>> getAllCommunities() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/communities'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> communitiesJson = data['data'];
          return communitiesJson
              .map((json) => CommunityData.fromJson(json))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch communities');
        }
      } else {
        throw Exception('Failed to fetch communities: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAllCommunities: $e');
      // Return sample data for now
      return _getSampleCommunities();
    }
  }

  // Get user's communities
  Future<List<CommunityData>> getUserCommunities(String userEmailOrId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/communities/user/$userEmailOrId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> communitiesJson = data['data'];
          return communitiesJson
              .map((json) => CommunityData.fromJson(json))
              .toList();
        } else {
          throw Exception(
            data['message'] ?? 'Failed to fetch user communities',
          );
        }
      } else {
        throw Exception(
          'Failed to fetch user communities: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in getUserCommunities: $e');
      // Return sample user communities for now
      return _getSampleUserCommunities();
    }
  }

  // Join a community
  Future<Map<String, dynamic>> joinCommunity(
    String userId,
    String communityId,
    String userEmail, {
    bool autoJoin = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/communities/join'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'communityId': communityId,
          'userEmail': userEmail,
          'autoJoin': autoJoin,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to join community',
        };
      }
    } catch (e) {
      print('Error in joinCommunity: $e');
      // Return success for demo purposes
      return {'success': true, 'message': 'Successfully joined community!'};
    }
  }

  // Leave a community
  Future<Map<String, dynamic>> leaveCommunity(
    String userId,
    String communityId,
    String userEmail,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/communities/leave'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'communityId': communityId,
          'userEmail': userEmail,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to leave community',
        };
      }
    } catch (e) {
      print('Error in leaveCommunity: $e');
      // Return success for demo purposes
      return {'success': true, 'message': 'Successfully left community'};
    }
  }

  // Get community by ID
  Future<CommunityData?> getCommunityById(String communityId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/communities/$communityId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return CommunityData.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error in getCommunityById: $e');
      return null;
    }
  }

  // Sample data for testing (will be replaced by real backend data)
  List<CommunityData> _getSampleCommunities() {
    return [
      CommunityData(
        id: 'dhanmondi',
        name: 'Dhanmondi',
        description:
            'A vibrant residential area known for its cultural heritage and green spaces.',
        location: 'Dhaka, Bangladesh',
        admins: ['admin@dhanmondi.com'],
        members: ['user1@example.com', 'user2@example.com'],
        joinRequests: [],
        memberCount: 1248,
        tags: ['Residential', 'Cultural', 'Safe'],
        recentActivity: 'Last active 2 hours ago',
      ),
      CommunityData(
        id: 'gulshan',
        name: 'Gulshan',
        description:
            'Upscale commercial and residential area with modern amenities.',
        location: 'Dhaka, Bangladesh',
        admins: ['admin@gulshan.com'],
        members: ['user3@example.com'],
        joinRequests: [],
        memberCount: 2156,
        tags: ['Commercial', 'Upscale', 'Modern'],
        recentActivity: 'Last active 1 hour ago',
      ),
      CommunityData(
        id: 'bashundhara',
        name: 'Bashundhara',
        description:
            'Modern planned residential area with excellent facilities.',
        location: 'Dhaka, Bangladesh',
        admins: ['admin@bashundhara.com'],
        members: [],
        joinRequests: [],
        memberCount: 1876,
        tags: ['Modern', 'Planned', 'Facilities'],
        recentActivity: 'Last active 20 minutes ago',
      ),
      CommunityData(
        id: 'mirpur',
        name: 'Mirpur',
        description:
            'Large residential area known for its diversity and community spirit.',
        location: 'Dhaka, Bangladesh',
        admins: ['admin@mirpur.com'],
        members: [],
        joinRequests: [],
        memberCount: 1543,
        tags: ['Residential', 'Diverse', 'Active'],
        recentActivity: 'Last active 15 minutes ago',
      ),
      CommunityData(
        id: 'mohammadpur',
        name: 'Mohammadpur',
        description:
            'Densely populated residential area with rich local culture.',
        location: 'Dhaka, Bangladesh',
        admins: ['admin@mohammadpur.com'],
        members: [],
        joinRequests: [],
        memberCount: 987,
        tags: ['Residential', 'Cultural', 'Busy'],
        recentActivity: 'Last active 30 minutes ago',
      ),
    ];
  }

  List<CommunityData> _getSampleUserCommunities() {
    return [
      CommunityData(
        id: 'dhanmondi',
        name: 'Dhanmondi',
        description:
            'A vibrant residential area known for its cultural heritage and green spaces.',
        location: 'Dhaka, Bangladesh',
        admins: ['admin@dhanmondi.com'],
        members: ['user1@example.com', 'user2@example.com'],
        joinRequests: [],
        memberCount: 1248,
        tags: ['Residential', 'Cultural', 'Safe'],
        joinDate: DateTime.now().subtract(const Duration(days: 180)),
        recentActivity: 'Last active 2 hours ago',
      ),
      CommunityData(
        id: 'gulshan',
        name: 'Gulshan',
        description:
            'Upscale commercial and residential area with modern amenities.',
        location: 'Dhaka, Bangladesh',
        admins: ['admin@gulshan.com'],
        members: ['user3@example.com'],
        joinRequests: [],
        memberCount: 2156,
        tags: ['Commercial', 'Upscale', 'Modern'],
        joinDate: DateTime.now().subtract(const Duration(days: 365)),
        recentActivity: 'Last active 1 hour ago',
      ),
    ];
  }
}

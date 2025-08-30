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

  // Join a community (always submits join request for admin approval)
  Future<Map<String, dynamic>> joinCommunity(
    String userId,
    String communityId,
    String userEmail, {
    String username = '',
    String message = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/communities/join'),
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
      print('Error in joinCommunity: $e');
      return {
        'success': false,
        'message': 'Network error: Failed to submit join request',
      };
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

  // Get community members with user details
  Future<List<CommunityUser>> getCommunityMembers(String communityId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/communities/$communityId/members'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> membersJson = data['data'];
          return membersJson
              .map((json) => CommunityUser.fromJson(json))
              .toList();
        } else {
          throw Exception(
            data['message'] ?? 'Failed to fetch community members',
          );
        }
      } else {
        throw Exception(
          'Failed to fetch community members: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in getCommunityMembers: $e');
      // Return sample data for now
      return _getSampleCommunityMembers(communityId);
    }
  }

  // Get communities where user is admin
  Future<List<CommunityData>> getAdminCommunities(String userEmail) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/communities/admin/$userEmail'),
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
            data['message'] ?? 'Failed to fetch admin communities',
          );
        }
      } else {
        throw Exception(
          'Failed to fetch admin communities: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in getAdminCommunities: $e');
      // Return sample admin communities for now
      return _getSampleAdminCommunities();
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

  List<CommunityData> _getSampleAdminCommunities() {
    return [
      CommunityData(
        id: 'dhanmondi',
        name: 'Dhanmondi',
        description:
            'A vibrant residential area known for its cultural heritage and green spaces.',
        location: 'Dhaka, Bangladesh',
        imageUrl: 'assets/images/Image1.jpg',
        admins: ['admin@dhanmondi.com', 'test@example.com'],
        members: [
          'user1@example.com',
          'user2@example.com',
          'user3@example.com',
        ],
        joinRequests: ['pending1@example.com', 'pending2@example.com'],
        memberCount: 156,
        tags: ['Residential', 'Cultural', 'Safe'],
        recentActivity: 'Last active 2 hours ago',
      ),
      CommunityData(
        id: 'gulshan',
        name: 'Gulshan',
        description:
            'Upscale commercial and residential area with modern amenities.',
        location: 'Dhaka, Bangladesh',
        imageUrl: 'assets/images/Image2.jpg',
        admins: ['admin@gulshan.com', 'test@example.com'],
        members: ['user4@example.com', 'user5@example.com'],
        joinRequests: ['pending3@example.com'],
        memberCount: 89,
        tags: ['Commercial', 'Upscale', 'Modern'],
        recentActivity: 'Last active 1 hour ago',
      ),
    ];
  }

  List<CommunityUser> _getSampleCommunityMembers(String communityId) {
    return [
      CommunityUser(
        userId: '1',
        username: 'Sarah Ahmed',
        email: 'user1@example.com',
        profileImage: 'assets/images/Image1.jpg',
        preferredCommunity: communityId,
        isAdmin: false,
        blocked: false,
        joinedDate: DateTime.now().subtract(const Duration(days: 30)),
      ),
      CommunityUser(
        userId: '2',
        username: 'Karim Hassan',
        email: 'user2@example.com',
        profileImage: 'assets/images/Image2.jpg',
        preferredCommunity: communityId,
        isAdmin: false,
        blocked: true,
        joinedDate: DateTime.now().subtract(const Duration(days: 45)),
        blockedDate: DateTime.now().subtract(const Duration(days: 5)),
        blockedReason: 'Inappropriate behavior in community chat',
      ),
      CommunityUser(
        userId: '3',
        username: 'Rashida Begum',
        email: 'user3@example.com',
        profileImage: 'assets/images/Image3.jpg',
        preferredCommunity: communityId,
        isAdmin: false,
        blocked: false,
        joinedDate: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];
  }
}

// Community User Model for API responses
class CommunityUser {
  final String userId;
  final String username;
  final String email;
  final String profileImage;
  final String preferredCommunity;
  final bool isAdmin;
  bool blocked;
  final DateTime joinedDate;
  DateTime? blockedDate;
  String? blockedReason;

  CommunityUser({
    required this.userId,
    required this.username,
    required this.email,
    required this.profileImage,
    required this.preferredCommunity,
    required this.isAdmin,
    required this.blocked,
    required this.joinedDate,
    this.blockedDate,
    this.blockedReason,
  });

  factory CommunityUser.fromJson(Map<String, dynamic> json) {
    return CommunityUser(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profileImage'] ?? 'assets/images/dummy.png',
      preferredCommunity: json['preferredCommunity'] ?? '',
      isAdmin: json['isAdmin'] ?? false,
      blocked: json['blocked'] ?? false,
      joinedDate: _parseDateTime(json['joinedDate']),
      blockedDate: _parseDateTime(json['blockedDate']),
      blockedReason: json['blockedReason'],
    );
  }

  // Helper method to parse different date formats
  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();

    // Handle Firestore Timestamp format
    if (dateValue is Map && dateValue.containsKey('_seconds')) {
      final seconds = dateValue['_seconds'] as int;
      final nanoseconds = dateValue['_nanoseconds'] as int? ?? 0;
      return DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000 + (nanoseconds ~/ 1000000),
      );
    }

    // Handle ISO string format
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }

    // Default fallback
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'profileImage': profileImage,
      'preferredCommunity': preferredCommunity,
      'isAdmin': isAdmin,
      'blocked': blocked,
      'joinedDate': joinedDate.toIso8601String(),
      'blockedDate': blockedDate?.toIso8601String(),
      'blockedReason': blockedReason,
    };
  }
}

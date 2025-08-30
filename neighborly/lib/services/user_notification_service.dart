import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class UserNotification {
  final String id;
  final String recipientUserId;
  final String recipientEmail;
  final String type;
  final String title;
  final String message;
  final String? helpRequestId;
  final HelpRequestData? helpRequestData;
  final String communityId;
  final String communityName;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final Map<String, dynamic>? metadata;

  UserNotification({
    required this.id,
    required this.recipientUserId,
    required this.recipientEmail,
    required this.type,
    required this.title,
    required this.message,
    this.helpRequestId,
    this.helpRequestData,
    required this.communityId,
    required this.communityName,
    required this.isRead,
    required this.createdAt,
    this.expiresAt,
    this.metadata,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['id'] ?? '',
      recipientUserId: json['recipientUserId'] ?? '',
      recipientEmail: json['recipientEmail'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      helpRequestId: json['helpRequestId'],
      helpRequestData:
          json['helpRequestData'] != null
              ? HelpRequestData.fromJson(json['helpRequestData'])
              : null,
      communityId: json['communityId'] ?? '',
      communityName: json['communityName'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt']) ?? DateTime.now(),
      expiresAt:
          json['expiresAt'] != null
              ? DateTime.tryParse(json['expiresAt'])
              : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipientUserId': recipientUserId,
      'recipientEmail': recipientEmail,
      'type': type,
      'title': title,
      'message': message,
      'helpRequestId': helpRequestId,
      'helpRequestData': helpRequestData?.toJson(),
      'communityId': communityId,
      'communityName': communityName,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  UserNotification copyWith({
    String? id,
    String? recipientUserId,
    String? recipientEmail,
    String? type,
    String? title,
    String? message,
    String? helpRequestId,
    HelpRequestData? helpRequestData,
    String? communityId,
    String? communityName,
    bool? isRead,
    DateTime? createdAt,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) {
    return UserNotification(
      id: id ?? this.id,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      helpRequestId: helpRequestId ?? this.helpRequestId,
      helpRequestData: helpRequestData ?? this.helpRequestData,
      communityId: communityId ?? this.communityId,
      communityName: communityName ?? this.communityName,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

class HelpRequestData {
  final String requesterName;
  final String requesterUserId;
  final String helpType;
  final String urgency;
  final String location;
  final Map<String, double> coordinates;
  final String phone;
  final String description;

  HelpRequestData({
    required this.requesterName,
    required this.requesterUserId,
    required this.helpType,
    required this.urgency,
    required this.location,
    required this.coordinates,
    required this.phone,
    required this.description,
  });

  factory HelpRequestData.fromJson(Map<String, dynamic> json) {
    return HelpRequestData(
      requesterName: json['requesterName'] ?? '',
      requesterUserId: json['requesterUserId'] ?? '',
      helpType: json['helpType'] ?? '',
      urgency: json['urgency'] ?? 'general',
      location: json['location'] ?? '',
      coordinates: Map<String, double>.from(json['coordinates'] ?? {}),
      phone: json['phone'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requesterName': requesterName,
      'requesterUserId': requesterUserId,
      'helpType': helpType,
      'urgency': urgency,
      'location': location,
      'coordinates': coordinates,
      'phone': phone,
      'description': description,
    };
  }
}

class UserNotificationService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<String?> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    return await user?.getIdToken();
  }

  // Fetch user notifications
  static Future<List<UserNotification>> fetchUserNotifications({
    int limit = 50,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/notifications?limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> notificationsJson = data['data'] ?? [];
          return notificationsJson
              .map((json) => UserNotification.fromJson(json))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch notifications');
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: Failed to fetch notifications',
        );
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  // Mark notification as read
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/api/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        print('Failed to mark notification as read: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  // Mark all notifications as read
  static Future<bool> markAllNotificationsAsRead() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/api/notifications/read-all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        print(
          'Failed to mark all notifications as read: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  // Get urgency color for UI
  static String getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'emergency':
        return '#F44336'; // Red
      case 'urgent':
        return '#FF9800'; // Orange
      case 'general':
        return '#71BB7B'; // Green
      default:
        return '#9E9E9E'; // Grey
    }
  }

  // Get help type icon for UI
  static String getHelpTypeIcon(String helpType) {
    switch (helpType.toLowerCase()) {
      case 'medical':
        return '🏥';
      case 'fire':
        return '🔥';
      case 'shifting house':
        return '🏠';
      case 'grocery':
        return '🛒';
      case 'traffic update':
        return '🚦';
      case 'route':
        return '🗺️';
      case 'shifting furniture':
        return '🪑';
      case 'lost person':
        return '👤';
      case 'lost item/pet':
        return '🐕';
      default:
        return '🆘';
    }
  }

  // Format time ago
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}

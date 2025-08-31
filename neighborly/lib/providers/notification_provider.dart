import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/notification.dart';
import '../services/user_notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  // Legacy notifications for backward compatibility
  List<NotificationData> _legacyNotifications = [
    NotificationData(
      id: '1',
      name: 'Jack Conniler',
      message:
          'Needs immediate medical assistance. Please help if you\'re nearby with medical training.',
      image: 'assets/images/Image1.jpg',
      urgency: 'emergency',
      type: 'help_request',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      location: 'Dhanmondi 15, Dhaka',
      extraData: {
        'coordinates': {'lat': 23.8103, 'lng': 90.4125},
        'phone': '+880 1234-567890',
        'helpType': 'Medical',
      },
    ),
    NotificationData(
      id: '2',
      name: 'Sual Canal',
      message:
          'Emergency ambulance service required immediately. Patient is unconscious.',
      image: 'assets/images/Image2.jpg',
      urgency: 'emergency',
      type: 'help_request',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      location: 'Gulshan 2, Dhaka',
      extraData: {
        'coordinates': {'lat': 23.7925, 'lng': 90.4078},
        'phone': '+880 1987-654321',
        'helpType': 'Medical',
      },
    ),
    NotificationData(
      id: '3',
      name: 'Samuel Badre',
      message: 'Looking for help with grocery shopping for elderly neighbor.',
      image: 'assets/images/Image3.jpg',
      urgency: 'urgent',
      type: 'help_request',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      location: 'Bashundhara R/A, Dhaka',
      extraData: {
        'coordinates': {'lat': 23.8207, 'lng': 90.4290},
        'phone': '+880 1555-666777',
        'helpType': 'Grocery',
      },
    ),
  ];

  // New backend-integrated notifications
  List<UserNotification> _userNotifications = [];
  bool _isLoading = false;
  String? _error;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getters
  List<NotificationData> get legacyNotifications =>
      List.unmodifiable(_legacyNotifications);
  List<UserNotification> get userNotifications =>
      List.unmodifiable(_userNotifications);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Combined notifications getter for UI compatibility
  List<NotificationData> get notifications {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserUid = currentUser?.uid;

    // Convert UserNotifications to NotificationData for UI compatibility
    final convertedNotifications =
        _userNotifications
            .where((userNotif) {
              // Filter out notifications where current user is the requester
              if (currentUserUid != null) {
                final requesterUserId =
                    userNotif.helpRequestData?.requesterUserId;

                // If current user is the requester, filter it out
                if (requesterUserId == currentUserUid) {
                  print(
                    '🚫 Filtering out own help request notification: ${userNotif.title}',
                  );
                  print(
                    '🚫 Current user UID: $currentUserUid, Requester UID: $requesterUserId',
                  );
                  return false;
                }
              }

              return true;
            })
            .map((userNotif) {
              return NotificationData(
                id: userNotif.id,
                name:
                    userNotif.helpRequestData?.requesterName ?? 'Unknown User',
                message: userNotif.message,
                image: 'assets/images/dummy.png', // Default image
                urgency: _mapTypeToUrgency(
                  userNotif.type,
                  userNotif.helpRequestData?.urgency,
                ),
                type: _mapNotificationType(userNotif.type),
                timestamp: userNotif.createdAt,
                location:
                    userNotif.helpRequestData?.location ?? 'Unknown location',
                isRead: userNotif.isRead,
                extraData: {
                  'helpRequestId': userNotif.helpRequestId,
                  'requesterUserId': userNotif.helpRequestData?.requesterUserId,
                  'notificationType': userNotif.type,
                  'communityId': userNotif.communityId,
                  'communityName': userNotif.communityName,
                },
              );
            })
            .toList();

    // Combine and sort by timestamp
    final allNotifications = [
      ..._legacyNotifications,
      ...convertedNotifications,
    ];
    allNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    print(
      '📊 Showing ${allNotifications.length} notifications after filtering',
    );
    return allNotifications;
  }

  int get unreadCount {
    final legacyUnread = _legacyNotifications.where((n) => !n.isRead).length;
    final userUnread = _userNotifications.where((n) => !n.isRead).length;
    return legacyUnread + userUnread;
  }

  // Initialize notifications (using backend API only)
  Future<void> initializeNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ No authenticated user found for notifications');
      return;
    }

    print('🔔 Initializing notifications for user: ${user.uid}');
    print('🔔 User email: ${user.email}');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load notifications from backend API (which handles community-based filtering)
      print('📡 Loading notifications from backend...');
      await loadNotifications();
      print('✅ Notifications initialized successfully');
    } catch (e) {
      _error = 'Failed to initialize notifications: $e';
      print('❌ Error initializing notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load notifications from backend
  Future<void> loadNotifications() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('📡 Fetching notifications from backend API...');
      _userNotifications =
          await UserNotificationService.fetchUserNotifications();
      print(
        '✅ Backend API returned ${_userNotifications.length} notifications',
      );

      for (var notif in _userNotifications) {
        print('📋 Notification: ${notif.title} - ${notif.message}');
      }
    } catch (e) {
      _error = 'Failed to load notifications: $e';
      print('❌ Error loading notifications from backend: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      // Check if it's a legacy notification
      final legacyIndex = _legacyNotifications.indexWhere(
        (n) => n.id == notificationId,
      );
      if (legacyIndex != -1) {
        _legacyNotifications[legacyIndex] = _legacyNotifications[legacyIndex]
            .copyWith(isRead: true);
        notifyListeners();
        return;
      }

      // Handle user notification
      final userIndex = _userNotifications.indexWhere(
        (n) => n.id == notificationId,
      );
      if (userIndex != -1 && !_userNotifications[userIndex].isRead) {
        // Optimistically update UI
        _userNotifications[userIndex] = _userNotifications[userIndex].copyWith(
          isRead: true,
        );
        notifyListeners();

        // Update backend
        await UserNotificationService.markNotificationAsRead(notificationId);
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      // Revert optimistic update on error
      await loadNotifications();
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      // Mark legacy notifications as read
      _legacyNotifications =
          _legacyNotifications
              .map((notification) => notification.copyWith(isRead: true))
              .toList();

      // Optimistically update user notifications
      _userNotifications =
          _userNotifications
              .map((notification) => notification.copyWith(isRead: true))
              .toList();

      notifyListeners();

      // Update backend for user notifications
      await UserNotificationService.markAllNotificationsAsRead();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      // Revert optimistic update on error
      await loadNotifications();
    }
  }

  // Undo mark all as read (legacy functionality)
  void undoMarkAllAsRead() {
    _legacyNotifications =
        _legacyNotifications
            .map((notification) => notification.copyWith(isRead: false))
            .toList();
    notifyListeners();
  }

  // Add legacy notification (for backward compatibility)
  void addNotification(NotificationData notification) {
    _legacyNotifications.insert(0, notification);
    notifyListeners();
  }

  // Add help request notification (legacy method)
  void addHelpRequestNotification({
    required String name,
    required String message,
    required String helpType,
    required String urgency,
    required String location,
    required LatLng coordinates,
    required String phone,
    String? imageUrl,
  }) {
    final notification = NotificationData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      message: message,
      image: imageUrl ?? 'assets/images/dummy.png',
      urgency: urgency.toLowerCase(),
      type: 'help_request',
      timestamp: DateTime.now(),
      location: location,
      extraData: {
        'coordinates': {
          'lat': coordinates.latitude,
          'lng': coordinates.longitude,
        },
        'phone': phone,
        'helpType': helpType,
      },
    );

    addNotification(notification);
  }

  // Get filtered notifications
  List<NotificationData> getFilteredNotifications(String filter) {
    final allNotifications = notifications;
    if (filter == 'All') return allNotifications;
    return allNotifications.where((notification) {
      return notification.urgency.toLowerCase() == filter.toLowerCase();
    }).toList();
  }

  // Helper method to map type and urgency to UI urgency
  String _mapTypeToUrgency(String type, String? helpUrgency) {
    // For help request notifications, use the help request urgency
    if (type == 'help_request' && helpUrgency != null) {
      switch (helpUrgency.toLowerCase()) {
        case 'emergency':
          return 'emergency';
        case 'urgent':
          return 'urgent';
        case 'general':
        default:
          return 'normal';
      }
    }

    // For other notification types, map based on type
    switch (type) {
      case 'help_response':
        return 'urgent';
      case 'help_status_update':
        return 'normal';
      default:
        return 'normal';
    }
  }

  // Helper method to map notification type
  String _mapNotificationType(String type) {
    switch (type) {
      case 'help_request_created':
      case 'help_request_response':
      case 'help_request_status':
        return 'help_request';
      default:
        return 'general';
    }
  }

  // Refresh notifications
  Future<void> refresh() async {
    print('🔄 Refreshing notifications...');
    await loadNotifications();
    print('✅ Notifications refresh completed');
  }

  // Dispose method
  @override
  void dispose() {
    super.dispose();
  }
}

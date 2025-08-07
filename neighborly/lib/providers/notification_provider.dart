import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../pages/notification.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationData> _notifications = [
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
    NotificationData(
      id: '4',
      name: 'Alice Johnson',
      message:
          'Traffic jam reported on main road. Alternative routes suggested.',
      image: 'assets/images/Image1.jpg',
      urgency: 'normal',
      type: 'traffic_update',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      location: 'Dhanmondi 27, Dhaka',
      extraData: {
        'coordinates': {'lat': 23.7461, 'lng': 90.3742},
        'phone': '+880 1444-555666',
        'helpType': 'Traffic Update',
      },
    ),
    NotificationData(
      id: '5',
      name: 'Bob Smith',
      message:
          'Lost pet cat named Sania. Last seen near the park. Please help find her.',
      image: 'assets/images/Image2.jpg',
      urgency: 'urgent',
      type: 'lost_pet',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      location: 'Wari, Dhaka',
      extraData: {
        'coordinates': {'lat': 23.7183, 'lng': 90.4206},
        'phone': '+880 1333-444555',
        'helpType': 'Lost Item/Pet',
      },
    ),
    NotificationData(
      id: '6',
      name: 'Charlie Davis',
      message:
          'Community meeting scheduled for tomorrow evening. All neighbors welcome.',
      image: 'assets/images/Image3.jpg',
      urgency: 'normal',
      type: 'community',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      location: 'Community Center, Dhanmondi',
      extraData: {
        'coordinates': {'lat': 23.7461, 'lng': 90.3742},
        'phone': '+880 1222-333444',
        'helpType': 'General',
      },
    ),
    NotificationData(
      id: '7',
      name: 'Dana White',
      message:
          'Need help moving furniture to 4th floor. Willing to provide refreshments.',
      image: 'assets/images/Image1.jpg',
      urgency: 'normal',
      type: 'help_request',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      location: 'Mirpur 10, Dhaka',
      extraData: {
        'coordinates': {'lat': 23.8223, 'lng': 90.3654},
        'phone': '+880 1111-222333',
        'helpType': 'Shifting Furniture',
      },
    ),
  ];

  List<NotificationData> get notifications => List.unmodifiable(_notifications);

  void addNotification(NotificationData notification) {
    _notifications.insert(0, notification); // Add to the beginning
    notifyListeners();
  }

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

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllAsRead() {
    _notifications =
        _notifications
            .map((notification) => notification.copyWith(isRead: true))
            .toList();
    notifyListeners();
  }

  void undoMarkAllAsRead() {
    _notifications =
        _notifications
            .map((notification) => notification.copyWith(isRead: false))
            .toList();
    notifyListeners();
  }

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  List<NotificationData> getFilteredNotifications(String filter) {
    if (filter == 'All') return _notifications;
    return _notifications.where((notification) {
      return notification.urgency.toLowerCase() == filter.toLowerCase();
    }).toList();
  }
}

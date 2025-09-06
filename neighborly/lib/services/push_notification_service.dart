import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');

  // Handle background message
  await PushNotificationService._handleBackgroundMessage(message);
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static String? _fcmToken;
  static Function(Map<String, dynamic>)? _onMessageReceived;
  static Function(Map<String, dynamic>)? _onMessageOpenedApp;

  // Initialize push notifications
  static Future<void> initialize({
    Function(Map<String, dynamic>)? onMessageReceived,
    Function(Map<String, dynamic>)? onMessageOpenedApp,
  }) async {
    _onMessageReceived = onMessageReceived;
    _onMessageOpenedApp = onMessageOpenedApp;

    debugPrint('Initializing push notifications...');

    // Initialize local notifications first
    await _initializeLocalNotifications();

    // Request permission
    bool permissionGranted = await _requestPermission();

    if (permissionGranted) {
      debugPrint('Permissions granted, getting FCM token...');
      // Get FCM token only if permission is granted
      await _getFCMToken();
    } else {
      debugPrint('Notification permissions not granted, skipping FCM token');
    }

    // Configure message handlers regardless of permission status
    _configureMessageHandlers();

    debugPrint('Push notifications initialized successfully');
  }

  // Request notification permissions
  static Future<bool> _requestPermission() async {
    try {
      debugPrint('Requesting notification permissions...');

      // Request Firebase Messaging permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint(
        'Firebase Messaging permission status: ${settings.authorizationStatus}',
      );

      // Request system notification permission (Android)
      PermissionStatus permissionStatus = await Permission.notification.status;
      debugPrint('System notification permission status: $permissionStatus');

      if (permissionStatus.isDenied) {
        debugPrint('Requesting system notification permission...');
        permissionStatus = await Permission.notification.request();
        debugPrint(
          'System notification permission after request: $permissionStatus',
        );
      }

      bool isGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized &&
          permissionStatus.isGranted;

      debugPrint('Final permission status - Granted: $isGranted');
      return isGranted;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  // Manual permission request (can be called from UI)
  static Future<bool> requestNotificationPermission() async {
    debugPrint('Manual notification permission request initiated');
    return await _requestPermission();
  }

  // Check current permission status
  static Future<bool> isNotificationPermissionGranted() async {
    try {
      NotificationSettings settings =
          await _messaging.getNotificationSettings();
      PermissionStatus systemPermission = await Permission.notification.status;

      bool isGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized &&
          systemPermission.isGranted;

      debugPrint('Current notification permission status: $isGranted');
      debugPrint(
        'Firebase: ${settings.authorizationStatus}, System: $systemPermission',
      );

      return isGranted;
    } catch (e) {
      debugPrint('Error checking permission status: $e');
      return false;
    }
  }

  // Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'neighborly_channel',
      'Neighborly Notifications',
      description: 'Notifications for help requests and community updates',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  // Get FCM token
  static Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Send token to backend for storage
      if (_fcmToken != null) {
        await _sendTokenToBackend(_fcmToken!);
      }

      return _fcmToken;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  // Send FCM token to backend
  static Future<void> _sendTokenToBackend(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('User not authenticated, cannot send FCM token');
        return;
      }

      final authToken = await user.getIdToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/fcm/token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'fcmToken': token}),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM token sent to backend successfully');
      } else {
        debugPrint(
          'Failed to send FCM token to backend: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error sending FCM token to backend: $e');
    }
  }

  // Configure message handlers
  static void _configureMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.notification?.title}');
      _handleForegroundMessage(message);
    });

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        'App opened from notification: ${message.notification?.title}',
      );
      _handleMessageOpenedApp(message);
    });

    // Handle messages when app is terminated
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint(
          'App opened from terminated state: ${message.notification?.title}',
        );
        _handleMessageOpenedApp(message);
      }
    });

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((String token) {
      debugPrint('FCM Token refreshed: $token');
      _fcmToken = token;
      _sendTokenToBackend(token);
    });
  }

  // Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      // Show local notification when app is in foreground
      await _showLocalNotification(
        title: notification.title ?? 'Neighborly',
        body: notification.body ?? 'You have a new notification',
        data: data,
      );
    }

    // Call custom handler
    if (_onMessageReceived != null) {
      _onMessageReceived!(data);
    }
  }

  // Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    final data = message.data;

    // Process background message
    debugPrint('Processing background message: ${data.toString()}');

    // You can update local storage, sync data, etc.
    // Note: You cannot update UI from background handlers
  }

  // Handle message when app is opened
  static void _handleMessageOpenedApp(RemoteMessage message) {
    final data = message.data;

    if (_onMessageOpenedApp != null) {
      _onMessageOpenedApp!(data);
    }
  }

  // Show local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'neighborly_channel',
          'Neighborly Notifications',
          channelDescription:
              'Notifications for help requests and community updates',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformDetails,
      payload: data != null ? json.encode(data) : null,
    );
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;

    if (payload != null) {
      try {
        final data = json.decode(payload) as Map<String, dynamic>;

        if (_onMessageOpenedApp != null) {
          _onMessageOpenedApp!(data);
        }
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  // Get current FCM token
  static String? get fcmToken => _fcmToken;

  // Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  // Test notification (for development)
  static Future<void> sendTestNotification() async {
    await _showLocalNotification(
      title: 'Test Notification',
      body: 'This is a test notification from Neighborly',
      data: {'type': 'test', 'timestamp': DateTime.now().toIso8601String()},
    );
  }

  // Send test notification via backend (for development)
  static Future<void> sendTestNotificationViaBackend() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('User not authenticated');
        return;
      }

      final authToken = await user.getIdToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/fcm/test'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'title': 'Test from Backend',
          'body': 'This is a test push notification sent from the backend',
          'data': {
            'type': 'test',
            'timestamp': DateTime.now().toIso8601String(),
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Test notification sent via backend successfully');
      } else {
        debugPrint(
          'Failed to send test notification via backend: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error sending test notification via backend: $e');
    }
  }

  // Remove FCM token from backend (when user logs out)
  static Future<void> removeFCMTokenFromBackend() async {
    try {
      if (_fcmToken == null) {
        debugPrint('No FCM token to remove');
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('User not authenticated');
        return;
      }

      final authToken = await user.getIdToken();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/fcm/token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'fcmToken': _fcmToken}),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM token removed from backend successfully');
      } else {
        debugPrint(
          'Failed to remove FCM token from backend: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error removing FCM token from backend: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Send notification to a user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Store notification in Firestore
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Get user's FCM token and send push notification
      await _sendPushNotification(userId, title, body, data);
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Future<void> _sendPushNotification(
    String userId, 
    String title, 
    String body, 
    Map<String, dynamic>? data,
  ) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final fcmToken = userData['fcmToken'] as String?;
      
      if (fcmToken == null) return;

      // Send FCM message
      // Note: In production, you would use Firebase Functions or your backend
      // to send FCM messages using the Admin SDK
      print('Would send FCM to $fcmToken: $title - $body');
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }
}

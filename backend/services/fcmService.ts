import admin from 'firebase-admin';
import { getFirestore } from 'firebase-admin/firestore';

export interface FCMNotificationData {
  title: string;
  body: string;
  data?: Record<string, string>;
  userId?: string;
  tokens?: string[];
  topic?: string;
}

export class FCMService {
  // Get Firestore instance
  private static getDB() {
    return getFirestore();
  }
  
  // Send notification to specific user
  static async sendToUser(userId: string, notification: FCMNotificationData): Promise<boolean> {
    try {
      // Get user's FCM tokens from Firestore
      const userDoc = await this.getDB().collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        console.error(`User ${userId} not found`);
        return false;
      }

      const userData = userDoc.data();
      const fcmTokens = userData?.fcmTokens || [];

      if (fcmTokens.length === 0) {
        console.log(`No FCM tokens found for user ${userId}`);
        return false;
      }

      return await this.sendToTokens(fcmTokens, notification);
    } catch (error) {
      console.error('Error sending FCM notification to user:', error);
      return false;
    }
  }

  // Send notification to multiple users
  static async sendToUsers(userIds: string[], notification: FCMNotificationData): Promise<boolean> {
    try {
      const results = await Promise.allSettled(
        userIds.map(userId => this.sendToUser(userId, notification))
      );

      const successCount = results.filter(result => 
        result.status === 'fulfilled' && result.value === true
      ).length;

      console.log(`FCM notifications sent successfully to ${successCount}/${userIds.length} users`);
      return successCount > 0;
    } catch (error) {
      console.error('Error sending FCM notifications to users:', error);
      return false;
    }
  }

  // Send notification to specific tokens
  static async sendToTokens(tokens: string[], notification: FCMNotificationData): Promise<boolean> {
    try {
      if (tokens.length === 0) {
        console.log('No FCM tokens provided');
        return false;
      }

      const message = {
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: notification.data || {},
        tokens: tokens,
        android: {
          notification: {
            channelId: 'neighborly_channel',
            priority: 'high' as const,
            defaultSound: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      
      console.log(`FCM multicast result: ${response.successCount}/${tokens.length} successful`);

      // Handle failed tokens (remove invalid ones)
      if (response.failureCount > 0) {
        await this.handleFailedTokens(tokens, response.responses);
      }

      return response.successCount > 0;
    } catch (error) {
      console.error('Error sending FCM notification to tokens:', error);
      return false;
    }
  }

  // Send notification to topic
  static async sendToTopic(topic: string, notification: FCMNotificationData): Promise<boolean> {
    try {
      const message = {
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: notification.data || {},
        topic: topic,
        android: {
          notification: {
            channelId: 'neighborly_channel',
            priority: 'high' as const,
            defaultSound: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      const response = await admin.messaging().send(message);
      console.log('FCM topic message sent successfully:', response);
      return true;
    } catch (error) {
      console.error('Error sending FCM notification to topic:', error);
      return false;
    }
  }

  // Subscribe user to topic
  static async subscribeToTopic(tokens: string[], topic: string): Promise<boolean> {
    try {
      if (tokens.length === 0) {
        console.log('No tokens provided for topic subscription');
        return false;
      }

      const response = await admin.messaging().subscribeToTopic(tokens, topic);
      console.log(`Successfully subscribed ${response.successCount}/${tokens.length} tokens to topic ${topic}`);
      return response.successCount > 0;
    } catch (error) {
      console.error('Error subscribing to topic:', error);
      return false;
    }
  }

  // Unsubscribe user from topic
  static async unsubscribeFromTopic(tokens: string[], topic: string): Promise<boolean> {
    try {
      if (tokens.length === 0) {
        console.log('No tokens provided for topic unsubscription');
        return false;
      }

      const response = await admin.messaging().unsubscribeFromTopic(tokens, topic);
      console.log(`Successfully unsubscribed ${response.successCount}/${tokens.length} tokens from topic ${topic}`);
      return response.successCount > 0;
    } catch (error) {
      console.error('Error unsubscribing from topic:', error);
      return false;
    }
  }

  // Store FCM token for user
  static async storeFCMToken(userId: string, fcmToken: string): Promise<boolean> {
    try {
      const userRef = this.getDB().collection('users').doc(userId);
      
      // Check if user document exists
      const userDoc = await userRef.get();
      
      if (!userDoc.exists) {
        // Create user document if it doesn't exist
        await userRef.set({
          fcmTokens: [fcmToken],
          lastTokenUpdate: admin.firestore.FieldValue.serverTimestamp(),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`User document created and FCM token stored for user ${userId}`);
      } else {
        // Update existing user document
        await userRef.update({
          fcmTokens: admin.firestore.FieldValue.arrayUnion(fcmToken),
          lastTokenUpdate: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`FCM token updated for existing user ${userId}`);
      }

      return true;
    } catch (error) {
      console.error('Error storing FCM token:', error);
      return false;
    }
  }

  // Remove FCM token for user
  static async removeFCMToken(userId: string, fcmToken: string): Promise<boolean> {
    try {
      const userRef = this.getDB().collection('users').doc(userId);
      
      await userRef.update({
        fcmTokens: admin.firestore.FieldValue.arrayRemove(fcmToken),
      });

      console.log(`FCM token removed for user ${userId}`);
      return true;
    } catch (error) {
      console.error('Error removing FCM token:', error);
      return false;
    }
  }

  // Handle failed tokens (remove invalid ones)
  private static async handleFailedTokens(tokens: string[], responses: any[]): Promise<void> {
    const invalidTokens: string[] = [];

    responses.forEach((response, index) => {
      if (!response.success) {
        const error = response.error;
        if (error?.code === 'messaging/registration-token-not-registered' || 
            error?.code === 'messaging/invalid-registration-token') {
          const token = tokens[index];
          if (token) {
            invalidTokens.push(token);
          }
        }
      }
    });

    if (invalidTokens.length > 0) {
      console.log(`Removing ${invalidTokens.length} invalid FCM tokens`);
      
      // Remove invalid tokens from all users
      const usersQuery = this.getDB().collection('users')
        .where('fcmTokens', 'array-contains-any', invalidTokens);
      
      const userDocs = await usersQuery.get();
      
      const batch = this.getDB().batch();
      userDocs.docs.forEach((doc: any) => {
        const userData = doc.data();
        const cleanTokens = userData.fcmTokens?.filter((token: string) => 
          !invalidTokens.includes(token)
        ) || [];
        
        batch.update(doc.ref, { fcmTokens: cleanTokens });
      });

      await batch.commit();
    }
  }

  // Send help request notifications
  static async sendHelpRequestNotification(
    communityUserIds: string[],
    requesterName: string,
    helpType: string,
    location: string,
    helpRequestId: string
  ): Promise<boolean> {
    const notification: FCMNotificationData = {
      title: `New Help Request: ${helpType}`,
      body: `${requesterName} needs help in ${location}`,
      data: {
        type: 'help_request_created',
        helpRequestId,
        requesterName,
        helpType,
        location,
        timestamp: new Date().toISOString(),
      },
    };

    return await this.sendToUsers(communityUserIds, notification);
  }

  // Send help response notifications
  static async sendHelpResponseNotification(
    requesterId: string,
    responderName: string,
    helpType: string,
    helpRequestId: string
  ): Promise<boolean> {
    const notification: FCMNotificationData = {
      title: 'Someone responded to your help request!',
      body: `${responderName} wants to help with ${helpType}`,
      data: {
        type: 'help_request_response',
        helpRequestId,
        responderName,
        helpType,
        timestamp: new Date().toISOString(),
      },
    };

    return await this.sendToUser(requesterId, notification);
  }

  // Send help status update notifications
  static async sendHelpStatusNotification(
    userId: string,
    helpType: string,
    status: string,
    helpRequestId: string
  ): Promise<boolean> {
    let title: string;
    let body: string;

    switch (status) {
      case 'completed':
        title = 'Help Request Completed!';
        body = `Your ${helpType} request has been marked as completed`;
        break;
      case 'cancelled':
        title = 'Help Request Cancelled';
        body = `Your ${helpType} request has been cancelled`;
        break;
      default:
        title = 'Help Request Updated';
        body = `Your ${helpType} request status has been updated to ${status}`;
    }

    const notification: FCMNotificationData = {
      title,
      body,
      data: {
        type: 'help_request_status',
        helpRequestId,
        status,
        helpType,
        timestamp: new Date().toISOString(),
      },
    };

    return await this.sendToUser(userId, notification);
  }
}

import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { FCMService } from './fcmService.js';

let db: any;

// Initialize Firestore lazily
function getDB() {
  if (!db) {
    db = getFirestore();
  }
  return db;
}

export interface UserNotification {
  id?: string;
  recipientUserId: string;
  recipientEmail: string;
  type: 'help_request' | 'help_response' | 'help_status_update';
  title: string;
  message: string;
  helpRequestId?: string;
  helpRequestData?: {
    requesterName: string;
    requesterUserId: string;
    helpType: string;
    urgency: 'emergency' | 'urgent' | 'general';
    location: string;
    coordinates: { lat: number; lng: number };
    phone: string;
    description: string;
  };
  communityId: string;
  communityName: string;
  isRead: boolean;
  createdAt: Date;
  expiresAt?: Date;
  metadata?: any;
}

class NotificationService {
  
  // Create notifications for help request creation
  async createHelpRequestNotifications(helpRequestData: any): Promise<{ success: boolean; message: string; notificationCount?: number }> {
    try {
      const { userId, userEmail, username, type, title, description, location, address, phone, priority } = helpRequestData;
      
      console.log('Creating notifications for help request:', { userId, userEmail, username, type, title });

      // Get requester's communities using email
      const requesterCommunities = await this.getUserCommunities(userEmail);
      console.log('Requester communities:', requesterCommunities.map(c => c.name));

      if (requesterCommunities.length === 0) {
        return { success: false, message: 'User is not a member of any community' };
      }

      let totalNotifications = 0;

      // For each community, notify all members except the requester
      for (const community of requesterCommunities) {
        const communityMembers = await this.getCommunityMembers(community.id, userId);
        console.log(`Community ${community.name} has ${communityMembers.length} members to notify`);

        // Check daily notification limits for each member
        const eligibleMembers = await this.filterMembersByNotificationLimit(communityMembers);
        console.log(`${eligibleMembers.length} members are within daily notification limit`);

        // Create notifications for eligible members
        const notifications = eligibleMembers.map(member => ({
          recipientUserId: member.userId,
          recipientEmail: member.email,
          type: 'help_request' as const,
          title: `${priority === 'emergency' ? '🚨 ' : priority === 'urgent' ? '⚠️ ' : '📢 '}${title} Help Needed`,
          message: `${username} needs ${title.toLowerCase()} help: ${description}`,
          helpRequestId: helpRequestData.id,
          helpRequestData: {
            requesterName: username,
            requesterUserId: userId,
            helpType: title,
            urgency: priority.toLowerCase() as 'emergency' | 'urgent' | 'general',
            location: address,
            coordinates: { 
              lat: location.latitude, 
              lng: location.longitude 
            },
            phone: phone || '',
            description: description
          },
          communityId: community.id,
          communityName: community.name,
          isRead: false,
          createdAt: new Date(),
          expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
        }));

        // Batch create notifications
        if (notifications.length > 0) {
          await this.batchCreateNotifications(notifications);
          totalNotifications += notifications.length;

          // Send push notifications
          const recipientUserIds = notifications.map(n => n.recipientUserId);
          await FCMService.sendHelpRequestNotification(
            recipientUserIds,
            username,
            title,
            address,
            helpRequestData.id
          );
        }
      }

      console.log(`Successfully created ${totalNotifications} notifications`);
      return { 
        success: true, 
        message: `Notifications sent to ${totalNotifications} community members`,
        notificationCount: totalNotifications
      };

    } catch (error) {
      console.error('Error creating help request notifications:', error);
      return { success: false, message: 'Failed to create notifications' };
    }
  }

  // Create notification for help response
  async createHelpResponseNotification(helpRequestId: string, responderData: any): Promise<{ success: boolean; message: string }> {
    try {
      // Get original help request
      const helpRequestDoc = await getDB().collection('helpRequests').doc(helpRequestId).get();
      if (!helpRequestDoc.exists) {
        return { success: false, message: 'Help request not found' };
      }

      const helpRequest = helpRequestDoc.data();
      const requesterId = helpRequest.userId;

      // Check if requester is within daily notification limit
      const dailyCount = await this.getDailyNotificationCount(requesterId);
      if (dailyCount >= 100) {
        console.log('Requester has reached daily notification limit');
        return { success: true, message: 'Notification skipped due to daily limit' };
      }

      // Get requester's email
      const requesterDoc = await getDB().collection('users').doc(requesterId).get();
      const requesterEmail = requesterDoc.exists ? requesterDoc.data()?.email : '';

      const notification: UserNotification = {
        recipientUserId: requesterId,
        recipientEmail: requesterEmail,
        type: 'help_response',
        title: '👋 Someone Wants to Help!',
        message: `${responderData.username} responded to your ${helpRequest.title} help request`,
        helpRequestId: helpRequestId,
        helpRequestData: {
          requesterName: helpRequest.username,
          requesterUserId: requesterId,
          helpType: helpRequest.title,
          urgency: helpRequest.priority,
          location: helpRequest.address,
          coordinates: { 
            lat: helpRequest.location.latitude, 
            lng: helpRequest.location.longitude 
          },
          phone: responderData.phone || '',
          description: responderData.message || 'I can help with this request'
        },
        communityId: 'response', // Special type for responses
        communityName: 'Help Response',
        isRead: false,
        createdAt: new Date(),
      };

      await this.createSingleNotification(notification);

      // Send push notification
      await FCMService.sendHelpResponseNotification(
        requesterId,
        responderData.username,
        helpRequest.title,
        helpRequestId
      );

      return { success: true, message: 'Response notification created' };

    } catch (error) {
      console.error('Error creating help response notification:', error);
      return { success: false, message: 'Failed to create response notification' };
    }
  }

  // Create notification for help status updates
  async createHelpStatusNotification(helpRequestId: string, status: string, updaterName: string): Promise<{ success: boolean; message: string }> {
    try {
      // Get original help request
      const helpRequestDoc = await getDB().collection('helpRequests').doc(helpRequestId).get();
      if (!helpRequestDoc.exists) {
        return { success: false, message: 'Help request not found' };
      }

      const helpRequest = helpRequestDoc.data();
      
      // Get all users who responded to this request
      const responsesSnapshot = await getDB().collection('helpRequests')
        .doc(helpRequestId)
        .collection('responses')
        .get();

      const responderIds = responsesSnapshot.docs.map((doc: any) => doc.data().userId);
      
      // Add original requester to notification list
      const notificationRecipients = [...responderIds];
      if (!notificationRecipients.includes(helpRequest.userId)) {
        notificationRecipients.push(helpRequest.userId);
      }

      const notifications = [];

      for (const userId of notificationRecipients) {
        // Check daily notification limit
        const dailyCount = await this.getDailyNotificationCount(userId);
        if (dailyCount >= 100) continue;

        // Get user email
        const userDoc = await getDB().collection('users').doc(userId).get();
        const userEmail = userDoc.exists ? userDoc.data()?.email : '';

        let title = '';
        let message = '';

        if (status === 'completed') {
          title = '✅ Help Request Completed';
          message = `The ${helpRequest.title} help request has been completed by ${updaterName}`;
        } else if (status === 'cancelled') {
          title = '❌ Help Request Cancelled';
          message = `The ${helpRequest.title} help request has been cancelled by ${updaterName}`;
        } else {
          title = '📝 Help Request Updated';
          message = `The ${helpRequest.title} help request status changed to ${status}`;
        }

        const notification: UserNotification = {
          recipientUserId: userId,
          recipientEmail: userEmail,
          type: 'help_status_update',
          title: title,
          message: message,
          helpRequestId: helpRequestId,
          helpRequestData: {
            requesterName: helpRequest.username,
            requesterUserId: helpRequest.userId,
            helpType: helpRequest.title,
            urgency: helpRequest.priority,
            location: helpRequest.address,
            coordinates: { 
              lat: helpRequest.location.latitude, 
              lng: helpRequest.location.longitude 
            },
            phone: helpRequest.phone || '',
            description: helpRequest.description
          },
          communityId: 'status_update',
          communityName: 'Status Update',
          isRead: false,
          createdAt: new Date(),
        };

        notifications.push(notification);
      }

      if (notifications.length > 0) {
        await this.batchCreateNotifications(notifications);

        // Send push notifications to all recipients
        for (const notification of notifications) {
          await FCMService.sendHelpStatusNotification(
            notification.recipientUserId,
            helpRequest.title,
            status,
            helpRequestId
          );
        }
      }

      return { success: true, message: `Status notifications sent to ${notifications.length} users` };

    } catch (error) {
      console.error('Error creating help status notification:', error);
      return { success: false, message: 'Failed to create status notification' };
    }
  }

  // Get user's communities
  private async getUserCommunities(userEmail: string): Promise<any[]> {
    try {
      // Find user by email field (not document ID) - consistent with other services
      const userQuery = await getDB().collection('users').where('email', '==', userEmail).get();
      if (userQuery.empty) {
        console.log(`No user found with email: ${userEmail}`);
        return [];
      }

      const userDoc = userQuery.docs[0];
      const userData = userDoc.data();
      const preferredCommunities = userData?.preferredCommunity || [];

      const communities = [];
      for (const communityId of preferredCommunities) {
        const communityDoc = await getDB().collection('communities').doc(communityId).get();
        if (communityDoc.exists) {
          communities.push({
            id: communityDoc.id,
            ...communityDoc.data()
          });
        }
      }

      return communities;
    } catch (error) {
      console.error('Error getting user communities:', error);
      return [];
    }
  }

  // Get community members excluding the requester
  private async getCommunityMembers(communityId: string, excludeUserId: string): Promise<any[]> {
    try {
      const communityDoc = await getDB().collection('communities').doc(communityId).get();
      if (!communityDoc.exists) return [];

      const communityData = communityDoc.data();
      const memberEmails = communityData?.members || [];

      const members = [];
      for (const email of memberEmails) {
        const userQuery = await getDB().collection('users').where('email', '==', email).get();
        if (!userQuery.empty) {
          const userDoc = userQuery.docs[0];
          const userData = userDoc.data();
          
          // Exclude the requester
          if (userDoc.id !== excludeUserId) {
            members.push({
              userId: userDoc.id,
              email: email,
              username: userData?.username || 'Unknown User'
            });
          }
        }
      }

      return members;
    } catch (error) {
      console.error('Error getting community members:', error);
      return [];
    }
  }

  // Filter members by daily notification limit
  private async filterMembersByNotificationLimit(members: any[]): Promise<any[]> {
    const eligibleMembers = [];

    for (const member of members) {
      const dailyCount = await this.getDailyNotificationCount(member.userId);
      if (dailyCount < 100) { // 100 notifications per day limit
        eligibleMembers.push(member);
      }
    }

    return eligibleMembers;
  }

  // Get daily notification count for a user
  private async getDailyNotificationCount(userId: string): Promise<number> {
    try {
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);

      const snapshot = await getDB().collection('user_notifications')
        .where('recipientUserId', '==', userId)
        .where('createdAt', '>=', today)
        .where('createdAt', '<', tomorrow)
        .get();

      return snapshot.docs.length;
    } catch (error) {
      console.error('Error getting daily notification count:', error);
      return 0;
    }
  }

  // Batch create notifications
  private async batchCreateNotifications(notifications: UserNotification[]): Promise<void> {
    const batch = getDB().batch();

    notifications.forEach((notification) => {
      const notificationRef = getDB().collection('user_notifications').doc();
      batch.set(notificationRef, notification);
    });

    await batch.commit();
  }

  // Create single notification
  private async createSingleNotification(notification: UserNotification): Promise<void> {
    const notificationRef = getDB().collection('user_notifications').doc();
    await notificationRef.set(notification);
  }

  // Get notifications for a user
  async getUserNotifications(userId: string, limit: number = 50): Promise<UserNotification[]> {
    try {
      // Try the compound query first
      let snapshot;
      try {
        snapshot = await getDB().collection('user_notifications')
          .where('recipientUserId', '==', userId)
          .orderBy('createdAt', 'desc')
          .limit(limit)
          .get();
      } catch (indexError: any) {
        console.warn('Compound index not available, using simple query:', indexError?.message || 'Unknown error');
        // Fallback to simple query without ordering
        snapshot = await getDB().collection('user_notifications')
          .where('recipientUserId', '==', userId)
          .limit(limit)
          .get();
      }

      const notifications = snapshot.docs.map((doc: any) => ({
        id: doc.id,
        ...doc.data()
      } as UserNotification));

      // Sort manually if we used the fallback query
      if (notifications.length > 0 && !notifications[0].createdAt) {
        console.warn('Manual sorting required due to missing index');
        notifications.sort((a: any, b: any) => {
          const dateA = a.createdAt instanceof Date ? a.createdAt : new Date(a.createdAt);
          const dateB = b.createdAt instanceof Date ? b.createdAt : new Date(b.createdAt);
          return dateB.getTime() - dateA.getTime();
        });
      }

      return notifications;
    } catch (error) {
      console.error('Error getting user notifications:', error);
      return [];
    }
  }

  // Mark notification as read
  async markNotificationAsRead(notificationId: string): Promise<{ success: boolean; message: string }> {
    try {
      await getDB().collection('user_notifications').doc(notificationId).update({
        isRead: true,
        readAt: new Date()
      });

      return { success: true, message: 'Notification marked as read' };
    } catch (error) {
      console.error('Error marking notification as read:', error);
      return { success: false, message: 'Failed to mark notification as read' };
    }
  }

  // Mark all notifications as read for a user
  async markAllNotificationsAsRead(userId: string): Promise<{ success: boolean; message: string }> {
    try {
      const snapshot = await getDB().collection('user_notifications')
        .where('recipientUserId', '==', userId)
        .where('isRead', '==', false)
        .get();

      const batch = getDB().batch();
      snapshot.docs.forEach((doc: any) => {
        batch.update(doc.ref, { 
          isRead: true,
          readAt: new Date()
        });
      });

      await batch.commit();

      return { success: true, message: `Marked ${snapshot.docs.length} notifications as read` };
    } catch (error) {
      console.error('Error marking all notifications as read:', error);
      return { success: false, message: 'Failed to mark notifications as read' };
    }
  }

  // Clean up expired notifications
  async cleanupExpiredNotifications(): Promise<{ success: boolean; message: string; deletedCount?: number }> {
    try {
      const now = new Date();
      const snapshot = await getDB().collection('user_notifications')
        .where('expiresAt', '<=', now)
        .get();

      if (snapshot.empty) {
        return { success: true, message: 'No expired notifications to clean up', deletedCount: 0 };
      }

      const batch = getDB().batch();
      snapshot.docs.forEach((doc: any) => {
        batch.delete(doc.ref);
      });

      await batch.commit();

      return { 
        success: true, 
        message: `Cleaned up ${snapshot.docs.length} expired notifications`,
        deletedCount: snapshot.docs.length
      };
    } catch (error) {
      console.error('Error cleaning up expired notifications:', error);
      return { success: false, message: 'Failed to clean up expired notifications' };
    }
  }
}

export default new NotificationService();

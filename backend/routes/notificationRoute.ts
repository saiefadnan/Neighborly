import { Hono } from 'hono';
import type { Context } from 'hono';
import { getAuth } from 'firebase-admin/auth';
import notificationService from '../services/notificationService';

const notificationRoute = new Hono();

// Get user notifications
notificationRoute.get('/notifications', async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');
    
    if (!idToken) {
      return c.json({ success: false, message: 'No authorization token provided' }, 401);
    }

    const decodedToken = await getAuth().verifyIdToken(idToken);
    const userEmail = decodedToken.email;

    if (!userEmail) {
      return c.json({ success: false, message: 'User email not found in token' }, 401);
    }

    const { limit = '50' } = c.req.query();
    
    const notifications = await notificationService.getUserNotificationsByEmail(
      userEmail, 
      parseInt(limit)
    );

    return c.json({ 
      success: true, 
      data: notifications,
      count: notifications.length
    });

  } catch (error) {
    console.error('Error fetching notifications:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to fetch notifications' 
    }, 500);
  }
});

// Mark notification as read
notificationRoute.put('/notifications/:notificationId/read', async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');
    
    if (!idToken) {
      return c.json({ success: false, message: 'No authorization token provided' }, 401);
    }

    await getAuth().verifyIdToken(idToken);

    const { notificationId } = c.req.param();
    
    if (!notificationId) {
      return c.json({ success: false, message: 'Notification ID is required' }, 400);
    }
    
    const result = await notificationService.markNotificationAsRead(notificationId);

    return c.json(result);

  } catch (error) {
    console.error('Error marking notification as read:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to mark notification as read' 
    }, 500);
  }
});

// Mark all notifications as read
notificationRoute.put('/notifications/read-all', async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');
    
    if (!idToken) {
      return c.json({ success: false, message: 'No authorization token provided' }, 401);
    }

    const decodedToken = await getAuth().verifyIdToken(idToken);
    const userEmail = decodedToken.email;

    if (!userEmail) {
      return c.json({ success: false, message: 'User email not found in token' }, 401);
    }
    
    const result = await notificationService.markAllNotificationsAsReadByEmail(userEmail);

    return c.json(result);

  } catch (error) {
    console.error('Error marking all notifications as read:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to mark all notifications as read' 
    }, 500);
  }
});

// Clean up expired notifications (admin endpoint)
notificationRoute.delete('/notifications/cleanup', async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');
    
    if (!idToken) {
      return c.json({ success: false, message: 'No authorization token provided' }, 401);
    }

    await getAuth().verifyIdToken(idToken);
    
    const result = await notificationService.cleanupExpiredNotifications();

    return c.json(result);

  } catch (error) {
    console.error('Error cleaning up notifications:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to clean up notifications' 
    }, 500);
  }
});

export default notificationRoute;

import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { getAuth } from 'firebase-admin/auth';
import { FCMService } from '../services/fcmService.js';

const fcmRouter = new Hono();

fcmRouter.use('*', cors());

// Middleware to verify authentication
const authMiddleware = async (c: any, next: any) => {
  try {
    const authHeader = c.req.header('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return c.json({ error: 'Authorization header missing or invalid' }, 401);
    }

    const token = authHeader.split(' ')[1];
    const decodedToken = await getAuth().verifyIdToken(token);
    c.set('user', decodedToken);
    
    await next();
  } catch (error) {
    console.error('Authentication error:', error);
    return c.json({ error: 'Unauthorized' }, 401);
  }
};

// Store FCM token for authenticated user
fcmRouter.post('/token', authMiddleware, async (c: any) => {
  try {
    const user = c.get('user');
    const { fcmToken } = await c.req.json();

    if (!fcmToken) {
      return c.json({ error: 'FCM token is required' }, 400);
    }

    const success = await FCMService.storeFCMToken(user.uid, fcmToken);

    if (success) {
      return c.json({
        success: true,
        message: 'FCM token stored successfully'
      });
    } else {
      return c.json({ error: 'Failed to store FCM token' }, 500);
    }
  } catch (error) {
    console.error('Error storing FCM token:', error);
    return c.json({ error: 'Internal server error' }, 500);
  }
});

// Remove FCM token for authenticated user
fcmRouter.delete('/token', authMiddleware, async (c: any) => {
  try {
    const user = c.get('user');
    const { fcmToken } = await c.req.json();

    if (!fcmToken) {
      return c.json({ error: 'FCM token is required' }, 400);
    }

    const success = await FCMService.removeFCMToken(user.uid, fcmToken);

    if (success) {
      return c.json({
        success: true,
        message: 'FCM token removed successfully'
      });
    } else {
      return c.json({ error: 'Failed to remove FCM token' }, 500);
    }
  } catch (error) {
    console.error('Error removing FCM token:', error);
    return c.json({ error: 'Internal server error' }, 500);
  }
});

// Subscribe to topic
fcmRouter.post('/subscribe/:topic', authMiddleware, async (c: any) => {
  try {
    const user = c.get('user');
    const topic = c.req.param('topic');
    const { fcmTokens } = await c.req.json();

    if (!fcmTokens || !Array.isArray(fcmTokens)) {
      return c.json({ error: 'FCM tokens array is required' }, 400);
    }

    const success = await FCMService.subscribeToTopic(fcmTokens, topic);

    if (success) {
      return c.json({
        success: true,
        message: `Successfully subscribed to topic: ${topic}`
      });
    } else {
      return c.json({ error: 'Failed to subscribe to topic' }, 500);
    }
  } catch (error) {
    console.error('Error subscribing to topic:', error);
    return c.json({ error: 'Internal server error' }, 500);
  }
});

// Unsubscribe from topic
fcmRouter.post('/unsubscribe/:topic', authMiddleware, async (c: any) => {
  try {
    const user = c.get('user');
    const topic = c.req.param('topic');
    const { fcmTokens } = await c.req.json();

    if (!fcmTokens || !Array.isArray(fcmTokens)) {
      return c.json({ error: 'FCM tokens array is required' }, 400);
    }

    const success = await FCMService.unsubscribeFromTopic(fcmTokens, topic);

    if (success) {
      return c.json({
        success: true,
        message: `Successfully unsubscribed from topic: ${topic}`
      });
    } else {
      return c.json({ error: 'Failed to unsubscribe from topic' }, 500);
    }
  } catch (error) {
    console.error('Error unsubscribing from topic:', error);
    return c.json({ error: 'Internal server error' }, 500);
  }
});

// Send test notification (for development)
fcmRouter.post('/test', authMiddleware, async (c: any) => {
  try {
    const user = c.get('user');
    const { title, body, data } = await c.req.json();

    const success = await FCMService.sendToUser(user.uid, {
      title: title || 'Test Notification',
      body: body || 'This is a test notification from Neighborly',
      data: data || { type: 'test', timestamp: new Date().toISOString() }
    });

    if (success) {
      return c.json({
        success: true,
        message: 'Test notification sent successfully'
      });
    } else {
      return c.json({ error: 'Failed to send test notification' }, 500);
    }
  } catch (error) {
    console.error('Error sending test notification:', error);
    return c.json({ error: 'Internal server error' }, 500);
  }
});

export { fcmRouter };

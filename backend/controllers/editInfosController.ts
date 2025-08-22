import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import type { Context } from 'hono';

// Get user info (view current values)
export const getUserInfo = async (c: Context) => {
  console.log('getUserInfo called');
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');

    if (!idToken) {
      return c.json({ success: false, message: 'Missing Authorization header' }, 401);
    }

    // Verify user token
    const decodedToken = await getAuth().verifyIdToken(idToken);
    const userId = decodedToken.uid;

  // Debug: print the decoded UID
  console.log('Decoded UID:', userId);
  // Fetch user document from Firestore
  const userDoc = await getFirestore().collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return c.json({ success: false, message: 'Userss not found' }, 404);
    }
    // Only return allowed fields
    const allowedFields = [
      'firstName',
      'lastName',
      'username',
      'addressLine1',
      'addressLine2',
      'city',
      'contactNumber',
      'email' // for display only, not updatable
    ];
    const userData = userDoc.data() || {};
    const filteredData: Record<string, any> = {};
    for (const key of allowedFields) {
      if (userData[key] !== undefined) {
        filteredData[key] = userData[key];
      } else {
        filteredData[key] = null;
      }
    }
    return c.json({ success: true, data: filteredData });
  } catch (error) {
    console.error('Error fetching user info:', error);
    return c.json({ success: false, message: 'Failed to fetch user info' }, 500);
  }
};

// Update user info (except email and passwords)
export const updateUserInfo = async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');

    if (!idToken) {
      return c.json({ success: false, message: 'Missing Authorization header' }, 401);
    }

    // Verify user token
    const decodedToken = await getAuth().verifyIdToken(idToken);
    const userId = decodedToken.uid;

    // Get update data from request body
    const updateData = await c.req.json();

    // Only allow these fields to be updated
    const allowedFields = [
      'firstName',
      'lastName',
      'username',
      'addressLine1',
      'addressLine2',
      'city',
      'contactNumber'
    ];

    // Filter updateData to only allowed fields
    const filteredData: Record<string, any> = {};
    for (const key of allowedFields) {
      if (updateData[key] !== undefined) {
        filteredData[key] = updateData[key];
      }
    }

    if (Object.keys(filteredData).length === 0) {
      return c.json({ success: false, message: 'No valid fields to update' }, 400);
    }

    // Update Firestore user document (merge: true to insert if not exists)
    await getFirestore().collection('users').doc(userId).set(filteredData, { merge: true });

    return c.json({ success: true, message: 'User info updated successfully', data: filteredData });
  } catch (error) {
    console.error('Error updating user info:', error);
    return c.json({ success: false, message: 'Failed to update user info' }, 500);
  }
};
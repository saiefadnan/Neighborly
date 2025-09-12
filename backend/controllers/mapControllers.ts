import type { Context } from 'hono';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import notificationService from '../services/notificationService';


// Add these at the end of your mapControllers.ts file

// Migrate existing helpedRequests to add XP values
export const migrateHelpedRequestsXP = async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');
    
    if (!idToken) {
      return c.json({ success: false, message: 'No authorization token provided' }, 401);
    }

    await getAuth().verifyIdToken(idToken);

    const db = getFirestore();
    
    // Get all helpedRequests that don't have XP field
    const helpedRequestsQuery = await db.collection('helpedRequests').get();
    
    const batch = db.batch();
    let migratedCount = 0;
    
    // Calculate XP based on priority
    const calculateXP = (priority: string): number => {
      switch (priority?.toLowerCase()) {
        case 'emergency':
          return 500;
        case 'urgent':
          return 300;
        default:
          return 100; // for 'medium', 'low', or any other priority
      }
    };

    for (const doc of helpedRequestsQuery.docs) {
      const data = doc.data();
      
      // Only update if XP field doesn't exist
      if (!data.hasOwnProperty('xp')) {
        const priority = data.originalRequestData?.priority || 'medium';
        const xpValue = calculateXP(priority);
        
        batch.update(doc.ref, {
          xp: xpValue,
          migratedAt: new Date().toISOString()
        });
        
        migratedCount++;
        console.log(`Adding XP ${xpValue} to helpedRequest ${doc.id} with priority ${priority}`);
      }
    }

    if (migratedCount > 0) {
      await batch.commit();
    }

    return c.json({ 
      success: true, 
      message: `Successfully migrated ${migratedCount} helpedRequests with XP values`,
      migratedCount: migratedCount
    });

  } catch (error) {
    console.error('Error migrating helpedRequests XP:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to migrate helpedRequests XP' 
    }, 500);
  }
};

// Migrate user accumulated XP based on existing helpedRequests
export const migrateUserAccumulatedXP = async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');
    
    if (!idToken) {
      return c.json({ success: false, message: 'No authorization token provided' }, 401);
    }

    await getAuth().verifyIdToken(idToken);

    const db = getFirestore();
    
    // Get all helpedRequests that have status completed or in_progress
    const helpedRequestsQuery = await db.collection('helpedRequests')
      .where('status', 'in', ['completed', 'in_progress'])
      .get();
    
    // Group XP by user
    const userXPMap = new Map();
    
    for (const doc of helpedRequestsQuery.docs) {
      const data = doc.data();
      const userId = data.acceptedUserID;
      const xp = data.xp || 0;
      
      if (userId && xp > 0) {
        const currentXP = userXPMap.get(userId) || 0;
        userXPMap.set(userId, currentXP + xp);
      }
    }

    const batch = db.batch();
    let migratedUsers = 0;

    // Update each user's accumulated XP
    for (const [userId, totalXP] of userXPMap) {
      const userRef = db.collection('users').doc(userId);
      const userDoc = await userRef.get();
      
      if (userDoc.exists) {
        const userData = userDoc.data();
        
        // Only update if accumulateXP field doesn't exist
        if (!userData?.hasOwnProperty('accumulateXP')) {
          batch.update(userRef, {
            accumulateXP: totalXP,
            xpMigratedAt: new Date().toISOString()
          });
          
          migratedUsers++;
          console.log(`Setting accumulated XP ${totalXP} for user ${userId}`);
        }
      }
    }

    if (migratedUsers > 0) {
      await batch.commit();
    }

    return c.json({ 
      success: true, 
      message: `Successfully migrated accumulated XP for ${migratedUsers} users`,
      migratedUsers: migratedUsers,
      totalXPEntries: userXPMap.size
    });

  } catch (error) {
    console.error('Error migrating user accumulated XP:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to migrate user accumulated XP' 
    }, 500);
  }
};

// Create a new help request
export const createHelpRequest = async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');
    
    if (!idToken) {
      return c.json({ success: false, message: 'No authorization token provided' }, 401);
    }

    // Verify the user token
    const decodedToken = await getAuth().verifyIdToken(idToken);
    const userId = decodedToken.uid;
    
    // Get user info from Firebase Auth
    const userRecord = await getAuth().getUser(userId);
    const userEmail = userRecord.email;
    
    if (!userEmail) {
      return c.json({ success: false, message: 'User email not found' }, 400);
    }

    // Fetch username from users collection using email
    let username = 'Anonymous User'; // Default fallback
    try {
      const userDoc = await getFirestore().collection('users').doc(userEmail).get();
      if (userDoc.exists) {
        const userData = userDoc.data();
        username = userData?.username || userRecord.displayName || userRecord.email?.split('@')[0] || 'Anonymous User';
        console.log(`Found username from Firestore: ${username}`);
      } else {
        // Fallback to Firebase Auth if no Firestore document found
        username = userRecord.displayName || userRecord.email?.split('@')[0] || 'Anonymous User';
        console.log(`No Firestore document found, using fallback username: ${username}`);
      }
    } catch (error) {
      console.error('Error fetching user from Firestore:', error);
      // Use Firebase Auth fallback on error
      username = userRecord.displayName || userRecord.email?.split('@')[0] || 'Anonymous User';
      console.log(`Error occurred, using fallback username: ${username}`);
    }
    
    const requestData = await c.req.json();
    const { 
      type, 
      title, 
      description, 
      location, 
      address, 
      priority, 
      phone 
    } = requestData;

    // Validate required fields
    if (!type || !title || !description || !location || !address) {
      return c.json({ 
        success: false, 
        message: 'Missing required fields: type, title, description, location, address' 
      }, 400);
    }

    // Create the help request document
    const helpRequestRef = getFirestore().collection('helpRequests').doc();
    const helpRequestId = helpRequestRef.id;

    const helpRequest = {
      id: helpRequestId,
      userId: userId,
      userEmail: userEmail,
      username: username,
      type,
      title,
      description,
      location: {
        latitude: location.latitude,
        longitude: location.longitude
      },
      address,
      priority: priority || 'medium',
      phone: phone || '',
      status: 'open', // open, in_progress, completed, cancelled
      acceptedResponderId: null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    await helpRequestRef.set(helpRequest);

    // Create notifications for community members
    const notificationResult = await notificationService.createHelpRequestNotifications(helpRequest);
    console.log('Notification result:', notificationResult);

    return c.json({ 
      success: true, 
      message: 'Help request created successfully',
      requestId: helpRequestId,
      data: helpRequest,
      notifications: notificationResult
    }, 201);

  } catch (error) {
    console.error('Error creating help request:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to create help request' 
    }, 500);
  }
};

// Get all help requests with optional filters
export const getHelpRequests = async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');
    
    if (!idToken) {
      return c.json({ success: false, message: 'No authorization token provided' }, 401);
    }

    await getAuth().verifyIdToken(idToken);

    // Get query parameters for filtering
    const { status, type, userId, limit = '50' } = c.req.query();
    console.log(`Getting help requests - status: ${status}, type: ${type}, userId: ${userId}, limit: ${limit}`);
    
    let query: any = getFirestore().collection('helpRequests');
    
    // First, let's check total documents in collection
    const totalSnapshot = await getFirestore().collection('helpRequests').get();
    console.log(`Total documents in helpRequests collection: ${totalSnapshot.docs.length}`);

    // Apply filters if provided
    if (status) {
      query = query.where('status', '==', status);
    }
    if (type) {
      query = query.where('type', '==', type);
    }
    if (userId) {
      query = query.where('userId', '==', userId);
    }

    // Limit results (removed orderBy to avoid index requirement)
    query = query.limit(parseInt(limit));

    const snapshot = await query.get();
    const helpRequests = [];
    
    console.log(`Found ${snapshot.docs.length} help requests`);

    for (const doc of snapshot.docs) {
      const requestData = doc.data();
      console.log(`Processing request: ${requestData.id} - ${requestData.title}`);
      
      // Get responses for this request
      const responsesSnapshot = await doc.ref.collection('responses').get();
      const responses = responsesSnapshot.docs.map((responseDoc: any) => ({
        id: responseDoc.id,
        ...responseDoc.data()
      }));

      console.log(`Request ${requestData.id} has ${responses.length} responses`);

      helpRequests.push({
        ...requestData,
        responses
      });
    }

    console.log(`Returning ${helpRequests.length} help requests`);

    return c.json({ 
      success: true, 
      data: helpRequests,
      count: helpRequests.length
    });

  } catch (error) {
    console.error('Error fetching help requests:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to fetch help requests' 
    }, 500);
  }
};

// Respond to a help request
export const respondToHelpRequest = async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');
    
    if (!idToken) {
      return c.json({ success: false, message: 'No authorization token provided' }, 401);
    }

    const decodedToken = await getAuth().verifyIdToken(idToken);
    const responderId = decodedToken.uid;

    const { requestId } = c.req.param();
    const { message, phone, username } = await c.req.json();

    if (!requestId) {
      return c.json({ success: false, message: 'Request ID is required' }, 400);
    }

    // Check if help request exists and is still open
    const helpRequestRef = getFirestore().collection('helpRequests').doc(requestId);
    const helpRequestDoc = await helpRequestRef.get();

    if (!helpRequestDoc.exists) {
      return c.json({ success: false, message: 'Help request not found' }, 404);
    }

    const helpRequestData = helpRequestDoc.data();
    if (helpRequestData?.status !== 'open') {
      return c.json({ 
        success: false, 
        message: 'This help request is no longer accepting responses' 
      }, 400);
    }

    // Check if user already responded
    const existingResponse = await helpRequestRef
      .collection('responses')
      .where('userId', '==', responderId)
      .get();

    if (!existingResponse.empty) {
      return c.json({ 
        success: false, 
        message: 'You have already responded to this request' 
      }, 400);
    }

    // Create response document
    const responseRef = helpRequestRef.collection('responses').doc();
    const responseData = {
      id: responseRef.id,
      userId: responderId,
      username: username || 'Anonymous',
      phone: phone || '',
      message: message || '',
      status: 'pending', // pending, accepted, rejected
      createdAt: new Date().toISOString()
    };

    await responseRef.set(responseData);

    // Create notification for the help request owner
    const notificationResult = await notificationService.createHelpResponseNotification(requestId, responseData);
    console.log('Response notification result:', notificationResult);

    return c.json({ 
      success: true, 
      message: 'Response submitted successfully',
      responseId: responseRef.id,
      notifications: notificationResult
    });

  } catch (error) {
    console.error('Error responding to help request:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to submit response' 
    }, 500);
  }
};

// Accept a responder (only request owner can do this)
export const acceptResponder = async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');
    
    if (!idToken) {
      return c.json({ success: false, message: 'No authorization token provided' }, 401);
    }

    const decodedToken = await getAuth().verifyIdToken(idToken);
    const userId = decodedToken.uid;

    const { requestId, responseId } = c.req.param();

    if (!requestId || !responseId) {
      return c.json({ 
        success: false, 
        message: 'Request ID and Response ID are required' 
      }, 400);
    }

    // Get help request and verify ownership
    const helpRequestRef = getFirestore().collection('helpRequests').doc(requestId);
    const helpRequestDoc = await helpRequestRef.get();

    if (!helpRequestDoc.exists) {
      return c.json({ success: false, message: 'Help request not found' }, 404);
    }

    const helpRequestData = helpRequestDoc.data();
    if (helpRequestData?.userId !== userId) {
      return c.json({ 
        success: false, 
        message: 'You can only accept responders for your own requests' 
      }, 403);
    }

    if (helpRequestData?.status !== 'open') {
      return c.json({ 
        success: false, 
        message: 'This request is not accepting new responders' 
      }, 400);
    }

    // Get the response
    const responseRef = helpRequestRef.collection('responses').doc(responseId);
    const responseDoc = await responseRef.get();

    if (!responseDoc.exists) {
      return c.json({ success: false, message: 'Response not found' }, 404);
    }

    const responseData = responseDoc.data();

    // Update help request status and accepted responder
    
// Update help request status and accepted responder
await helpRequestRef.update({
  status: 'in_progress',
  acceptedResponderId: responseId,
  acceptedResponderUserId: responseData?.userId,
  updatedAt: new Date().toISOString()
});

// Create entry in helpedRequests collection when responder is accepted
const helpedRequestRef = getFirestore().collection('helpedRequests').doc(requestId);
// Calculate XP based on priority for gamification
const calculateXP = (priority: string): number => {
  switch (priority?.toLowerCase()) {
    case 'emergency':
      return 500;
    case 'urgent':
      return 300;
    default:
      return 100; // for 'medium', 'low', or any other priority
  }
};

const helpedRequestData = {
  requestId: requestId,
  acceptedUserID: responseData?.userId, // This is the responder's userId
  acceptedAt: new Date().toISOString(),
  status: 'in_progress', // Initially in progress
  xp: calculateXP(helpRequestData.priority), // XP points based on priority
  originalRequestData: {
    title: helpRequestData.title,
    type: helpRequestData.type,
    description: helpRequestData.description,
    priority: helpRequestData.priority,
    requesterId: helpRequestData.userId,
    requesterUsername: helpRequestData.username,
    location: helpRequestData.location,
    address: helpRequestData.address
  },
  responderData: {
    userId: responseData?.userId,
    username: responseData?.username,
    phone: responseData?.phone,
    message: responseData?.message
  }
};

await helpedRequestRef.set(helpedRequestData);
console.log(`Created helpedRequests entry for ${requestId} with acceptedUserID: ${responseData?.userId}`);
    // Update response status
    await responseRef.update({
      status: 'accepted',
      acceptedAt: new Date().toISOString()
    });

    // Reject all other pending responses
    const allResponsesSnapshot = await helpRequestRef
      .collection('responses')
      .where('status', '==', 'pending')
      .get();

    const batch = getFirestore().batch();
    allResponsesSnapshot.docs.forEach(doc => {
      if (doc.id !== responseId) {
        batch.update(doc.ref, { 
          status: 'rejected',
          rejectedAt: new Date().toISOString()
        });
      }
    });
    await batch.commit();

    return c.json({ 
      success: true, 
      message: 'Responder accepted successfully' 
    });

  } catch (error) {
    console.error('Error accepting responder:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to accept responder' 
    }, 500);
  }
};

// Update help request status (complete, cancel, etc.)
export const updateHelpRequestStatus = async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');
    
    if (!idToken) {
      return c.json({ success: false, message: 'No authorization token provided' }, 401);
    }

    const decodedToken = await getAuth().verifyIdToken(idToken);
    const userId = decodedToken.uid;

    const { requestId } = c.req.param();
    const { status } = await c.req.json();

    if (!requestId || !status) {
      return c.json({ 
        success: false, 
        message: 'Request ID and status are required' 
      }, 400);
    }

    const validStatuses = ['open', 'in_progress', 'completed', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return c.json({ 
        success: false, 
        message: 'Invalid status. Must be one of: ' + validStatuses.join(', ') 
      }, 400);
    }

    // Get help request and verify ownership
    const helpRequestRef = getFirestore().collection('helpRequests').doc(requestId);
    const helpRequestDoc = await helpRequestRef.get();

    if (!helpRequestDoc.exists) {
      return c.json({ success: false, message: 'Help request not found' }, 404);
    }

    const helpRequestData = helpRequestDoc.data();
    if (helpRequestData?.userId !== userId) {
      return c.json({ 
        success: false, 
        message: 'You can only update your own requests' 
      }, 403);
    }

    // Update the status
    const updateData: any = {
      status,
      updatedAt: new Date().toISOString()
    };

   if (status === 'completed') {
  updateData.completedAt = new Date().toISOString();
}

// Handle XP accumulation for both completed and in_progress statuses
if (status === 'completed' || status === 'in_progress') {
  if (helpRequestData.acceptedResponderUserId) {
    console.log(`Updating helpedRequests entry for request ${requestId} to ${status} status`);
    
    const helpedRequestRef = getFirestore().collection('helpedRequests').doc(requestId);
    const helpedRequestDoc = await helpedRequestRef.get();
    
    if (helpedRequestDoc.exists) {
      const helpedRequestData = helpedRequestDoc.data();
      const xpGained = helpedRequestData?.xp || 0;
      
      // Update helpedRequests status
      const helpedUpdateData: any = {
        status: status,
        updatedAt: new Date().toISOString()
      };
      
      if (status === 'completed') {
        helpedUpdateData.completedAt = new Date().toISOString();
      }
      
      await helpedRequestRef.update(helpedUpdateData);
      
      // Update user's accumulated XP in users collection
      const userRef = getFirestore().collection('users').doc(helpRequestData.acceptedResponderUserId);
      const userDoc = await userRef.get();

      if (userDoc.exists) {
        const userData = userDoc.data();
        const currentAccumulateXP = userData?.accumulateXP || 0;
        const newAccumulateXP = currentAccumulateXP + xpGained;
        
        await userRef.update({
          accumulateXP: newAccumulateXP
        });
        
        console.log(`Updated user ${helpRequestData.acceptedResponderUserId} XP: ${currentAccumulateXP} + ${xpGained} = ${newAccumulateXP}`);
      } else {
        console.log(`User document ${helpRequestData.acceptedResponderUserId} does not exist. Cannot update XP.`);
      }
      
      console.log(`Successfully updated helpedRequests entry for ${requestId} to ${status} and accumulated ${xpGained} XP`);
    }
  }
}

else if (status === 'cancelled') {
      updateData.cancelledAt = new Date().toISOString();
      // Reset accepted responder if cancelling
      updateData.acceptedResponderId = null;
      updateData.acceptedResponderUserId = null;
    }

    await helpRequestRef.update(updateData);

    // Get user info for notification
    const userRecord = await getAuth().getUser(userId);
    
    // Create status update notifications
    const notificationResult = await notificationService.createHelpStatusNotification(
      requestId, 
      status, 
      userRecord.displayName || userRecord.email?.split('@')[0] || 'Someone'
    );
    console.log('Status notification result:', notificationResult);

    return c.json({ 
      success: true, 
      message: `Help request status updated to ${status}`,
      notifications: notificationResult
    });

  } catch (error) {
    console.error('Error updating help request status:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to update help request status' 
    }, 500);
  }
};

// Delete help request (only owner can delete)
export const deleteHelpRequest = async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');
    
    if (!idToken) {
      return c.json({ success: false, message: 'No authorization token provided' }, 401);
    }

    const decodedToken = await getAuth().verifyIdToken(idToken);
    const userId = decodedToken.uid;

    const { requestId } = c.req.param();

    if (!requestId) {
      return c.json({ success: false, message: 'Request ID is required' }, 400);
    }

    // Get help request and verify ownership
    const helpRequestRef = getFirestore().collection('helpRequests').doc(requestId);
    const helpRequestDoc = await helpRequestRef.get();

    if (!helpRequestDoc.exists) {
      return c.json({ success: false, message: 'Help request not found' }, 404);
    }

    const helpRequestData = helpRequestDoc.data();
    if (helpRequestData?.userId !== userId) {
      return c.json({ 
        success: false, 
        message: 'You can only delete your own requests' 
      }, 403);
    }

    // Delete all responses first
    const responsesSnapshot = await helpRequestRef.collection('responses').get();
    const batch = getFirestore().batch();
    
    responsesSnapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    // Delete the help request
    batch.delete(helpRequestRef);
    
    await batch.commit();

    return c.json({ 
      success: true, 
      message: 'Help request deleted successfully' 
    });

  } catch (error) {
    console.error('Error deleting help request:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to delete help request' 
    }, 500);
  }
};

// Get help requests near a location
export const getNearbyHelpRequests = async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');
    
    console.log('Auth header received:', authHeader ? 'Present' : 'Missing');
    
    if (!idToken) {
      return c.json({ success: false, message: 'No authorization token provided' }, 401);
    }

    try {
      await getAuth().verifyIdToken(idToken);
      console.log('Token verified successfully');
    } catch (authError) {
      console.error('Token verification failed:', authError);
      return c.json({ success: false, message: 'Invalid authentication token' }, 401);
    }

    const { latitude, longitude, radiusKm = '10', status = 'open' } = c.req.query();

    if (!latitude || !longitude) {
      return c.json({ 
        success: false, 
        message: 'Latitude and longitude are required' 
      }, 400);
    }

    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    const radius = parseFloat(radiusKm);

    console.log(`Searching for nearby requests at (${lat}, ${lng}) within ${radius}km with status: ${status}`);

    // For now, we'll get all requests and filter by distance
    // In production, you might want to use a more efficient geospatial query
    let query: any = getFirestore().collection('helpRequests');
    
    if (status) {
      query = query.where('status', '==', status);
    }

    const snapshot = await query.limit(100).get();
    console.log(`Total documents found: ${snapshot.docs.length}`);
    
    const nearbyRequests = [];

    for (const doc of snapshot.docs) {
      const requestData = doc.data();
      const requestLat = requestData.location?.latitude;
      const requestLng = requestData.location?.longitude;

      console.log(`Processing document ${doc.id}:`, {
        id: requestData.id,
        title: requestData.title,
        status: requestData.status,
        location: { lat: requestLat, lng: requestLng }
      });

      if (requestLat && requestLng) {
        // Calculate distance using Haversine formula
        const distance = calculateDistance(lat, lng, requestLat, requestLng);
        console.log(`Distance from search point: ${distance}km (radius: ${radius}km)`);
        
        if (distance <= radius) {
          console.log(`Document ${doc.id} is within radius, adding to results`);
          
          // Get responses for this request
          const responsesSnapshot = await doc.ref.collection('responses').get();
          const responses = responsesSnapshot.docs.map((responseDoc: any) => ({
            id: responseDoc.id,
            ...responseDoc.data()
          }));

          nearbyRequests.push({
            ...requestData,
            responses,
            distanceKm: Math.round(distance * 100) / 100 // Round to 2 decimal places
          });
        } else {
          console.log(`Document ${doc.id} is outside radius (${distance}km > ${radius}km)`);
        }
      } else {
        console.log(`Document ${doc.id} has invalid location data:`, { lat: requestLat, lng: requestLng });
      }
    }

    console.log(`Final nearby requests count: ${nearbyRequests.length}`);

    // Sort by distance
    nearbyRequests.sort((a, b) => a.distanceKm - b.distanceKm);

    return c.json({ 
      success: true, 
      data: nearbyRequests,
      count: nearbyRequests.length
    });

  } catch (error) {
    console.error('Error fetching nearby help requests:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to fetch nearby help requests' 
    }, 500);
  }
};

// Helper function to calculate distance between two coordinates
function calculateDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371; // Radius of the Earth in kilometers
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
    Math.sin(dLng/2) * Math.sin(dLng/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  const distance = R * c;
  return distance;
}

// Test endpoint to create sample help request
export const createSampleHelpRequest = async (c: Context) => {
  try {
    const db = getFirestore();
    const helpRequestRef = db.collection('helpRequests').doc();
    const helpRequestId = helpRequestRef.id;

    const sampleRequest = {
      id: helpRequestId,
      userId: 'test-user-123',
      username: 'Test User',
      type: 'General',
      title: 'Test Help Request',
      description: 'This is a test help request for debugging',
      location: {
        latitude: 23.8103,
        longitude: 90.4125
      },
      address: 'Dhanmondi, Dhaka, Bangladesh',
      priority: 'medium',
      phone: '+880 1XXX-XXXXXX',
      status: 'open',
      acceptedResponderId: null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    await helpRequestRef.set(sampleRequest);

    return c.json({ 
      success: true, 
      message: 'Sample help request created successfully',
      data: sampleRequest
    }, 201);

  } catch (error) {
    console.error('Error creating sample help request:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to create sample help request' 
    }, 500);
  }
};

// Create multiple dummy help requests for testing
export const createDummyHelpRequests = async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');
    
    if (!idToken) {
      return c.json({ success: false, message: 'No authorization token provided' }, 401);
    }

    await getAuth().verifyIdToken(idToken);

    const db = getFirestore();
    const batch = db.batch();
    
    // Dummy data around MIST area (23.8223, 90.3654) and nearby Dhaka locations
    const dummyRequests = [
      {
        type: 'Medical Emergency',
        title: 'Need urgent medical help',
        description: 'Someone collapsed near the main gate. Need immediate medical assistance.',
        location: { latitude: 23.8225, longitude: 90.3656 },
        address: 'MIST Main Gate, Mirpur Cantonment, Dhaka',
        priority: 'high',
        phone: '+880 1712-345678'
      },
      {
        type: 'Transportation',
        title: 'Car breakdown assistance needed',
        description: 'My car broke down and I need a mechanic or towing service.',
        location: { latitude: 23.8220, longitude: 90.3650 },
        address: 'Near MIST Academic Building, Mirpur Cantonment',
        priority: 'medium',
        phone: '+880 1823-456789'
      },
      {
        type: 'General',
        title: 'Lost pet - help needed',
        description: 'My cat is missing since yesterday. Golden colored, wearing a red collar.',
        location: { latitude: 23.8218, longitude: 90.3658 },
        address: 'MIST Residential Area, Mirpur Cantonment',
        priority: 'medium',
        phone: '+880 1934-567890'
      },
      {
        type: 'Emergency',
        title: 'Stuck in elevator',
        description: 'Trapped in elevator between 3rd and 4th floor. Need help immediately.',
        location: { latitude: 23.8227, longitude: 90.3652 },
        address: 'MIST Engineering Building, Mirpur Cantonment',
        priority: 'high',
        phone: '+880 1645-678901'
      },
      {
        type: 'General',
        title: 'Need help moving furniture',
        description: 'Moving to a new apartment and need 2-3 people to help with furniture.',
        location: { latitude: 23.8215, longitude: 90.3662 },
        address: 'MIST Officer Quarter, Mirpur Cantonment',
        priority: 'low',
        phone: '+880 1756-789012'
      },
      {
        type: 'Transportation',
        title: 'Ride sharing to airport',
        description: 'Need someone to share a ride to Hazrat Shahjalal International Airport.',
        location: { latitude: 23.8230, longitude: 90.3648 },
        address: 'MIST Sports Complex, Mirpur Cantonment',
        priority: 'medium',
        phone: '+880 1867-890123'
      },
      {
        type: 'General',
        title: 'Tutor needed for Math',
        description: 'Looking for a math tutor for high school level. Flexible timing.',
        location: { latitude: 23.8212, longitude: 90.3665 },
        address: 'Near MIST Library, Mirpur Cantonment',
        priority: 'low',
        phone: '+880 1978-901234'
      },
      {
        type: 'Emergency',
        title: 'Water leakage emergency',
        description: 'Major water pipe burst in basement. Need emergency plumber.',
        location: { latitude: 23.8235, longitude: 90.3645 },
        address: 'MIST Administrative Building, Mirpur Cantonment',
        priority: 'high',
        phone: '+880 1589-012345'
      }
    ];

    const createdRequests = [];
    
    for (const requestData of dummyRequests) {
      const helpRequestRef = db.collection('helpRequests').doc();
      const helpRequestId = helpRequestRef.id;

      const helpRequest = {
        id: helpRequestId,
        userId: 'dummy-user-' + Math.random().toString(36).substr(2, 9),
        username: 'Dummy User ' + Math.floor(Math.random() * 100),
        isDummy: true, // Special flag to identify dummy data for easy removal
        dummyCreatedAt: new Date().toISOString(), // Additional timestamp for dummy data
        ...requestData,
        status: 'open',
        acceptedResponderId: null,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };

      batch.set(helpRequestRef, helpRequest);
      createdRequests.push(helpRequest);
    }

    await batch.commit();

    return c.json({ 
      success: true, 
      message: `${dummyRequests.length} dummy help requests created successfully`,
      data: createdRequests,
      count: createdRequests.length
    }, 201);

  } catch (error) {
    console.error('Error creating dummy help requests:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to create dummy help requests' 
    }, 500);
  }
};

// Remove all dummy help requests
export const removeDummyHelpRequests = async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');
    
    if (!idToken) {
      return c.json({ success: false, message: 'No authorization token provided' }, 401);
    }

    await getAuth().verifyIdToken(idToken);

    const db = getFirestore();
    
    // Find all dummy requests
    const dummyRequestsQuery = await db.collection('helpRequests')
      .where('isDummy', '==', true)
      .get();

    if (dummyRequestsQuery.empty) {
      return c.json({ 
        success: true, 
        message: 'No dummy help requests found to remove',
        removedCount: 0
      });
    }

    const batch = db.batch();
    let removedCount = 0;

    dummyRequestsQuery.docs.forEach((doc) => {
      batch.delete(doc.ref);
      removedCount++;
    });

    await batch.commit();

    return c.json({ 
      success: true, 
      message: `Successfully removed ${removedCount} dummy help requests`,
      removedCount: removedCount
    });

  } catch (error) {
    console.error('Error removing dummy help requests:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to remove dummy help requests' 
    }, 500);
  }
};

// Get responses for a specific help request
export const getHelpRequestResponses = async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');

    if (!idToken) {
      return c.json({ success: false, message: 'Missing Authorization header' }, 401);
    }
    await getAuth().verifyIdToken(idToken);

    const requestId = c.req.param('requestId');
    
    if (!requestId) {
      return c.json({ success: false, message: 'Request ID is required' }, 400);
    }

    // Get the help request first to verify it exists
    const db = getFirestore();
    const helpRequestDoc = await db.collection('helpRequests').doc(requestId).get();
    
    if (!helpRequestDoc.exists) {
      return c.json({ success: false, message: 'Help request not found' }, 404);
    }

    // Get all responses for this help request
    const responsesQuery = await db.collection('helpRequestResponses')
      .where('requestId', '==', requestId)
      .orderBy('createdAt', 'desc')
      .get();

    const responses = responsesQuery.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    return c.json({ 
      success: true, 
      responses: responses,
      count: responses.length
    });

  } catch (error) {
    console.error('Error getting help request responses:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to get help request responses' 
    }, 500);
  }
};

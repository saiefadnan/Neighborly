import type { Context } from 'hono';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';

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
    const username = userRecord.displayName || userRecord.email?.split('@')[0] || 'Anonymous User';
    
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

    return c.json({ 
      success: true, 
      message: 'Help request created successfully',
      requestId: helpRequestId,
      data: helpRequest
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

    return c.json({ 
      success: true, 
      message: 'Response submitted successfully',
      responseId: responseRef.id
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
const helpedRequestData = {
  requestId: requestId,
  acceptedUserID: responseData?.userId, // This is the responder's userId
  acceptedAt: new Date().toISOString(),
  status: 'in_progress', // Initially in progress
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
  
  // Update the existing helpedRequests entry to mark as completed
  if (helpRequestData.acceptedResponderUserId) {
    console.log(`Updating helpedRequests entry for request ${requestId} to completed status`);
    
    const helpedRequestRef = getFirestore().collection('helpedRequests').doc(requestId);
    await helpedRequestRef.update({
      status: 'completed',
      completedAt: new Date().toISOString()
    });
    console.log(`Successfully updated helpedRequests entry for ${requestId} to completed`);
  }
} 

else if (status === 'cancelled') {
      updateData.cancelledAt = new Date().toISOString();
      // Reset accepted responder if cancelling
      updateData.acceptedResponderId = null;
      updateData.acceptedResponderUserId = null;
    }

    await helpRequestRef.update(updateData);

    return c.json({ 
      success: true, 
      message: `Help request status updated to ${status}` 
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

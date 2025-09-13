import type { Context } from 'hono';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

// Calculate XP based on priority
const calculateXP = (priority: string): number => {
  switch (priority?.toLowerCase()) {
    case 'emergency':
      return 500;
    case 'urgent':
      return 300;
    default:
      return 100;
  }
};

// Get help requests that the logged-in user has provided help for
export const getUserHelpProvided = async (c: Context) => {
  try {
    console.log('getUserHelpProvided called');
    
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');

    if (!idToken) {
      return c.json({ success: false, message: 'Missing Authorization header' }, 401);
    }

    // Verify user token
    const decodedToken = await getAuth().verifyIdToken(idToken);
    const userId = decodedToken.uid;
    console.log('User authenticated:', userId);

    // Get helpedRequests where current user is the acceptedUserID (helper)
    console.log('Fetching helpedRequests where acceptedUserID =', userId);
    
    const helpedRequestsSnapshot = await getFirestore()
      .collection('helpedRequests')
      .where('acceptedUserID', '==', userId)
      .get();

    console.log('Found', helpedRequestsSnapshot.docs.length, 'helped requests');

    const helpProvided: any[] = [];

    for (const doc of helpedRequestsSnapshot.docs) {
      try {
        const helpData = doc.data();
        console.log('Processing help request:', doc.id);
        
        // Get requester user info with better error handling
        // Get requester user info with Firestore fallback
let requesterInfo: any = {
  name: 'Unknown User',
  username: 'Unknown',
  profilePicture: null
};

// Get requesterId from helpData or originalRequestData
const requesterUserId = helpData.requesterId || helpData.originalRequestData?.requesterId;

if (requesterUserId) {
  try {
    console.log('Fetching user data for requesterId:', requesterUserId);
    
    // Try to get user info from users collection
    const requesterDoc = await getFirestore()
      .collection('users')
      .doc(requesterUserId)
      .get();
    
    console.log('Requester doc exists?', requesterDoc.exists);
    
    if (requesterDoc.exists) {
  const userData = requesterDoc.data();
  console.log('Requester user data keys:', Object.keys(userData || {}));
  console.log('All user data:', JSON.stringify(userData, null, 2));
  console.log('profilepicurl field:', userData?.profilepicurl);
  console.log('profilePicUrl field:', userData?.profilePicUrl);
  console.log('profile_pic_url field:', userData?.profile_pic_url);
      
      requesterInfo = {
        name: `${userData?.firstName || ''} ${userData?.lastName || ''}`.trim() || userData?.username || 'Unknown User',
        username: userData?.username || 'Unknown',
        profilePicture: userData?.profilepicurl || userData?.profilePicUrl || userData?.profile_pic_url || userData?.profilePicture || null      };
      
      console.log('Final requester info:', requesterInfo);
    } else {
      // Firestore fallback: use data already in helpedRequests document
      console.log('User document not found, using embedded data');
      requesterInfo = {
        name: helpData.requesterName || helpData.originalRequestData?.requesterUsername || 'Unknown User',
        username: helpData.requesterUsername || helpData.originalRequestData?.requesterUsername || 'Unknown',
        profilePicture: null
      };
    }
  } catch (e) {
    console.log('Failed to fetch requester info from users collection, using embedded data:', e);
    // Use fallback data from helpedRequests document itself
    requesterInfo = {
      name: helpData.requesterName || helpData.originalRequestData?.requesterUsername || 'Unknown User',
      username: helpData.requesterUsername || helpData.originalRequestData?.requesterUsername || 'Unknown',
      profilePicture: null
    };
  }
}

        // Use originalRequestData if available
        let requestDetails: any = helpData.originalRequestData || {};
        const priority = requestDetails.priority || 'normal';
        
        // Calculate XP based on priority
        const calculatedXP = calculateXP(priority);
        const actualXP = helpData.xp || calculatedXP; // Use stored XP or calculate

        helpProvided.push({
          id: doc.id,
          helpRequestId: helpData.helpRequestId || helpData.requestId || '',
          requester: requesterInfo,
          title: requestDetails.title || helpData.title || 'Help Request',
          description: requestDetails.description || helpData.description || '',
          location: requestDetails.address || helpData.location || 'Unknown location',
          type: requestDetails.type || requestDetails.title || 'General',
          status: helpData.status || 'Completed',
          priority: priority,
          acceptedAt: helpData.acceptedAt || null,
          completedAt: helpData.completedAt || null,
          updatedAt: helpData.updatedAt || null,
          message: helpData.message || 'Help has been completed!',
          xp: actualXP,
          initiatorName: helpData.initiatorName || 'Unknown',
          initiatorType: helpData.initiatorType || 'helper',
          rating: null,
          feedback: null
        });
      } catch (docError) {
        console.error('Error processing document:', doc.id, docError);
        // Continue with next document
      }
    }

    console.log('Successfully processed', helpProvided.length, 'help requests');

    return c.json({
      success: true,
      data: helpProvided,
      count: helpProvided.length,
      totalXP: helpProvided.reduce((sum, help) => sum + (help.xp || 0), 0),
      message: `Found ${helpProvided.length} help requests you provided`
    });

  } catch (error) {
    console.error('Error in getUserHelpProvided:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to fetch help provided',
      error: error instanceof Error ? error.message : 'Unknown error'
    }, 500);
  }
};

// Get help requests that the logged-in user has received help for
export const getUserHelpReceived = async (c: Context) => {
  try {
    console.log('getUserHelpReceived called');
    
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');

    if (!idToken) {
      return c.json({ success: false, message: 'Missing Authorization header' }, 401);
    }

    // Verify user token
    const decodedToken = await getAuth().verifyIdToken(idToken);
    const userId = decodedToken.uid;
    console.log('User authenticated:', userId);

    // Get helpedRequests where current user is the requesterId (receiver)
    console.log('Fetching helpedRequests where requesterId =', userId);
    
    const helpedRequestsSnapshot = await getFirestore()
      .collection('helpedRequests')
      .where('requesterId', '==', userId)
      .get();

    console.log('Found', helpedRequestsSnapshot.docs.length, 'received help requests');

    const helpReceived: any[] = [];

    for (const doc of helpedRequestsSnapshot.docs) {
      try {
        const helpData = doc.data();
        console.log('Processing received help request:', doc.id);
        
        // Get helper user info with better error handling
        // Get helper user info with Firestore fallback
let helperInfo: any = {
  name: 'Unknown User',
  username: 'Unknown',
  profilePicture: null
};

// Get acceptedUserID (helper ID) from helpData
const helperUserId = helpData.acceptedUserID || helpData.responderId || helpData.responderData?.userId;

if (helperUserId) {
  try {
    console.log('Fetching user data for helper userId:', helperUserId);
    
    // Try to get user info from users collection
    const helperDoc = await getFirestore()
      .collection('users')
      .doc(helperUserId)
      .get();
    
    console.log('Helper doc exists?', helperDoc.exists);
    
    if (helperDoc.exists) {
      const userData = helperDoc.data();
      console.log('Helper user data:', userData);
      console.log('Helper profile pic URL:', userData?.profilepicurl);
      
      helperInfo = {
        name: `${userData?.firstName || ''} ${userData?.lastName || ''}`.trim() || userData?.username || 'Unknown User',
        username: userData?.username || 'Unknown',
        profilePicture: userData?.profilepicurl || userData?.profilePicUrl || userData?.profile_pic_url || userData?.profilePicture || null
      };
      
      console.log('Final helper info:', helperInfo);
    } else {
      // Firestore fallback: use data already in helpedRequests document
      helperInfo = {
        name: helpData.responderName || helpData.initiatorName || 'Unknown User',
        username: helpData.responderData?.username || helpData.initiatorName || 'Unknown',
        profilePicture: null
      };
    }
  } catch (e) {
    console.log('Failed to fetch helper info from users collection, using embedded data:', e);
    // Use fallback data from helpedRequests document itself
    helperInfo = {
      name: helpData.responderName || helpData.initiatorName || 'Unknown User',
      username: helpData.responderData?.username || helpData.initiatorName || 'Unknown',
      profilePicture: null
    };
  }
}

        // Use originalRequestData if available
        let requestDetails: any = helpData.originalRequestData || {};

        helpReceived.push({
          id: doc.id,
          helpRequestId: helpData.helpRequestId || helpData.requestId || '',
          helper: helperInfo,
          title: requestDetails.title || helpData.title || 'Help Request',
          description: requestDetails.description || helpData.description || '',
          location: requestDetails.address || helpData.location || 'Unknown location',
          type: requestDetails.type || requestDetails.title || 'General',
          status: helpData.status || 'Completed',
          priority: requestDetails.priority || 'normal',
          acceptedAt: helpData.acceptedAt || null,
          completedAt: helpData.completedAt || null,
          updatedAt: helpData.updatedAt || null,
          message: helpData.message || 'Help has been completed!',
          xp: 0, // Receivers don't get XP
          initiatorName: helpData.initiatorName || 'Unknown',
          initiatorType: helpData.initiatorType || 'requester',
          rating: null,
          feedback: null
        });
      } catch (docError) {
        console.error('Error processing received help document:', doc.id, docError);
        // Continue with next document
      }
    }

    console.log('Successfully processed', helpReceived.length, 'received help requests');

    return c.json({
      success: true,
      data: helpReceived,
      count: helpReceived.length,
      message: `Found ${helpReceived.length} help requests you received help for`
    });

  } catch (error) {
    console.error('Error in getUserHelpReceived:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to fetch help received',
      error: error instanceof Error ? error.message : 'Unknown error'
    }, 500);
  }
};
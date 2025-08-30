import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import type { Context } from 'hono';

// help request statistics by title
export const getHelpRequestStats = async (c: Context) => {
  console.log('getHelpRequestStats called');
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');

    if (!idToken) {
      return c.json({ success: false, message: 'Missing Authorization header' }, 401);
    }

    // Verify user token
    const decodedToken = await getAuth().verifyIdToken(idToken);
    console.log('User authenticated:', decodedToken.uid);

    // Fetch all help requests from Firestore
    const helpRequestsCollection = await getFirestore().collection('helpRequests').get();
    
    if (helpRequestsCollection.empty) {
      return c.json({ success: true, data: {}, message: 'No help requests found' });
    }

    // Count by title
    const titleCounts: Record<string, number> = {};
    
    helpRequestsCollection.docs.forEach((doc) => {
      const data = doc.data();
      const title = data.title || 'Unknown'; // Default to 'Unknown' if no title
      
      if (titleCounts[title]) {
        titleCounts[title]++;
      } else {
        titleCounts[title] = 1;
      }
    });

    console.log('Title counts:', titleCounts);

    return c.json({ 
      success: true, 
      data: titleCounts,
      totalRequests: helpRequestsCollection.docs.length
    });

  } catch (error) {
    console.error('Error fetching help request stats:', error);
    return c.json({ success: false, message: 'Failed to fetch help request statistics' }, 500);
  }
};

// Get successful helps count for the logged-in user
export const getUserSuccessfulHelpsCount = async (c: Context) => {
  console.log('getUserSuccessfulHelpsCount called');
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');

    if (!idToken) {
      return c.json({ success: false, message: 'Missing Authorization header' }, 401);
    }

    // Verify user token
    const decodedToken = await getAuth().verifyIdToken(idToken);
    const userId = decodedToken.uid;
    console.log('User authenticated:', userId);

    // Fetch all help requests where this user's ID is in acceptedResponderId
    const helpRequestsCollection = await getFirestore().collection('helpRequests').get();
    
    if (helpRequestsCollection.empty) {
      return c.json({ success: true, count: 0, message: 'No help requests found' });
    }

    // Count help requests where acceptedResponderId matches the user's UID
    let successfulHelpsCount = 0;
    
    helpRequestsCollection.docs.forEach((doc) => {
      const data = doc.data();
      const acceptedResponderId = data.acceptedResponderId;
      
      if (acceptedResponderId === userId) {
        successfulHelpsCount++;
      }
    });

    console.log(`User ${userId} has ${successfulHelpsCount} successful helps`);

    return c.json({ 
      success: true, 
      count: successfulHelpsCount,
      message: `User has successfully helped in ${successfulHelpsCount} requests`
    });

  } catch (error) {
    console.error('Error fetching user successful helps count:', error);
    return c.json({ success: false, message: 'Failed to fetch successful helps count' }, 500);
  }
};

// Get helped requests stats by title for radial chart
// Get helped requests stats by title for radial chart (for current user only)
export const getHelpedRequestStats = async (c: Context) => {
  console.log('getHelpedRequestStats called');
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');

    if (!idToken) {
      return c.json({ success: false, message: 'Missing Authorization header' }, 401);
    }

    // Verify user token
    const decodedToken = await getAuth().verifyIdToken(idToken);
    const currentUserId = decodedToken.uid; // Get the current user's ID
    console.log('User authenticated:', currentUserId);

    // Fetch all helped requests from Firestore
    const helpedRequestsCollection = await getFirestore().collection('helpedRequests').get();
    
    if (helpedRequestsCollection.empty) {
      return c.json({ success: true, data: {}, message: 'No helped requests found' });
    }

    // Count by originalRequestData.title, but only for current user's contributions
    const titleCounts: Record<string, number> = {};
    let userContributionsCount = 0;
    
    helpedRequestsCollection.docs.forEach((doc) => {
      const data = doc.data();
      const acceptedUserID = data.acceptedUserID; // This is the helper's userId
      
      // Only count requests where the current user was the accepted helper
      if (acceptedUserID === currentUserId) {
        const title = data.originalRequestData?.title || 'Unknown';
        
        if (titleCounts[title]) {
          titleCounts[title]++;
        } else {
          titleCounts[title] = 1;
        }
        userContributionsCount++;
      }
    });

    console.log(`User ${currentUserId} contributions by title:`, titleCounts);
    console.log(`Total user contributions: ${userContributionsCount}`);

    return c.json({ 
      success: true, 
      data: titleCounts,
      totalUserContributions: userContributionsCount,
      message: `User has ${userContributionsCount} contributions`
    });

  } catch (error) {
    console.error('Error fetching helped request stats:', error);
    return c.json({ success: false, message: 'Failed to fetch helped request statistics' }, 500);
  }
};
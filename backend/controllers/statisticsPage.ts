import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import type { Context } from 'hono';

// Get help request statistics by title
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
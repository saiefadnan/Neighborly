import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import type { Context } from 'hono';

// Define the type for user posts
interface UserPost {
  postId: string;
  title: string;
  category: string;
  type: string;
  timestamp: string;
  originalTimestamp: any;
  upvotes: number;
  totalComments: number;
  reacts: number;
}

// Get active posts with timestamps for the logged-in user
export const getUserActivePostsCount = async (c: Context) => {
  console.log('getUserActivePostsCount called');
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

    // Fetch all posts where this user's ID is in authorID (WITHOUT orderBy to avoid index issues)
    const postsQuery = await getFirestore()
      .collection('posts')
      .where('authorID', '==', userId)
      .get();
    
    if (postsQuery.empty) {
      return c.json({ 
        success: true, 
        count: 0, 
        posts: [],
        message: 'No posts found' 
      });
    }

    // Process posts and format timestamps
    const userPosts: UserPost[] = [];
    
    postsQuery.docs.forEach((doc) => {
      const data = doc.data();
      const postId = doc.id;
      
      // Format timestamp to readable format
      let formattedTimestamp = 'Unknown date';
      if (data.timestamp) {
        try {
          // Handle Firestore Timestamp object
          let date: Date;
          
          if (data.timestamp && typeof data.timestamp === 'object' && data.timestamp.toDate) {
            // Firestore Timestamp object
            date = data.timestamp.toDate();
          } else if (data.timestamp._seconds) {
            // Firestore Timestamp with _seconds property
            date = new Date(data.timestamp._seconds * 1000);
          } else if (typeof data.timestamp === 'string') {
            // String timestamp
            date = new Date(data.timestamp);
          } else if (data.timestamp instanceof Date) {
            // Already a Date object
            date = data.timestamp;
          } else {
            // Try to parse as is
            date = new Date(data.timestamp);
          }
          
          if (date && !isNaN(date.getTime())) {
            // Format: August 10, 2025 at 1:58 AM
            formattedTimestamp = date.toLocaleString('en-US', {
              year: 'numeric',
              month: 'long',
              day: 'numeric',
              hour: 'numeric',
              minute: '2-digit',
              hour12: true,
              timeZone: 'Asia/Dhaka'
            });
          }
        } catch (error) {
          console.error('Error formatting timestamp for post', postId, ':', error);
          formattedTimestamp = 'Invalid date';
        }
      }
      
      userPosts.push({
        postId: postId,
        title: data.title || 'Untitled Post',
        category: data.category || 'General',
        type: data.type || 'text',
        timestamp: formattedTimestamp,
        originalTimestamp: data.timestamp,
        upvotes: data.upvotes || 0,
        totalComments: data.totalComments || 0,
        reacts: data.reacts || 0
      });
    });

    // Sort posts by timestamp manually (newest first)
    userPosts.sort((a, b) => {
      if (a.originalTimestamp && b.originalTimestamp) {
        try {
          const dateA = a.originalTimestamp.toDate ? a.originalTimestamp.toDate() : new Date(a.originalTimestamp);
          const dateB = b.originalTimestamp.toDate ? b.originalTimestamp.toDate() : new Date(b.originalTimestamp);
          return dateB.getTime() - dateA.getTime();
        } catch (error) {
          return 0;
        }
      }
      return 0;
    });

    const activePostsCount = userPosts.length;

    console.log(`User ${userId} has ${activePostsCount} active posts`);

    return c.json({ 
      success: true, 
      count: activePostsCount,
      posts: userPosts,
      message: `User has ${activePostsCount} active posts`
    });

  } catch (error) {
    console.error('Error fetching user active posts:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to fetch active posts', 
      error: error instanceof Error ? error.message : 'Unknown error'
    }, 500);
  }
};

// Add this interface after the existing UserPost interface
interface AcceptedHelpRequest {
  requestId: string;
  requesterUsername: string;
  requesterId: string;
  title: string;
  description: string;
  type: string;
  priority: string;
  address: string;
  acceptedAt: string;
  originalAcceptedAt: any;
  status: string;
}

// Add this new function after getUserActivePostsCount
// Replace the getUserAcceptedHelpRequests function with this debug version:
// Replace the getUserAcceptedHelpRequests function with this fixed version:
export const getUserAcceptedHelpRequests = async (c: Context) => {
  console.log('getUserAcceptedHelpRequests called');
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

    // Fetch all helpedRequests where this user's help was accepted
    const helpedRequestsQuery = await getFirestore()
      .collection('helpedRequests')
      .where('acceptedUserID', '==', userId)
      .get();
    
    if (helpedRequestsQuery.empty) {
      return c.json({ 
        success: true, 
        count: 0, 
        acceptedRequests: [],
        message: 'No accepted help requests found' 
      });
    }

    // Process accepted help requests and format timestamps
    const acceptedRequests: AcceptedHelpRequest[] = [];
    
    for (const doc of helpedRequestsQuery.docs) {
      const data = doc.data();
      const requestId = doc.id;
      
      // Get requester info - IT'S ALREADY IN originalRequestData!
      let requesterUsername = 'Unknown User';
      let requesterId = 'Unknown';
      
      if (data.originalRequestData) {
        // The data is already here!
        requesterId = data.originalRequestData.requesterId || 'Unknown';
        requesterUsername = data.originalRequestData.requesterUsername || 'Unknown User';
        console.log('Found requester info in originalRequestData:', { requesterId, requesterUsername });
      } else {
        // Fallback: try to fetch from helpRequests collection
        try {
          const originalRequestId = data.requestId || requestId;
          const originalRequestDoc = await getFirestore()
            .collection('helpRequests')
            .doc(originalRequestId)
            .get();
          
          if (originalRequestDoc.exists) {
            const originalData = originalRequestDoc.data();
            
            // The original request uses 'userId' and 'username' (without 'r')
            requesterId = originalData?.userId || 'Unknown';
            requesterUsername = originalData?.username || 'Unknown User';
            console.log('Found requester info in original request:', { requesterId, requesterUsername });
          }
        } catch (requestError) {
          console.error('Error fetching original request:', requestError);
        }
      }
      
      // Format acceptedAt timestamp to readable format
      let formattedAcceptedAt = 'Unknown date';
      if (data.acceptedAt) {
        try {
          let date: Date;
          
          if (data.acceptedAt && typeof data.acceptedAt === 'object' && data.acceptedAt.toDate) {
            date = data.acceptedAt.toDate();
          } else if (data.acceptedAt._seconds) {
            date = new Date(data.acceptedAt._seconds * 1000);
          } else if (typeof data.acceptedAt === 'string') {
            date = new Date(data.acceptedAt);
          } else if (data.acceptedAt instanceof Date) {
            date = data.acceptedAt;
          } else {
            date = new Date(data.acceptedAt);
          }
          
          if (date && !isNaN(date.getTime())) {
            formattedAcceptedAt = date.toLocaleString('en-US', {
              year: 'numeric',
              month: 'long',
              day: 'numeric',
              hour: 'numeric',
              minute: '2-digit',
              hour12: true,
              timeZone: 'Asia/Dhaka'
            });
          }
        } catch (error) {
          console.error('Error formatting acceptedAt timestamp for request', requestId, ':', error);
          formattedAcceptedAt = 'Invalid date';
        }
      }
      
      // Extract original request data
      const originalData = data.originalRequestData || {};
      
      acceptedRequests.push({
        requestId: data.requestId || requestId,
        requesterUsername: requesterUsername,  // ← Now correctly gets "ruslan"
        requesterId: requesterId,             // ← Now correctly gets "Ghysk4UoppWdaMeoqwJLpLJGsNw2"
        title: originalData.title || 'Help Request',
        description: originalData.description || 'No description available',
        type: originalData.type || 'General',
        priority: originalData.priority || 'normal',
        address: originalData.address || 'Unknown location',
        acceptedAt: formattedAcceptedAt,
        originalAcceptedAt: data.acceptedAt,
        status: data.status || 'unknown'
      });
    }

    // Sort by acceptedAt timestamp (newest first)
    acceptedRequests.sort((a, b) => {
      if (a.originalAcceptedAt && b.originalAcceptedAt) {
        try {
          const dateA = a.originalAcceptedAt.toDate ? a.originalAcceptedAt.toDate() : new Date(a.originalAcceptedAt);
          const dateB = b.originalAcceptedAt.toDate ? b.originalAcceptedAt.toDate() : new Date(b.originalAcceptedAt);
          return dateB.getTime() - dateA.getTime();
        } catch (error) {
          return 0;
        }
      }
      return 0;
    });

    const acceptedRequestsCount = acceptedRequests.length;

    console.log(`User ${userId} has ${acceptedRequestsCount} accepted help requests`);

    return c.json({ 
      success: true, 
      count: acceptedRequestsCount,
      acceptedRequests: acceptedRequests,
      message: `User has ${acceptedRequestsCount} accepted help requests`
    });

  } catch (error) {
    console.error('Error fetching user accepted help requests:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to fetch accepted help requests', 
      error: error instanceof Error ? error.message : 'Unknown error'
    }, 500);
  }
};
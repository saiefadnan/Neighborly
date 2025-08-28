import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import type { Context } from 'hono';

// Get active posts count for the logged-in user
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

    // Fetch all posts where this user's ID is in authorID
    const postsCollection = await getFirestore().collection('posts').get();
    
    if (postsCollection.empty) {
      return c.json({ success: true, count: 0, message: 'No posts found' });
    }

    // Count posts where authorID matches the user's UID
    let activePostsCount = 0;
    
    postsCollection.docs.forEach((doc) => {
      const data = doc.data();
      const authorID = data.authorID;
      
      if (authorID === userId) {
        activePostsCount++;
      }
    });

    console.log(`User ${userId} has ${activePostsCount} active posts`);

    return c.json({ 
      success: true, 
      count: activePostsCount,
      message: `User has ${activePostsCount} active posts`
    });

  } catch (error) {
    console.error('Error fetching user active posts count:', error);
    return c.json({ success: false, message: 'Failed to fetch active posts count' }, 500);
  }
};
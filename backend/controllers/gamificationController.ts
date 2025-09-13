import type { Context } from 'hono';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';

// Level calculation function
// Level calculation function
function calculateLevel(accumulateXP: number): number {
  const xpRequirements: number[] = [
    0,     // Level 1 starts at 0
    1000,  // Level 1 to 2: 1000 XP
    3500,  // Level 2 to 3: 2500 more (1000 + 2500)
    8500,  // Level 3 to 4: 5000 more (3500 + 5000)
    16500, // Level 4 to 5: 8000 more
    28500, // Level 5 to 6: 12000 more
    45500, // Level 6 to 7: 17000 more
    68500, // Level 7 to 8: 23000 more
    98500, // Level 8 to 9: 30000 more
    136500, // Level 9 to 10: 38000 more
  ];

  let currentLevel = 1; // Default level is 1
  
  for (let i = 1; i < xpRequirements.length; i++) {
    const requiredXP = xpRequirements[i];
    if (requiredXP !== undefined && accumulateXP >= requiredXP) {
      currentLevel = i + 1;
    } else {
      break;
    }
  }

  return currentLevel;
}

// Get accumulated XP for the logged-in user
export const getUserAccumulatedXP = async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');
    
    if (!idToken) {
      return c.json({ success: false, message: 'No authorization token provided' }, 401);
    }

    // Verify the user token and get user ID
    const decodedToken = await getAuth().verifyIdToken(idToken);
    const userId = decodedToken.uid;

    // Get user document from Firestore
    const userRef = getFirestore().collection('users').doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      return c.json({ 
        success: false, 
        message: 'User not found' 
      }, 404);
    }

    const userData = userDoc.data();
    const accumulateXP = userData?.accumulateXP || 0;
    const calculatedLevel = calculateLevel(accumulateXP);
    const currentStoredLevel = userData?.level || 1;

    // Update level in database if it's different from calculated level
    if (calculatedLevel !== currentStoredLevel) {
      await userRef.update({
        level: calculatedLevel,
        levelUpdatedAt: new Date().toISOString()
      });
      console.log(`Updated user ${userId} level from ${currentStoredLevel} to ${calculatedLevel} based on ${accumulateXP} XP`);
    }

    // Get additional user info
    const userRecord = await getAuth().getUser(userId);
    const username = userRecord.displayName || userRecord.email?.split('@')[0] || 'Anonymous User';

    return c.json({ 
      success: true, 
      data: {
        userId: userId,
        username: username,
        accumulateXP: accumulateXP,
        level: calculatedLevel, // Return the calculated level
        lastUpdated: userData?.xpMigratedAt || userData?.updatedAt || null
      }
    });

  } catch (error) {
    console.error('Error getting user accumulated XP:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to get user accumulated XP' 
    }, 500);
  }
};

// Get user's help history with XP breakdown
export const getUserHelpHistory = async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');
    
    if (!idToken) {
      return c.json({ success: false, message: 'No authorization token provided' }, 401);
    }

    const decodedToken = await getAuth().verifyIdToken(idToken);
    const userId = decodedToken.uid;

    // Get all helpedRequests for this user
    const helpedRequestsQuery = await getFirestore()
      .collection('helpedRequests')
      .where('acceptedUserID', '==', userId)
      .get();

    const helpHistory = [];
    let totalXP = 0;

    for (const doc of helpedRequestsQuery.docs) {
      const data = doc.data();
      const xp = data.xp || 0;
      totalXP += xp;

      helpHistory.push({
        requestId: data.requestId,
        xp: xp,
        status: data.status,
        acceptedAt: data.acceptedAt,
        completedAt: data.completedAt || null,
        originalRequestData: {
          title: data.originalRequestData?.title || 'Unknown',
          type: data.originalRequestData?.type || 'Unknown',
          priority: data.originalRequestData?.priority || 'medium'
        }
      });
    }

    // Sort by acceptance date (newest first)
    helpHistory.sort((a, b) => new Date(b.acceptedAt).getTime() - new Date(a.acceptedAt).getTime());

    return c.json({ 
      success: true, 
      data: {
        userId: userId,
        totalHelpRequests: helpHistory.length,
        totalXPEarned: totalXP,
        helpHistory: helpHistory
      }
    });

  } catch (error) {
    console.error('Error getting user help history:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to get user help history' 
    }, 500);
  }
};

// Combined migration for both XP and levels
// Combined migration for both XP and levels
// Combined migration for both XP and levels
export const migrateUserXPAndLevels = async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');
    
    if (!idToken) {
      return c.json({ success: false, message: 'No authorization token provided' }, 401);
    }

    await getAuth().verifyIdToken(idToken);

    const db = getFirestore();
    
    // First, get all helpedRequests to calculate XP
    const helpedRequestsQuery = await db.collection('helpedRequests')
  .where('status', '==', 'completed')  // ← ONLY completed
  .get();
    
    // Group XP by user - FORCE NUMBERS
    const userXPMap = new Map<string, number>();
    
    for (const doc of helpedRequestsQuery.docs) {
      const data = doc.data();
      const userId = data.acceptedUserID;
const xp = typeof data.xp === 'number' ? data.xp : parseInt(data.xp?.toString() || '0', 10) || 0;      
      if (userId && xp > 0) {
        const currentXP = Number(userXPMap.get(userId) || 0);  // ← FORCE NUMBER
        userXPMap.set(userId, currentXP + xp);  // ← NOW PROPER ADDITION
      }
    }

    // Get ALL users (not just those with XP)
    const allUsersQuery = await db.collection('users').get();
    const batch = db.batch();
    let migratedCount = 0;

    // Update each user's XP and level (including users with 0 XP)
    for (const userDoc of allUsersQuery.docs) {
      const userId = userDoc.id;
      const userData = userDoc.data();
      
      // Get XP for this user (0 if they haven't helped anyone) - FORCE NUMBER
      const totalXP = Number(userXPMap.get(userId) || 0);
      const calculatedLevel = calculateLevel(totalXP);
      
      const updateData: any = {};
      let needsUpdate = false;
      
      // Update XP if missing or different - FORCE NUMBER STORAGE
      const currentXP = Number(userData?.accumulateXP || 0);
      if (!userData?.hasOwnProperty('accumulateXP') || currentXP !== totalXP) {
        updateData.accumulateXP = Number(totalXP);  // ← FORCE NUMBER
        needsUpdate = true;
      }
      
      // Update level if missing or different - FORCE NUMBER STORAGE
      const currentLevel = Number(userData?.level || 1);
      if (!userData?.hasOwnProperty('level') || currentLevel !== calculatedLevel) {
        updateData.level = Number(calculatedLevel);  // ← FORCE NUMBER
        needsUpdate = true;
      }
      
      if (needsUpdate) {
        updateData.xpAndLevelMigratedAt = new Date().toISOString();
        batch.update(userDoc.ref, updateData);
        migratedCount++;
        console.log(`Migrating user ${userId}: XP=${totalXP}, Level=${calculatedLevel}`);
      }
    }

    if (migratedCount > 0) {
      await batch.commit();
    }

    return c.json({ 
      success: true, 
      message: `Successfully migrated XP and levels for ${migratedCount} users`,
      migratedCount: migratedCount,
      totalUsers: allUsersQuery.docs.length,
      usersWithXP: userXPMap.size
    });

  } catch (error) {
    console.error('Error migrating user XP and levels:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to migrate user XP and levels' 
    }, 500);
  }
};

// Add this to gamificationController.ts (after migrateUserXPAndLevels)
export const migrateUserLevels = async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');
    
    if (!idToken) {
      return c.json({ success: false, message: 'No authorization token provided' }, 401);
    }

    await getAuth().verifyIdToken(idToken);

    const db = getFirestore();
    const usersQuery = await db.collection('users').get();
    
    const batch = db.batch();
    let migratedCount = 0;

    for (const doc of usersQuery.docs) {
      const userData = doc.data();
      const accumulateXP = userData.accumulateXP || 0;
      const calculatedLevel = calculateLevel(accumulateXP);
      
      // Only update if level field doesn't exist or is different
      if (!userData.hasOwnProperty('level') || userData.level !== calculatedLevel) {
        batch.update(doc.ref, {
          level: calculatedLevel,
          levelMigratedAt: new Date().toISOString()
        });
        migratedCount++;
        console.log(`Setting level ${calculatedLevel} for user ${doc.id} with ${accumulateXP} XP`);
      }
    }

    if (migratedCount > 0) {
      await batch.commit();
    }

    return c.json({ 
      success: true, 
      message: `Successfully migrated levels for ${migratedCount} users`,
      migratedCount: migratedCount
    });

  } catch (error) {
    console.error('Error migrating user levels:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to migrate user levels' 
    }, 500);
  }
};



// Get user's badge counts based on help request types
// Get user's badge counts based on help request types + Community Hero
// Get user's badge counts based on help request types + Community Hero + Kindstart
export const getUserBadgeCounts = async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');
    
    if (!idToken) {
      return c.json({ success: false, message: 'No authorization token provided' }, 401);
    }

    const decodedToken = await getAuth().verifyIdToken(idToken);
    const userId = decodedToken.uid;

    // Get all helpedRequests for this user (any status for Kindstart badge)
    const allHelpedRequestsQuery = await getFirestore()
      .collection('helpedRequests')
      .where('acceptedUserID', '==', userId)
      .get();

    // Get completed/in_progress helpedRequests for medal counts
    // Get completed helpedRequests for medal counts
const completedHelpedRequestsQuery = await getFirestore()
  .collection('helpedRequests')
  .where('acceptedUserID', '==', userId)
  .where('status', '==', 'completed')  // ← ONLY completed
  .get();

    let bronzeCount = 0;  // General type
    let goldCount = 0;    // Emergency type
    let otherCount = 0;   // Other types
    
    // Total help count for Kindstart badge (any status)
    const totalHelpCount = allHelpedRequestsQuery.docs.length;
    const kindstartUnlocked = totalHelpCount >= 1;

    const helpDetails = [];

    // Count medals based on completed/in_progress helps only
    for (const doc of completedHelpedRequestsQuery.docs) {
      const data = doc.data();
      const type = data.originalRequestData?.type || 'Unknown';
      
      // Count based on type
      if (type === 'General') {
        bronzeCount++;
      } else if (type === 'Emergency') {
        goldCount++;
      } else {
        otherCount++;
      }

      // Collect details for debugging
      helpDetails.push({
        requestId: data.requestId,
        type: type,
        status: data.status,
        acceptedAt: data.acceptedAt,
        xp: data.xp || 0
      });
    }

    // Get user's post count for Community Hero badge
    const postsQuery = await getFirestore()
      .collection('posts')
      .where('authorID', '==', userId)
      .get();

    const postCount = postsQuery.docs.length;
    const communityHeroUnlocked = postCount >= 3;

    return c.json({ 
      success: true, 
      data: {
        userId: userId,
        badges: {
          Bronze: bronzeCount,    // General type count (completed/in_progress only)
          Gold: goldCount,        // Emergency type count (completed/in_progress only)
          Other: otherCount,      // Other types count (completed/in_progress only)
          CommunityHero: communityHeroUnlocked ? 1 : 0,  // Community Hero badge (3+ posts)
          Kindstart: kindstartUnlocked ? 1 : 0  // Kindstart badge (1+ helps of any status)
        },
        helpCount: totalHelpCount,  // Total helps (any status)
        postCount: postCount,
        communityHeroUnlocked: communityHeroUnlocked,
        kindstartUnlocked: kindstartUnlocked,
        totalHelps: bronzeCount + goldCount + otherCount,  // Only completed  // Only completed/in_progress
        helpDetails: helpDetails  // For debugging
      }
    });

  } catch (error) {
    console.error('Error getting user badge counts:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to get user badge counts' 
    }, 500);
  }
};

// Get user's post count and Community Hero badge status
export const getUserPostCount = async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');
    
    if (!idToken) {
      return c.json({ success: false, message: 'No authorization token provided' }, 401);
    }

    const decodedToken = await getAuth().verifyIdToken(idToken);
    const userId = decodedToken.uid;

    // Get all posts for this user
    const postsQuery = await getFirestore()
      .collection('posts')
      .where('authorID', '==', userId)
      .get();

    const postCount = postsQuery.docs.length;
    const communityHeroUnlocked = postCount >= 3;

    const postDetails = [];

    for (const doc of postsQuery.docs) {
      const data = doc.data();
      
      // Collect post details for debugging
      postDetails.push({
        postID: doc.id,
        title: data.title || 'Untitled',
        category: data.category || 'Unknown',
        timestamp: data.timestamp,
        totalComments: data.totalComments || 0,
        upvotes: data.upvotes || 0,
        downvotes: data.downvotes || 0
      });
    }

    return c.json({ 
      success: true, 
      data: {
        userId: userId,
        postCount: postCount,
        communityHeroUnlocked: communityHeroUnlocked,
        postDetails: postDetails  // For debugging
      }
    });

  } catch (error) {
    console.error('Error getting user post count:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to get user post count' 
    }, 500);
  }
};

// Get user's help count and Kindstart badge status
export const getUserHelpCount = async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');
    
    if (!idToken) {
      return c.json({ success: false, message: 'No authorization token provided' }, 401);
    }

    const decodedToken = await getAuth().verifyIdToken(idToken);
    const userId = decodedToken.uid;

    // Get all helpedRequests for this user (any status)
    const helpedRequestsQuery = await getFirestore()
      .collection('helpedRequests')
      .where('acceptedUserID', '==', userId)
      .get();

    const helpCount = helpedRequestsQuery.docs.length;
    const kindstartUnlocked = helpCount >= 1;

    const helpDetails = [];

    for (const doc of helpedRequestsQuery.docs) {
      const data = doc.data();
      
      // Collect help details for debugging
      helpDetails.push({
        requestId: data.requestId,
        type: data.originalRequestData?.type || 'Unknown',
        status: data.status || 'Unknown',
        acceptedAt: data.acceptedAt,
        xp: data.xp || 0,
        requesterUsername: data.originalRequestData?.requesterUsername || 'Unknown'
      });
    }

    return c.json({ 
      success: true, 
      data: {
        userId: userId,
        helpCount: helpCount,
        kindstartUnlocked: kindstartUnlocked,
        helpDetails: helpDetails  // For debugging
      }
    });

  } catch (error) {
    console.error('Error getting user help count:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to get user help count' 
    }, 500);
  }
};


// ADD to gamificationController.ts
export const getUserRank = async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');
    
    if (!idToken) {
      return c.json({ success: false, message: 'No authorization token provided' }, 401);
    }

    const decodedToken = await getAuth().verifyIdToken(idToken);
    const userId = decodedToken.uid;

    // Get all users ordered by accumulateXP
    const usersQuery = await getFirestore()
      .collection('users')
      .orderBy('accumulateXP', 'desc')
      .get();

    let rank = 0;
    for (let i = 0; i < usersQuery.docs.length; i++) {
  const doc = usersQuery.docs[i];
  if (doc?.id === userId) {
    rank = i + 1;
    break;
  }
}

// If user not found in ranking, they might have 0 XP
if (rank === 0) {
  rank = usersQuery.docs.length + 1;
}

    return c.json({ 
      success: true, 
      rank: rank,
      totalUsers: usersQuery.docs.length
    });

  } catch (error) {
    console.error('Error getting user rank:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to get user rank' 
    }, 500);
  }
};

// Get user's successful helps count (completed only)
export const getUserSuccessfulHelpsCount = async (c: Context) => {
  try {
    const authHeader = c.req.header('Authorization');
    const idToken = authHeader?.replace('Bearer ', '');
    
    if (!idToken) {
      return c.json({ success: false, message: 'No authorization token provided' }, 401);
    }

    const decodedToken = await getAuth().verifyIdToken(idToken);
    const userId = decodedToken.uid;

    // Get only COMPLETED helpedRequests for this user
    const completedHelpedRequestsQuery = await getFirestore()
      .collection('helpedRequests')
      .where('acceptedUserID', '==', userId)
      .where('status', '==', 'completed')  // ← ONLY completed
      .get();

    const count = completedHelpedRequestsQuery.docs.length;

    return c.json({ 
      success: true, 
      count: count,
      message: 'Successfully retrieved successful helps count'
    });

  } catch (error) {
    console.error('Error getting user successful helps count:', error);
    return c.json({ 
      success: false, 
      message: 'Failed to get user successful helps count' 
    }, 500);
  }
};
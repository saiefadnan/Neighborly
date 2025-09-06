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
      .where('status', 'in', ['completed', 'in_progress'])
      .get();
    
    // Group XP by user - FORCE NUMBERS
    const userXPMap = new Map<string, number>();
    
    for (const doc of helpedRequestsQuery.docs) {
      const data = doc.data();
      const userId = data.acceptedUserID;
      const xp = Number(data.xp || 0);  // ← FORCE NUMBER
      
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
export const getUserBadgeCounts = async (c: Context) => {
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
      .where('status', 'in', ['completed', 'in_progress'])
      .get();

    let bronzeCount = 0;  // General type
    let goldCount = 0;    // Emergency type
    let otherCount = 0;   // Other types

    const helpDetails = [];

    for (const doc of helpedRequestsQuery.docs) {
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

    return c.json({ 
      success: true, 
      data: {
        userId: userId,
        badges: {
          Bronze: bronzeCount,    // General type count
          Gold: goldCount,        // Emergency type count
          Other: otherCount       // Other types count
        },
        totalHelps: bronzeCount + goldCount + otherCount,
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
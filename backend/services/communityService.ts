import { getFirestore, FieldValue } from 'firebase-admin/firestore';

let db: any;

// Initialize Firestore lazily
function getDB() {
  if (!db) {
    db = getFirestore();
  }
  return db;
}

export interface Community {
  id: string;
  name: string;
  description: string;
  location: string;
  imageUrl?: string;
  admins: string[]; // array of admin emails
  members: string[]; // array of member emails
  joinRequests: string[]; // array of pending join request emails
  memberCount: number;
  tags: string[];
  createdAt?: Date;
  recentActivity?: string;
}

class CommunityService {
  
  // Get all communities for explore tab
  async getAllCommunities(): Promise<Community[]> {
    try {
      const snapshot = await getDB().collection('communities')
        .orderBy('memberCount', 'desc')
        .get();
      
      return snapshot.docs.map((doc: any) => ({
        id: doc.id,
        ...doc.data()
      } as Community));
    } catch (error) {
      console.error('Error fetching communities:', error);
      throw error;
    }
  }

  // Get user's joined communities for "My Communities" tab
  async getUserCommunities(userEmail: string): Promise<Community[]> {
    try {
      // Find user by email field (not document ID)
      const userQuery = await getDB().collection('users').where('email', '==', userEmail).get();
      if (userQuery.empty) {
        return [];
      }

      const userDoc = userQuery.docs[0];
      const userData = userDoc.data();
      const preferredCommunities = userData?.preferredCommunity || [];

      if (preferredCommunities.length === 0) {
        return [];
      }

      // Get community details for each preferred community
      const communities: Community[] = [];
      for (const communityId of preferredCommunities) {
        const communityDoc = await getDB().collection('communities').doc(communityId).get();
        if (communityDoc.exists) {
          communities.push({
            id: communityDoc.id,
            ...communityDoc.data()
          } as Community);
        }
      }

      return communities;
    } catch (error) {
      console.error('Error fetching user communities:', error);
      throw error;
    }
  }

  // Get communities where user is admin
  async getAdminCommunities(userEmail: string): Promise<Community[]> {
    try {
      // Query communities where the user's email is in the admins array
      const snapshot = await getDB().collection('communities')
        .where('admins', 'array-contains', userEmail)
        .get();
      
      return snapshot.docs.map((doc: any) => ({
        id: doc.id,
        ...doc.data()
      } as Community));
    } catch (error) {
      console.error('Error fetching admin communities:', error);
      throw error;
    }
  }

  // Get community members with their user details and block status (for admin management)
  async getCommunityMembers(communityId: string): Promise<any[]> {
    try {
      // First get the community to access the members and blockedMembers arrays
      const communityDoc = await getDB().collection('communities').doc(communityId).get();
      
      if (!communityDoc.exists) {
        throw new Error('Community not found');
      }

      const communityData = communityDoc.data();
      const memberEmails = [...(communityData?.members || []), ...(communityData?.blockedMembers || [])];

      if (memberEmails.length === 0) {
        return [];
      }

      // Fetch user details for each member email
      const memberDetails = [];
      for (const email of memberEmails) {
        try {
          const userQuery = await getDB().collection('users').where('email', '==', email).get();
          
          if (!userQuery.empty) {
            const userDoc = userQuery.docs[0];
            const userData = userDoc.data();
            
            // Check if user is in blockedMembers array
            const isBlocked = (communityData?.blockedMembers || []).includes(email);
            
            memberDetails.push({
              userId: userDoc.id,
              username: userData.username || userData.name || 'Unknown User',
              email: userData.email,
              profileImage: userData.profileImage || userData.photoURL,
              blocked: isBlocked,
              joinedDate: userData.createdAt ? new Date(userData.createdAt.seconds * 1000).toISOString() : new Date().toISOString(),
              blockedDate: isBlocked ? new Date().toISOString() : null, // Will be fetched from communityBlocks if needed
              blockedReason: null, // Will be fetched from communityBlocks if needed
              isAdmin: communityData?.admins?.includes(email) || false,
              preferredCommunity: communityId
            });
          }
        } catch (userError) {
          console.error(`Error fetching user ${email}:`, userError);
          // Continue with other users even if one fails
        }
      }

      return memberDetails;
    } catch (error) {
      console.error('Error fetching community members:', error);
      throw error;
    }
  }

  // Join community (always requires admin approval)
  async joinCommunity(userId: string, communityId: string, userEmail: string, username?: string, message?: string): Promise<{ success: boolean; message: string; pending?: boolean }> {
    try {
      const communityRef = getDB().collection('communities').doc(communityId);

      // Check if community exists
      const communityDoc = await communityRef.get();
      if (!communityDoc.exists) {
        return { success: false, message: 'Community not found' };
      }

      // Find user by email field (not document ID)
      const userQuery = await getDB().collection('users').where('email', '==', userEmail).get();
      if (userQuery.empty) {
        return { success: false, message: 'User not found' };
      }

      const userDoc = userQuery.docs[0];
      const userRef = userDoc.ref;
      const userData = userDoc.data();
      
      // Check if user is already a member
      const preferredCommunities = userData?.preferredCommunity || [];
      if (preferredCommunities.includes(communityId)) {
        return { success: false, message: 'Already a member of this community' };
      }

      // Check if user already has pending request
      const communityData = communityDoc.data();
      const existingRequests = communityData?.joinRequests || [];
      const hasPendingRequest = existingRequests.some((req: any) => 
        typeof req === 'string' ? req === userEmail : req.userEmail === userEmail
      );
      
      if (hasPendingRequest) {
        return { success: false, message: 'Join request already pending' };
      }

      // Create join request object with user details
      const joinRequest = {
        userEmail,
        username: username || userData?.username || 'Unknown User',
        profileImage: userData?.profilePicture || userData?.profileImage || '',
        message: message || '',
        requestDate: new Date(),
        userId
      };

      // Add to pending requests
      await userRef.update({
        pendingCommunityRequests: FieldValue.arrayUnion(communityId),
      });

      await communityRef.update({
        joinRequests: FieldValue.arrayUnion(joinRequest),
      });

      return { success: true, message: 'Join request submitted for admin approval', pending: true };
    } catch (error) {
      console.error('Error joining community:', error);
      throw error;
    }
  }

  // Leave community
  async leaveCommunity(userId: string, communityId: string, userEmail: string): Promise<{ success: boolean; message: string }> {
    try {
      const communityRef = getDB().collection('communities').doc(communityId);

      // Check if community exists
      const communityDoc = await communityRef.get();
      if (!communityDoc.exists) {
        return { success: false, message: 'Community not found' };
      }

      // Find user by email field (not document ID)
      const userQuery = await getDB().collection('users').where('email', '==', userEmail).get();
      if (userQuery.empty) {
        return { success: false, message: 'User not found' };
      }

      const userDoc = userQuery.docs[0];
      const userRef = userDoc.ref;

      const userData = userDoc.data();
      
      // Check if user is actually a member
      const preferredCommunities = userData?.preferredCommunity || [];
      if (!preferredCommunities.includes(communityId)) {
        return { success: false, message: 'Not a member of this community' };
      }

      // Remove user from community and community from user's preferences
      await userRef.update({
        preferredCommunity: FieldValue.arrayRemove(communityId),
      });

      await communityRef.update({
        members: FieldValue.arrayRemove(userEmail),
        memberCount: FieldValue.increment(-1),
      });

      return { success: true, message: 'Successfully left community' };
    } catch (error) {
      console.error('Error leaving community:', error);
      throw error;
    }
  }

  // Get community by ID
  async getCommunityById(communityId: string): Promise<Community | null> {
    try {
      const communityDoc = await getDB().collection('communities').doc(communityId).get();
      
      if (!communityDoc.exists) {
        return null;
      }

      return {
        id: communityDoc.id,
        ...communityDoc.data()
      } as Community;
    } catch (error) {
      console.error('Error fetching community by ID:', error);
      throw error;
    }
  }

  // === ADMIN FUNCTIONS (for later implementation) ===

  // Get pending join requests for a community (admin only)
  async getPendingJoinRequests(communityId: string): Promise<any[]> {
    try {
      const communityDoc = await getDB().collection('communities').doc(communityId).get();
      
      if (!communityDoc.exists) {
        throw new Error('Community not found');
      }

      const communityData = communityDoc.data();
      const joinRequests = communityData?.joinRequests || [];

      // If join requests are just email strings (legacy), convert them to objects
      const formattedRequests = [];
      for (const request of joinRequests) {
        if (typeof request === 'string') {
          // Legacy format - just email, need to fetch user details
          const userQuery = await getDB().collection('users').where('email', '==', request).get();
          if (!userQuery.empty) {
            const userData = userQuery.docs[0].data();
            formattedRequests.push({
              userEmail: request,
              username: userData?.username || 'Unknown User',
              profileImage: userData?.profilePicture || userData?.profileImage || '',
              message: '',
              requestDate: new Date(),
              userId: userQuery.docs[0].id
            });
          }
        } else {
          // New format - already has user details
          formattedRequests.push(request);
        }
      }

      return formattedRequests;
    } catch (error) {
      console.error('Error fetching pending join requests:', error);
      throw error;
    }
  }

  // Approve join request (admin only)
  async approveJoinRequest(adminEmail: string, communityId: string, userEmail: string): Promise<{ success: boolean; message: string }> {
    try {
      const communityRef = getDB().collection('communities').doc(communityId);
      const communityDoc = await communityRef.get();
      
      if (!communityDoc.exists) {
        return { success: false, message: 'Community not found' };
      }

      const communityData = communityDoc.data();
      
      // Verify admin permissions
      const admins = communityData?.admins || [];
      if (!admins.includes(adminEmail)) {
        return { success: false, message: 'Unauthorized: Only community admins can approve requests' };
      }

      // Find user by email
      const userQuery = await getDB().collection('users').where('email', '==', userEmail).get();
      if (userQuery.empty) {
        return { success: false, message: 'User not found' };
      }

      const userDoc = userQuery.docs[0];
      const userRef = userDoc.ref;
      const userData = userDoc.data();

      // Check if user is already a member
      const preferredCommunities = userData?.preferredCommunity || [];
      if (preferredCommunities.includes(communityId)) {
        return { success: false, message: 'User is already a member of this community' };
      }

      // Find and remove the join request
      const joinRequests = communityData?.joinRequests || [];
      const updatedRequests = joinRequests.filter((req: any) => {
        if (typeof req === 'string') {
          return req !== userEmail;
        } else {
          return req.userEmail !== userEmail;
        }
      });

      // Use batch operation for atomic updates
      const batch = getDB().batch();

      // Add user to community members
      batch.update(communityRef, {
        members: FieldValue.arrayUnion(userEmail),
        memberCount: FieldValue.increment(1),
        joinRequests: updatedRequests
      });

      // Add community to user's preferred communities and remove from pending
      batch.update(userRef, {
        preferredCommunity: FieldValue.arrayUnion(communityId),
        pendingCommunityRequests: FieldValue.arrayRemove(communityId)
      });

      await batch.commit();

      console.log(`Join request approved: ${userEmail} added to ${communityId} by ${adminEmail}`);
      return { success: true, message: 'Join request approved successfully' };
    } catch (error) {
      console.error('Error approving join request:', error);
      throw error;
    }
  }

  // Reject join request (admin only)
  async rejectJoinRequest(adminEmail: string, communityId: string, userEmail: string): Promise<{ success: boolean; message: string }> {
    try {
      const communityRef = getDB().collection('communities').doc(communityId);
      const communityDoc = await communityRef.get();
      
      if (!communityDoc.exists) {
        return { success: false, message: 'Community not found' };
      }

      const communityData = communityDoc.data();
      
      // Verify admin permissions
      const admins = communityData?.admins || [];
      if (!admins.includes(adminEmail)) {
        return { success: false, message: 'Unauthorized: Only community admins can reject requests' };
      }

      // Find user by email
      const userQuery = await getDB().collection('users').where('email', '==', userEmail).get();
      if (userQuery.empty) {
        return { success: false, message: 'User not found' };
      }

      const userDoc = userQuery.docs[0];
      const userRef = userDoc.ref;

      // Find and remove the join request
      const joinRequests = communityData?.joinRequests || [];
      const updatedRequests = joinRequests.filter((req: any) => {
        if (typeof req === 'string') {
          return req !== userEmail;
        } else {
          return req.userEmail !== userEmail;
        }
      });

      // Use batch operation for atomic updates
      const batch = getDB().batch();

      // Remove join request from community
      batch.update(communityRef, {
        joinRequests: updatedRequests
      });

      // Remove community from user's pending requests
      batch.update(userRef, {
        pendingCommunityRequests: FieldValue.arrayRemove(communityId)
      });

      await batch.commit();

      console.log(`Join request rejected: ${userEmail} request to ${communityId} rejected by ${adminEmail}`);
      return { success: true, message: 'Join request rejected successfully' };
    } catch (error) {
      console.error('Error rejecting join request:', error);
      throw error;
    }
  }
}

export default new CommunityService();

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

  // Join community (auto-join for now, ready for admin approval later)
  async joinCommunity(userId: string, communityId: string, userEmail: string, autoJoin: boolean = true): Promise<{ success: boolean; message: string; pending?: boolean }> {
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
      const pendingRequests = userData?.pendingCommunityRequests || [];
      if (pendingRequests.includes(communityId)) {
        return { success: false, message: 'Join request already pending' };
      }

      if (autoJoin) {
        // Auto-join: Add user to community and community to user's preferences
        await userRef.update({
          preferredCommunity: FieldValue.arrayUnion(communityId),
        });

        await communityRef.update({
          members: FieldValue.arrayUnion(userEmail),
          memberCount: FieldValue.increment(1),
        });

        return { success: true, message: 'Successfully joined community' };
      } else {
        // Admin approval required: Add to pending requests
        await userRef.update({
          pendingCommunityRequests: FieldValue.arrayUnion(communityId),
        });

        await communityRef.update({
          joinRequests: FieldValue.arrayUnion(userEmail),
        });

        return { success: true, message: 'Join request submitted for admin approval', pending: true };
      }
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
  async getPendingJoinRequests(communityId: string): Promise<string[]> {
    try {
      const communityDoc = await getDB().collection('communities').doc(communityId).get();
      
      if (!communityDoc.exists) {
        throw new Error('Community not found');
      }

      const communityData = communityDoc.data();
      return communityData?.joinRequests || [];
    } catch (error) {
      console.error('Error fetching pending join requests:', error);
      throw error;
    }
  }

  // Approve join request (admin only)
  async approveJoinRequest(adminId: string, communityId: string, userEmail: string): Promise<{ success: boolean; message: string }> {
    try {
      // TODO: Verify admin permissions
      // For now, this is just a placeholder
      return { success: true, message: 'Join request approved (placeholder)' };
    } catch (error) {
      console.error('Error approving join request:', error);
      throw error;
    }
  }

  // Reject join request (admin only)
  async rejectJoinRequest(adminId: string, communityId: string, userEmail: string): Promise<{ success: boolean; message: string }> {
    try {
      // TODO: Verify admin permissions
      // For now, this is just a placeholder
      return { success: true, message: 'Join request rejected (placeholder)' };
    } catch (error) {
      console.error('Error rejecting join request:', error);
      throw error;
    }
  }
}

export default new CommunityService();

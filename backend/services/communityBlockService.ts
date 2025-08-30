import { getFirestore, FieldValue } from 'firebase-admin/firestore';

let db: any;

// Initialize Firestore lazily
function getDB() {
  if (!db) {
    db = getFirestore();
  }
  return db;
}

export interface CommunityBlock {
  id?: string;
  communityId: string;
  blockedUserEmail: string;
  blockedByAdminEmail: string;
  blockType: 'temporary' | 'indefinite' | 'permanent';
  duration?: string; // "1 day", "3 days", etc. null for indefinite/permanent
  startDate: Date;
  endDate?: Date; // null for indefinite/permanent
  reason: string;
  customReason?: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

class CommunityBlockService {
  
  // Block a user in a specific community
  async blockUserInCommunity(
    adminEmail: string,
    communityId: string,
    userEmail: string,
    blockData: {
      blockType: 'temporary' | 'indefinite' | 'permanent';
      duration?: string;
      reason: string;
      customReason?: string;
    }
  ): Promise<{ success: boolean; message: string }> {
    try {
      const now = new Date();
      let endDate: Date | undefined;

      // Calculate end date for temporary blocks
      if (blockData.blockType === 'temporary' && blockData.duration) {
        endDate = this.calculateEndDate(now, blockData.duration);
      }

      // Create block record
      const blockRecord: any = {
        communityId,
        blockedUserEmail: userEmail,
        blockedByAdminEmail: adminEmail,
        blockType: blockData.blockType,
        startDate: now,
        reason: blockData.reason,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      };

      // Only add optional fields if they have values
      if (blockData.duration) {
        blockRecord.duration = blockData.duration;
      }
      if (endDate) {
        blockRecord.endDate = endDate;
      }
      if (blockData.customReason) {
        blockRecord.customReason = blockData.customReason;
      }

      // Add to communityBlocks collection
      await getDB().collection('communityBlocks').add(blockRecord);

      // Update community document based on block type
      const communityRef = getDB().collection('communities').doc(communityId);
      
      if (blockData.blockType === 'permanent') {
        // Permanent block: remove from both members and blockedMembers
        await communityRef.update({
          members: FieldValue.arrayRemove(userEmail),
          blockedMembers: FieldValue.arrayRemove(userEmail),
          memberCount: FieldValue.increment(-1),
        });
      } else {
        // Temporary/Indefinite block: move from members to blockedMembers
        await communityRef.update({
          members: FieldValue.arrayRemove(userEmail),
          blockedMembers: FieldValue.arrayUnion(userEmail),
        });
      }

      // Notify other admins
      await this.notifyAdmins(communityId, adminEmail, userEmail, 'blocked', blockData.reason);

      return { 
        success: true, 
        message: `User ${blockData.blockType}ly blocked from community` 
      };
    } catch (error) {
      console.error('Error blocking user:', error);
      throw error;
    }
  }

  // Unblock a user in a specific community
  async unblockUserInCommunity(
    adminEmail: string,
    communityId: string,
    userEmail: string
  ): Promise<{ success: boolean; message: string }> {
    try {
      // Deactivate existing block records
      const blockQuery = await getDB().collection('communityBlocks')
        .where('communityId', '==', communityId)
        .where('blockedUserEmail', '==', userEmail)
        .where('isActive', '==', true)
        .get();

      const batch = getDB().batch();
      blockQuery.docs.forEach((doc: any) => {
        batch.update(doc.ref, {
          isActive: false,
          updatedAt: new Date(),
        });
      });

      // Update community document: move from blockedMembers to members
      const communityRef = getDB().collection('communities').doc(communityId);
      batch.update(communityRef, {
        blockedMembers: FieldValue.arrayRemove(userEmail),
        members: FieldValue.arrayUnion(userEmail),
      });

      await batch.commit();

      // Notify other admins
      await this.notifyAdmins(communityId, adminEmail, userEmail, 'unblocked', 'Admin action');

      return { success: true, message: 'User unblocked successfully' };
    } catch (error) {
      console.error('Error unblocking user:', error);
      throw error;
    }
  }

  // Remove user from community (without blocking)
  async removeUserFromCommunity(
    adminEmail: string,
    communityId: string,
    userEmail: string
  ): Promise<{ success: boolean; message: string }> {
    try {
      const communityRef = getDB().collection('communities').doc(communityId);
      
      await communityRef.update({
        members: FieldValue.arrayRemove(userEmail),
        blockedMembers: FieldValue.arrayRemove(userEmail),
        memberCount: FieldValue.increment(-1),
      });

      // Notify other admins
      await this.notifyAdmins(communityId, adminEmail, userEmail, 'removed', 'Admin action');

      return { success: true, message: 'User removed from community' };
    } catch (error) {
      console.error('Error removing user:', error);
      throw error;
    }
  }

  // Check if user is blocked in a specific community
  async isUserBlockedInCommunity(
    userEmail: string,
    communityId: string
  ): Promise<{ isBlocked: boolean; blockInfo?: CommunityBlock }> {
    try {
      console.log(`Checking block status for ${userEmail} in ${communityId}`);
      
      // Query for active blocks for this user in this community
      const blocksQuery = await getDB()
        .collection('communityBlocks')
        .where('communityId', '==', communityId)
        .where('blockedUserEmail', '==', userEmail)
        .where('isActive', '==', true)
        .orderBy('createdAt', 'desc')
        .get();

      if (blocksQuery.empty) {
        return { isBlocked: false };
      }

      // Check the most recent active block
      const mostRecentBlock = blocksQuery.docs[0];
      const blockData = mostRecentBlock.data() as CommunityBlock;

      // For temporary blocks, check if they've expired
      if (blockData.blockType === 'temporary' && blockData.endDate) {
        const endDate = blockData.endDate instanceof Date ? blockData.endDate : (blockData.endDate as any).toDate();
        const now = new Date();
        
        if (now > endDate) {
          // Block has expired, mark as inactive
          await mostRecentBlock.ref.update({ isActive: false });
          return { isBlocked: false };
        }
      }

      // Block is still active
      return {
        isBlocked: true,
        blockInfo: {
          id: mostRecentBlock.id,
          ...blockData
        } as CommunityBlock
      };
    } catch (error) {
      console.error('Error checking block status:', error);
      throw error;
    }
  }

  // Calculate end date for temporary blocks
  private calculateEndDate(startDate: Date, duration: string): Date {
    const endDate = new Date(startDate);
    
    switch (duration.toLowerCase()) {
      case '1 day':
        endDate.setDate(endDate.getDate() + 1);
        break;
      case '3 days':
        endDate.setDate(endDate.getDate() + 3);
        break;
      case '1 week':
        endDate.setDate(endDate.getDate() + 7);
        break;
      case '2 weeks':
        endDate.setDate(endDate.getDate() + 14);
        break;
      case '1 month':
        endDate.setMonth(endDate.getMonth() + 1);
        break;
      case '3 months':
        endDate.setMonth(endDate.getMonth() + 3);
        break;
      default:
        // Handle custom duration (e.g., "5 days", "2 hours")
        const match = duration.match(/(\d+)\s*(day|days|hour|hours|week|weeks|month|months)/i);
        if (match && match[1] && match[2]) {
          const amount = parseInt(match[1]);
          const unit = match[2].toLowerCase();
          
          if (unit.includes('day')) {
            endDate.setDate(endDate.getDate() + amount);
          } else if (unit.includes('hour')) {
            endDate.setHours(endDate.getHours() + amount);
          } else if (unit.includes('week')) {
            endDate.setDate(endDate.getDate() + (amount * 7));
          } else if (unit.includes('month')) {
            endDate.setMonth(endDate.getMonth() + amount);
          }
        }
        break;
    }
    
    return endDate;
  }

  // Notify other admins about block/unblock actions
  private async notifyAdmins(
    communityId: string,
    adminEmail: string,
    userEmail: string,
    action: string,
    reason: string
  ): Promise<void> {
    try {
      // Get community to find other admins
      const communityDoc = await getDB().collection('communities').doc(communityId).get();
      if (!communityDoc.exists) return;

      const communityData = communityDoc.data();
      const otherAdmins = (communityData?.admins || []).filter((email: string) => email !== adminEmail);

      // Create notification records for other admins
      const notifications = otherAdmins.map((adminEmail: string) => ({
        recipientEmail: adminEmail,
        type: 'admin_action',
        title: `User ${action} in ${communityData?.name}`,
        message: `${userEmail} was ${action} by ${adminEmail}. Reason: ${reason}`,
        communityId,
        createdAt: new Date(),
        read: false,
      }));

      // Add notifications to Firestore
      if (notifications.length > 0) {
        const batch = getDB().batch();
        notifications.forEach((notification: any) => {
          const notificationRef = getDB().collection('notifications').doc();
          batch.set(notificationRef, notification);
        });
        await batch.commit();
      }
    } catch (error) {
      console.error('Error notifying admins:', error);
      // Don't throw error here, notification failure shouldn't break the main operation
    }
  }

  // Get all active blocks for a community (for admin dashboard)
  async getCommunityBlocks(communityId: string): Promise<CommunityBlock[]> {
    try {
      const snapshot = await getDB().collection('communityBlocks')
        .where('communityId', '==', communityId)
        .where('isActive', '==', true)
        .orderBy('createdAt', 'desc')
        .get();

      return snapshot.docs.map((doc: any) => ({
        id: doc.id,
        ...doc.data(),
      } as CommunityBlock));
    } catch (error) {
      console.error('Error fetching community blocks:', error);
      throw error;
    }
  }

  // Check for expired blocks and auto-unblock them (can be called by a cron job)
  async processExpiredBlocks(): Promise<void> {
    try {
      const now = new Date();
      const expiredBlocksQuery = await getDB().collection('communityBlocks')
        .where('blockType', '==', 'temporary')
        .where('isActive', '==', true)
        .where('endDate', '<=', now)
        .get();

      const batch = getDB().batch();
      const communityUpdates: { [key: string]: string[] } = {};

      expiredBlocksQuery.docs.forEach((doc: any) => {
        const blockData = doc.data();
        
        // Deactivate block
        batch.update(doc.ref, {
          isActive: false,
          updatedAt: now,
        });

        // Collect community updates
        const communityId = blockData.communityId;
        const userEmail = blockData.blockedUserEmail;
        if (!communityUpdates[communityId]) {
          communityUpdates[communityId] = [];
        }
        communityUpdates[communityId].push(userEmail);
      });

      // Update community documents
      Object.entries(communityUpdates).forEach(([communityId, userEmails]) => {
        const communityRef = getDB().collection('communities').doc(communityId);
        userEmails.forEach((userEmail) => {
          batch.update(communityRef, {
            blockedMembers: FieldValue.arrayRemove(userEmail),
            members: FieldValue.arrayUnion(userEmail),
          });
        });
      });

      await batch.commit();
      console.log(`Processed ${expiredBlocksQuery.docs.length} expired blocks`);
    } catch (error) {
      console.error('Error processing expired blocks:', error);
    }
  }
}

export default new CommunityBlockService();

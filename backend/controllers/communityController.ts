import type { Context } from 'hono';
import CommunityService from '../services/communityService';

class CommunityController {
  
  // GET /api/communities - Get all communities
  async getAllCommunities(c: Context) {
    try {
      const communities = await CommunityService.getAllCommunities();
      return c.json({
        success: true,
        data: communities
      }, 200);
    } catch (error) {
      console.error('Error in getAllCommunities:', error);
      return c.json({
        success: false,
        message: 'Failed to fetch communities'
      }, 500);
    }
  }

  // GET /api/communities/user/:userId - Get user's communities (userId is actually email)
  async getUserCommunities(c: Context) {
    try {
      const userIdOrEmail = c.req.param('userId'); // This will be email now
      
      if (!userIdOrEmail) {
        return c.json({
          success: false,
          message: 'User identifier is required'
        }, 400);
      }

      const communities = await CommunityService.getUserCommunities(userIdOrEmail);
      return c.json({
        success: true,
        data: communities
      }, 200);
    } catch (error) {
      console.error('Error in getUserCommunities:', error);
      return c.json({
        success: false,
        message: 'Failed to fetch user communities'
      }, 500);
    }
  }

  // GET /api/communities/admin/:userEmail - Get communities where user is admin
  async getAdminCommunities(c: Context) {
    try {
      const userEmail = c.req.param('userEmail');
      
      if (!userEmail) {
        return c.json({
          success: false,
          message: 'User email is required'
        }, 400);
      }

      const communities = await CommunityService.getAdminCommunities(userEmail);
      return c.json({
        success: true,
        data: communities
      }, 200);
    } catch (error) {
      console.error('Error in getAdminCommunities:', error);
      return c.json({
        success: false,
        message: 'Failed to fetch admin communities'
      }, 500);
    }
  }

  // GET /api/communities/:communityId/members - Get community members with user details
  async getCommunityMembers(c: Context) {
    try {
      const communityId = c.req.param('communityId');
      
      if (!communityId) {
        return c.json({
          success: false,
          message: 'Community ID is required'
        }, 400);
      }

      const members = await CommunityService.getCommunityMembers(communityId);
      return c.json({
        success: true,
        data: members
      }, 200);
    } catch (error) {
      console.error('Error in getCommunityMembers:', error);
      return c.json({
        success: false,
        message: 'Failed to fetch community members'
      }, 500);
    }
  }

  // POST /api/communities/join - Join a community
  async joinCommunity(c: Context) {
    try {
      const body = await c.req.json();
      const { userId, communityId, userEmail, username, message } = body;
      
      if (!userId || !communityId || !userEmail) {
        return c.json({
          success: false,
          message: 'User ID, Community ID, and User Email are required'
        }, 400);
      }

      const result = await CommunityService.joinCommunity(userId, communityId, userEmail, username, message);
      
      if (result.success) {
        return c.json(result, 200);
      } else {
        return c.json(result, 400);
      }
    } catch (error) {
      console.error('Error in joinCommunity:', error);
      return c.json({
        success: false,
        message: 'Failed to join community'
      }, 500);
    }
  }

  // POST /api/communities/leave - Leave a community
  async leaveCommunity(c: Context) {
    try {
      const body = await c.req.json();
      const { userId, communityId, userEmail } = body;
      
      if (!userId || !communityId || !userEmail) {
        return c.json({
          success: false,
          message: 'User ID, Community ID, and User Email are required'
        }, 400);
      }

      const result = await CommunityService.leaveCommunity(userId, communityId, userEmail);
      
      if (result.success) {
        return c.json(result, 200);
      } else {
        return c.json(result, 400);
      }
    } catch (error) {
      console.error('Error in leaveCommunity:', error);
      return c.json({
        success: false,
        message: 'Failed to leave community'
      }, 500);
    }
  }

  // GET /api/communities/:communityId - Get community by ID
  async getCommunityById(c: Context) {
    try {
      const communityId = c.req.param('communityId');
      
      if (!communityId) {
        return c.json({
          success: false,
          message: 'Community ID is required'
        }, 400);
      }

      const community = await CommunityService.getCommunityById(communityId);
      
      if (!community) {
        return c.json({
          success: false,
          message: 'Community not found'
        }, 404);
      }

      return c.json({
        success: true,
        data: community
      }, 200);
    } catch (error) {
      console.error('Error in getCommunityById:', error);
      return c.json({
        success: false,
        message: 'Failed to fetch community'
      }, 500);
    }
  }

  // === ADMIN ENDPOINTS (for later implementation) ===
  
  // GET /api/communities/:communityId/join-requests - Get pending join requests
  async getPendingJoinRequests(c: Context) {
    try {
      const communityId = c.req.param('communityId');
      
      if (!communityId) {
        return c.json({
          success: false,
          message: 'Community ID is required'
        }, 400);
      }

      const requests = await CommunityService.getPendingJoinRequests(communityId);
      return c.json({
        success: true,
        data: requests
      }, 200);
    } catch (error) {
      console.error('Error in getPendingJoinRequests:', error);
      return c.json({
        success: false,
        message: 'Failed to fetch pending requests'
      }, 500);
    }
  }

  // POST /api/communities/approve-join - Approve join request (admin only)
  async approveJoinRequest(c: Context) {
    try {
      const body = await c.req.json();
      const { communityId, userEmail } = body;
      const adminEmail = c.req.header('admin-email');
      
      if (!adminEmail || !communityId || !userEmail) {
        return c.json({
          success: false,
          message: 'Admin Email, Community ID, and User Email are required'
        }, 400);
      }

      const result = await CommunityService.approveJoinRequest(adminEmail, communityId, userEmail);
      
      if (result.success) {
        return c.json(result, 200);
      } else {
        return c.json(result, 400);
      }
    } catch (error) {
      console.error('Error in approveJoinRequest:', error);
      return c.json({
        success: false,
        message: 'Failed to approve join request'
      }, 500);
    }
  }

  // POST /api/communities/reject-join - Reject join request (admin only)
  async rejectJoinRequest(c: Context) {
    try {
      const body = await c.req.json();
      const { communityId, userEmail } = body;
      const adminEmail = c.req.header('admin-email');
      
      if (!adminEmail || !communityId || !userEmail) {
        return c.json({
          success: false,
          message: 'Admin Email, Community ID, and User Email are required'
        }, 400);
      }

      const result = await CommunityService.rejectJoinRequest(adminEmail, communityId, userEmail);
      
      if (result.success) {
        return c.json(result, 200);
      } else {
        return c.json(result, 400);
      }
    } catch (error) {
      console.error('Error in rejectJoinRequest:', error);
      return c.json({
        success: false,
        message: 'Failed to reject join request'
      }, 500);
    }
  }
}

export default new CommunityController();

import { Hono } from 'hono';
import CommunityController from '../controllers/communityController';

const communityRouter = new Hono();

// Community routes
communityRouter.get('/', CommunityController.getAllCommunities);
communityRouter.get('/user/:userId', CommunityController.getUserCommunities);
communityRouter.get('/admin/:userEmail', CommunityController.getAdminCommunities);
communityRouter.get('/:communityId/members', CommunityController.getCommunityMembers);
communityRouter.get('/:communityId', CommunityController.getCommunityById);
communityRouter.post('/join', CommunityController.joinCommunity);
communityRouter.post('/leave', CommunityController.leaveCommunity);

// Admin routes (for later implementation)
communityRouter.get('/:communityId/join-requests', CommunityController.getPendingJoinRequests);
communityRouter.post('/approve-join', CommunityController.approveJoinRequest);
communityRouter.post('/reject-join', CommunityController.rejectJoinRequest);

export default communityRouter;

import { Hono } from 'hono';
import {
  createHelpRequest,
  getHelpRequests,
  respondToHelpRequest,
  acceptResponder,
  updateHelpRequestStatus,
  deleteHelpRequest,
  getNearbyHelpRequests,
  createSampleHelpRequest,
  createDummyHelpRequests,
  removeDummyHelpRequests,
  migrateHelpedRequestsXP,
  migrateUserAccumulatedXP
} from '../controllers/mapControllers';

const mapRouter = new Hono();

// Create a new help request
mapRouter.post('/requests', createHelpRequest);

// Get all help requests (with optional filters)
mapRouter.get('/requests', getHelpRequests);

// Get nearby help requests
mapRouter.get('/requests/nearby', getNearbyHelpRequests);

// Respond to a help request
mapRouter.post('/requests/:requestId/responses', respondToHelpRequest);

// Accept a responder (only request owner)
mapRouter.put('/requests/:requestId/responses/:responseId/accept', acceptResponder);

// Update help request status (complete, cancel, etc.)
mapRouter.put('/requests/:requestId/status', updateHelpRequestStatus);

// Delete help request (only owner)
mapRouter.delete('/requests/:requestId', deleteHelpRequest);

// Test endpoint to create sample data
mapRouter.post('/test/create-sample', createSampleHelpRequest);

// Create multiple dummy help requests for testing
mapRouter.post('/test/create-dummy-data', createDummyHelpRequests);

// Remove all dummy help requests
mapRouter.delete('/test/remove-dummy-data', removeDummyHelpRequests);

// Add these routes to your router
mapRouter.post('/migrate-helped-requests-xp', migrateHelpedRequestsXP);
mapRouter.post('/migrate-user-accumulated-xp', migrateUserAccumulatedXP);
export default mapRouter;

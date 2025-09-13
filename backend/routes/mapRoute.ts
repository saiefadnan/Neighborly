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
  migrateUserAccumulatedXP,
  getHelpRequestResponses,
  createRoute,
  getRoutesForHelpRequest,
  acceptRoute,
  deleteRoute,
  requestHelpCompletion,
  confirmHelpCompletion,
  sendProgressUpdate,
  getCompletionRequest
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
// Get responses for a help request
mapRouter.get('/requests/:requestId/responses', getHelpRequestResponses);
// Add these routes to your router
mapRouter.post('/migrate-helped-requests-xp', migrateHelpedRequestsXP);
mapRouter.post('/migrate-user-accumulated-xp', migrateUserAccumulatedXP);

// ============= ROUTE MANAGEMENT ENDPOINTS =============

// Create a new route for a help request
mapRouter.post('/routes', createRoute);

// Get routes for a specific help request
mapRouter.get('/routes/help-request/:helpRequestId', getRoutesForHelpRequest);

// Accept a route (only by help request owner)
mapRouter.put('/routes/:routeId/accept', acceptRoute);

// Delete a route (only by route creator)
mapRouter.delete('/routes/:routeId', deleteRoute);

// Help completion and progress endpoints
mapRouter.post('/help-requests/:helpRequestId/request-completion', requestHelpCompletion);
mapRouter.post('/help-requests/:helpRequestId/confirm-completion', confirmHelpCompletion);
mapRouter.post('/help-requests/:helpRequestId/progress-update', sendProgressUpdate);
mapRouter.get('/help-requests/:helpRequestId/completion-request', getCompletionRequest);

export default mapRouter;

import { Hono } from 'hono';
import { getHelpRequestStats, getUserSuccessfulHelpsCount, getHelpedRequestStats, getLeaderboard } from '../controllers/statisticsPage';

const statRouter = new Hono();

// GET /api/stats/help-request-counts
statRouter.get('/help-request-counts', getHelpRequestStats);
// GET /api/stats/helped-request-counts
statRouter.get('/helped-request-counts', getHelpedRequestStats);
// GET /api/stats/user-successful-helps
statRouter.get('/user-successful-helps', getUserSuccessfulHelpsCount);
// Add this to your existing routes
statRouter.get('/leaderboard', getLeaderboard);
export default statRouter;

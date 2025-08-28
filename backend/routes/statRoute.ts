import { Hono } from 'hono';
import { getHelpRequestStats, getUserSuccessfulHelpsCount } from '../controllers/statisticsPage';

const statRouter = new Hono();

// GET /api/stats/help-request-counts
statRouter.get('/help-request-counts', getHelpRequestStats);

// GET /api/stats/user-successful-helps
statRouter.get('/user-successful-helps', getUserSuccessfulHelpsCount);

export default statRouter;

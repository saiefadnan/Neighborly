import { Hono } from 'hono';
import { getHelpRequestStats } from '../controllers/statisticsPage';

const statRouter = new Hono();

// GET /api/stats/help-request-counts
statRouter.get('/help-request-counts', getHelpRequestStats);

export default statRouter;

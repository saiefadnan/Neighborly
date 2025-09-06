import { Hono } from 'hono';
import { 
  getUserAccumulatedXP,
  getUserHelpHistory,
  migrateUserLevels,
  migrateUserXPAndLevels,
  getUserBadgeCounts,
  getUserPostCount,
  getUserHelpCount
} from '../controllers/gamificationController';

const gamificationRouter = new Hono();

// Get logged-in user's accumulated XP
gamificationRouter.get('/user/xp', getUserAccumulatedXP);

// Get logged-in user's help history with XP breakdown
gamificationRouter.get('/user/badges', getUserBadgeCounts);  // ← Add this route
gamificationRouter.get('/user/history', getUserHelpHistory);
gamificationRouter.post('/migrate-user-levels', migrateUserLevels);
gamificationRouter.post('/migrate-xp-and-levels', migrateUserXPAndLevels);  // ← Add this new route
gamificationRouter.get('/user/badges', getUserBadgeCounts);
gamificationRouter.get('/user/posts', getUserPostCount);  // ← Add this route
gamificationRouter.get('/user/helps', getUserHelpCount);

export default gamificationRouter;
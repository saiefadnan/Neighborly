import { Hono } from 'hono';
import { getUserActivePostsCount, getUserAcceptedHelpRequests } from '../controllers/activeTController';

const activTRouter = new Hono();

activTRouter.get('/user-active-posts', getUserActivePostsCount);
activTRouter.get('/user-accepted-help-requests', getUserAcceptedHelpRequests);  // Add this line

export default activTRouter;
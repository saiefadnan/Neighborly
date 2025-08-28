import { Hono } from 'hono';
import { getUserActivePostsCount } from '../controllers/activeTController';

const activTRouter = new Hono();

activTRouter.get('/user-active-posts', getUserActivePostsCount);

export default activTRouter;
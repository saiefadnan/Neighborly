import { Hono } from 'hono';
import { getUserInfo, updateUserInfo } from '../controllers/editInfosController';

const infosRouter = new Hono();

// Get user info (view current values)
infosRouter.get('/info', getUserInfo);

// Update user info (insert/update allowed fields)
infosRouter.post('/info', updateUserInfo);
infosRouter.get('/test', (c) => c.text('Test route works!'));

export default infosRouter;

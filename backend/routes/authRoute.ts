import {signin } from '../controllers/authController';
import { Hono } from 'hono';

const authRouter = new Hono();

authRouter.post('/signin/idtoken', signin);

export default authRouter;
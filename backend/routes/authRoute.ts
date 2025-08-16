import {signin } from '../controllers/authControllers';
import { Hono } from 'hono';

const authRouter = new Hono();

authRouter.post('/signin/idtoken', signin);

export default authRouter;
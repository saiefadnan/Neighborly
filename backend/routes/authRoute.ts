import {signin } from '../controllers/authController';
import { Hono } from 'hono';

const router = new Hono();

router.post('/auth/signin/idtoken', signin);

export default router;
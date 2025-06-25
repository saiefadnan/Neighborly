import {Test } from '../controllers/testController';
import { Hono } from 'hono';

const router = new Hono();

router.post('/test', Test);

export default router;
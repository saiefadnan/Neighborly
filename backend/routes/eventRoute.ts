import { Hono } from 'hono';
import { loadevents, storevents } from '../controllers/eventControllers';
const eventRouter = new Hono();

eventRouter.post('/store/event', storevents);
eventRouter.post('/load/nearby/events', loadevents);

export default eventRouter;
import { Hono } from 'hono';
import { generateUploadSignature, storeComments } from '../controllers/forumControllers';

const forumRouter = new Hono();

forumRouter.get('/upload/signature', generateUploadSignature);
forumRouter.post('/store/comments', storeComments);

export default forumRouter;
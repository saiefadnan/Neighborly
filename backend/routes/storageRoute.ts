import { Hono } from 'hono';
import { generateUploadSignature } from '../controllers/storageController';

const mediaRouter = new Hono();

mediaRouter.get('/media/upload/signature', generateUploadSignature);

export default mediaRouter;
import { Hono } from 'hono'
import authRouter from './routes/authRoute';
import bloodDonorRoute from './routes/bloodDonorRoute';
import forumRouter from './routes/forumRoute';
import mapRouter from './routes/mapRoute';
import infosRouter from './routes/infosRoute';
import statRouter from './routes/statRoute';
import activTRouter from './routes/activTRoute';
import communityRouter from './routes/communityRoutes';
import blockRoutes from './routes/blockRoutes';
import notificationRouter from './routes/notificationRoute';
import { fcmRouter } from './routes/fcmRoute';
import { initializeApp, cert} from 'firebase-admin/app';
import { readFileSync } from 'fs'
import { join } from 'path';
import eventRouter from './routes/eventRoute';
const serviceAccount = JSON.parse(
  readFileSync(join(__dirname, 'neighborly-3cb66-firebase-adminsdk-fbsvc-e1cb696dc4.json'), 'utf8')
);
const app = new Hono();

initializeApp({
  credential: cert(serviceAccount)
});
console.log('🔥 Firebase initialized successfully!');

app.get('/', (c) => c.text('Hello from Bun + Hono on Windows!!'));

app.route('/api/auth', authRouter);
app.route('/api/blood-donor', bloodDonorRoute);
app.route('/api/forum',forumRouter);
app.route('/api/events',eventRouter);
app.route('/api/map', mapRouter);
app.route('/api/infos', infosRouter);
app.route('/api/stats', statRouter);
app.route('/api/activeT', activTRouter);
app.route('/api/communities', communityRouter);
app.route('/api', blockRoutes);
app.route('/api', notificationRouter);
app.route('/api/fcm', fcmRouter);
Bun.serve({
  fetch: app.fetch,
  port: 4000,
  hostname: '0.0.0.0'
})


console.log('🌐 server is running on http://localhost:4000');
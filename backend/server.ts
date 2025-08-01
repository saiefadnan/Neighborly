import { Hono } from 'hono'
import router from './routes/testRoute';
import { initializeApp, cert} from 'firebase-admin/app';
import { readFileSync } from 'fs'
import { join } from 'path';
const serviceAccount = JSON.parse(
  readFileSync(join(__dirname, 'neighborly-3cb66-firebase-adminsdk-fbsvc-e1cb696dc4.json'), 'utf8')
);
const app = new Hono();

initializeApp({
  credential: cert(serviceAccount)
});
console.log('🔥 Firebase initialized successfully!');

app.get('/', (c) => c.text('Hello from Bun + Hono on Windows!!'));

app.route('/api', router);

Bun.serve({
  fetch: app.fetch,
  port: 4000,
})


console.log('🌐 server is running on http://localhost:4000');
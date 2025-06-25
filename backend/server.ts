import { Hono } from 'hono'
import router from './routes/testRoute';

const app = new Hono()

app.get('/', (c) => c.text('Hello from Bun + Hono on Windows!!'));

app.route('/api', router);

Bun.serve({
  fetch: app.fetch,
  port: 4000,
})


console.log('server is running on http://localhost:4000');
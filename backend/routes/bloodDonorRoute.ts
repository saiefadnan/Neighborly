import { Hono } from 'hono';
import bloodDonorController from '../controllers/bloodDonorController';

const bloodDonorRoute = new Hono();

bloodDonorRoute.route('/blood-donor', bloodDonorController);

export default bloodDonorRoute;

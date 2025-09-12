import { Hono } from 'hono';
import bloodDonorController from '../controllers/bloodDonorController';

const bloodDonorRoute = new Hono();

// Mount the controller directly without additional path
bloodDonorRoute.route('/', bloodDonorController);

export default bloodDonorRoute;

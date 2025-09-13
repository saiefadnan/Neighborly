import { Hono } from 'hono';
import { 
  getUserHelpProvided, 
  getUserHelpReceived 
} from '../controllers/help_historyController';

const helpHistoryRouter = new Hono();

// Get help requests that the user has provided help for
helpHistoryRouter.get('/provided', getUserHelpProvided);

// Get help requests that the user has received help for
helpHistoryRouter.get('/received', getUserHelpReceived);

export default helpHistoryRouter;
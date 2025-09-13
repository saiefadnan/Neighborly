import { Hono } from "hono";
import { reportFeedbackController } from "../controllers/reportFeedbackController";

const reportFeedbackRoute = new Hono();

// Mount the report/feedback controller
reportFeedbackRoute.route('/', reportFeedbackController);

export { reportFeedbackRoute };

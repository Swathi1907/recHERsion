
import { Router } from "express";
import { requireAuth } from "../middleware/auth.middleware";
import {
  registerDeviceToken,
  sendTestNotification,
  deleteDeviceToken,
} from "../controllers/deviceTokens.controller";

const router = Router();

router.use(requireAuth);

router.post("/", registerDeviceToken);
router.delete("/", deleteDeviceToken);
router.post("/test", sendTestNotification);
export default router;

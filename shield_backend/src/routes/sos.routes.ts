
import { Router } from "express";
import { requireAuth } from "../middleware/auth.middleware";
import { createSosAlert } from "../controllers/sos_controllers";

const router = Router();

router.post("/", requireAuth, createSosAlert);

export default router;

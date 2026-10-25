
import { Router } from "express";
import { requireAuth } from "../middleware/auth.middleware";
import {
  getTrustedContacts,
  addTrustedContact,
  deleteTrustedContact,
} from "../controllers/trustedContacts.controller";

const router = Router();

router.use(requireAuth);

router.get("/", getTrustedContacts);
router.post("/", addTrustedContact);
router.delete("/:id", deleteTrustedContact);

export default router;

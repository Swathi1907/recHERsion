
import { Router } from "express";
import { requireAuth } from "../middleware/auth.middleware";
import {
  getTrustedContacts,
  addTrustedContact,
  deleteTrustedContact,
} from "../controllers/trustedContacts.controller";
import {
  createTrustedContactInvitation,
  respondToTrustedContactInvitation,
} from "../controllers/trustedContactInvitations.controller";
const router = Router();

router.use(requireAuth);
router.post("/:id/invite", createTrustedContactInvitation);
router.post("/invitations/:invitationId/respond", respondToTrustedContactInvitation);
router.get("/", getTrustedContacts);
router.post("/", addTrustedContact);
router.delete("/:id", deleteTrustedContact);

export default router;

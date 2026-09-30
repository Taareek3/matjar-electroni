import { Router } from "express";
import {
  getAvailableOrders,
  getMyOrders,
  acceptOrder,
  updateOrderStatus,
  sendToDelivery,
  getAgentProfile,
} from "../controllers/agent.controller";
import { authenticate, requireRole } from "../middlewares/auth.middleware";
import { Role } from "../generated/prisma/client";

const router = Router();

const AGENT_ROLES = [Role.VENDOR, Role.KITCHEN_STAFF];

router.get(
  "/orders/available",
  authenticate,
  requireRole(...AGENT_ROLES),
  getAvailableOrders,
);
router.get(
  "/orders/my",
  authenticate,
  requireRole(...AGENT_ROLES),
  getMyOrders,
);
router.post(
  "/orders/:id/accept",
  authenticate,
  requireRole(...AGENT_ROLES),
  acceptOrder,
);
router.patch(
  "/orders/:id/status",
  authenticate,
  requireRole(...AGENT_ROLES),
  updateOrderStatus,
);
router.post(
  "/orders/:id/send-delivery",
  authenticate,
  requireRole(...AGENT_ROLES),
  sendToDelivery,
);
router.get(
  "/profile",
  authenticate,
  requireRole(...AGENT_ROLES),
  getAgentProfile,
);

export default router;

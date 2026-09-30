import { Router } from "express";
import {
  acceptDeliveryOrder,
  completeDelivery,
  getDeliveryProfile,
  getMyDeliveries,
  getReadyOrders,
} from "../controllers/delivery.controller";
import { authenticate, requireRole } from "../middlewares/auth.middleware";
import { Role } from "../generated/prisma/client";

const router = Router();

router.get("/orders/ready", authenticate, requireRole(Role.AGENT), getReadyOrders);
router.post(
  "/orders/:id/accept",
  authenticate,
  requireRole(Role.AGENT),
  acceptDeliveryOrder,
);
router.get("/orders/my", authenticate, requireRole(Role.AGENT), getMyDeliveries);
router.patch(
  "/orders/:id/status",
  authenticate,
  requireRole(Role.AGENT),
  completeDelivery,
);
router.get("/profile", authenticate, requireRole(Role.AGENT), getDeliveryProfile);

export default router;

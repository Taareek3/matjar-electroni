import { Router } from "express";
import {
  cancelOrder,
  createOrder,
  getMyOrders,
  getOrder,
} from "../controllers/orders.controller";
import { authenticate } from "../middlewares/auth.middleware";

const router = Router();

router.post("/", authenticate, createOrder);
router.get("/my", authenticate, getMyOrders);
router.get("/:id", authenticate, getOrder);
router.patch("/:id/cancel", authenticate, cancelOrder);

export default router;

import { Router } from "express";
import {
  createVendor,
  deleteVendor,
  listVendors,
  updateVendor,
} from "../controllers/admin.agents.controller";
import {
  createDeliveryMan,
  deleteDeliveryMan,
  listDeliveryMen,
  updateDeliveryMan,
} from "../controllers/admin.deliverymen.controller";
import {
  createCategory,
  deleteCategory,
  listCategories,
  reorderCategories,
  updateCategory,
} from "../controllers/admin.categories.controller";
import {
  createMenuItem,
  createOptionGroup,
  deleteMenuItem,
  deleteOptionGroup,
  listAdminMenu,
  setMenuItemAvailability,
  updateMenuItem,
  updateOptionGroup,
} from "../controllers/admin.menu.controller";
import {
  listOrders,
  updateOrderStatus,
} from "../controllers/admin.orders.controller";
import {
  getSettings,
  updateSettings,
} from "../controllers/admin.settings.controller";
import { getStats } from "../controllers/admin.stats.controller";
import { authenticate, requireRole } from "../middlewares/auth.middleware";
import { Role } from "../generated/prisma/client";

const router = Router();

router.use(authenticate);
router.use(requireRole(Role.ADMIN, Role.KITCHEN_STAFF));

router.get("/orders", listOrders);
router.patch("/orders/:id/status", updateOrderStatus);
router.get("/stats", getStats);

router.use(requireRole(Role.ADMIN));

router.get("/menu", listAdminMenu);
router.post("/menu/items", createMenuItem);
router.put("/menu/items/:id", updateMenuItem);
router.patch("/menu/items/:id/availability", setMenuItemAvailability);
router.delete("/menu/items/:id", deleteMenuItem);
router.post("/menu/items/:id/groups", createOptionGroup);
router.put("/menu/groups/:groupId", updateOptionGroup);
router.delete("/menu/groups/:groupId", deleteOptionGroup);

router.get("/categories", listCategories);
router.post("/categories", createCategory);
router.put("/categories/:id", updateCategory);
router.delete("/categories/:id", deleteCategory);
router.patch("/categories/reorder", reorderCategories);

router.get("/settings", getSettings);
router.put("/settings", updateSettings);

router.get("/vendors", listVendors);
router.post("/vendors", createVendor);
router.put("/vendors/:id", updateVendor);
router.delete("/vendors/:id", deleteVendor);

router.get("/delivery-men", listDeliveryMen);
router.post("/delivery-men", createDeliveryMan);
router.put("/delivery-men/:id", updateDeliveryMan);
router.delete("/delivery-men/:id", deleteDeliveryMan);

router.get("/agents", listVendors);
router.post("/agents", createVendor);
router.put("/agents/:id", updateVendor);
router.delete("/agents/:id", deleteVendor);

export default router;

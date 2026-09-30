import { Request, Response } from "express";
import { prisma } from "../config/database";
import { OrderStatus } from "../generated/prisma/client";
import { sendError, sendSuccess } from "../utils/response";

const ORDER_INCLUDE = {
  user: { select: { name: true, phone: true, email: true } },
  items: {
    include: { menuItem: { select: { name: true, image: true } } },
  },
} as const;

const TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  PENDING: [OrderStatus.CONFIRMED, OrderStatus.CANCELED],
  CONFIRMED: [OrderStatus.IN_KITCHEN, OrderStatus.CANCELED],
  IN_KITCHEN: [OrderStatus.READY, OrderStatus.CANCELED],
  READY: [OrderStatus.OUT_FOR_DELIVERY, OrderStatus.DELIVERED],
  OUT_FOR_DELIVERY: [OrderStatus.DELIVERED],
  DELIVERED: [],
  CANCELED: [],
};

function isOrderStatus(value: unknown): value is OrderStatus {
  return (
    typeof value === "string" &&
    Object.values(OrderStatus).includes(value as OrderStatus)
  );
}

export async function listOrders(req: Request, res: Response): Promise<void> {
  const status = req.query.status;

  const orders = await prisma.order.findMany({
    where: isOrderStatus(status) ? { status } : undefined,
    include: ORDER_INCLUDE,
    orderBy: { createdAt: "desc" },
    take: 200,
  });

  sendSuccess(
    res,
    {
      orders: orders.map((order) => ({
        id: order.id,
        orderType: order.orderType,
        status: order.status,
        totalPrice: order.totalPrice,
        deliveryAddress: order.deliveryAddress,
        notes: order.notes,
        createdAt: order.createdAt,
        customer: {
          name: order.user.name,
          phone: order.user.phone ?? "",
          email: order.user.email,
        },
        items: order.items.map((item) => ({
          id: item.id,
          name: item.menuItem.name,
          image: item.menuItem.image ?? "",
          quantity: item.quantity,
          price: item.price,
          selectedOptions: item.selectedOptions ?? [],
        })),
      })),
    },
    "تم جلب الطلبات بنجاح",
  );
}

export async function updateOrderStatus(
  req: Request,
  res: Response,
): Promise<void> {
  const id = String(req.params.id);
  const { status } = (req.body ?? {}) as { status?: unknown };

  if (!isOrderStatus(status)) {
    sendError(res, "حالة الطلب غير صالحة", 400);
    return;
  }

  const order = await prisma.order.findUnique({ where: { id } });

  if (!order) {
    sendError(res, "الطلب غير موجود", 404);
    return;
  }

  const allowed = TRANSITIONS[order.status];

  if (!allowed.includes(status)) {
    sendError(
      res,
      `لا يمكن نقل الطلب من ${order.status} إلى ${status}`,
      400,
    );
    return;
  }

  const updated = await prisma.order.update({
    where: { id },
    data: { status },
    include: ORDER_INCLUDE,
  });

  sendSuccess(
    res,
    { order: { id: updated.id, status: updated.status } },
    "تم تحديث حالة الطلب",
  );
}

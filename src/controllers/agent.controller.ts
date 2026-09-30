import { Request, Response } from "express";
import { prisma } from "../config/database";
import { OrderStatus, Role } from "../generated/prisma/client";
import { sendError, sendSuccess } from "../utils/response";

const VENDOR_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  PENDING: [],
  CONFIRMED: [OrderStatus.IN_KITCHEN, OrderStatus.CANCELED],
  IN_KITCHEN: [OrderStatus.READY, OrderStatus.CANCELED],
  READY: [],
  OUT_FOR_DELIVERY: [],
  DELIVERED: [],
  CANCELED: [],
};

const ORDER_INCLUDE = {
  user: { select: { id: true, name: true, phone: true, addressLine: true } },
  items: {
    include: { menuItem: { select: { name: true } } },
  },
} as const;

export async function getAvailableOrders(
  req: Request,
  res: Response,
): Promise<void> {
  const orders = await prisma.order.findMany({
    where: {
      status: "PENDING",
      agentId: null,
    },
    include: ORDER_INCLUDE,
    orderBy: { createdAt: "asc" },
    take: 50,
  });

  sendSuccess(res, { orders }, "تم جلب الطلبات الواردة");
}

export async function getMyOrders(req: Request, res: Response): Promise<void> {
  const agentId = req.user?.userId;

  const orders = await prisma.order.findMany({
    where: {
      agentId,
      status: {
        in: ["CONFIRMED", "IN_KITCHEN", "READY", "OUT_FOR_DELIVERY", "DELIVERED"],
      },
    },
    include: ORDER_INCLUDE,
    orderBy: { createdAt: "desc" },
    take: 50,
  });

  sendSuccess(res, { orders }, "تم جلب طلباتي");
}

export async function acceptOrder(req: Request, res: Response): Promise<void> {
  const agentId = req.user?.userId;
  const id = String(req.params.id);

  const order = await prisma.order.findUnique({ where: { id } });

  if (!order) {
    sendError(res, "الطلب غير موجود", 404);
    return;
  }

  if (order.status !== "PENDING" || order.agentId !== null) {
    sendError(res, "الطلب غير متاح للاستلام", 400);
    return;
  }

  const updated = await prisma.order.update({
    where: { id },
    data: { agentId, status: OrderStatus.CONFIRMED },
    include: ORDER_INCLUDE,
  });

  sendSuccess(res, { order: updated }, "تم استلام الطلب");
}

export async function updateOrderStatus(
  req: Request,
  res: Response,
): Promise<void> {
  const agentId = req.user?.userId;
  const id = String(req.params.id);
  const { status } = (req.body ?? {}) as { status?: OrderStatus };

  if (!status) {
    sendError(res, "الحالة مطلوبة", 400);
    return;
  }

  const order = await prisma.order.findUnique({ where: { id } });

  if (!order) {
    sendError(res, "الطلب غير موجود", 404);
    return;
  }

  if (order.agentId !== agentId) {
    sendError(res, "ليس لديك صلاحية تعديل هذا الطلب", 403);
    return;
  }

  const allowed = VENDOR_TRANSITIONS[order.status];
  if (!allowed.includes(status)) {
    sendError(res, "انتقال غير صالح للحالة", 400);
    return;
  }

  const updated = await prisma.order.update({
    where: { id },
    data: { status },
    include: ORDER_INCLUDE,
  });

  sendSuccess(res, { order: updated }, "تم تحديث حالة الطلب");
}

export async function sendToDelivery(
  req: Request,
  res: Response,
): Promise<void> {
  const agentId = req.user?.userId;
  const id = String(req.params.id);

  const order = await prisma.order.findUnique({ where: { id } });

  if (!order) {
    sendError(res, "الطلب غير موجود", 404);
    return;
  }

  if (order.agentId !== agentId) {
    sendError(res, "ليس لديك صلاحية إرسال هذا الطلب", 403);
    return;
  }

  if (order.status !== OrderStatus.READY) {
    sendError(res, "الطلب جاهز فقط يمكن إرساله لعامل التوصيل", 400);
    return;
  }

  if (order.sentToDelivery) {
    sendError(res, "الطلب مُرسل بالفعل لعامل التوصيل", 400);
    return;
  }

  const updated = await prisma.order.update({
    where: { id },
    data: { sentToDelivery: true },
    include: ORDER_INCLUDE,
  });

  sendSuccess(res, { order: updated }, "تم إرسال الطلب إلى تطبيق الديليفيري");
}

export async function getAgentProfile(
  req: Request,
  res: Response,
): Promise<void> {
  const userId = req.user?.userId;

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      name: true,
      firstName: true,
      lastName: true,
      email: true,
      phone: true,
      avatar: true,
      role: true,
      restaurantName: true,
      country: true,
      city: true,
      addressLine: true,
      createdAt: true,
    },
  });

  if (!user) {
    sendError(res, "المستخدم غير موجود", 404);
    return;
  }

  sendSuccess(res, { user }, "تم جلب بيانات الوكيل");
}

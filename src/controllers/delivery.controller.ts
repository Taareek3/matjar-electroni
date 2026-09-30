import { Request, Response } from "express";
import { prisma } from "../config/database";
import { OrderStatus } from "../generated/prisma/client";
import { sendError, sendSuccess } from "../utils/response";

const ORDER_INCLUDE = {
  user: { select: { id: true, name: true, phone: true, addressLine: true } },
  items: {
    include: { menuItem: { select: { name: true } } },
  },
} as const;

async function getOrigin() {
  const rows = await prisma.setting.findMany({
    where: { key: { in: ["restaurantName", "address"] } },
  });
  const map = new Map(rows.map((row) => [row.key, row.value]));
  return {
    name: map.get("restaurantName") || "المطعم",
    address: map.get("address") || "",
  };
}

export async function getReadyOrders(
  req: Request,
  res: Response,
): Promise<void> {
  const [orders, origin] = await Promise.all([
    prisma.order.findMany({
      where: {
        status: "READY",
        sentToDelivery: true,
        deliveryManId: null,
      },
      include: ORDER_INCLUDE,
      orderBy: { createdAt: "asc" },
      take: 50,
    }),
    getOrigin(),
  ]);

  sendSuccess(res, { orders, origin }, "تم جلب الطلبات الجاهزة");
}

export async function acceptDeliveryOrder(
  req: Request,
  res: Response,
): Promise<void> {
  const deliveryManId = req.user?.userId;
  const id = String(req.params.id);

  const order = await prisma.order.findUnique({ where: { id } });

  if (!order) {
    sendError(res, "الطلب غير موجود", 404);
    return;
  }

  if (
    order.status !== OrderStatus.READY ||
    !order.sentToDelivery ||
    order.deliveryManId !== null
  ) {
    sendError(res, "الطلب غير متاح للاستلام", 400);
    return;
  }

  const updated = await prisma.order.update({
    where: { id },
    data: { deliveryManId, status: OrderStatus.OUT_FOR_DELIVERY },
    include: ORDER_INCLUDE,
  });

  sendSuccess(res, { order: updated }, "تم استلام الطلب للتوصيل");
}

export async function getMyDeliveries(
  req: Request,
  res: Response,
): Promise<void> {
  const deliveryManId = req.user?.userId;

  const orders = await prisma.order.findMany({
    where: {
      deliveryManId,
      status: { in: ["OUT_FOR_DELIVERY", "DELIVERED"] },
    },
    include: ORDER_INCLUDE,
    orderBy: { createdAt: "desc" },
    take: 50,
  });

  const origin = await getOrigin();

  sendSuccess(res, { orders, origin }, "تم جلب تسليماتي");
}

export async function completeDelivery(
  req: Request,
  res: Response,
): Promise<void> {
  const deliveryManId = req.user?.userId;
  const id = String(req.params.id);
  const body = (req.body ?? {}) as {
    status?: OrderStatus;
    orderNumber?: unknown;
  };

  if (body.status !== OrderStatus.DELIVERED) {
    sendError(res, "الحالة المطلوبة هي تم التوصيل فقط", 400);
    return;
  }

  const enteredNumber =
    typeof body.orderNumber === "string"
      ? body.orderNumber.trim()
      : String(body.orderNumber ?? "").trim();

  if (!/^\d{6}$/.test(enteredNumber)) {
    sendError(res, "خطأ في الطلب", 400);
    return;
  }

  const order = await prisma.order.findUnique({ where: { id } });

  if (!order) {
    sendError(res, "الطلب غير موجود", 404);
    return;
  }

  if (order.deliveryManId !== deliveryManId) {
    sendError(res, "ليس لديك صلاحية تعديل هذا الطلب", 403);
    return;
  }

  if (order.status !== OrderStatus.OUT_FOR_DELIVERY) {
    sendError(res, "الطلب ليس قيد التوصيل حالياً", 400);
    return;
  }

  if (!order.orderNumber || order.orderNumber !== enteredNumber) {
    sendError(res, "خطأ في الطلب", 400);
    return;
  }

  const updated = await prisma.order.update({
    where: { id },
    data: { status: OrderStatus.DELIVERED },
    include: ORDER_INCLUDE,
  });

  sendSuccess(res, { order: updated }, "تم تسجيل التوصيل بنجاح");
}

export async function getDeliveryProfile(
  req: Request,
  res: Response,
): Promise<void> {
  const userId = req.user?.userId;

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      name: true,
      email: true,
      phone: true,
      avatar: true,
      role: true,
      createdAt: true,
    },
  });

  if (!user) {
    sendError(res, "المستخدم غير موجود", 404);
    return;
  }

  sendSuccess(res, { user }, "تم جلب بيانات عامل التوصيل");
}

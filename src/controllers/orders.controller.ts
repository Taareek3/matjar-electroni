import { Request, Response } from "express";
import { prisma } from "../config/database";
import { OrderStatus, OrderType, Prisma } from "../generated/prisma/client";
import { sendError, sendSuccess } from "../utils/response";

const ORDER_INCLUDE = {
  items: {
    include: {
      menuItem: {
        select: {
          id: true,
          name: true,
          description: true,
          basePrice: true,
          image: true,
          categoryId: true,
        },
      },
    },
  },
} as const;

type OrderWithItems = Prisma.OrderGetPayload<{ include: typeof ORDER_INCLUDE }>;

interface OrderItemInput {
  menuItemId?: unknown;
  quantity?: unknown;
  price?: unknown;
  selectedOptions?: unknown;
}

interface CreateOrderBody {
  orderType?: unknown;
  deliveryAddress?: unknown;
  notes?: unknown;
  paymentMethod?: unknown;
  items?: unknown;
}

const CANCELABLE_STATUSES: OrderStatus[] = [
  OrderStatus.PENDING,
  OrderStatus.CONFIRMED,
  OrderStatus.IN_KITCHEN,
];

function isOrderType(value: unknown): value is OrderType {
  return value === OrderType.DELIVERY || value === OrderType.TAKEAWAY;
}

async function getDeliveryFee(): Promise<number> {
  const row = await prisma.setting.findUnique({
    where: { key: "deliveryFee" },
  });
  if (!row) return 2.99;
  const value = Number(row.value);
  return Number.isFinite(value) && value >= 0 ? value : 2.99;
}

async function generateOrderNumber(): Promise<string> {
  for (let attempt = 0; attempt < 20; attempt++) {
    const candidate = String(Math.floor(100000 + Math.random() * 900000));
    const existing = await prisma.order.findUnique({
      where: { orderNumber: candidate },
      select: { id: true },
    });
    if (!existing) return candidate;
  }
  throw new Error("تعذر توليد رقم طلب فريد");
}

function presentOrder(order: OrderWithItems) {
  return {
    id: order.id,
    orderNumber: order.orderNumber,
    orderType: order.orderType,
    status: order.status,
    totalPrice: order.totalPrice,
    deliveryAddress: order.deliveryAddress,
    notes: order.notes,
    paymentMethod: order.paymentMethod,
    createdAt: order.createdAt,
    items: order.items.map((item) => ({
      id: item.id,
      quantity: item.quantity,
      price: item.price,
      selectedOptions: item.selectedOptions,
      menuItem: {
        id: item.menuItem.id,
        name: item.menuItem.name,
        description: item.menuItem.description,
        price: item.menuItem.basePrice,
        imageUrl: item.menuItem.image ?? "",
        categoryId: item.menuItem.categoryId,
      },
    })),
  };
}

export async function createOrder(
  req: Request,
  res: Response,
): Promise<void> {
  const userId = req.user?.userId;

  if (!userId) {
    sendError(res, "غير موثق", 401);
    return;
  }

  const body = (req.body ?? {}) as CreateOrderBody;
  const items = Array.isArray(body.items)
    ? (body.items as OrderItemInput[])
    : [];

  if (!isOrderType(body.orderType)) {
    sendError(res, "نوع الطلب غير صالح", 400);
    return;
  }

  if (items.length === 0) {
    sendError(res, "الطلب فارغ", 400);
    return;
  }

  if (body.orderType === OrderType.DELIVERY) {
    const address =
      typeof body.deliveryAddress === "string"
        ? body.deliveryAddress.trim()
        : "";
    if (!address) {
      sendError(res, "عنوان التوصيل مطلوب", 400);
      return;
    }
  }

  const menuItems = await prisma.menuItem.findMany({
    where: {
      id: { in: items.map((item) => String(item.menuItemId ?? "")) },
      isAvailable: true,
    },
  });

  const itemById = new Map(menuItems.map((item) => [item.id, item]));

  let itemsTotal = 0;
  const orderItems: {
    menuItemId: string;
    quantity: number;
    price: number;
    selectedOptions: Prisma.InputJsonValue;
  }[] = [];

  for (const item of items) {
    const menuItem = itemById.get(String(item.menuItemId ?? ""));

    if (!menuItem) {
      sendError(res, "منتج غير متوفر في المنيو", 400);
      return;
    }

    const quantity = Math.max(1, Math.floor(Number(item.quantity) || 1));
    const optionsPrice = Array.isArray(item.selectedOptions)
      ? (item.selectedOptions as { price?: unknown }[]).reduce(
          (sum, option) =>
            sum +
            (Number.isFinite(Number(option?.price)) ? Number(option.price) : 0),
          0,
        )
      : 0;

    const unitPrice = menuItem.basePrice + optionsPrice;
    itemsTotal += unitPrice * quantity;

    orderItems.push({
      menuItemId: menuItem.id,
      quantity,
      price: unitPrice,
      selectedOptions: Array.isArray(item.selectedOptions)
        ? item.selectedOptions
        : [],
    });
  }

  const deliveryFee =
    body.orderType === OrderType.DELIVERY ? await getDeliveryFee() : 0;
  const totalPrice = Math.round((itemsTotal + deliveryFee) * 100) / 100;

  const paymentMethod =
    typeof body.paymentMethod === "string" && body.paymentMethod.trim()
      ? body.paymentMethod.trim().slice(0, 40)
      : null;

  const orderNumber = await generateOrderNumber();

  const created = await prisma.order.create({
    data: {
      userId,
      orderNumber,
      orderType: body.orderType,
      status: OrderStatus.PENDING,
      totalPrice,
      deliveryAddress:
        typeof body.deliveryAddress === "string" &&
        body.deliveryAddress.trim()
          ? body.deliveryAddress.trim()
          : null,
      notes:
        typeof body.notes === "string" && body.notes.trim()
          ? body.notes.trim()
          : null,
      paymentMethod,
      items: { create: orderItems },
    },
    include: ORDER_INCLUDE,
  });

  sendSuccess(res, { order: presentOrder(created) }, "تم إنشاء الطلب بنجاح", 201);
}

export async function getMyOrders(
  req: Request,
  res: Response,
): Promise<void> {
  const userId = req.user?.userId;

  if (!userId) {
    sendError(res, "غير موثق", 401);
    return;
  }

  const orders = await prisma.order.findMany({
    where: { userId },
    include: ORDER_INCLUDE,
    orderBy: { createdAt: "desc" },
    take: 30,
  });

  sendSuccess(
    res,
    { orders: orders.map(presentOrder) },
    "تم جلب طلباتك",
  );
}

export async function getOrder(
  req: Request,
  res: Response,
): Promise<void> {
  const userId = req.user?.userId;
  const id = String(req.params.id);

  const order = await prisma.order.findUnique({
    where: { id },
    include: ORDER_INCLUDE,
  });

  if (!order || order.userId !== userId) {
    sendError(res, "الطلب غير موجود", 404);
    return;
  }

  sendSuccess(res, { order: presentOrder(order) }, "تم جلب الطلب");
}

export async function cancelOrder(
  req: Request,
  res: Response,
): Promise<void> {
  const userId = req.user?.userId;
  const id = String(req.params.id);

  const order = await prisma.order.findUnique({
    where: { id },
    include: ORDER_INCLUDE,
  });

  if (!order || order.userId !== userId) {
    sendError(res, "الطلب غير موجود", 404);
    return;
  }

  if (!CANCELABLE_STATUSES.includes(order.status)) {
    sendError(res, "لا يمكن إلغاء الطلب بعد بدء التجهيز", 400);
    return;
  }

  const updated = await prisma.order.update({
    where: { id },
    data: { status: OrderStatus.CANCELED },
    include: ORDER_INCLUDE,
  });

  sendSuccess(res, { order: presentOrder(updated) }, "تم إلغاء الطلب");
}

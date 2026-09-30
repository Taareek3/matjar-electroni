import { Request, Response } from "express";
import { prisma } from "../config/database";
import { OrderStatus } from "../generated/prisma/client";
import { sendSuccess } from "../utils/response";

const ACTIVE_STATUSES: OrderStatus[] = [
  OrderStatus.PENDING,
  OrderStatus.CONFIRMED,
  OrderStatus.IN_KITCHEN,
  OrderStatus.READY,
  OrderStatus.OUT_FOR_DELIVERY,
];

function startOfToday(): Date {
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), now.getDate());
}

function dayKey(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

export async function getStats(
  _req: Request,
  res: Response,
): Promise<void> {
  const today = startOfToday();

  const [todayOrders, salesAgg, activeCount, recentOrders, orderItems] =
    await Promise.all([
      prisma.order.count({ where: { createdAt: { gte: today } } }),
      prisma.order.aggregate({
        _sum: { totalPrice: true },
        where: { status: { not: OrderStatus.CANCELED } },
      }),
      prisma.order.count({
        where: { status: { in: ACTIVE_STATUSES } },
      }),
      prisma.order.findMany({
        where: { createdAt: { gte: new Date(Date.now() - 7 * 864e5) } },
        select: { createdAt: true, totalPrice: true, status: true },
        orderBy: { createdAt: "asc" },
      }),
      prisma.orderItem.findMany({
        where: {
          order: { createdAt: { gte: new Date(Date.now() - 7 * 864e5) } },
        },
        select: {
          quantity: true,
          price: true,
          menuItem: { select: { name: true } },
        },
      }),
    ]);

  const series = new Map<
    string,
    { date: string; sales: number; orders: number }
  >();

  for (let i = 6; i >= 0; i -= 1) {
    const d = new Date(Date.now() - i * 864e5);
    series.set(dayKey(d), { date: dayKey(d), sales: 0, orders: 0 });
  }

  for (const order of recentOrders) {
    const bucket = series.get(dayKey(order.createdAt));
    if (!bucket) continue;
    bucket.orders += 1;
    if (order.status !== OrderStatus.CANCELED) {
      bucket.sales += order.totalPrice;
    }
  }

  const productMap = new Map<
    string,
    { name: string; quantity: number; revenue: number }
  >();

  for (const item of orderItems) {
    const key = item.menuItem.name;
    const entry = productMap.get(key) ?? {
      name: key,
      quantity: 0,
      revenue: 0,
    };
    entry.quantity += item.quantity;
    entry.revenue += item.price * item.quantity;
    productMap.set(key, entry);
  }

  const topProducts = [...productMap.values()]
    .sort((a, b) => b.quantity - a.quantity)
    .slice(0, 5);

  sendSuccess(
    res,
    {
      todayOrders,
      totalSales: salesAgg._sum.totalPrice ?? 0,
      activeOrders: activeCount,
      topProducts,
      salesSeries: [...series.values()],
    },
    "تم جلب الإحصائيات بنجاح",
  );
}

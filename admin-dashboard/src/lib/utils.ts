import type { OrderStatus, OrderType } from "../types";

export function formatCurrency(value: number): string {
  return `${value.toFixed(2)} $`;
}

export function formatTime(iso: string): string {
  const date = new Date(iso);
  return date.toLocaleTimeString("ar", {
    hour: "2-digit",
    minute: "2-digit",
  });
}

export function formatDate(iso: string): string {
  const date = new Date(iso);
  return date.toLocaleDateString("ar", {
    day: "numeric",
    month: "short",
  });
}

export function elapsedMinutes(iso: string): number {
  return Math.max(0, Math.floor((Date.now() - new Date(iso).getTime()) / 60000));
}

export function formatElapsed(iso: string): string {
  const minutes = elapsedMinutes(iso);
  if (minutes < 60) return `${minutes} د`;
  const hours = Math.floor(minutes / 60);
  const rest = minutes % 60;
  return `${hours} س ${rest > 0 ? `${rest} د` : ""}`;
}

export const ORDER_TYPE_LABEL: Record<OrderType, string> = {
  DELIVERY: "توصيل",
  TAKEAWAY: "استلام",
};

export interface StatusMeta {
  label: string;
  badge: string;
  dot: string;
}

export const STATUS_META: Record<OrderStatus, StatusMeta> = {
  PENDING: {
    label: "جديد",
    badge: "bg-amber-100 text-amber-700 ring-amber-200",
    dot: "bg-amber-500",
  },
  CONFIRMED: {
    label: "مؤكد",
    badge: "bg-sky-100 text-sky-700 ring-sky-200",
    dot: "bg-sky-500",
  },
  IN_KITCHEN: {
    label: "قيد التحضير",
    badge: "bg-orange-100 text-orange-700 ring-orange-200",
    dot: "bg-orange-500",
  },
  READY: {
    label: "جاهز",
    badge: "bg-violet-100 text-violet-700 ring-violet-200",
    dot: "bg-violet-500",
  },
  OUT_FOR_DELIVERY: {
    label: "في الطريق",
    badge: "bg-indigo-100 text-indigo-700 ring-indigo-200",
    dot: "bg-indigo-500",
  },
  DELIVERED: {
    label: "مكتمل",
    badge: "bg-emerald-100 text-emerald-700 ring-emerald-200",
    dot: "bg-emerald-500",
  },
  CANCELED: {
    label: "ملغي",
    badge: "bg-rose-100 text-rose-700 ring-rose-200",
    dot: "bg-rose-500",
  },
};

export interface KanbanColumn {
  id: string;
  title: string;
  accent: string;
  header: string;
  statuses: OrderStatus[];
}

export const KANBAN_COLUMNS: KanbanColumn[] = [
  {
    id: "new",
    title: "طلبات جديدة",
    accent: "from-amber-400 to-orange-400",
    header: "bg-amber-50 text-amber-700",
    statuses: ["PENDING", "CONFIRMED"],
  },
  {
    id: "kitchen",
    title: "قيد التحضير",
    accent: "from-orange-400 to-rose-400",
    header: "bg-orange-50 text-orange-700",
    statuses: ["IN_KITCHEN"],
  },
  {
    id: "ready",
    title: "جاهزة للتسليم",
    accent: "from-violet-400 to-indigo-400",
    header: "bg-violet-50 text-violet-700",
    statuses: ["READY", "OUT_FOR_DELIVERY"],
  },
  {
    id: "done",
    title: "مكتملة / ملغاة",
    accent: "from-emerald-400 to-teal-400",
    header: "bg-emerald-50 text-emerald-700",
    statuses: ["DELIVERED", "CANCELED"],
  },
];

export function nextStatusOf(
  order: { status: OrderStatus; orderType: OrderType },
): { status: OrderStatus; label: string } | null {
  switch (order.status) {
    case "PENDING":
      return { status: "CONFIRMED", label: "تأكيد الطلب" };
    case "CONFIRMED":
      return { status: "IN_KITCHEN", label: "ابدأ التحضير" };
    case "IN_KITCHEN":
      return { status: "READY", label: "جاهز للتسليم" };
    case "READY":
      return order.orderType === "DELIVERY"
        ? { status: "OUT_FOR_DELIVERY", label: "خرج للتوصيل" }
        : { status: "DELIVERED", label: "تم التسليم" };
    case "OUT_FOR_DELIVERY":
      return { status: "DELIVERED", label: "تم التسليم" };
    default:
      return null;
  }
}

export function canCancel(status: OrderStatus): boolean {
  return status === "PENDING" || status === "CONFIRMED" || status === "IN_KITCHEN";
}

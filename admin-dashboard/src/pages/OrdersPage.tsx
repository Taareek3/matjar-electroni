import { useEffect, useMemo, useRef, useState } from "react";
import {
  BellRing,
  Bike,
  CheckCircle2,
  ChevronLeft,
  MapPin,
  Phone,
  ShoppingBag,
  Timer,
} from "lucide-react";
import {
  Badge,
  EmptyState,
  ErrorView,
  Modal,
  PageLoader,
} from "../components/ui";
import { useOrders } from "../queries/hooks";
import { playNewOrderSound } from "../lib/sound";
import {
  elapsedMinutes,
  formatCurrency,
  formatElapsed,
  formatTime,
  KANBAN_COLUMNS,
  ORDER_TYPE_LABEL,
  STATUS_META,
} from "../lib/utils";
import type { Order } from "../types";

function OrderCard({
  order,
  isNew,
  onOpen,
}: {
  order: Order;
  isNew: boolean;
  onOpen: (order: Order) => void;
}) {
  const minutes = elapsedMinutes(order.createdAt);
  const late = minutes >= 20 && order.status !== "DELIVERED" && order.status !== "CANCELED";
  const meta = STATUS_META[order.status];

  return (
    <div
      className={`animate-fade-in rounded-2xl border bg-white p-4 shadow-sm transition hover:shadow-md ${
        isNew ? "animate-new-order border-orange-300" : "border-slate-200/80"
      }`}
    >
      <div className="mb-3 flex items-start justify-between gap-2">
        <button
          type="button"
          onClick={() => onOpen(order)}
          className="text-start"
        >
          <p className="font-extrabold text-slate-800">
            {order.customer.name}
          </p>
          <p className="text-xs text-slate-400">
            {formatTime(order.createdAt)} · {order.items.length} أصناف
          </p>
        </button>
        <Badge className={`${meta.badge}`}>
          <span className={`h-1.5 w-1.5 rounded-full ${meta.dot}`} />
          {meta.label}
        </Badge>
      </div>

      <ul className="mb-3 space-y-1.5">
        {order.items.slice(0, 3).map((item) => (
          <li
            key={item.id}
            className="flex items-center justify-between gap-2 text-sm text-slate-600"
          >
            <span className="truncate">
              <span className="font-bold text-indigo-600">{item.quantity}×</span>{" "}
              {item.name}
            </span>
          </li>
        ))}
        {order.items.length > 3 && (
          <li className="text-xs text-slate-400">
            + {order.items.length - 3} أصناف أخرى
          </li>
        )}
      </ul>

      <div className="mb-3 flex flex-wrap items-center gap-2 text-xs">
        <Badge className="bg-slate-100 text-slate-600 ring-slate-200">
          {ORDER_TYPE_LABEL[order.orderType]}
        </Badge>
        <Badge className="bg-slate-100 text-slate-700 ring-slate-200">
          {formatCurrency(order.totalPrice)}
        </Badge>
        <Badge
          className={
            late
              ? "bg-rose-100 text-rose-700 ring-rose-200"
              : "bg-slate-100 text-slate-500 ring-slate-200"
          }
        >
          <Timer className="h-3 w-3" />
          {formatElapsed(order.createdAt)}
        </Badge>
      </div>

      {(order.status === "PENDING" || order.status === "CONFIRMED") && (
        <button
          type="button"
          onClick={() => onOpen(order)}
          className="flex w-full items-center gap-1.5 rounded-lg bg-indigo-50 px-2.5 py-1.5 text-xs font-bold text-indigo-600 transition hover:bg-indigo-100"
        >
          <ChevronLeft className="h-3.5 w-3.5" />
          عرض التفاصيل الكاملة
        </button>
      )}
    </div>
  );
}

function OrderDetailsModal({
  order,
  onClose,
}: {
  order: Order | null;
  onClose: () => void;
}) {
  if (!order) return null;

  const meta = STATUS_META[order.status];

  return (
    <Modal open={!!order} title={`طلب #${order.id.slice(-6)}`} onClose={onClose}>
      <div className="space-y-4">
        <div className="flex flex-wrap items-center gap-2">
          <Badge className={meta.badge}>
            <span className={`h-1.5 w-1.5 rounded-full ${meta.dot}`} />
            {meta.label}
          </Badge>
          <Badge className="bg-slate-100 text-slate-600 ring-slate-200">
            {ORDER_TYPE_LABEL[order.orderType]}
          </Badge>
          <Badge className="bg-slate-100 text-slate-600 ring-slate-200">
            {formatTime(order.createdAt)}
          </Badge>
        </div>

        <div className="rounded-xl bg-slate-50 p-4 text-sm">
          <p className="font-extrabold text-slate-700">{order.customer.name}</p>
          {order.customer.phone && (
            <p className="mt-1 flex items-center gap-1.5 text-slate-500">
              <Phone className="h-3.5 w-3.5" />
              <span dir="ltr">{order.customer.phone}</span>
            </p>
          )}
          {order.deliveryAddress && (
            <p className="mt-1 flex items-start gap-1.5 text-slate-500">
              <MapPin className="mt-0.5 h-3.5 w-3.5 shrink-0" />
              {order.deliveryAddress}
            </p>
          )}
        </div>

        <div>
          <p className="mb-2 text-sm font-extrabold text-slate-700">الأصناف</p>
          <ul className="divide-y divide-slate-100 rounded-xl border border-slate-100">
            {order.items.map((item) => (
              <li key={item.id} className="p-3">
                <div className="flex items-center justify-between gap-2">
                  <span className="text-sm font-bold text-slate-700">
                    <span className="text-indigo-600">{item.quantity}×</span>{" "}
                    {item.name}
                  </span>
                  <span className="text-sm font-bold text-slate-700">
                    {formatCurrency(item.price * item.quantity)}
                  </span>
                </div>
                {item.selectedOptions.length > 0 && (
                  <p className="mt-1 text-xs text-slate-400">
                    {item.selectedOptions.map((option) => option.name).join(" · ")}
                  </p>
                )}
              </li>
            ))}
          </ul>
        </div>

        {order.notes && (
          <div className="rounded-xl bg-amber-50 p-3 text-sm text-amber-700 ring-1 ring-inset ring-amber-100">
            ملاحظة: {order.notes}
          </div>
        )}

        <div className="flex items-center justify-between border-t border-dashed border-slate-200 pt-4">
          <span className="font-bold text-slate-600">الإجمالي</span>
          <span className="text-lg font-extrabold text-slate-800">
            {formatCurrency(order.totalPrice)}
          </span>
        </div>
      </div>
    </Modal>
  );
}

export function OrdersPage() {
  const ordersQuery = useOrders();
  const [selected, setSelected] = useState<Order | null>(null);
  const [toast, setToast] = useState<string | null>(null);
  const knownIds = useRef<Set<string> | null>(null);
  const previousCount = useRef(0);

  const orders = ordersQuery.data?.orders ?? [];

  useEffect(() => {
    if (!ordersQuery.data) return;

    const ids = new Set(orders.map((order) => order.id));

    if (knownIds.current === null) {
      knownIds.current = ids;
      previousCount.current = ids.size;
      return;
    }

    const fresh = [...ids].filter((id) => !knownIds.current?.has(id));

    if (fresh.length > 0) {
      playNewOrderSound();
      const newest = orders.find((order) => order.id === fresh[0]);
      setToast(`🔔 طلب جديد من ${newest?.customer.name ?? "عميل"}!`);
      window.setTimeout(() => setToast(null), 5000);
    }

    knownIds.current = ids;
  }, [ordersQuery.data, orders]);

  const activeCount = useMemo(
    () =>
      orders.filter(
        (order) =>
          order.status !== "DELIVERED" && order.status !== "CANCELED",
      ).length,
    [orders],
  );

  if (ordersQuery.isPending) return <PageLoader label="جارٍ تحميل الطلبات..." />;
  if (ordersQuery.isError) {
    return (
      <ErrorView
        message="تعذر جلب الطلبات — تأكد من تشغيل الخادم"
        onRetry={() => void ordersQuery.refetch()}
      />
    );
  }

  return (
    <div className="animate-fade-in">
      <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 rounded-xl bg-orange-50 px-4 py-2 text-sm font-bold text-orange-600 ring-1 ring-inset ring-orange-100">
            <BellRing className="h-4 w-4" />
            {activeCount} طلب نشط
          </div>
          <div className="hidden items-center gap-2 rounded-xl bg-indigo-50 px-4 py-2 text-sm font-bold text-indigo-600 ring-1 ring-inset ring-indigo-100 sm:flex">
            <ShoppingBag className="h-4 w-4" />
            {orders.length} طلب اليوم (كل الأوقات)
          </div>
        </div>
        <p className="text-xs text-slate-400">
          عرض فقط — تُدار حالات الطلبات من تطبيق الوكيل وتطبيق التوصيل
        </p>
      </div>

      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
        {KANBAN_COLUMNS.map((column) => {
          const columnOrders = orders.filter((order) =>
            column.statuses.includes(order.status),
          );

          return (
            <div key={column.id} className="flex min-h-[200px] flex-col">
              <div
                className={`mb-3 flex items-center justify-between rounded-xl px-4 py-2.5 ${column.header}`}
              >
                <p className="text-sm font-extrabold">{column.title}</p>
                <span className="flex h-6 min-w-6 items-center justify-center rounded-full bg-white px-1.5 text-xs font-extrabold shadow-sm">
                  {columnOrders.length}
                </span>
              </div>

              <div className="flex-1 space-y-3">
                {columnOrders.length === 0 ? (
                  <div className="rounded-2xl border border-dashed border-slate-200 bg-white/50 py-10 text-center text-xs text-slate-400">
                    لا توجد طلبات
                  </div>
                ) : (
                  columnOrders.map((order) => (
                    <OrderCard
                      key={order.id}
                      order={order}
                      isNew={order.status === "PENDING"}
                      onOpen={setSelected}
                    />
                  ))
                )}
              </div>
            </div>
          );
        })}
      </div>

      {orders.length === 0 && (
        <div className="mt-6">
          <EmptyState
            icon={<Bike className="h-10 w-10" />}
            title="لا توجد طلبات بعد"
            subtitle="ستظهر الطلبات هنا فور وصولها"
          />
        </div>
      )}

      <OrderDetailsModal order={selected} onClose={() => setSelected(null)} />

      {toast && (
        <div className="animate-fade-in fixed bottom-6 left-1/2 z-50 -translate-x-1/2 rounded-2xl bg-slate-900 px-6 py-3 text-sm font-bold text-white shadow-2xl">
          {toast}
        </div>
      )}

      <div className="sr-only" aria-live="polite">
        <CheckCircle2 />
      </div>
    </div>
  );
}

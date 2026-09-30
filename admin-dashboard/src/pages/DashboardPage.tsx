import { useMemo } from "react";
import { Link } from "react-router-dom";
import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import {
  ArrowLeft,
  ClipboardList,
  DollarSign,
  Flame,
  TrendingUp,
} from "lucide-react";
import {
  Card,
  ErrorView,
  PageLoader,
} from "../components/ui";
import { useStats } from "../queries/hooks";
import { formatCurrency } from "../lib/utils";

const TOOLTIP_STYLE = {
  contentStyle: {
    fontFamily: "Tajawal, sans-serif",
    direction: "rtl" as const,
    borderRadius: "12px",
    border: "1px solid #e2e8f0",
    fontSize: "13px",
  },
  labelStyle: { fontWeight: 700 },
};

const BAR_COLORS = [
  "#6366f1",
  "#8b5cf6",
  "#ec4899",
  "#f59e0b",
  "#10b981",
];

export function DashboardPage() {
  const statsQuery = useStats();

  const series = useMemo(() => {
    const data = statsQuery.data?.salesSeries ?? [];
    return data.map((point) => ({
      ...point,
      label: new Date(`${point.date}T00:00:00`).toLocaleDateString("ar", {
        weekday: "short",
      }),
    }));
  }, [statsQuery.data]);

  if (statsQuery.isPending) return <PageLoader />;
  if (statsQuery.isError) {
    return (
      <ErrorView
        message="تعذر جلب الإحصائيات — تأكد من تشغيل الخادم"
        onRetry={() => void statsQuery.refetch()}
      />
    );
  }

  const stats = statsQuery.data;

  const cards = [
    {
      label: "طلبات اليوم",
      value: String(stats.todayOrders),
      icon: ClipboardList,
      gradient: "from-indigo-500 to-blue-500",
      shadow: "shadow-indigo-200",
    },
    {
      label: "إجمالي المبيعات",
      value: formatCurrency(stats.totalSales),
      icon: DollarSign,
      gradient: "from-emerald-500 to-teal-500",
      shadow: "shadow-emerald-200",
    },
    {
      label: "طلبات نشطة الآن",
      value: String(stats.activeOrders),
      icon: Flame,
      gradient: "from-orange-500 to-rose-500",
      shadow: "shadow-orange-200",
    },
    {
      label: "الأكثر طلباً",
      value: stats.topProducts[0]?.name ?? "—",
      icon: TrendingUp,
      gradient: "from-violet-500 to-purple-500",
      shadow: "shadow-violet-200",
      small: true,
    },
  ];

  return (
    <div className="animate-fade-in space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {cards.map((card) => (
          <Card key={card.label} className="p-5">
            <div className="flex items-start justify-between gap-3">
              <div className="min-w-0">
                <p className="text-xs font-bold text-slate-400">
                  {card.label}
                </p>
                <p
                  className={`mt-2 truncate font-extrabold text-slate-800 ${
                    card.small ? "text-lg" : "text-2xl"
                  }`}
                  title={card.value}
                >
                  {card.value}
                </p>
              </div>
              <div
                className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br ${card.gradient} ${card.shadow} text-white shadow-lg`}
              >
                <card.icon className="h-5 w-5" />
              </div>
            </div>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-1 gap-6 xl:grid-cols-3">
        <Card className="p-5 xl:col-span-2">
          <div className="mb-4 flex items-center justify-between">
            <div>
              <h2 className="font-extrabold text-slate-800">
                المبيعات خلال آخر 7 أيام
              </h2>
              <p className="text-xs text-slate-400">
                إجمالي المبيعات والطلبات يومياً
              </p>
            </div>
            <TrendingUp className="h-5 w-5 text-indigo-500" />
          </div>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={series} margin={{ top: 5, right: 5, left: -15, bottom: 0 }}>
                <defs>
                  <linearGradient id="salesGradient" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#6366f1" stopOpacity={0.35} />
                    <stop offset="100%" stopColor="#6366f1" stopOpacity={0.02} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" vertical={false} />
                <XAxis dataKey="label" tick={{ fontSize: 12 }} reversed />
                <YAxis tick={{ fontSize: 12 }} orientation="right" />
                <Tooltip {...TOOLTIP_STYLE} />
                <Area
                  type="monotone"
                  dataKey="sales"
                  name="المبيعات"
                  stroke="#6366f1"
                  strokeWidth={3}
                  fill="url(#salesGradient)"
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </Card>

        <Card className="p-5">
          <div className="mb-4">
            <h2 className="font-extrabold text-slate-800">
              المنتجات الأكثر طلباً
            </h2>
            <p className="text-xs text-slate-400">حسب الكمية خلال أسبوع</p>
          </div>
          {stats.topProducts.length === 0 ? (
            <p className="py-10 text-center text-sm text-slate-400">
              لا توجد بيانات بعد
            </p>
          ) : (
            <div className="h-72">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart
                  data={stats.topProducts}
                  layout="vertical"
                  margin={{ top: 0, right: 10, left: 0, bottom: 0 }}
                >
                  <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" horizontal={false} />
                  <XAxis type="number" tick={{ fontSize: 11 }} />
                  <YAxis
                    type="category"
                    dataKey="name"
                    width={95}
                    tick={{ fontSize: 11 }}
                    orientation="right"
                  />
                  <Tooltip {...TOOLTIP_STYLE} />
                  <Bar dataKey="quantity" name="الكمية" radius={[0, 8, 8, 0]} barSize={18}>
                    {stats.topProducts.map((_, index) => (
                      <Cell key={index} fill={BAR_COLORS[index % BAR_COLORS.length]} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            </div>
          )}
        </Card>
      </div>

      <Card className="flex flex-wrap items-center justify-between gap-4 p-5">
        <div>
          <h2 className="font-extrabold text-slate-800">
            متابعة الطلبات لحظة بلحظة
          </h2>
          <p className="text-sm text-slate-500">
            {stats.activeOrders > 0
              ? `لديك ${stats.activeOrders} طلب نشط يتطلب المتابعة الآن`
              : "لا توجد طلبات نشطة حالياً"}
          </p>
        </div>
        <Link
          to="/orders"
          className="inline-flex items-center gap-2 rounded-xl bg-gradient-to-l from-indigo-600 to-violet-600 px-5 py-2.5 text-sm font-bold text-white shadow-sm shadow-indigo-200 transition hover:from-indigo-500 hover:to-violet-500"
        >
          فتح شاشة الطلبات
          <ArrowLeft className="h-4 w-4" />
        </Link>
      </Card>
    </div>
  );
}

import { NavLink } from "react-router-dom";
import {
  Bike,
  ClipboardList,
  LayoutDashboard,
  LogOut,
  Settings,
  Tags,
  Users,
  UtensilsCrossed,
  X,
} from "lucide-react";
import { useAuth } from "../../auth/AuthContext";

const NAV_ITEMS = [
  { to: "/", label: "لوحة التحكم", icon: LayoutDashboard, end: true },
  { to: "/orders", label: "الطلبات الحية", icon: ClipboardList },
  { to: "/menu", label: "إدارة المنيو", icon: UtensilsCrossed },
  { to: "/categories", label: "إدارة الأقسام", icon: Tags },
  { to: "/settings", label: "إعدادات الفرع", icon: Settings },
  { to: "/agents", label: "إدارة الوكلاء", icon: Users },
  { to: "/delivery-men", label: "إدارة عمال التوصيل", icon: Bike },
];

export function Sidebar({
  open,
  onClose,
}: {
  open: boolean;
  onClose: () => void;
}) {
  const { user, logout } = useAuth();

  const content = (
    <div className="flex h-full flex-col">
      <div className="flex items-center justify-between gap-2 px-5 py-6">
        <div className="flex items-center gap-3">
          <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-gradient-to-br from-indigo-500 to-violet-600 text-white shadow-lg shadow-indigo-200">
            <UtensilsCrossed className="h-6 w-6" />
          </div>
          <div>
            <p className="text-base font-extrabold text-white">بينا فلاو</p>
            <p className="text-xs text-indigo-200">لوحة التحكم</p>
          </div>
        </div>
        <button
          type="button"
          onClick={onClose}
          className="rounded-lg p-1.5 text-indigo-200 hover:bg-white/10 lg:hidden"
          aria-label="إغلاق القائمة"
        >
          <X className="h-5 w-5" />
        </button>
      </div>

      <nav className="flex-1 space-y-1 px-3">
        {NAV_ITEMS.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            end={item.end}
            onClick={onClose}
            className={({ isActive }) =>
              `flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-bold transition-all ${
                isActive
                  ? "bg-white/15 text-white shadow-inner"
                  : "text-indigo-100 hover:bg-white/10 hover:text-white"
              }`
            }
          >
            <item.icon className="h-5 w-5 shrink-0" />
            <span>{item.label}</span>
          </NavLink>
        ))}
      </nav>

      <div className="border-t border-white/10 p-4">
        <div className="mb-3 rounded-xl bg-white/10 px-4 py-3">
          <p className="truncate text-sm font-bold text-white">
            {user?.name ?? "المستخدم"}
          </p>
          <p className="truncate text-xs text-indigo-200">{user?.email}</p>
        </div>
        <button
          type="button"
          onClick={logout}
          className="flex w-full items-center gap-3 rounded-xl px-4 py-2.5 text-sm font-bold text-rose-200 transition hover:bg-rose-500/20 hover:text-rose-100"
        >
          <LogOut className="h-5 w-5" />
          تسجيل الخروج
        </button>
      </div>
    </div>
  );

  return (
    <>
      <aside className="fixed inset-y-0 right-0 z-40 hidden w-64 bg-gradient-to-b from-slate-900 via-indigo-950 to-slate-900 lg:block">
        {content}
      </aside>

      {open && (
        <div className="fixed inset-0 z-50 lg:hidden">
          <div
            className="absolute inset-0 bg-slate-900/60 backdrop-blur-sm"
            onClick={onClose}
          />
          <aside className="absolute inset-y-0 right-0 w-72 bg-gradient-to-b from-slate-900 via-indigo-950 to-slate-900 shadow-2xl">
            {content}
          </aside>
        </div>
      )}
    </>
  );
}

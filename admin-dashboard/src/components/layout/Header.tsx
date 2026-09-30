import { type ReactNode } from "react";
import { Menu, RefreshCw } from "lucide-react";

export function Header({
  title,
  subtitle,
  onMenuClick,
  onRefresh,
  refreshing = false,
  action,
}: {
  title: string;
  subtitle?: string;
  onMenuClick: () => void;
  onRefresh?: () => void;
  refreshing?: boolean;
  action?: ReactNode;
}) {
  const today = new Date().toLocaleDateString("ar", {
    weekday: "long",
    day: "numeric",
    month: "long",
  });

  return (
    <header className="sticky top-0 z-30 border-b border-slate-200/70 bg-white/80 backdrop-blur-md">
      <div className="flex items-center justify-between gap-4 px-4 py-3.5 sm:px-6">
        <div className="flex min-w-0 items-center gap-3">
          <button
            type="button"
            onClick={onMenuClick}
            className="rounded-xl border border-slate-200 p-2 text-slate-600 transition hover:bg-slate-50 lg:hidden"
            aria-label="فتح القائمة"
          >
            <Menu className="h-5 w-5" />
          </button>
          <div className="min-w-0">
            <h1 className="truncate text-lg font-extrabold text-slate-800 sm:text-xl">
              {title}
            </h1>
            <p className="hidden text-xs text-slate-400 sm:block">
              {subtitle ?? today}
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          {action}
          {onRefresh && (
            <button
              type="button"
              onClick={onRefresh}
              disabled={refreshing}
              className="rounded-xl border border-slate-200 p-2 text-slate-500 transition hover:bg-slate-50 disabled:opacity-50"
              aria-label="تحديث"
            >
              <RefreshCw
                className={`h-5 w-5 ${refreshing ? "animate-spin" : ""}`}
              />
            </button>
          )}
        </div>
      </div>
    </header>
  );
}

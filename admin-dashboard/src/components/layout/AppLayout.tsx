import { useState } from "react";
import { Navigate, Outlet, useLocation } from "react-router-dom";
import { useAuth } from "../../auth/AuthContext";
import { Header } from "./Header";
import { Sidebar } from "./Sidebar";

const TITLES: Record<string, { title: string; subtitle: string }> = {
  "/": {
    title: "لوحة التحكم",
    subtitle: "نظرة عامة على أداء المطعم",
  },
  "/orders": {
    title: "الطلبات الحية",
    subtitle: "إدارة الطلبات وفق مسار التحضير",
  },
  "/menu": {
    title: "إدارة قائمة الطعام",
    subtitle: "المنتجات، الأسعار، والإضافات",
  },
  "/categories": {
    title: "إدارة الأقسام",
    subtitle: "ترتيب وتنظيم أقسام المنيو",
  },
  "/settings": {
    title: "إعدادات الفرع",
    subtitle: "الطلبات والتوصيل وبيانات المطعم",
  },
  "/agents": {
    title: "إدارة الوكلاء",
    subtitle: "إنشاء حسابات موظفي التوصيل وإدارة بياناتهم",
  },
};

export function AppLayout() {
  const { token } = useAuth();
  const location = useLocation();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  if (!token) {
    return <Navigate to="/login" replace />;
  }

  const meta = TITLES[location.pathname] ?? {
    title: "لوحة التحكم",
    subtitle: undefined,
  };

  return (
    <div className="min-h-screen">
      <Sidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} />
      <div className="flex min-h-screen flex-col lg:mr-64">
        <Header
          title={meta.title}
          subtitle={meta.subtitle}
          onMenuClick={() => setSidebarOpen(true)}
        />
        <main className="flex-1 px-4 py-6 sm:px-6 lg:px-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
}

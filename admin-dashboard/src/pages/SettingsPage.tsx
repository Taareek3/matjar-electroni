import { useEffect, useState, type ReactNode } from "react";
import {
  Bike,
  CheckCircle2,
  Phone,
  Save,
  Store,
  XCircle,
} from "lucide-react";
import {
  Button,
  Card,
  ErrorView,
  Field,
  inputClass,
  PageLoader,
  Spinner,
  Toggle,
} from "../components/ui";
import { useSettings, useUpdateSettings } from "../queries/hooks";
import { extractError } from "../lib/api";
import type { Settings } from "../types";

function ToggleRow({
  icon,
  title,
  description,
  checked,
  onChange,
  dangerWhenOff = false,
}: {
  icon: ReactNode;
  title: string;
  description: string;
  checked: boolean;
  onChange: (value: boolean) => void;
  dangerWhenOff?: boolean;
}) {
  return (
    <div className="flex items-center justify-between gap-4 rounded-xl border border-slate-100 bg-slate-50/60 p-4">
      <div className="flex min-w-0 items-start gap-3">
        <div
          className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl ${
            checked
              ? "bg-emerald-100 text-emerald-600"
              : dangerWhenOff
                ? "bg-rose-100 text-rose-500"
                : "bg-slate-200 text-slate-400"
          }`}
        >
          {icon}
        </div>
        <div className="min-w-0">
          <p className="text-sm font-extrabold text-slate-700">{title}</p>
          <p className="text-xs text-slate-400">{description}</p>
        </div>
      </div>
      <Toggle checked={checked} onChange={onChange} label={title} />
    </div>
  );
}

export function SettingsPage() {
  const settingsQuery = useSettings();
  const updateSettings = useUpdateSettings();

  const [form, setForm] = useState<Settings | null>(null);
  const [toast, setToast] = useState<{ type: "ok" | "err"; text: string } | null>(
    null,
  );

  useEffect(() => {
    if (settingsQuery.data?.settings) {
      setForm(settingsQuery.data.settings);
    }
  }, [settingsQuery.data]);

  function showToast(type: "ok" | "err", text: string) {
    setToast({ type, text });
    window.setTimeout(() => setToast(null), 4000);
  }

  async function handleSave() {
    if (!form) return;
    try {
      const saved = await updateSettings.mutateAsync({
        acceptOrders: form.acceptOrders,
        deliveryEnabled: form.deliveryEnabled,
        deliveryFee: Number(form.deliveryFee) || 0,
        restaurantName: form.restaurantName,
        phone: form.phone,
      });
      setForm(saved);
      showToast("ok", "تم حفظ الإعدادات بنجاح");
    } catch (error) {
      showToast("err", extractError(error));
    }
  }

  if (settingsQuery.isPending || !form) {
    return <PageLoader label="جارٍ تحميل الإعدادات..." />;
  }

  if (settingsQuery.isError) {
    return (
      <ErrorView
        message="تعذر جلب الإعدادات — تأكد من تشغيل الخادم"
        onRetry={() => void settingsQuery.refetch()}
      />
    );
  }

  const dirty =
    settingsQuery.data?.settings === undefined ||
    JSON.stringify(form) !== JSON.stringify(settingsQuery.data.settings);

  return (
    <div className="animate-fade-in mx-auto max-w-3xl space-y-6">
      <Card className="p-6">
        <h2 className="mb-4 flex items-center gap-2 font-extrabold text-slate-800">
          <Store className="h-5 w-5 text-indigo-500" />
          استقبال الطلبات
        </h2>

        <div className="space-y-3">
          <ToggleRow
            icon={<CheckCircle2 className="h-5 w-5" />}
            title="استقبال الطلبات"
            description="عند التعطيل ستتوقف تلقي الطلبات الجديدة من العملاء"
            checked={form.acceptOrders}
            dangerWhenOff
            onChange={(value) =>
              setForm((current) =>
                current ? { ...current, acceptOrders: value } : current,
              )
            }
          />

          <ToggleRow
            icon={<Bike className="h-5 w-5" />}
            title="خدمة التوصيل"
            description="تفعيل أو تعطيل خيار التوصيل للعملاء"
            checked={form.deliveryEnabled}
            onChange={(value) =>
              setForm((current) =>
                current ? { ...current, deliveryEnabled: value } : current,
              )
            }
          />
        </div>

        <div className="mt-5 grid grid-cols-1 gap-4 sm:grid-cols-2">
          <Field label="رسوم التوصيل ($)" hint="يُضاف على طلبات التوصيل">
            <input
              className={inputClass}
              type="number"
              min="0"
              step="0.25"
              value={form.deliveryFee}
              onChange={(event) =>
                setForm((current) =>
                  current
                    ? { ...current, deliveryFee: Number(event.target.value) }
                    : current,
                )
              }
            />
          </Field>

          <Field label="هاتف الفرع" hint="يظهر للعملاء للتواصل">
            <input
              className={inputClass}
              dir="ltr"
              value={form.phone}
              onChange={(event) =>
                setForm((current) =>
                  current ? { ...current, phone: event.target.value } : current,
                )
              }
            />
          </Field>
        </div>
      </Card>

      <Card className="p-6">
        <h2 className="mb-4 flex items-center gap-2 font-extrabold text-slate-800">
          <Phone className="h-5 w-5 text-violet-500" />
          بيانات المطعم
        </h2>

        <Field label="اسم المطعم">
          <input
            className={inputClass}
            value={form.restaurantName}
            onChange={(event) =>
              setForm((current) =>
                current
                  ? { ...current, restaurantName: event.target.value }
                  : current,
              )
            }
          />
        </Field>
      </Card>

      <div className="flex items-center justify-between gap-3">
        <p className="text-xs text-slate-400">
          التغييرات تنطبق على تطبيق العملاء مباشرة
        </p>
        <Button onClick={() => void handleSave()} disabled={updateSettings.isPending || !dirty}>
          {updateSettings.isPending ? <Spinner className="h-4 w-4" /> : <Save className="h-4 w-4" />}
          حفظ الإعدادات
        </Button>
      </div>

      {toast && (
        <div
          className={`animate-fade-in fixed bottom-6 left-1/2 z-50 -translate-x-1/2 rounded-2xl px-6 py-3 text-sm font-bold text-white shadow-2xl ${
            toast.type === "ok" ? "bg-emerald-600" : "bg-rose-600"
          }`}
        >
          {toast.type === "ok" ? (
            <span className="flex items-center gap-2">
              <CheckCircle2 className="h-4 w-4" /> {toast.text}
            </span>
          ) : (
            <span className="flex items-center gap-2">
              <XCircle className="h-4 w-4" /> {toast.text}
            </span>
          )}
        </div>
      )}
    </div>
  );
}

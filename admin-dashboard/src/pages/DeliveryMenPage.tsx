import { useState, type FormEvent } from "react";
import {
  Bike,
  Mail,
  Pencil,
  Phone,
  Plus,
  Trash2,
} from "lucide-react";
import { extractError } from "../lib/api";
import {
  useCreateDeliveryMan,
  useDeleteDeliveryMan,
  useUpdateDeliveryMan,
  useDeliveryMen,
} from "../queries/hooks";
import type { DeliveryMan, DeliveryManInput } from "../types";
import {
  Button,
  Card,
  ConfirmDialog,
  EmptyState,
  ErrorView,
  Field,
  inputClass,
  Modal,
  PageLoader,
  Spinner,
} from "../components/ui";

interface DeliveryManFormState {
  name: string;
  email: string;
  phone: string;
  password: string;
  avatar: string;
}

const EMPTY_FORM: DeliveryManFormState = {
  name: "",
  email: "",
  phone: "",
  password: "",
  avatar: "",
};

export function DeliveryMenPage() {
  const deliveryMenQuery = useDeliveryMen();
  const createDeliveryMan = useCreateDeliveryMan();
  const updateDeliveryMan = useUpdateDeliveryMan();
  const deleteDeliveryMan = useDeleteDeliveryMan();

  const [modal, setModal] = useState<"new" | DeliveryMan | null>(null);
  const [form, setForm] = useState<DeliveryManFormState>(EMPTY_FORM);
  const [formError, setFormError] = useState<string | null>(null);
  const [deleting, setDeleting] = useState<DeliveryMan | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  function showToast(message: string) {
    setToast(message);
    window.setTimeout(() => setToast(null), 3000);
  }

  function openNew() {
    setForm(EMPTY_FORM);
    setFormError(null);
    setModal("new");
  }

  function openEdit(deliveryMan: DeliveryMan) {
    setForm({
      name: deliveryMan.name,
      email: deliveryMan.email,
      phone: deliveryMan.phone,
      password: "",
      avatar: deliveryMan.avatar ?? "",
    });
    setFormError(null);
    setModal(deliveryMan);
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setFormError(null);

    if (!form.name.trim() || !form.email.trim() || !form.phone.trim()) {
      setFormError("الاسم والبريد ورقم الهاتف مطلوبة");
      return;
    }

    if (modal === "new" && form.password.length < 6) {
      setFormError("كلمة المرور يجب ألا تقل عن 6 أحرف");
      return;
    }

    try {
      const input: DeliveryManInput = {
        name: form.name.trim(),
        email: form.email.trim(),
        phone: form.phone.trim(),
        password: form.password,
        avatar: form.avatar.trim() || undefined,
      };

      if (modal === "new") {
        await createDeliveryMan.mutateAsync(input);
        showToast("تم إنشاء حساب عامل التوصيل");
      } else if (modal) {
        const { password, ...rest } = input;
        await updateDeliveryMan.mutateAsync({
          id: modal.id,
          input: password ? input : rest,
        });
        showToast("تم تحديث بيانات عامل التوصيل");
      }
      setModal(null);
    } catch (error) {
      setFormError(extractError(error));
    }
  }

  async function handleDelete() {
    if (!deleting) return;
    try {
      await deleteDeliveryMan.mutateAsync(deleting.id);
      showToast("تم حذف عامل التوصيل");
      setDeleting(null);
    } catch (error) {
      showToast(`⚠️ ${extractError(error)}`);
      setDeleting(null);
    }
  }

  if (deliveryMenQuery.isPending) {
    return <PageLoader label="جارٍ تحميل عمال التوصيل..." />;
  }

  if (deliveryMenQuery.isError) {
    return (
      <ErrorView
        message={extractError(deliveryMenQuery.error)}
        onRetry={() => void deliveryMenQuery.refetch()}
      />
    );
  }

  const deliveryMen = deliveryMenQuery.data?.deliveryMen ?? [];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-extrabold text-slate-900">
            إدارة عمال التوصيل
          </h1>
          <p className="text-sm text-slate-500">
            إنشاء حسابات لتطبيق التوصيل وإدارة بياناتهم
          </p>
        </div>
        <Button onClick={openNew}>
          <Plus className="h-4 w-4" />
          عامل توصيل جديد
        </Button>
      </div>

      {deliveryMen.length === 0 ? (
        <Card>
          <EmptyState
            icon={<Bike className="h-10 w-10 text-slate-300" />}
            title="لا يوجد عمال توصيل بعد"
            subtitle="ابدأ بإنشاء حساب لتطبيق التوصيل"
          />
        </Card>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {deliveryMen.map((deliveryMan) => (
            <Card key={deliveryMan.id} className="p-5">
              <div className="flex items-start gap-4">
                <div className="flex h-14 w-14 shrink-0 items-center justify-center overflow-hidden rounded-2xl bg-gradient-to-br from-emerald-500 to-teal-600 text-white shadow-lg shadow-emerald-200">
                  {deliveryMan.avatar ? (
                    <img
                      src={deliveryMan.avatar}
                      alt={deliveryMan.name}
                      className="h-full w-full object-cover"
                    />
                  ) : (
                    <Bike className="h-7 w-7" />
                  )}
                </div>
                <div className="min-w-0 flex-1">
                  <p className="truncate font-bold text-slate-900">
                    {deliveryMan.name}
                  </p>
                  <p className="flex items-center gap-1.5 text-xs text-slate-500">
                    <Mail className="h-3.5 w-3.5 shrink-0" />
                    <span className="truncate">{deliveryMan.email}</span>
                  </p>
                  <p className="mt-1 flex items-center gap-1.5 text-xs text-slate-500">
                    <Phone className="h-3.5 w-3.5 shrink-0" />
                    <span dir="ltr">{deliveryMan.phone}</span>
                  </p>
                </div>
              </div>
              <div className="mt-4 flex items-center justify-between border-t border-slate-100 pt-4">
                <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-bold text-emerald-700">
                  {deliveryMan._count?.deliveryOrders ?? 0} تسليم
                </span>
                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    onClick={() => openEdit(deliveryMan)}
                    className="px-3 py-1.5 text-xs"
                  >
                    <Pencil className="h-3.5 w-3.5" />
                    تعديل
                  </Button>
                  <Button
                    variant="danger"
                    onClick={() => setDeleting(deliveryMan)}
                    className="px-3 py-1.5 text-xs"
                  >
                    <Trash2 className="h-3.5 w-3.5" />
                    حذف
                  </Button>
                </div>
              </div>
            </Card>
          ))}
        </div>
      )}

      <Modal
        open={modal !== null}
        title={modal === "new" ? "عامل توصيل جديد" : "تعديل عامل التوصيل"}
        onClose={() => setModal(null)}
        wide
      >
        <form onSubmit={(e) => void handleSubmit(e)} className="space-y-4">
          <Field label="الاسم الكامل">
            <input
              className={inputClass}
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
              placeholder="مثال: أحمد محمود"
            />
          </Field>
          <Field label="البريد الإلكتروني">
            <input
              className={inputClass}
              type="email"
              value={form.email}
              onChange={(e) => setForm({ ...form, email: e.target.value })}
              placeholder="delivery@binaflow.com"
              dir="ltr"
            />
          </Field>
          <Field label="رقم الهاتف">
            <input
              className={inputClass}
              value={form.phone}
              onChange={(e) => setForm({ ...form, phone: e.target.value })}
              placeholder="05xxxxxxxx"
              dir="ltr"
            />
          </Field>
          <Field label="كلمة المرور">
            <input
              className={inputClass}
              type="password"
              value={form.password}
              onChange={(e) => setForm({ ...form, password: e.target.value })}
              placeholder={
                modal === "new"
                  ? "6 أحرف على الأقل"
                  : "اتركها فارغة للإبقاء على الحالية"
              }
              dir="ltr"
            />
          </Field>
          <Field label="رابط الصورة الشخصية (اختياري)">
            <input
              className={inputClass}
              value={form.avatar}
              onChange={(e) => setForm({ ...form, avatar: e.target.value })}
              placeholder="https://example.com/avatar.jpg"
              dir="ltr"
            />
          </Field>
          {formError && (
            <p className="rounded-xl bg-rose-50 px-4 py-3 text-sm font-bold text-rose-700">
              {formError}
            </p>
          )}
          <div className="flex justify-end gap-3 pt-2">
            <Button
              variant="outline"
              onClick={() => setModal(null)}
              type="button"
            >
              إلغاء
            </Button>
            <Button
              type="submit"
              disabled={
                createDeliveryMan.isPending || updateDeliveryMan.isPending
              }
            >
              {(createDeliveryMan.isPending ||
                updateDeliveryMan.isPending) && <Spinner className="h-4 w-4" />}
              حفظ
            </Button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog
        open={!!deleting}
        title="حذف عامل توصيل"
        message={`سيتم حذف "${deleting?.name}" نهائياً.`}
        confirmLabel="حذف نهائي"
        loading={deleteDeliveryMan.isPending}
        onConfirm={() => void handleDelete()}
        onCancel={() => setDeleting(null)}
      />

      {toast && (
        <div className="animate-fade-in fixed bottom-6 left-1/2 z-50 -translate-x-1/2 rounded-2xl bg-slate-900 px-6 py-3 text-sm font-bold text-white shadow-2xl">
          {toast}
        </div>
      )}
    </div>
  );
}

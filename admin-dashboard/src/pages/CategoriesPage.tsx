import { useState, type FormEvent } from "react";
import {
  ArrowDown,
  ArrowUp,
  Image as ImageIcon,
  Pencil,
  Plus,
  Tags,
  Trash2,
} from "lucide-react";
import {
  Badge,
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
import {
  useCategories,
  useCreateCategory,
  useDeleteCategory,
  useReorderCategories,
  useUpdateCategory,
} from "../queries/hooks";
import { extractError } from "../lib/api";
import type { Category } from "../types";

export function CategoriesPage() {
  const categoriesQuery = useCategories();
  const createCategory = useCreateCategory();
  const updateCategory = useUpdateCategory();
  const deleteCategory = useDeleteCategory();
  const reorderCategories = useReorderCategories();

  const [modal, setModal] = useState<"new" | Category | null>(null);
  const [editing, setEditing] = useState<Category | null>(null);
  const [name, setName] = useState("");
  const [image, setImage] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [deleting, setDeleting] = useState<Category | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  const categories = categoriesQuery.data?.categories ?? [];

  function showToast(message: string) {
    setToast(message);
    window.setTimeout(() => setToast(null), 3500);
  }

  function openNew() {
    setName("");
    setImage("");
    setError(null);
    setEditing(null);
    setModal("new");
  }

  function openEdit(category: Category) {
    setName(category.name);
    setImage(category.image);
    setError(null);
    setEditing(category);
    setModal(category);
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError(null);

    if (!name.trim()) {
      setError("اسم القسم مطلوب");
      return;
    }

    try {
      if (editing) {
        await updateCategory.mutateAsync({
          id: editing.id,
          input: { name: name.trim(), image: image.trim() },
        });
        showToast("تم تحديث القسم");
      } else {
        await createCategory.mutateAsync({
          name: name.trim(),
          image: image.trim(),
        });
        showToast("تمت إضافة القسم");
      }
      setModal(null);
      setEditing(null);
    } catch (err) {
      setError(extractError(err));
    }
  }

  async function handleDelete() {
    if (!deleting) return;
    try {
      await deleteCategory.mutateAsync(deleting.id);
      showToast("تم حذف القسم");
      setDeleting(null);
    } catch (err) {
      showToast(`⚠️ ${extractError(err)}`);
      setDeleting(null);
    }
  }

  async function move(index: number, direction: -1 | 1) {
    const target = index + direction;
    if (target < 0 || target >= categories.length) return;

    const ids = categories.map((category) => category.id);
    const [moved] = ids.splice(index, 1);
    ids.splice(target, 0, moved);

    try {
      await reorderCategories.mutateAsync(ids);
    } catch (err) {
      showToast(`⚠️ ${extractError(err)}`);
    }
  }

  if (categoriesQuery.isPending) return <PageLoader label="جارٍ تحميل الأقسام..." />;
  if (categoriesQuery.isError) {
    return (
      <ErrorView
        message="تعذر جلب الأقسام — تأكد من تشغيل الخادم"
        onRetry={() => void categoriesQuery.refetch()}
      />
    );
  }

  return (
    <div className="animate-fade-in">
      <div className="mb-6 flex justify-end">
        <Button onClick={openNew}>
          <Plus className="h-4 w-4" />
          إضافة قسم
        </Button>
      </div>

      {categories.length === 0 ? (
        <EmptyState
          icon={<Tags className="h-10 w-10" />}
          title="لا توجد أقسام"
          subtitle="ابدأ بإضافة قسم جديد للمنيو"
        />
      ) : (
        <div className="space-y-3">
          {categories.map((category, index) => (
            <Card
              key={category.id}
              className="flex flex-wrap items-center gap-4 p-4"
            >
              <div className="h-14 w-14 shrink-0 overflow-hidden rounded-xl bg-gradient-to-br from-slate-100 to-slate-200">
                {category.image ? (
                  <img
                    src={category.image}
                    alt={category.name}
                    className="h-full w-full object-cover"
                  />
                ) : (
                  <div className="flex h-full items-center justify-center text-slate-300">
                    <ImageIcon className="h-6 w-6" />
                  </div>
                )}
              </div>

              <div className="min-w-0 flex-1">
                <p className="font-extrabold text-slate-800">{category.name}</p>
                <div className="mt-1 flex flex-wrap gap-2">
                  <Badge className="bg-indigo-50 text-indigo-600 ring-indigo-100">
                    {category.itemsCount ?? 0} منتج
                  </Badge>
                  <Badge className="bg-slate-100 text-slate-500 ring-slate-200">
                    الترتيب {category.position + 1}
                  </Badge>
                </div>
              </div>

              <div className="flex items-center gap-1.5">
                <button
                  type="button"
                  onClick={() => void move(index, -1)}
                  disabled={index === 0 || reorderCategories.isPending}
                  className="rounded-lg border border-slate-200 p-2 text-slate-400 transition hover:bg-slate-50 disabled:opacity-30"
                  aria-label="تحريك لأعلى"
                >
                  <ArrowUp className="h-4 w-4" />
                </button>
                <button
                  type="button"
                  onClick={() => void move(index, 1)}
                  disabled={index === categories.length - 1 || reorderCategories.isPending}
                  className="rounded-lg border border-slate-200 p-2 text-slate-400 transition hover:bg-slate-50 disabled:opacity-30"
                  aria-label="تحريك لأسفل"
                >
                  <ArrowDown className="h-4 w-4" />
                </button>
                <button
                  type="button"
                  onClick={() => openEdit(category)}
                  className="rounded-lg border border-slate-200 p-2 text-slate-400 transition hover:border-indigo-200 hover:bg-indigo-50 hover:text-indigo-600"
                  aria-label="تعديل"
                >
                  <Pencil className="h-4 w-4" />
                </button>
                <button
                  type="button"
                  onClick={() => setDeleting(category)}
                  disabled={(category.itemsCount ?? 0) > 0}
                  className="rounded-lg border border-slate-200 p-2 text-slate-400 transition hover:border-rose-200 hover:bg-rose-50 hover:text-rose-600 disabled:opacity-30"
                  aria-label="حذف"
                  title={
                    (category.itemsCount ?? 0) > 0
                      ? "لا يمكن حذف قسم يحتوي على منتجات"
                      : "حذف"
                  }
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
            </Card>
          ))}
        </div>
      )}

      <Modal
        open={modal !== null}
        title={editing ? "تعديل قسم" : "إضافة قسم جديد"}
        onClose={() => {
          setModal(null);
          setEditing(null);
        }}
      >
        <form onSubmit={(event) => void handleSubmit(event)} className="space-y-4">
          <Field label="اسم القسم">
            <input
              className={inputClass}
              value={name}
              onChange={(event) => setName(event.target.value)}
              placeholder="مثال: وجبات سريعة"
            />
          </Field>

          <Field label="رابط الصورة (اختياري)">
            <input
              className={inputClass}
              dir="ltr"
              value={image}
              onChange={(event) => setImage(event.target.value)}
              placeholder="https://..."
            />
          </Field>

          {image && (
            <div className="h-32 overflow-hidden rounded-xl border border-slate-200 bg-slate-50">
              <img
                src={image}
                alt="معاينة"
                className="h-full w-full object-cover"
                onError={(event) => {
                  event.currentTarget.style.display = "none";
                }}
              />
            </div>
          )}

          {error && (
            <p className="rounded-xl bg-rose-50 px-4 py-2.5 text-sm font-bold text-rose-600">
              {error}
            </p>
          )}

          <div className="flex justify-end gap-3">
            <Button
              variant="outline"
              onClick={() => {
                setModal(null);
                setEditing(null);
              }}
            >
              إلغاء
            </Button>
            <Button
              type="submit"
              disabled={createCategory.isPending || updateCategory.isPending}
            >
              {(createCategory.isPending || updateCategory.isPending) && (
                <Spinner className="h-4 w-4" />
              )}
              حفظ
            </Button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog
        open={!!deleting}
        title="حذف قسم"
        message={`سيتم حذف "${deleting?.name ?? ""}" نهائياً. لا يمكن التراجع عن هذا الإجراء.`}
        confirmLabel="حذف"
        loading={deleteCategory.isPending}
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

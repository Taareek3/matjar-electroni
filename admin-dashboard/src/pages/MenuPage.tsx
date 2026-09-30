import { useMemo, useState, type FormEvent } from "react";
import {
  Image as ImageIcon,
  Layers,
  Pencil,
  Plus,
  Search,
  Trash2,
  UtensilsCrossed,
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
  Toggle,
} from "../components/ui";
import {
  useAdminMenu,
  useCategories,
  useCreateMenuItem,
  useCreateOptionGroup,
  useDeleteMenuItem,
  useDeleteOptionGroup,
  useSetAvailability,
  useUpdateMenuItem,
  useUpdateOptionGroup,
} from "../queries/hooks";
import { extractError } from "../lib/api";
import type { MenuItem, OptionGroup, OptionGroupInput } from "../types";

interface ItemFormState {
  name: string;
  description: string;
  price: string;
  image: string;
  categoryId: string;
}

interface GroupFormState {
  name: string;
  isRequired: boolean;
  allowMultiple: boolean;
  options: { name: string; price: string }[];
}

const EMPTY_ITEM: ItemFormState = {
  name: "",
  description: "",
  price: "",
  image: "",
  categoryId: "",
};

function groupToForm(group: OptionGroup): GroupFormState {
  return {
    name: group.name,
    isRequired: group.isRequired,
    allowMultiple: group.allowMultiple,
    options: group.options.map((option) => ({
      name: option.name,
      price: String(option.price),
    })),
  };
}

function OptionGroupsEditor({
  item,
  onChanged,
}: {
  item: MenuItem;
  onChanged: (message: string) => void;
}) {
  const createGroup = useCreateOptionGroup();
  const updateGroup = useUpdateOptionGroup();
  const deleteGroup = useDeleteOptionGroup();

  const [editing, setEditing] = useState<"new" | OptionGroup | null>(null);
  const [form, setForm] = useState<GroupFormState>({
    name: "",
    isRequired: false,
    allowMultiple: false,
    options: [{ name: "", price: "0" }],
  });
  const [error, setError] = useState<string | null>(null);
  const [deleting, setDeleting] = useState<OptionGroup | null>(null);

  function openNew() {
    setError(null);
    setForm({
      name: "",
      isRequired: false,
      allowMultiple: false,
      options: [{ name: "", price: "0" }],
    });
    setEditing("new");
  }

  function openEdit(group: OptionGroup) {
    setError(null);
    setForm(groupToForm(group));
    setEditing(group);
  }

  function addOptionRow() {
    setForm((current) => ({
      ...current,
      options: [...current.options, { name: "", price: "0" }],
    }));
  }

  function removeOptionRow(index: number) {
    setForm((current) => ({
      ...current,
      options: current.options.filter((_, i) => i !== index),
    }));
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError(null);

    const options = form.options
      .filter((option) => option.name.trim())
      .map((option) => ({
        name: option.name.trim(),
        price: Number(option.price) || 0,
      }));

    if (!form.name.trim()) {
      setError("اسم مجموعة الإضافات مطلوب");
      return;
    }

    if (options.length === 0) {
      setError("أضف خياراً واحداً على الأقل");
      return;
    }

    const input: OptionGroupInput = {
      name: form.name.trim(),
      isRequired: form.isRequired,
      allowMultiple: form.allowMultiple,
      options,
    };

    try {
      if (editing === "new") {
        await createGroup.mutateAsync({ itemId: item.id, input });
        onChanged("تمت إضافة مجموعة الإضافات");
      } else if (editing) {
        await updateGroup.mutateAsync({ groupId: editing.id, input });
        onChanged("تم تحديث مجموعة الإضافات");
      }
      setEditing(null);
    } catch (err) {
      setError(extractError(err));
    }
  }

  async function handleDelete() {
    if (!deleting) return;
    try {
      await deleteGroup.mutateAsync(deleting.id);
      onChanged("تم حذف مجموعة الإضافات");
      setDeleting(null);
    } catch (err) {
      setError(extractError(err));
      setDeleting(null);
    }
  }

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <p className="text-sm font-extrabold text-slate-700">
          الإضافات وخيارات التخصيص
        </p>
        <Button size="sm" variant="outline" onClick={openNew}>
          <Plus className="h-4 w-4" />
          مجموعة إضافات
        </Button>
      </div>

      {item.optionGroups.length === 0 && (
        <p className="rounded-xl bg-slate-50 px-4 py-3 text-xs text-slate-400">
          لا توجد إضافات لهذا المنتج — يمكن للعميل طلبه مباشرة
        </p>
      )}

      {item.optionGroups.map((group) => (
        <div
          key={group.id}
          className="rounded-xl border border-slate-200 bg-slate-50/60 p-3.5"
        >
          <div className="flex items-center justify-between gap-2">
            <div className="min-w-0">
              <p className="truncate text-sm font-extrabold text-slate-700">
                {group.name}
              </p>
              <div className="mt-1 flex flex-wrap gap-1.5">
                <Badge className="bg-white text-slate-500 ring-slate-200">
                  {group.isRequired ? "إلزامي" : "اختياري"}
                </Badge>
                <Badge className="bg-white text-slate-500 ring-slate-200">
                  {group.allowMultiple ? "اختيارات متعددة" : "اختيار واحد"}
                </Badge>
                <Badge className="bg-white text-slate-500 ring-slate-200">
                  {group.options.length} خيارات
                </Badge>
              </div>
            </div>
            <div className="flex shrink-0 gap-1.5">
              <button
                type="button"
                onClick={() => openEdit(group)}
                className="rounded-lg p-2 text-slate-400 transition hover:bg-white hover:text-indigo-600"
                aria-label="تعديل"
              >
                <Pencil className="h-4 w-4" />
              </button>
              <button
                type="button"
                onClick={() => setDeleting(group)}
                className="rounded-lg p-2 text-slate-400 transition hover:bg-white hover:text-rose-600"
                aria-label="حذف"
              >
                <Trash2 className="h-4 w-4" />
              </button>
            </div>
          </div>

          <ul className="mt-2 space-y-1">
            {group.options.map((option) => (
              <li
                key={option.id}
                className="flex items-center justify-between text-xs text-slate-500"
              >
                <span>{option.name}</span>
                <span className="font-bold text-slate-600">
                  {option.price > 0 ? `+${option.price.toFixed(2)} $` : "مجاناً"}
                </span>
              </li>
            ))}
          </ul>
        </div>
      ))}

      <Modal
        open={editing !== null}
        title={editing === "new" ? "مجموعة إضافات جديدة" : "تعديل مجموعة الإضافات"}
        onClose={() => setEditing(null)}
      >
        <form onSubmit={(event) => void handleSubmit(event)} className="space-y-4">
          <Field label="اسم المجموعة">
            <input
              className={inputClass}
              value={form.name}
              onChange={(event) =>
                setForm((current) => ({ ...current, name: event.target.value }))
              }
              placeholder="مثال: حجم البيتزا"
            />
          </Field>

          <div className="flex flex-wrap gap-4">
            <label className="flex items-center gap-2 text-sm font-bold text-slate-600">
              <Toggle
                checked={form.isRequired}
                onChange={(value) =>
                  setForm((current) => ({ ...current, isRequired: value }))
                }
                label="إلزامي"
              />
              إلزامي
            </label>
            <label className="flex items-center gap-2 text-sm font-bold text-slate-600">
              <Toggle
                checked={form.allowMultiple}
                onChange={(value) =>
                  setForm((current) => ({ ...current, allowMultiple: value }))
                }
                label="متعدد"
              />
              اختيار متعدد
            </label>
          </div>

          <div>
            <p className="mb-2 text-sm font-bold text-slate-700">الخيارات</p>
            <div className="space-y-2">
              {form.options.map((option, index) => (
                <div key={index} className="flex gap-2">
                  <input
                    className={`${inputClass} flex-1`}
                    value={option.name}
                    onChange={(event) =>
                      setForm((current) => ({
                        ...current,
                        options: current.options.map((item, i) =>
                          i === index ? { ...item, name: event.target.value } : item,
                        ),
                      }))
                    }
                    placeholder="اسم الخيار"
                  />
                  <input
                    className={`${inputClass} w-24`}
                    type="number"
                    min="0"
                    step="0.25"
                    value={option.price}
                    onChange={(event) =>
                      setForm((current) => ({
                        ...current,
                        options: current.options.map((item, i) =>
                          i === index ? { ...item, price: event.target.value } : item,
                        ),
                      }))
                    }
                    placeholder="السعر"
                  />
                  <button
                    type="button"
                    onClick={() => removeOptionRow(index)}
                    disabled={form.options.length === 1}
                    className="rounded-xl border border-slate-200 px-3 text-slate-400 transition hover:border-rose-200 hover:bg-rose-50 hover:text-rose-500 disabled:opacity-40"
                    aria-label="حذف الخيار"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              ))}
            </div>
            <button
              type="button"
              onClick={addOptionRow}
              className="mt-2 text-xs font-bold text-indigo-600 hover:text-indigo-500"
            >
              + إضافة خيار
            </button>
          </div>

          {error && (
            <p className="rounded-xl bg-rose-50 px-4 py-2.5 text-sm font-bold text-rose-600">
              {error}
            </p>
          )}

          <div className="flex justify-end gap-3">
            <Button variant="outline" onClick={() => setEditing(null)}>
              إلغاء
            </Button>
            <Button
              type="submit"
              disabled={createGroup.isPending || updateGroup.isPending}
            >
              {(createGroup.isPending || updateGroup.isPending) && (
                <Spinner className="h-4 w-4" />
              )}
              حفظ
            </Button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog
        open={!!deleting}
        title="حذف مجموعة الإضافات"
        message={`سيتم حذف "${deleting?.name ?? ""}" مع جميع خياراتها. هل أنت متأكد؟`}
        confirmLabel="حذف"
        loading={deleteGroup.isPending}
        onConfirm={() => void handleDelete()}
        onCancel={() => setDeleting(null)}
      />
    </div>
  );
}

export function MenuPage() {
  const menuQuery = useAdminMenu();
  const categoriesQuery = useCategories();

  const createItem = useCreateMenuItem();
  const updateItem = useUpdateMenuItem();
  const deleteItem = useDeleteMenuItem();
  const setAvailability = useSetAvailability();

  const [search, setSearch] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("all");
  const [showUnavailable, setShowUnavailable] = useState(true);

  const [itemModal, setItemModal] = useState<"new" | MenuItem | null>(null);
  const [editingItem, setEditingItem] = useState<MenuItem | null>(null);
  const [form, setForm] = useState<ItemFormState>(EMPTY_ITEM);
  const [formError, setFormError] = useState<string | null>(null);

  const [deleting, setDeleting] = useState<MenuItem | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  const categories = categoriesQuery.data?.categories ?? [];
  const items = menuQuery.data?.items ?? [];

  const filtered = useMemo(() => {
    const query = search.trim();
    return items.filter((item) => {
      if (!showUnavailable && !item.isAvailable) return false;
      if (categoryFilter !== "all" && item.categoryId !== categoryFilter) {
        return false;
      }
      if (query && !item.name.includes(query) && !item.description.includes(query)) {
        return false;
      }
      return true;
    });
  }, [items, search, categoryFilter, showUnavailable]);

  function showToast(message: string) {
    setToast(message);
    window.setTimeout(() => setToast(null), 3500);
  }

  function openNew() {
    setForm({
      ...EMPTY_ITEM,
      categoryId: categories[0]?.id ?? "",
    });
    setFormError(null);
    setItemModal("new");
    setEditingItem(null);
  }

  function openEdit(item: MenuItem) {
    setForm({
      name: item.name,
      description: item.description,
      price: String(item.price),
      image: item.imageUrl,
      categoryId: item.categoryId,
    });
    setFormError(null);
    setEditingItem(item);
    setItemModal(item);
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setFormError(null);

    const price = Number(form.price);

    if (!form.name.trim()) {
      setFormError("اسم المنتج مطلوب");
      return;
    }
    if (!Number.isFinite(price) || price < 0) {
      setFormError("أدخل سعراً صالحاً");
      return;
    }
    if (!form.categoryId) {
      setFormError("اختر قسماً للمنتج");
      return;
    }

    const input = {
      name: form.name.trim(),
      description: form.description.trim(),
      price,
      image: form.image.trim(),
      categoryId: form.categoryId,
    };

    try {
      if (editingItem) {
        await updateItem.mutateAsync({ id: editingItem.id, input });
        showToast("تم تحديث المنتج بنجاح");
      } else {
        await createItem.mutateAsync(input);
        showToast("تمت إضافة المنتج بنجاح");
      }
      setItemModal(null);
      setEditingItem(null);
    } catch (error) {
      setFormError(extractError(error));
    }
  }

  async function handleDelete() {
    if (!deleting) return;
    try {
      const result = await deleteItem.mutateAsync(deleting.id);
      showToast(result?.message ?? "تم الحذف");
      setDeleting(null);
    } catch (error) {
      showToast(`⚠️ ${extractError(error)}`);
      setDeleting(null);
    }
  }

  async function toggleAvailability(item: MenuItem) {
    try {
      await setAvailability.mutateAsync({
        id: item.id,
        isAvailable: !item.isAvailable,
      });
      showToast(
        item.isAvailable
          ? `تم تعطيل "${item.name}"`
          : `تم تفعيل "${item.name}"`,
      );
    } catch (error) {
      showToast(`⚠️ ${extractError(error)}`);
    }
  }

  if (menuQuery.isPending || categoriesQuery.isPending) {
    return <PageLoader label="جارٍ تحميل المنيو..." />;
  }

  if (menuQuery.isError) {
    return (
      <ErrorView
        message="تعذر جلب المنيو — تأكد من تشغيل الخادم"
        onRetry={() => void menuQuery.refetch()}
      />
    );
  }

  return (
    <div className="animate-fade-in">
      <div className="mb-6 flex flex-wrap items-center gap-3">
        <div className="relative min-w-56 flex-1">
          <Search className="absolute top-1/2 right-3.5 h-5 w-5 -translate-y-1/2 text-slate-400" />
          <input
            className={`${inputClass} ps-10`}
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder="ابحث عن منتج..."
          />
        </div>

        <label className="flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-bold text-slate-600">
          <Toggle
            checked={showUnavailable}
            onChange={setShowUnavailable}
            label="إظهار المعطل"
          />
          إظهار غير المتوفر
        </label>

        <Button onClick={openNew}>
          <Plus className="h-4 w-4" />
          إضافة منتج
        </Button>
      </div>

      <div className="mb-5 flex flex-wrap gap-2">
        <button
          type="button"
          onClick={() => setCategoryFilter("all")}
          className={`rounded-full px-4 py-1.5 text-sm font-bold transition ${
            categoryFilter === "all"
              ? "bg-indigo-600 text-white shadow-sm shadow-indigo-200"
              : "bg-white text-slate-600 ring-1 ring-inset ring-slate-200 hover:bg-slate-50"
          }`}
        >
          الكل ({items.length})
        </button>
        {categories.map((category) => {
          const count = items.filter((item) => item.categoryId === category.id).length;
          return (
            <button
              key={category.id}
              type="button"
              onClick={() => setCategoryFilter(category.id)}
              className={`rounded-full px-4 py-1.5 text-sm font-bold transition ${
                categoryFilter === category.id
                  ? "bg-indigo-600 text-white shadow-sm shadow-indigo-200"
                  : "bg-white text-slate-600 ring-1 ring-inset ring-slate-200 hover:bg-slate-50"
              }`}
            >
              {category.name} ({count})
            </button>
          );
        })}
      </div>

      {filtered.length === 0 ? (
        <EmptyState
          icon={<UtensilsCrossed className="h-10 w-10" />}
          title="لا توجد منتجات مطابقة"
          subtitle="جرّب تعديل البحث أو الفلاتر"
        />
      ) : (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
          {filtered.map((item) => (
            <Card
              key={item.id}
              className={`group overflow-hidden transition hover:shadow-md ${
                item.isAvailable ? "" : "opacity-60"
              }`}
            >
              <div className="relative h-36 bg-gradient-to-br from-slate-100 to-slate-200">
                {item.imageUrl ? (
                  <img
                    src={item.imageUrl}
                    alt={item.name}
                    className="h-full w-full object-cover"
                    loading="lazy"
                  />
                ) : (
                  <div className="flex h-full items-center justify-center text-slate-300">
                    <ImageIcon className="h-10 w-10" />
                  </div>
                )}
                <div className="absolute top-2 right-2 flex gap-1.5">
                  {!item.isAvailable && (
                    <Badge className="bg-rose-600 text-white ring-rose-600">
                      غير متوفر
                    </Badge>
                  )}
                  {item.optionGroups.length > 0 && (
                    <Badge className="bg-slate-900/70 text-white ring-slate-900/40">
                      <Layers className="h-3 w-3" />
                      {item.optionGroups.length}
                    </Badge>
                  )}
                </div>
              </div>

              <div className="p-4">
                <div className="mb-1 flex items-start justify-between gap-2">
                  <p className="font-extrabold text-slate-800">{item.name}</p>
                  <p className="shrink-0 text-sm font-extrabold text-indigo-600">
                    {item.price.toFixed(2)} $
                  </p>
                </div>
                <p className="mb-1 line-clamp-2 min-h-8 text-xs text-slate-400">
                  {item.description || "لا يوجد وصف"}
                </p>
                <p className="mb-3 text-[11px] font-bold text-slate-400">
                  {item.categoryName}
                </p>

                <div className="flex items-center justify-between gap-2 border-t border-slate-100 pt-3">
                  <label className="flex items-center gap-2 text-xs font-bold text-slate-500">
                    <Toggle
                      checked={item.isAvailable}
                      onChange={() => void toggleAvailability(item)}
                      label={`توفر ${item.name}`}
                    />
                    متوفر
                  </label>
                  <div className="flex gap-1.5">
                    <button
                      type="button"
                      onClick={() => openEdit(item)}
                      className="rounded-lg border border-slate-200 p-2 text-slate-400 transition hover:border-indigo-200 hover:bg-indigo-50 hover:text-indigo-600"
                      aria-label="تعديل"
                    >
                      <Pencil className="h-4 w-4" />
                    </button>
                    <button
                      type="button"
                      onClick={() => setDeleting(item)}
                      className="rounded-lg border border-slate-200 p-2 text-slate-400 transition hover:border-rose-200 hover:bg-rose-50 hover:text-rose-600"
                      aria-label="حذف"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                </div>
              </div>
            </Card>
          ))}
        </div>
      )}

      <Modal
        open={itemModal !== null}
        title={editingItem ? "تعديل منتج" : "إضافة منتج جديد"}
        onClose={() => {
          setItemModal(null);
          setEditingItem(null);
        }}
        wide
      >
        <form onSubmit={(event) => void handleSubmit(event)} className="space-y-4">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Field label="اسم المنتج">
              <input
                className={inputClass}
                value={form.name}
                onChange={(event) =>
                  setForm((current) => ({ ...current, name: event.target.value }))
                }
                placeholder="مثال: برغر كلاسيك"
              />
            </Field>

            <Field label="السعر (دولار)">
              <input
                className={inputClass}
                type="number"
                min="0"
                step="0.01"
                value={form.price}
                onChange={(event) =>
                  setForm((current) => ({ ...current, price: event.target.value }))
                }
                placeholder="0.00"
              />
            </Field>
          </div>

          <Field label="الوصف">
            <textarea
              className={`${inputClass} min-h-20 resize-y`}
              value={form.description}
              onChange={(event) =>
                setForm((current) => ({
                  ...current,
                  description: event.target.value,
                }))
              }
              placeholder="وصف قصير للمنتج..."
            />
          </Field>

          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Field label="رابط الصورة">
              <input
                className={inputClass}
                dir="ltr"
                value={form.image}
                onChange={(event) =>
                  setForm((current) => ({ ...current, image: event.target.value }))
                }
                placeholder="https://..."
              />
            </Field>

            <Field label="القسم">
              <select
                className={inputClass}
                value={form.categoryId}
                onChange={(event) =>
                  setForm((current) => ({
                    ...current,
                    categoryId: event.target.value,
                  }))
                }
              >
                <option value="" disabled>
                  اختر قسماً
                </option>
                {categories.map((category) => (
                  <option key={category.id} value={category.id}>
                    {category.name}
                  </option>
                ))}
              </select>
            </Field>
          </div>

          {form.image && (
            <div className="h-40 overflow-hidden rounded-xl border border-slate-200 bg-slate-50">
              <img
                src={form.image}
                alt="معاينة"
                className="h-full w-full object-cover"
                onError={(event) => {
                  event.currentTarget.style.display = "none";
                }}
              />
            </div>
          )}

          {editingItem && (
            <div className="border-t border-slate-100 pt-4">
              <OptionGroupsEditor
                item={editingItem}
                onChanged={(message) => {
                  showToast(message);
                  void menuQuery.refetch().then(() => {
                    const fresh = (menuQuery.data?.items ?? []).find(
                      (value) => value.id === editingItem.id,
                    );
                    if (fresh) setEditingItem(fresh);
                  });
                }}
              />
            </div>
          )}

          {formError && (
            <p className="rounded-xl bg-rose-50 px-4 py-2.5 text-sm font-bold text-rose-600">
              {formError}
            </p>
          )}

          <div className="flex justify-end gap-3 border-t border-slate-100 pt-4">
            <Button
              variant="outline"
              onClick={() => {
                setItemModal(null);
                setEditingItem(null);
              }}
            >
              إغلاق
            </Button>
            <Button type="submit" disabled={createItem.isPending || updateItem.isPending}>
              {(createItem.isPending || updateItem.isPending) && (
                <Spinner className="h-4 w-4" />
              )}
              {editingItem ? "حفظ التعديلات" : "إضافة المنتج"}
            </Button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog
        open={!!deleting}
        title="حذف منتج"
        message={
          deleting && deleting.optionGroups.length > 0
            ? `"${deleting.name}" يحتوي على إضافات. سيتم حذفه نهائياً مع الإضافات.`
            : `سيتم حذف "${deleting?.name ?? ""}" نهائياً. لا يمكن التراجع عن هذا الإجراء.`
        }
        confirmLabel="حذف نهائي"
        loading={deleteItem.isPending}
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

import { Request, Response } from "express";
import { prisma } from "../config/database";
import { sendError, sendSuccess } from "../utils/response";

const ITEM_INCLUDE = {
  category: { select: { id: true, name: true } },
  optionGroups: {
    orderBy: { position: "asc" as const },
    include: { options: { orderBy: { position: "asc" as const } } },
  },
} as const;

interface OptionInput {
  id?: string;
  name?: unknown;
  price?: unknown;
  position?: unknown;
}

interface GroupInput {
  name?: unknown;
  isRequired?: unknown;
  allowMultiple?: unknown;
  position?: unknown;
  options?: unknown;
}

function serializeGroup(group: {
  id: string;
  name: string;
  isRequired: boolean;
  allowMultiple: boolean;
  position: number;
  options: { id: string; name: string; price: number; position: number }[];
}) {
  return {
    id: group.id,
    name: group.name,
    isRequired: group.isRequired,
    allowMultiple: group.allowMultiple,
    position: group.position,
    options: group.options.map((option) => ({
      id: option.id,
      name: option.name,
      price: option.price,
      position: option.position,
    })),
  };
}

function serializeItem(item: Awaited<ReturnType<typeof findItemOr404>>) {
  return {
    id: item.id,
    name: item.name,
    description: item.description ?? "",
    price: item.basePrice,
    imageUrl: item.image ?? "",
    categoryId: item.categoryId,
    categoryName: item.category.name,
    isAvailable: item.isAvailable,
    position: item.position,
    optionGroups: item.optionGroups.map(serializeGroup),
  };
}

async function findItemOr404(id: string) {
  return prisma.menuItem.findUniqueOrThrow({
    where: { id },
    include: ITEM_INCLUDE,
  });
}

export async function listAdminMenu(
  _req: Request,
  res: Response,
): Promise<void> {
  const [categories, items] = await Promise.all([
    prisma.category.findMany({ orderBy: { position: "asc" } }),
    prisma.menuItem.findMany({
      include: ITEM_INCLUDE,
      orderBy: { position: "asc" },
    }),
  ]);

  sendSuccess(
    res,
    {
      categories: categories.map((category) => ({
        id: category.id,
        name: category.name,
        image: category.image ?? "",
        position: category.position,
      })),
      items: items.map((item) => ({
        id: item.id,
        name: item.name,
        description: item.description ?? "",
        price: item.basePrice,
        imageUrl: item.image ?? "",
        categoryId: item.categoryId,
        categoryName: item.category.name,
        isAvailable: item.isAvailable,
        position: item.position,
        optionGroups: item.optionGroups.map(serializeGroup),
      })),
    },
    "تم جلب المنيو بنجاح",
  );
}

function readItemBody(body: Record<string, unknown>) {
  const name = typeof body.name === "string" ? body.name.trim() : "";
  const price = Number(body.price ?? body.basePrice);

  if (!name) {
    return { error: "اسم المنتج مطلوب" as const };
  }

  if (!Number.isFinite(price) || price < 0) {
    return { error: "سعر المنتج غير صالح" as const };
  }

  return {
    data: {
      name,
      description:
        typeof body.description === "string" ? body.description.trim() : null,
      basePrice: price,
      image: typeof body.image === "string" && body.image ? body.image : null,
      categoryId: String(body.categoryId ?? ""),
      position: Number.isFinite(Number(body.position))
        ? Number(body.position)
        : 0,
      isAvailable:
        typeof body.isAvailable === "boolean" ? body.isAvailable : true,
    },
  };
}

export async function createMenuItem(
  req: Request,
  res: Response,
): Promise<void> {
  const body = (req.body ?? {}) as Record<string, unknown>;
  const parsed = readItemBody(body);

  if ("error" in parsed) {
    sendError(res, parsed.error, 400);
    return;
  }

  const category = await prisma.category.findUnique({
    where: { id: parsed.data.categoryId },
  });

  if (!category) {
    sendError(res, "القسم غير موجود", 404);
    return;
  }

  const item = await prisma.menuItem.create({
    data: parsed.data,
    include: ITEM_INCLUDE,
  });

  sendSuccess(res, { item: serializeItem(item) }, "تمت إضافة المنتج", 201);
}

export async function updateMenuItem(
  req: Request,
  res: Response,
): Promise<void> {
  const id = String(req.params.id);
  const body = (req.body ?? {}) as Record<string, unknown>;
  const parsed = readItemBody(body);

  if ("error" in parsed) {
    sendError(res, parsed.error, 400);
    return;
  }

  const existing = await prisma.menuItem.findUnique({ where: { id } });

  if (!existing) {
    sendError(res, "المنتج غير موجود", 404);
    return;
  }

  const category = await prisma.category.findUnique({
    where: { id: parsed.data.categoryId },
  });

  if (!category) {
    sendError(res, "القسم غير موجود", 404);
    return;
  }

  const item = await prisma.menuItem.update({
    where: { id },
    data: parsed.data,
    include: ITEM_INCLUDE,
  });

  sendSuccess(res, { item: serializeItem(item) }, "تم تحديث المنتج");
}

export async function setMenuItemAvailability(
  req: Request,
  res: Response,
): Promise<void> {
  const id = String(req.params.id);
  const { isAvailable } = (req.body ?? {}) as { isAvailable?: unknown };

  if (typeof isAvailable !== "boolean") {
    sendError(res, "قيمة التوفر غير صالحة", 400);
    return;
  }

  const existing = await prisma.menuItem.findUnique({ where: { id } });

  if (!existing) {
    sendError(res, "المنتج غير موجود", 404);
    return;
  }

  const item = await prisma.menuItem.update({
    where: { id },
    data: { isAvailable },
    include: ITEM_INCLUDE,
  });

  sendSuccess(
    res,
    { item: serializeItem(item) },
    isAvailable ? "تم تفعيل المنتج" : "تم تعطيل المنتج",
  );
}

export async function deleteMenuItem(
  req: Request,
  res: Response,
): Promise<void> {
  const id = String(req.params.id);

  const existing = await prisma.menuItem.findUnique({ where: { id } });

  if (!existing) {
    sendError(res, "المنتج غير موجود", 404);
    return;
  }

  const usedInOrders = await prisma.orderItem.count({
    where: { menuItemId: id },
  });

  if (usedInOrders > 0) {
    await prisma.menuItem.update({
      where: { id },
      data: { isAvailable: false },
    });
    sendSuccess(
      res,
      { deactivated: true },
      "المنتج مستخدم في طلبات سابقة، تم تعطيله بدلاً من حذفه",
    );
    return;
  }

  await prisma.menuItem.delete({ where: { id } });
  sendSuccess(res, { deleted: true }, "تم حذف المنتج");
}

export async function createOptionGroup(
  req: Request,
  res: Response,
): Promise<void> {
  const id = String(req.params.id);
  const body = (req.body ?? {}) as GroupInput;

  const existing = await prisma.menuItem.findUnique({ where: { id } });

  if (!existing) {
    sendError(res, "المنتج غير موجود", 404);
    return;
  }

  const name = typeof body.name === "string" ? body.name.trim() : "";
  if (!name) {
    sendError(res, "اسم مجموعة الخيارات مطلوب", 400);
    return;
  }

  const options = Array.isArray(body.options) ? body.options : [];
  const validOptions = (options as OptionInput[])
    .filter((option) => typeof option.name === "string" && option.name.trim())
    .map((option, index) => ({
      name: String(option.name).trim(),
      price: Number.isFinite(Number(option.price)) ? Number(option.price) : 0,
      position: index,
    }));

  const group = await prisma.optionGroup.create({
    data: {
      menuItemId: id,
      name,
      isRequired: body.isRequired === true,
      allowMultiple: body.allowMultiple === true,
      position: Number.isFinite(Number(body.position))
        ? Number(body.position)
        : 0,
      options: { create: validOptions },
    },
    include: { options: { orderBy: { position: "asc" } } },
  });

  sendSuccess(
    res,
    { group: serializeGroup(group) },
    "تمت إضافة مجموعة الخيارات",
    201,
  );
}

export async function updateOptionGroup(
  req: Request,
  res: Response,
): Promise<void> {
  const groupId = String(req.params.groupId);
  const body = (req.body ?? {}) as GroupInput;

  const existing = await prisma.optionGroup.findUnique({
    where: { id: groupId },
  });

  if (!existing) {
    sendError(res, "مجموعة الخيارات غير موجودة", 404);
    return;
  }

  const name = typeof body.name === "string" ? body.name.trim() : "";
  if (!name) {
    sendError(res, "اسم مجموعة الخيارات مطلوب", 400);
    return;
  }

  const options = Array.isArray(body.options) ? body.options : [];
  const validOptions = (options as OptionInput[])
    .filter((option) => typeof option.name === "string" && option.name.trim())
    .map((option, index) => ({
      name: String(option.name).trim(),
      price: Number.isFinite(Number(option.price)) ? Number(option.price) : 0,
      position: index,
    }));

  await prisma.$transaction([
    prisma.optionItem.deleteMany({ where: { optionGroupId: groupId } }),
    prisma.optionGroup.update({
      where: { id: groupId },
      data: {
        name,
        isRequired: body.isRequired === true,
        allowMultiple: body.allowMultiple === true,
        position: Number.isFinite(Number(body.position))
          ? Number(body.position)
          : existing.position,
        options: { create: validOptions },
      },
    }),
  ]);

  const group = await prisma.optionGroup.findUniqueOrThrow({
    where: { id: groupId },
    include: { options: { orderBy: { position: "asc" } } },
  });

  sendSuccess(res, { group: serializeGroup(group) }, "تم تحديث مجموعة الخيارات");
}

export async function deleteOptionGroup(
  req: Request,
  res: Response,
): Promise<void> {
  const groupId = String(req.params.groupId);

  const existing = await prisma.optionGroup.findUnique({
    where: { id: groupId },
  });

  if (!existing) {
    sendError(res, "مجموعة الخيارات غير موجودة", 404);
    return;
  }

  await prisma.optionGroup.delete({ where: { id: groupId } });
  sendSuccess(res, { deleted: true }, "تم حذف مجموعة الخيارات");
}

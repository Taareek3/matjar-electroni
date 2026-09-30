import { Request, Response } from "express";
import { prisma } from "../config/database";
import { sendError, sendSuccess } from "../utils/response";

export async function listCategories(
  _req: Request,
  res: Response,
): Promise<void> {
  const categories = await prisma.category.findMany({
    orderBy: { position: "asc" },
    include: { _count: { select: { items: true } } },
  });

  sendSuccess(
    res,
    {
      categories: categories.map((category) => ({
        id: category.id,
        name: category.name,
        image: category.image ?? "",
        position: category.position,
        itemsCount: category._count.items,
      })),
    },
    "تم جلب الأقسام بنجاح",
  );
}

export async function createCategory(
  req: Request,
  res: Response,
): Promise<void> {
  const body = (req.body ?? {}) as Record<string, unknown>;
  const name = typeof body.name === "string" ? body.name.trim() : "";

  if (!name) {
    sendError(res, "اسم القسم مطلوب", 400);
    return;
  }

  const existing = await prisma.category.findUnique({ where: { name } });

  if (existing) {
    sendError(res, "يوجد قسم بنفس الاسم", 409);
    return;
  }

  const last = await prisma.category.aggregate({ _max: { position: true } });

  const category = await prisma.category.create({
    data: {
      name,
      image: typeof body.image === "string" && body.image ? body.image : null,
      position: (last._max.position ?? -1) + 1,
    },
  });

  sendSuccess(
    res,
    {
      category: {
        id: category.id,
        name: category.name,
        image: category.image ?? "",
        position: category.position,
        itemsCount: 0,
      },
    },
    "تمت إضافة القسم",
    201,
  );
}

export async function updateCategory(
  req: Request,
  res: Response,
): Promise<void> {
  const id = String(req.params.id);
  const body = (req.body ?? {}) as Record<string, unknown>;

  const existing = await prisma.category.findUnique({ where: { id } });

  if (!existing) {
    sendError(res, "القسم غير موجود", 404);
    return;
  }

  const name = typeof body.name === "string" ? body.name.trim() : "";

  if (!name) {
    sendError(res, "اسم القسم مطلوب", 400);
    return;
  }

  const duplicate = await prisma.category.findFirst({
    where: { name, NOT: { id } },
  });

  if (duplicate) {
    sendError(res, "يوجد قسم بنفس الاسم", 409);
    return;
  }

  const category = await prisma.category.update({
    where: { id },
    data: {
      name,
      image: typeof body.image === "string" ? body.image || null : existing.image,
      position: Number.isFinite(Number(body.position))
        ? Number(body.position)
        : existing.position,
    },
    include: { _count: { select: { items: true } } },
  });

  sendSuccess(
    res,
    {
      category: {
        id: category.id,
        name: category.name,
        image: category.image ?? "",
        position: category.position,
        itemsCount: category._count.items,
      },
    },
    "تم تحديث القسم",
  );
}

export async function deleteCategory(
  req: Request,
  res: Response,
): Promise<void> {
  const id = String(req.params.id);

  const existing = await prisma.category.findUnique({
    where: { id },
    include: { _count: { select: { items: true } } },
  });

  if (!existing) {
    sendError(res, "القسم غير موجود", 404);
    return;
  }

  if (existing._count.items > 0) {
    sendError(res, "لا يمكن حذف قسم يحتوي على منتجات", 400);
    return;
  }

  await prisma.category.delete({ where: { id } });
  sendSuccess(res, { deleted: true }, "تم حذف القسم");
}

export async function reorderCategories(
  req: Request,
  res: Response,
): Promise<void> {
  const { ids } = (req.body ?? {}) as { ids?: unknown };

  if (!Array.isArray(ids) || ids.length === 0) {
    sendError(res, "قائمة الأقسام مطلوبة", 400);
    return;
  }

  await prisma.$transaction(
    ids.map((id, index) =>
      prisma.category.update({
        where: { id: String(id) },
        data: { position: index },
      }),
    ),
  );

  sendSuccess(res, { reordered: true }, "تم إعادة ترتيب الأقسام");
}

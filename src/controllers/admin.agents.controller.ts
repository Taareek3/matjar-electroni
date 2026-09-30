import bcrypt from "bcryptjs";
import { Request, Response } from "express";
import { prisma } from "../config/database";
import { presentUser, SafeUser } from "./auth.controller";
import { Role, User } from "../generated/prisma/client";
import { sendError, sendSuccess } from "../utils/response";

const SALT_ROUNDS = 10;
const EMAIL_REGEX = /^\S+@\S+\.\S+$/;

const VENDOR_ROLES: Role[] = [Role.VENDOR, Role.KITCHEN_STAFF];

interface CreateVendorBody {
  name?: unknown;
  email?: unknown;
  phone?: unknown;
  password?: unknown;
  restaurantName?: unknown;
  avatar?: unknown;
}

interface UpdateVendorBody {
  name?: unknown;
  phone?: unknown;
  password?: unknown;
  restaurantName?: unknown;
  avatar?: unknown;
}

function toVendor(safe: SafeUser & { restaurantName?: string | null }) {
  return {
    id: safe.id,
    name: safe.name,
    email: safe.email,
    phone: safe.phone,
    role: safe.role,
    avatar: safe.avatar,
    restaurantName: safe.restaurantName ?? null,
    vendorId: safe.vendorId,
    createdAt: safe.createdAt,
  };
}

export async function listVendors(req: Request, res: Response): Promise<void> {
  const vendors = await prisma.user.findMany({
    where: { role: { in: VENDOR_ROLES } },
    select: {
      id: true,
      name: true,
      email: true,
      phone: true,
      avatar: true,
      role: true,
      restaurantName: true,
      createdAt: true,
      _count: { select: { agentOrders: true } },
    },
    orderBy: { createdAt: "desc" },
  });

  sendSuccess(
    res,
    { vendors: vendors.map((v) => ({ ...v, vendorId: v.id })) },
    "تم جلب الوكلاء",
  );
}

export async function createVendor(req: Request, res: Response): Promise<void> {
  const { name, email, phone, password, restaurantName, avatar } = (req.body ??
    {}) as CreateVendorBody;

  const nameStr = name ? String(name).trim() : "";
  const emailStr = email ? String(email).trim().toLowerCase() : "";
  const phoneStr = phone ? String(phone).trim() : "";
  const passwordStr = password ? String(password) : "";
  const restaurantStr = restaurantName
    ? String(restaurantName).trim()
    : "";
  const avatarStr = avatar ? String(avatar).trim() : null;

  if (!nameStr || !emailStr || !phoneStr || !passwordStr) {
    sendError(res, "الاسم والبريد وكلمة المرور ورقم الهاتف مطلوبة", 400);
    return;
  }

  if (!EMAIL_REGEX.test(emailStr)) {
    sendError(res, "البريد الإلكتروني غير صالح", 400);
    return;
  }

  if (passwordStr.length < 6) {
    sendError(res, "كلمة المرور يجب ألا تقل عن 6 أحرف", 400);
    return;
  }

  const existing = await prisma.user.findUnique({
    where: { email: emailStr },
  });
  if (existing) {
    sendError(res, "البريد الإلكتروني مسجّل مسبقاً", 409);
    return;
  }

  const hashedPassword = await bcrypt.hash(passwordStr, SALT_ROUNDS);

  const created = await prisma.user.create({
    data: {
      name: nameStr,
      email: emailStr,
      phone: phoneStr,
      password: hashedPassword,
      avatar: avatarStr,
      restaurantName: restaurantStr || null,
      role: Role.VENDOR,
    },
  });

  const user = presentUser(created);
  sendSuccess(
    res,
    { vendor: toVendor(user), user },
    "تم إنشاء حساب الوكيل",
    201,
  );
}

export async function updateVendor(req: Request, res: Response): Promise<void> {
  const id = String(req.params.id);
  const { name, phone, password, restaurantName, avatar } = (req.body ??
    {}) as UpdateVendorBody;

  const existing = await prisma.user.findUnique({ where: { id } });
  if (!existing || !VENDOR_ROLES.includes(existing.role)) {
    sendError(res, "الوكيل غير موجود", 404);
    return;
  }

  const data: Record<string, unknown> = {};

  if (name !== undefined) data.name = String(name).trim();
  if (phone !== undefined) data.phone = String(phone).trim();
  if (avatar !== undefined) data.avatar = String(avatar).trim() || null;
  if (restaurantName !== undefined) {
    data.restaurantName = String(restaurantName).trim() || null;
  }
  if (password !== undefined) {
    const passwordStr = String(password);
    if (passwordStr.length > 0) {
      if (passwordStr.length < 6) {
        sendError(res, "كلمة المرور يجب ألا تقل عن 6 أحرف", 400);
        return;
      }
      data.password = await bcrypt.hash(passwordStr, SALT_ROUNDS);
    }
  }

  const updated = await prisma.user.update({ where: { id }, data });
  const user = presentUser(updated);
  sendSuccess(
    res,
    { vendor: toVendor(user), user },
    "تم تحديث بيانات الوكيل",
  );
}

export async function deleteVendor(req: Request, res: Response): Promise<void> {
  const id = String(req.params.id);

  const existing = await prisma.user.findUnique({ where: { id } });
  if (!existing || !VENDOR_ROLES.includes(existing.role)) {
    sendError(res, "الوكيل غير موجود", 404);
    return;
  }

  const activeOrders = await prisma.order.count({
    where: {
      agentId: id,
      status: { in: ["OUT_FOR_DELIVERY"] },
    },
  });

  if (activeOrders > 0) {
    sendError(res, "لا يمكن حذف الوكيل لديه طلبات قيد التوصيل", 409);
    return;
  }

  await prisma.order.updateMany({
    where: { agentId: id },
    data: { agentId: null },
  });

  await prisma.user.delete({ where: { id } });
  sendSuccess(res, null, "تم حذف الوكيل");
}

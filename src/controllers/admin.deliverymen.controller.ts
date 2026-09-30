import bcrypt from "bcryptjs";
import { Request, Response } from "express";
import { prisma } from "../config/database";
import { presentUser, SafeUser } from "./auth.controller";
import { Role, User } from "../generated/prisma/client";
import { sendError, sendSuccess } from "../utils/response";

const SALT_ROUNDS = 10;
const EMAIL_REGEX = /^\S+@\S+\.\S+$/;

interface CreateDeliveryManBody {
  name?: unknown;
  email?: unknown;
  phone?: unknown;
  password?: unknown;
  avatar?: unknown;
}

interface UpdateDeliveryManBody {
  name?: unknown;
  phone?: unknown;
  password?: unknown;
  avatar?: unknown;
}

function toDeliveryMan(
  user: User | (SafeUser & { createdAt?: Date | string }),
) {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    phone: user.phone,
    avatar: user.avatar,
    role: user.role,
    createdAt: user.createdAt,
  };
}

export async function listDeliveryMen(
  req: Request,
  res: Response,
): Promise<void> {
  const deliveryMen = await prisma.user.findMany({
    where: { role: Role.AGENT },
    select: {
      id: true,
      name: true,
      email: true,
      phone: true,
      avatar: true,
      role: true,
      createdAt: true,
      _count: { select: { deliveryOrders: true } },
    },
    orderBy: { createdAt: "desc" },
  });

  sendSuccess(res, { deliveryMen }, "تم جلب عمال التوصيل");
}

export async function createDeliveryMan(
  req: Request,
  res: Response,
): Promise<void> {
  const { name, email, phone, password, avatar } = (req.body ??
    {}) as CreateDeliveryManBody;

  const nameStr = name ? String(name).trim() : "";
  const emailStr = email ? String(email).trim().toLowerCase() : "";
  const phoneStr = phone ? String(phone).trim() : "";
  const passwordStr = password ? String(password) : "";
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
      role: Role.AGENT,
    },
  });

  sendSuccess(
    res,
    {
      deliveryMan: toDeliveryMan(created),
      user: presentUser(created),
    },
    "تم إنشاء حساب عامل التوصيل",
    201,
  );
}

export async function updateDeliveryMan(
  req: Request,
  res: Response,
): Promise<void> {
  const id = String(req.params.id);
  const { name, phone, password, avatar } = (req.body ??
    {}) as UpdateDeliveryManBody;

  const existing = await prisma.user.findUnique({ where: { id } });
  if (!existing || existing.role !== Role.AGENT) {
    sendError(res, "عامل التوصيل غير موجود", 404);
    return;
  }

  const data: Record<string, unknown> = {};

  if (name !== undefined) data.name = String(name).trim();
  if (phone !== undefined) data.phone = String(phone).trim();
  if (avatar !== undefined) data.avatar = String(avatar).trim() || null;
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

  sendSuccess(
    res,
    {
      deliveryMan: toDeliveryMan(updated),
      user: presentUser(updated),
    },
    "تم تحديث بيانات عامل التوصيل",
  );
}

export async function deleteDeliveryMan(
  req: Request,
  res: Response,
): Promise<void> {
  const id = String(req.params.id);

  const existing = await prisma.user.findUnique({ where: { id } });
  if (!existing || existing.role !== Role.AGENT) {
    sendError(res, "عامل التوصيل غير موجود", 404);
    return;
  }

  const activeOrders = await prisma.order.count({
    where: {
      deliveryManId: id,
      status: { in: ["OUT_FOR_DELIVERY"] },
    },
  });

  if (activeOrders > 0) {
    sendError(
      res,
      "لا يمكن حذف عامل التوصيل لديه طلبات قيد التوصيل",
      409,
    );
    return;
  }

  await prisma.order.updateMany({
    where: { deliveryManId: id },
    data: { deliveryManId: null },
  });

  await prisma.user.delete({ where: { id } });
  sendSuccess(res, null, "تم حذف عامل التوصيل");
}

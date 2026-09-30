import bcrypt from "bcryptjs";
import { Request, Response } from "express";
import jwt, { SignOptions } from "jsonwebtoken";
import { prisma } from "../config/database";
import env from "../config/env";
import { Role, User } from "../generated/prisma/client";
import { sendError, sendSuccess } from "../utils/response";

const SALT_ROUNDS = 10;
const EMAIL_REGEX = /^\S+@\S+\.\S+$/;
const MIN_PASSWORD_LENGTH = 6;

export type SafeUser = Omit<User, "password"> & { vendorId: string | null };

const VENDOR_ROLES: Role[] = [Role.VENDOR, Role.AGENT, Role.KITCHEN_STAFF];

export function presentUser(user: User): SafeUser {
  const { password: _password, ...safeUser } = user;
  return {
    ...safeUser,
    vendorId: VENDOR_ROLES.includes(user.role) ? user.id : null,
  };
}

interface RegisterBody {
  name?: unknown;
  firstName?: unknown;
  lastName?: unknown;
  email?: unknown;
  phone?: unknown;
  password?: unknown;
  country?: unknown;
  city?: unknown;
  addressLine?: unknown;
}

interface LoginBody {
  email?: unknown;
  password?: unknown;
}

interface UpdateMeBody {
  firstName?: unknown;
  lastName?: unknown;
  phone?: unknown;
  country?: unknown;
  city?: unknown;
  addressLine?: unknown;
}

function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

function signToken(user: User): string {
  return jwt.sign(
    { userId: user.id, email: user.email, role: user.role },
    env.JWT_SECRET,
    { expiresIn: env.JWT_EXPIRES_IN as SignOptions["expiresIn"] },
  );
}

export async function register(req: Request, res: Response): Promise<void> {
  const {
    name,
    firstName,
    lastName,
    email,
    phone,
    password,
    country,
    city,
    addressLine,
  } = (req.body ?? {}) as RegisterBody;

  const firstNameStr = firstName ? String(firstName).trim() : "";
  const lastNameStr = lastName ? String(lastName).trim() : "";
  const nameStr =
    name && String(name).trim()
      ? String(name).trim()
      : [firstNameStr, lastNameStr].filter(Boolean).join(" ");
  const emailStr = email ? normalizeEmail(String(email)) : "";
  const passwordStr = password ? String(password) : "";
  const phoneStr = phone ? String(phone).trim() : null;
  const countryStr =
    country && String(country).trim() ? String(country).trim() : "السعودية";
  const cityStr = city && String(city).trim() ? String(city).trim() : null;
  const addressLineStr =
    addressLine && String(addressLine).trim()
      ? String(addressLine).trim()
      : null;

  if (!nameStr || !emailStr || !passwordStr) {
    sendError(res, "الاسم والبريد الإلكتروني وكلمة المرور مطلوبة", 400);
    return;
  }

  if (!firstNameStr || !lastNameStr) {
    sendError(res, "الاسم الأول والاسم الأخير مطلوبان", 400);
    return;
  }

  if (nameStr.length < 2) {
    sendError(res, "الاسم قصير جداً", 400);
    return;
  }

  if (!EMAIL_REGEX.test(emailStr)) {
    sendError(res, "البريد الإلكتروني غير صالح", 400);
    return;
  }

  if (!phoneStr) {
    sendError(res, "رقم الهاتف مطلوب", 400);
    return;
  }

  if (passwordStr.length < MIN_PASSWORD_LENGTH) {
    sendError(
      res,
      `كلمة المرور يجب ألا تقل عن ${MIN_PASSWORD_LENGTH} أحرف`,
      400,
    );
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

  const user = await prisma.user.create({
    data: {
      name: nameStr,
      firstName: firstNameStr,
      lastName: lastNameStr,
      email: emailStr,
      phone: phoneStr,
      password: hashedPassword,
      country: countryStr,
      city: cityStr,
      addressLine: addressLineStr,
      role: Role.CUSTOMER,
    },
  });

  sendSuccess(
    res,
    { token: signToken(user), user: presentUser(user) },
    "تم إنشاء الحساب بنجاح",
    201,
  );
}

export async function login(req: Request, res: Response): Promise<void> {
  const { email, password } = (req.body ?? {}) as LoginBody;

  if (!email || !password) {
    sendError(res, "البريد الإلكتروني وكلمة المرور مطلوبان", 400);
    return;
  }

  const user = await prisma.user.findUnique({
    where: { email: normalizeEmail(String(email)) },
  });

  if (!user) {
    sendError(res, "بيانات الدخول غير صحيحة", 401);
    return;
  }

  const isValid = await bcrypt.compare(String(password), user.password);

  if (!isValid) {
    sendError(res, "بيانات الدخول غير صحيحة", 401);
    return;
  }

  sendSuccess(
    res,
    { token: signToken(user), user: presentUser(user) },
    "تم تسجيل الدخول بنجاح",
  );
}

export async function me(req: Request, res: Response): Promise<void> {
  const userId = req.user?.userId;

  if (!userId) {
    sendError(res, "غير موثق", 401);
    return;
  }

  const user = await prisma.user.findUnique({ where: { id: userId } });

  if (!user) {
    sendError(res, "المستخدم غير موجود", 404);
    return;
  }

  sendSuccess(res, { user: presentUser(user) }, "تم جلب بيانات المستخدم");
}

export async function updateMe(req: Request, res: Response): Promise<void> {
  const userId = req.user?.userId;

  if (!userId) {
    sendError(res, "غير موثق", 401);
    return;
  }

  const existing = await prisma.user.findUnique({ where: { id: userId } });

  if (!existing) {
    sendError(res, "المستخدم غير موجود", 404);
    return;
  }

  const body = (req.body ?? {}) as UpdateMeBody;

  const data: {
    firstName?: string;
    lastName?: string;
    name?: string;
    phone?: string;
    country?: string;
    city?: string | null;
    addressLine?: string | null;
  } = {};

  const firstNameStr =
    body.firstName !== undefined
      ? String(body.firstName).trim()
      : existing.firstName ?? "";
  const lastNameStr =
    body.lastName !== undefined
      ? String(body.lastName).trim()
      : existing.lastName ?? "";

  if (body.firstName !== undefined || body.lastName !== undefined) {
    if (!firstNameStr || !lastNameStr) {
      sendError(res, "الاسم الأول والاسم الأخير مطلوبان", 400);
      return;
    }
    data.firstName = firstNameStr;
    data.lastName = lastNameStr;
    data.name = `${firstNameStr} ${lastNameStr}`;
  }

  if (body.phone !== undefined) {
    const phoneStr = String(body.phone).trim();
    if (!phoneStr) {
      sendError(res, "رقم الهاتف مطلوب", 400);
      return;
    }
    data.phone = phoneStr;
  }

  if (body.country !== undefined) {
    const countryStr = String(body.country).trim();
    if (countryStr && countryStr !== "السعودية") {
      sendError(res, "البلد ثابت: السعودية", 400);
      return;
    }
    data.country = "السعودية";
  }

  if (body.city !== undefined) {
    data.city = String(body.city).trim() || null;
  }

  if (body.addressLine !== undefined) {
    data.addressLine = String(body.addressLine).trim() || null;
  }

  const user = await prisma.user.update({ where: { id: userId }, data });

  sendSuccess(res, { user: presentUser(user) }, "تم تحديث بيانات الحساب");
}

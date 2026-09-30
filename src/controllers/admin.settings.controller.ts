import { Request, Response } from "express";
import { prisma } from "../config/database";
import { sendError, sendSuccess } from "../utils/response";

interface SettingsShape {
  acceptOrders: boolean;
  deliveryEnabled: boolean;
  deliveryFee: number;
  restaurantName: string;
  phone: string;
  address: string;
}

const DEFAULTS: SettingsShape = {
  acceptOrders: true,
  deliveryEnabled: true,
  deliveryFee: 2.99,
  restaurantName: "مطعم بينا فلاو",
  phone: "0912345678",
  address: "شارع التحرير - وسط المدينة",
};

const KEYS = Object.keys(DEFAULTS) as (keyof SettingsShape)[];

function parseValue(key: keyof SettingsShape, raw: string): SettingsShape[keyof SettingsShape] {
  if (key === "deliveryFee") {
    const value = Number(raw);
    return Number.isFinite(value) && value >= 0 ? value : DEFAULTS[key];
  }
  if (key === "acceptOrders" || key === "deliveryEnabled") {
    return raw === "true";
  }
  return raw;
}

export async function getSettings(
  _req: Request,
  res: Response,
): Promise<void> {
  const rows = await prisma.setting.findMany({
    where: { key: { in: KEYS } },
  });

  const stored = new Map(rows.map((row) => [row.key, row.value]));

  const settings: SettingsShape = {
    acceptOrders: DEFAULTS.acceptOrders,
    deliveryEnabled: DEFAULTS.deliveryEnabled,
    deliveryFee: DEFAULTS.deliveryFee,
    restaurantName: DEFAULTS.restaurantName,
    phone: DEFAULTS.phone,
    address: DEFAULTS.address,
  };

  for (const key of KEYS) {
    const raw = stored.get(key);
    if (raw !== undefined) {
      (settings as unknown as Record<string, unknown>)[key] = parseValue(key, raw);
    }
  }

  sendSuccess(res, { settings }, "تم جلب الإعدادات بنجاح");
}

export async function updateSettings(
  req: Request,
  res: Response,
): Promise<void> {
  const body = (req.body ?? {}) as Record<string, unknown>;

  const rows = await prisma.setting.findMany({
    where: { key: { in: KEYS } },
  });
  const current = new Map(rows.map((row) => [row.key, row.value]));

  const next: SettingsShape = {
    acceptOrders: DEFAULTS.acceptOrders,
    deliveryEnabled: DEFAULTS.deliveryEnabled,
    deliveryFee: DEFAULTS.deliveryFee,
    restaurantName: DEFAULTS.restaurantName,
    phone: DEFAULTS.phone,
    address: DEFAULTS.address,
  };

  for (const key of KEYS) {
    const raw = current.get(key);
    if (raw !== undefined) {
      (next as unknown as Record<string, unknown>)[key] = parseValue(key, raw);
    }
  }

  if (typeof body.acceptOrders === "boolean") {
    next.acceptOrders = body.acceptOrders;
  }
  if (typeof body.deliveryEnabled === "boolean") {
    next.deliveryEnabled = body.deliveryEnabled;
  }
  if (body.deliveryFee !== undefined) {
    const fee = Number(body.deliveryFee);
    if (!Number.isFinite(fee) || fee < 0) {
      sendError(res, "رسوم التوصيل غير صالحة", 400);
      return;
    }
    next.deliveryFee = fee;
  }
  if (typeof body.restaurantName === "string" && body.restaurantName.trim()) {
    next.restaurantName = body.restaurantName.trim();
  }
  if (typeof body.phone === "string") {
    next.phone = body.phone.trim();
  }
  if (typeof body.address === "string") {
    next.address = body.address.trim();
  }

  await prisma.$transaction(
    KEYS.map((key) =>
      prisma.setting.upsert({
        where: { key },
        create: { key, value: String(next[key]) },
        update: { value: String(next[key]) },
      }),
    ),
  );

  sendSuccess(res, { settings: next }, "تم حفظ الإعدادات بنجاح");
}

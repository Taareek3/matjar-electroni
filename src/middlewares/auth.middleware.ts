import { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";
import env from "../config/env";
import { Role } from "../generated/prisma/client";
import { sendError } from "../utils/response";

export interface AuthPayload {
  userId: string;
  email: string;
  role: Role;
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthPayload;
    }
  }
}

export function authenticate(
  req: Request,
  res: Response,
  next: NextFunction,
): void {
  const header = req.headers.authorization;

  if (!header || !header.startsWith("Bearer ")) {
    sendError(res, "رمز الوصول مفقود", 401);
    return;
  }

  const token = header.slice(7);

  try {
    const decoded = jwt.verify(token, env.JWT_SECRET) as AuthPayload;

    if (!decoded.userId) {
      sendError(res, "الرمز غير صالح", 401);
      return;
    }

    req.user = {
      userId: decoded.userId,
      email: decoded.email,
      role: decoded.role,
    };
    next();
  } catch {
    sendError(res, "رمز غير صالح أو منتهي الصلاحية", 401);
  }
}

export function requireRole(...roles: Role[]) {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) {
      sendError(res, "غير موثق", 401);
      return;
    }

    if (!roles.includes(req.user.role)) {
      sendError(res, "ليس لديك صلاحية للوصول", 403);
      return;
    }

    next();
  };
}

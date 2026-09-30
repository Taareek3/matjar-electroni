import { Response } from "express";

export function sendSuccess(
  res: Response,
  data: unknown,
  message = "success",
  statusCode = 200,
): void {
  res.status(statusCode).json({
    success: true,
    status: "success",
    message,
    data,
  });
}

export function sendError(
  res: Response,
  message = "error",
  statusCode = 500,
): void {
  res.status(statusCode).json({
    success: false,
    status: "error",
    message,
  });
}

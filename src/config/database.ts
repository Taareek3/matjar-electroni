import { PrismaBetterSqlite3 } from "@prisma/adapter-better-sqlite3";
import { PrismaClient } from "../generated/prisma/client";
import env from "./env";

function resolveSqliteUrl(url: string): string {
  if (!url) return ":memory:";
  return url.startsWith("file:") ? url.slice("file:".length) : url;
}

const adapter = new PrismaBetterSqlite3({ url: resolveSqliteUrl(env.DATABASE_URL) });

export const prisma = new PrismaClient({ adapter });

export async function connectDatabase(): Promise<void> {
  if (!env.DATABASE_URL) {
    console.warn("⚠️  DATABASE_URL is not set — skipping database connection");
    return;
  }

  try {
    await prisma.$connect();
    console.log("✅ Database connected");
  } catch (error) {
    console.warn("⚠️  Database connection failed (server continues):", error);
  }
}

export async function disconnectDatabase(): Promise<void> {
  await prisma.$disconnect();
}

import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "../generated/prisma/client";
import env from "./env";

const adapter = new PrismaPg({ connectionString: env.DATABASE_URL });

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

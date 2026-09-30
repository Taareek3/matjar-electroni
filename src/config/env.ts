import dotenv from "dotenv";

dotenv.config();

const env = {
  NODE_ENV: process.env.NODE_ENV ?? "development",
  PORT: Number(process.env.PORT ?? 5000),
  DATABASE_URL: process.env.DATABASE_URL ?? "",
  JWT_SECRET: process.env.JWT_SECRET ?? "change-me-in-production",
  JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN ?? "1d",
};

export type Env = typeof env;

export default env;

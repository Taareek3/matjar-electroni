export function resolveDatabaseUrl(): string {
  const direct =
    process.env["DATABASE_URL"] ||
    process.env["POSTGRES_URL"] ||
    process.env["POSTGRESQL_URL"] ||
    process.env["PG_URL"] ||
    process.env["DATABASE_CONNECTION_STRING"] ||
    process.env["DB_URL"];

  if (direct) return direct;

  const host = process.env["PGHOST"];
  const database = process.env["PGDATABASE"];

  if (host && database) {
    const user = process.env["PGUSER"] ?? "postgres";
    const password = process.env["PGPASSWORD"] ?? "";
    const port = process.env["PGPORT"] ?? "5432";
    return `postgresql://${encodeURIComponent(user)}:${encodeURIComponent(password)}@${host}:${port}/${database}`;
  }

  return "";
}

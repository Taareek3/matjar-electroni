import { startServer } from "./app";
import { connectDatabase, disconnectDatabase } from "./config/database";

async function bootstrap(): Promise<void> {
  try {
    await connectDatabase();
    startServer();
  } catch (error) {
    console.error("❌ Failed to start server:", error);
    process.exit(1);
  }
}

process.on("SIGINT", async () => {
  console.log("\n🛑 Shutting down...");
  await disconnectDatabase();
  process.exit(0);
});

process.on("SIGTERM", async () => {
  await disconnectDatabase();
  process.exit(0);
});

void bootstrap();

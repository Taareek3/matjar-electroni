import cors from "cors";
import express, { Express } from "express";
import env from "./config/env";
import { errorHandler, notFoundHandler } from "./middlewares/error.middleware";
import adminRoutes from "./routes/admin.routes";
import agentRoutes from "./routes/agent.routes";
import authRoutes from "./routes/auth.routes";
import deliveryRoutes from "./routes/delivery.routes";
import healthRoutes from "./routes/health.routes";
import menuRoutes from "./routes/menu.routes";
import ordersRoutes from "./routes/orders.routes";
import settingsRoutes from "./routes/settings.routes";

const app: Express = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use("/api", healthRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/menu", menuRoutes);
app.use("/api/orders", ordersRoutes);
app.use("/api/settings", settingsRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/agent", agentRoutes);
app.use("/api/delivery", deliveryRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

export function startServer(): void {
  app.listen(env.PORT, () => {
    console.log(`🚀 Server running on http://localhost:${env.PORT}`);
    console.log(`❤️  Health check: http://localhost:${env.PORT}/api/health`);
  });
}

export default app;

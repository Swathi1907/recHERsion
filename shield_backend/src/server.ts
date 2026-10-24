import { app } from "./app";
import { env } from "./config/env";

const server = app.listen(env.port, "0.0.0.0", () => {
  console.log(`SHIELD API running on http://localhost:${env.port}`);
  console.log(`Health check: http://localhost:${env.port}/api/health`);
});

function shutdown(signal: string) {
  console.log(`${signal} received. Shutting down SHIELD API...`);
  server.close(() => process.exit(0));
}

process.on("SIGINT", () => shutdown("SIGINT"));
process.on("SIGTERM", () => shutdown("SIGTERM"));

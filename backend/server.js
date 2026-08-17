/**
 * server.js
 * Application entry point: security middleware, HTTPS-friendly headers,
 * rate limiting, request logging, route mounting, and the central error
 * handler.
 *
 * Encryption in transit: this app should sit behind a TLS-terminating
 * reverse proxy (nginx/IIS) or run with an HTTPS server directly in
 * production. helmet() + hsts below assume TLS is present; see the
 * "Encryption in transit" note in README.md.
 */
require("dotenv").config();
const express = require("express");
const helmet = require("helmet");
const cors = require("cors");
const rateLimit = require("express-rate-limit");

const logger = require("./config/logger");
const { testConnection } = require("./config/db");
const requestLogger = require("./middleware/requestLogger.middleware");
const errorHandler = require("./middleware/errorHandler.middleware");
const apiRoutes = require("./routes");
const { startScheduler } = require("./services/capture/scheduler");
const { startScheduler: startBackupScheduler } = require("./services/backup/scheduler");
const { startScheduler: startWorkflowScheduler } = require("./services/workflow/scheduler");

const app = express();

app.use(
  helmet({
    contentSecurityPolicy: false, // configure per-frontend if serving HTML from this app
  }),
);
app.use(
  helmet.hsts({ maxAge: 63072000, includeSubDomains: true, preload: true }),
);

app.use(
  cors({
    origin: process.env.CLIENT_URL || "*",
    credentials: true,
  }),
);

app.use(express.json({ limit: "2mb" }));
app.use(express.urlencoded({ extended: true }));
app.use(requestLogger);

const limiter = rateLimit({
  windowMs: Number(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: Number(process.env.RATE_LIMIT_MAX) || 300,
  standardHeaders: true,
  legacyHeaders: false,
});
app.use("/api", limiter);

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
});
app.use("/api/auth", authLimiter);

app.get("/health", (req, res) =>
  res.json({
    status: "ok",
    service: "pspf-edms-api",
    time: new Date().toISOString(),
  }),
);

app.use("/api", apiRoutes);

app.use((req, res) =>
  res.status(404).json({ success: false, message: "Not found" }),
);
app.use(errorHandler);

const PORT = process.env.PORT || 4000;

(async () => {
  try {
    await testConnection(logger);
    app.listen(PORT, () =>
      logger.info(`PSPF EDMS API listening on port ${PORT}`, {
        env: process.env.NODE_ENV,
      }),
    );
    await startScheduler();
    startBackupScheduler();
    startWorkflowScheduler();
  } catch (err) {
    logger.error("Failed to start server — check DB configuration", {
      error: err.message,
    });
    process.exit(1);
  }
})();

process.on("unhandledRejection", (reason) =>
  logger.error("Unhandled promise rejection", {
    reason: reason && reason.stack,
  }),
);
process.on("uncaughtException", (err) =>
  logger.error("Uncaught exception", { error: err.stack }),
);

module.exports = app;

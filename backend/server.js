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
const { startScheduler: startLicenseScheduler } = require("./services/license/scheduler");

const app = express();

// Express auto-computes an ETag from the response body by default, with no
// Cache-Control sent alongside it — the browser's HTTP cache is then free to
// serve (or conditionally-revalidate and still reuse) a prior response for
// the same URL regardless of which user/session made the request. Every
// endpoint here returns per-user, RBAC/ACL-filtered data from the same small
// set of URLs (GET /api/documents with no query params, etc.), so that's a
// real bug, not just an inefficiency — confirmed live: sign in as one role,
// view Repository, sign out, sign in as a different role, and the old
// response (or an empty one from the gap in between) keeps showing until a
// request with different query params forces a cache miss. Disable etag
// globally and mark every /api response uncacheable so the browser always
// re-fetches.
app.set("etag", false);
app.use("/api", (req, res, next) => {
  res.set("Cache-Control", "no-store");
  next();
});

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

const platformAdminLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
});
app.use("/api/platform-admin", platformAdminLimiter);

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
    startLicenseScheduler();
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

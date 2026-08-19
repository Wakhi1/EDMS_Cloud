/**
 * server.js — PSPF EDMS Documentation Portal entry point.
 * Serves the JSON API under /api/* AND the static frontend (the
 * docs site itself) — one process, one deployable, genuinely standalone.
 */
require('dotenv').config();
const path = require('path');
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

const logger = require('./config/logger');
const { testConnection } = require('./config/db');
const requestLogger = require('./middleware/requestLogger.middleware');
const errorHandler = require('./middleware/errorHandler.middleware');
const apiRoutes = require('./routes');

const app = express();

app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors({ origin: process.env.CLIENT_URL || '*', credentials: true }));
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(requestLogger);

const limiter = rateLimit({
  windowMs: Number(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: Number(process.env.RATE_LIMIT_MAX) || 300,
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api', limiter);

app.get('/health', (req, res) => res.json({ status: 'ok', service: 'pspf-edms-docs-portal', time: new Date().toISOString() }));

app.use('/api', apiRoutes);

// The docs site itself (public/ built from ../frontend at deploy time — see README).
app.use(express.static(path.join(__dirname, '..', 'frontend')));
app.get('*', (req, res, next) => {
  if (req.path.startsWith('/api')) return next();
  res.sendFile(path.join(__dirname, '..', 'frontend', 'index.html'));
});

app.use(errorHandler);

const PORT = process.env.PORT || 5000;

(async () => {
  try {
    await testConnection(logger);
    app.listen(PORT, () => logger.info(`PSPF EDMS Docs Portal listening on port ${PORT}`));
  } catch (err) {
    logger.error('Failed to start — check DB configuration', { error: err.message });
    process.exit(1);
  }
})();

process.on('unhandledRejection', (reason) => logger.error('Unhandled promise rejection', { reason: reason && reason.stack }));
process.on('uncaughtException', (err) => logger.error('Uncaught exception', { error: err.stack }));

module.exports = app;

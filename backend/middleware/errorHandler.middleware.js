/**
 * middleware/errorHandler.middleware.js
 * Central error handler. Must be registered last in server.js.
 */
const logger = require('../config/logger');
const { fail } = require('../utils/apiResponse');

module.exports = (err, req, res, next) => {
  logger.error(err.message, {
    stack: err.stack,
    path: req.originalUrl,
    method: req.method,
    userId: req.user ? req.user.id : null,
  });

  const status = err.status || 500;
  const message = process.env.NODE_ENV === 'production' && status === 500
    ? 'Internal server error'
    : err.message;

  return fail(res, message, status, err.errors || null);
};

/**
 * config/logger.js
 * Central Winston logger. Writes structured JSON logs to daily-rotated
 * files (logs/app-*.log, logs/error-*.log) and pretty console output in
 * development. Every layer of the app (routes, services, middleware)
 * imports this single logger instance.
 */
const path = require('path');
const winston = require('winston');
require('winston-daily-rotate-file');

const { combine, timestamp, printf, colorize, json, errors } = winston.format;

const logsDir = path.join(__dirname, '..', 'logs');

const consoleFormat = combine(
  colorize(),
  timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  printf(({ level, message, timestamp: ts, ...meta }) => {
    const metaStr = Object.keys(meta).length ? ` ${JSON.stringify(meta)}` : '';
    return `[${ts}] ${level}: ${message}${metaStr}`;
  })
);

const fileRotateTransport = new winston.transports.DailyRotateFile({
  filename: path.join(logsDir, 'app-%DATE%.log'),
  datePattern: 'YYYY-MM-DD',
  maxSize: '20m',
  maxFiles: '30d',
  level: 'info',
});

const errorRotateTransport = new winston.transports.DailyRotateFile({
  filename: path.join(logsDir, 'error-%DATE%.log'),
  datePattern: 'YYYY-MM-DD',
  maxSize: '20m',
  maxFiles: '90d',
  level: 'error',
});

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: combine(errors({ stack: true }), timestamp(), json()),
  defaultMeta: { service: 'pspf-edms-api' },
  transports: [fileRotateTransport, errorRotateTransport],
  exceptionHandlers: [
    new winston.transports.DailyRotateFile({
      filename: path.join(logsDir, 'exceptions-%DATE%.log'),
      datePattern: 'YYYY-MM-DD',
    }),
  ],
  rejectionHandlers: [
    new winston.transports.DailyRotateFile({
      filename: path.join(logsDir, 'rejections-%DATE%.log'),
      datePattern: 'YYYY-MM-DD',
    }),
  ],
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({ format: consoleFormat }));
}

module.exports = logger;

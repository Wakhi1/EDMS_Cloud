/**
 * config/logger.js — same Winston pattern as the EDMS backend: daily
 * rotated JSON files, pretty console in development.
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

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: combine(errors({ stack: true }), timestamp(), json()),
  defaultMeta: { service: 'pspf-edms-docs-portal' },
  transports: [
    new winston.transports.DailyRotateFile({ filename: path.join(logsDir, 'app-%DATE%.log'), datePattern: 'YYYY-MM-DD', maxSize: '20m', maxFiles: '30d' }),
    new winston.transports.DailyRotateFile({ filename: path.join(logsDir, 'error-%DATE%.log'), datePattern: 'YYYY-MM-DD', level: 'error', maxSize: '20m', maxFiles: '90d' }),
  ],
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({ format: consoleFormat }));
}

module.exports = logger;

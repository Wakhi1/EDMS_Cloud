/**
 * config/db.js — MySQL connection pool for the docs portal's OWN
 * database (pspf_edms_docs). Never points at the EDMS database — the
 * two systems only ever talk over HTTP, via the sandbox proxy.
 */
require('dotenv').config();
const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: process.env.DB_HOST || '127.0.0.1',
  port: Number(process.env.DB_PORT) || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'pspf_edms_docs',
  waitForConnections: true,
  connectionLimit: Number(process.env.DB_CONNECTION_LIMIT) || 10,
  queueLimit: 0,
  dateStrings: true,
});

async function testConnection(logger) {
  const conn = await pool.getConnection();
  await conn.ping();
  conn.release();
  if (logger) logger.info('MySQL connection pool established (pspf_edms_docs)');
}

module.exports = { pool, testConnection };

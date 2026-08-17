/**
 * config/db.js
 * MySQL connection pool (mysql2/promise), tuned for XAMPP-hosted MySQL.
 */
require('dotenv').config();
const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: process.env.DB_HOST || '127.0.0.1',
  port: Number(process.env.DB_PORT) || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'pspf_edms',
  waitForConnections: true,
  connectionLimit: Number(process.env.DB_CONNECTION_LIMIT) || 10,
  queueLimit: 0,
  dateStrings: true,
});

async function testConnection(logger) {
  try {
    const conn = await pool.getConnection();
    await conn.ping();
    conn.release();
    if (logger) logger.info('MySQL connection pool established');
  } catch (err) {
    if (logger) logger.error('MySQL connection failed', { error: err.message });
    throw err;
  }
}

module.exports = { pool, testConnection };

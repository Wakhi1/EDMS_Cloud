/**
 * services/settings.service.js
 * Thin read helper over `system_settings`, so every enforcement point
 * (watermarking, redaction, export limits, confidential-reason gating)
 * reads the live table instead of hard-coding a value — no caching, since
 * this app has no other cache layer and settings changes should apply on
 * the very next request.
 */
const { pool } = require('../config/db');

async function getSetting(key, fallback = null) {
  const [[row]] = await pool.query('SELECT setting_value FROM system_settings WHERE setting_key = ?', [key]);
  return row ? row.setting_value : fallback;
}

async function getSettingBool(key, fallback = false) {
  const value = await getSetting(key, null);
  if (value === null) return fallback;
  return value === 'true' || value === '1';
}

async function getSettingInt(key, fallback = 0) {
  const value = await getSetting(key, null);
  const parsed = Number.parseInt(value, 10);
  return Number.isNaN(parsed) ? fallback : parsed;
}

module.exports = { getSetting, getSettingBool, getSettingInt };

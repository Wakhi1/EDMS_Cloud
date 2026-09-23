/**
 * services/sqlDump.service.js
 * Pure-Node database dump/restore over the app's own mysql2 pool — the
 * fallback backup.service.js uses when the mysqldump/mysql binaries aren't
 * available or can't run (shared cPanel hosting such as Namecheap: no
 * XAMPP paths, often no shell binaries, and no PROCESS privilege for
 * mysqldump). Needs nothing beyond the DB credentials the app already has.
 *
 * dumpToFile writes a mysqldump-compatible script (DROP/CREATE per table,
 * batched INSERTs, views and triggers), so its output restores with either
 * this module or the mysql CLI. restoreFromFile runs any such script —
 * including real mysqldump output — statement by statement, honouring
 * quotes, comments and DELIMITER blocks.
 */
const fs = require('fs');
const fsp = require('fs/promises');
const { pool } = require('../config/db');

const ROWS_PER_SELECT = 1000;
const ROWS_PER_INSERT = 100;

const quoteId = (name) => `\`${String(name).replace(/`/g, '``')}\``;

/** SQL literal for one column value, as read with dateStrings (dates arrive as strings). */
function literal(value) {
  if (value === null || value === undefined) return 'NULL';
  if (Buffer.isBuffer(value)) return value.length ? `0x${value.toString('hex')}` : "''";
  if (typeof value === 'number' || typeof value === 'bigint') return String(value);
  if (typeof value === 'boolean') return value ? '1' : '0';
  if (typeof value === 'object') return pool.escape(JSON.stringify(value)); // JSON columns
  return pool.escape(String(value));
}

function writeLine(stream, text) {
  return new Promise((resolve, reject) => {
    stream.write(`${text}\n`, (err) => (err ? reject(err) : resolve()));
  });
}

/**
 * @param {string} outFilePath
 * @param {{ ignoreTables?: string[] }} [options]
 */
async function dumpToFile(outFilePath, { ignoreTables = [] } = {}) {
  const ignored = new Set(ignoreTables);
  const out = fs.createWriteStream(outFilePath);
  const conn = await pool.getConnection();
  try {
    // One consistent snapshot of every table, like mysqldump --single-transaction.
    await conn.query('SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ');
    await conn.query('START TRANSACTION WITH CONSISTENT SNAPSHOT');

    await writeLine(out, `-- PSPF EDMS database dump (Node engine) ${new Date().toISOString()}`);
    await writeLine(out, 'SET NAMES utf8mb4;');
    await writeLine(out, 'SET FOREIGN_KEY_CHECKS = 0;');
    await writeLine(out, "SET SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO';");

    const [objects] = await conn.query('SHOW FULL TABLES');
    const nameKey = Object.keys(objects[0] || {}).find((k) => k.startsWith('Tables_in_'));
    const tables = objects.filter((o) => o.Table_type === 'BASE TABLE').map((o) => o[nameKey]).filter((t) => !ignored.has(t));
    const views = objects.filter((o) => o.Table_type === 'VIEW').map((o) => o[nameKey]);

    for (const table of tables) {
      // eslint-disable-next-line no-await-in-loop
      const [[create]] = await conn.query(`SHOW CREATE TABLE ${quoteId(table)}`);
      /* eslint-disable no-await-in-loop */
      await writeLine(out, `\n-- Table ${table}`);
      await writeLine(out, `DROP TABLE IF EXISTS ${quoteId(table)};`);
      await writeLine(out, `${create['Create Table']};`);

      for (let offset = 0; ; offset += ROWS_PER_SELECT) {
        const [rows, fields] = await conn.query(`SELECT * FROM ${quoteId(table)} LIMIT ? OFFSET ?`, [ROWS_PER_SELECT, offset]);
        if (!rows.length) break;
        const columns = fields.map((f) => quoteId(f.name)).join(', ');
        for (let i = 0; i < rows.length; i += ROWS_PER_INSERT) {
          const values = rows.slice(i, i + ROWS_PER_INSERT)
            .map((row) => `(${fields.map((f) => literal(row[f.name])).join(', ')})`)
            .join(',\n  ');
          await writeLine(out, `INSERT INTO ${quoteId(table)} (${columns}) VALUES\n  ${values};`);
        }
        if (rows.length < ROWS_PER_SELECT) break;
      }
      /* eslint-enable no-await-in-loop */
    }

    for (const view of views) {
      // eslint-disable-next-line no-await-in-loop
      const [[create]] = await conn.query(`SHOW CREATE VIEW ${quoteId(view)}`);
      // Drop the definer so the view restores under whatever user runs the restore.
      const ddl = create['Create View'].replace(/ DEFINER=`[^`]*`@`[^`]*`/, '');
      // eslint-disable-next-line no-await-in-loop
      await writeLine(out, `\nDROP VIEW IF EXISTS ${quoteId(view)};\n${ddl};`);
    }

    const [triggers] = await conn.query('SHOW TRIGGERS');
    for (const trigger of triggers) {
      if (ignored.has(trigger.Table)) continue; // eslint-disable-line no-continue
      // eslint-disable-next-line no-await-in-loop
      const [[create]] = await conn.query(`SHOW CREATE TRIGGER ${quoteId(trigger.Trigger)}`);
      const ddl = create['SQL Original Statement'].replace(/ DEFINER=`[^`]*`@`[^`]*`/, '');
      // eslint-disable-next-line no-await-in-loop
      await writeLine(out, `\nDROP TRIGGER IF EXISTS ${quoteId(trigger.Trigger)};\nDELIMITER ;;\n${ddl};;\nDELIMITER ;`);
    }

    await writeLine(out, '\nSET FOREIGN_KEY_CHECKS = 1;');
    await conn.query('COMMIT');
  } finally {
    conn.release();
    await new Promise((resolve) => out.end(resolve));
  }
}

/** Splits a SQL script into statements, honouring quotes, comments and DELIMITER lines. */
function splitStatements(sql) {
  const statements = [];
  let delimiter = ';';
  let current = '';
  let i = 0;
  while (i < sql.length) {
    // DELIMITER directives only appear at the start of a line.
    if ((i === 0 || sql[i - 1] === '\n') && /^DELIMITER\s/i.test(sql.slice(i, i + 10))) {
      const end = sql.indexOf('\n', i);
      delimiter = sql.slice(i + 10, end === -1 ? sql.length : end).trim() || ';';
      i = end === -1 ? sql.length : end + 1;
      continue; // eslint-disable-line no-continue
    }
    const ch = sql[i];
    const next = sql[i + 1];
    if (ch === "'" || ch === '"' || ch === '`') {
      let j = i + 1;
      while (j < sql.length) {
        if (sql[j] === '\\' && ch !== '`') { j += 2; continue; } // eslint-disable-line no-continue
        if (sql[j] === ch) {
          if (sql[j + 1] === ch) { j += 2; continue; } // eslint-disable-line no-continue
          break;
        }
        j += 1;
      }
      current += sql.slice(i, j + 1);
      i = j + 1;
      continue; // eslint-disable-line no-continue
    }
    if ((ch === '-' && next === '-' && /\s/.test(sql[i + 2] || ' ')) || ch === '#') {
      const end = sql.indexOf('\n', i);
      i = end === -1 ? sql.length : end + 1;
      current += '\n';
      continue; // eslint-disable-line no-continue
    }
    if (ch === '/' && next === '*') {
      const end = sql.indexOf('*/', i + 2);
      const comment = sql.slice(i, end === -1 ? sql.length : end + 2);
      if (comment.startsWith('/*!')) current += comment; // version-conditional code MySQL executes
      i = end === -1 ? sql.length : end + 2;
      continue; // eslint-disable-line no-continue
    }
    if (sql.startsWith(delimiter, i)) {
      if (current.trim()) statements.push(current.trim());
      current = '';
      i += delimiter.length;
      continue; // eslint-disable-line no-continue
    }
    current += ch;
    i += 1;
  }
  if (current.trim()) statements.push(current.trim());
  return statements;
}

/** Runs a SQL dump against the app's database on a single connection. */
async function restoreFromFile(inFilePath) {
  const sql = await fsp.readFile(inFilePath, 'utf8');
  const statements = splitStatements(sql);
  const conn = await pool.getConnection();
  try {
    await conn.query('SET FOREIGN_KEY_CHECKS = 0');
    for (const statement of statements) {
      // eslint-disable-next-line no-await-in-loop
      await conn.query(statement);
    }
  } finally {
    await conn.query('SET FOREIGN_KEY_CHECKS = 1').catch(() => {});
    conn.release();
  }
  return { statements: statements.length };
}

module.exports = { dumpToFile, restoreFromFile, splitStatements };

/**
 * services/ad.service.js
 * Real Active Directory / LDAP authentication via ldapjs — standard
 * "search-then-bind" pattern: bind as a service account, search for the
 * user by email, then re-bind as that specific entry's DN with the
 * password being verified. Avoids needing to guess each user's DN
 * structure (uid=..., cn=..., userPrincipalName, etc. all vary by
 * directory), which is the whole reason this pattern is standard for AD.
 *
 * config comes from integrations.config_json (id='ad'), read via
 * getAdConfig() — same mysql2-JSON-string-not-object gotcha as every
 * other connector in this app (see services/capture/scheduler.js).
 */
const ldap = require('ldapjs');
const { pool } = require('../config/db');
const { parseConfig } = require('./capture/scheduler');

const BIND_TIMEOUT_MS = 5000;

/** Reads and parses the 'ad' integration row's config_json. */
async function getAdConfig() {
  const [[row]] = await pool.query("SELECT config_json FROM integrations WHERE id = 'ad'");
  return parseConfig(row?.config_json);
}

/**
 * Runs `fn(client)` against a fresh LDAP client, always unbinding
 * afterward. Connection-level failures (DNS, TCP refused, TLS) surface
 * from ldapjs as a client `'error'` EVENT, not via any operation's
 * callback — an EventEmitter with no 'error' listener throws and crashes
 * the whole Node process on that event, so this attaches one immediately
 * and races it against `fn`'s own promise, whichever rejects/resolves
 * first. Every caller in this file must go through this helper rather
 * than calling ldap.createClient directly.
 */
function withClient(url, tlsRejectUnauthorized, fn) {
  return new Promise((resolve, reject) => {
    const client = ldap.createClient({
      url,
      timeout: BIND_TIMEOUT_MS,
      connectTimeout: BIND_TIMEOUT_MS,
      tlsOptions: { rejectUnauthorized: tlsRejectUnauthorized },
    });

    let settled = false;
    const finish = (err, value) => {
      if (settled) return;
      settled = true;
      try {
        client.unbind();
      } catch {
        // already closed — nothing to do
      }
      if (err) reject(err);
      else resolve(value);
    };

    client.on('error', (err) => finish(err));
    fn(client).then((value) => finish(null, value), (err) => finish(err));
  });
}

function bind(client, dn, password) {
  return new Promise((resolve, reject) => {
    client.bind(dn, password, (err) => (err ? reject(err) : resolve()));
  });
}

/**
 * Resolves to an array of { dn, attrs } — attrs is a flat { type: firstValue }
 * map built from the ldapjs v3 SearchResultEntry pojo shape
 * (`{objectName: string, attributes: [{type, values}]}`, confirmed against
 * @ldapjs/messages' SearchResultEntry/Attribute pojo getters).
 */
function searchOne(client, base, filter) {
  return new Promise((resolve, reject) => {
    client.search(base, { filter, scope: 'sub', attributes: ['mail', 'sAMAccountName', 'cn'] }, (err, res) => {
      if (err) return reject(err);
      const results = [];
      res.on('searchEntry', (entry) => {
        const pojo = entry.pojo;
        const attrs = Object.fromEntries((pojo.attributes || []).map((a) => [a.type, a.values?.[0]]));
        results.push({ dn: pojo.objectName, attrs });
      });
      res.on('error', reject);
      res.on('end', () => resolve(results));
    });
  });
}

/**
 * Binds as the configured service account. Used both for the real
 * "Test connection" action in the Integrations screen and as the first
 * step of authenticateUser's search-then-bind flow.
 */
async function testConnection(config) {
  if (!config?.url) return { ok: false, message: 'No Active Directory URL configured' };
  try {
    await withClient(config.url, config.tlsRejectUnauthorized !== false, (client) =>
      bind(client, config.bindDN || '', process.env.AD_BIND_PASSWORD || '')
    );
    return { ok: true, message: `Bound to ${config.url} as ${config.bindDN || '(anonymous)'}` };
  } catch (err) {
    return { ok: false, message: err.message };
  }
}

/**
 * Verifies `email`/`password` against the directory. Never throws — every
 * failure mode (service-account bind failure, no matching entry, ambiguous
 * match, wrong password, connection error) collapses to
 * `{ok: false, message}` so the caller can map it to a single generic
 * "Invalid email or password" without leaking directory structure.
 */
async function authenticateUser(email, password, config) {
  if (!config?.url) return { ok: false, message: 'Active Directory is not configured' };
  const tlsRejectUnauthorized = config.tlsRejectUnauthorized !== false;

  let entries;
  try {
    entries = await withClient(config.url, tlsRejectUnauthorized, async (client) => {
      await bind(client, config.bindDN || '', process.env.AD_BIND_PASSWORD || '');
      const filter = (config.searchFilter || '(&(objectClass=user)(mail={{email}}))').replace('{{email}}', email);
      return searchOne(client, config.searchBase || '', filter);
    });
  } catch (err) {
    return { ok: false, message: err.message };
  }

  if (entries.length !== 1) {
    return { ok: false, message: entries.length === 0 ? 'No matching directory entry' : 'Ambiguous directory entry' };
  }
  const { dn, attrs } = entries[0];

  try {
    await withClient(config.url, tlsRejectUnauthorized, (client) => bind(client, dn, password));
    return {
      ok: true,
      providerUserId: attrs.sAMAccountName || dn,
      raw: { dn, mail: attrs.mail || email, cn: attrs.cn },
    };
  } catch (err) {
    return { ok: false, message: err.message };
  }
}

module.exports = { getAdConfig, testConnection, authenticateUser };

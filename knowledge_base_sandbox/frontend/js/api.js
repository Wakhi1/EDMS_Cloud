/**
 * js/api.js — thin fetch wrapper. Every module calls Api.get/post/put/del
 * instead of fetch() directly, so auth headers and the response envelope
 * ({ success, message, data }) are handled in exactly one place.
 */
const Api = (() => {
  const TOKEN_KEY = 'docs_access_token';
  const REFRESH_KEY = 'docs_refresh_token';

  function getAccessToken() { return localStorage.getItem(TOKEN_KEY); }
  function getRefreshToken() { return localStorage.getItem(REFRESH_KEY); }
  function setTokens(access, refresh) {
    localStorage.setItem(TOKEN_KEY, access);
    if (refresh) localStorage.setItem(REFRESH_KEY, refresh);
  }
  function clearTokens() {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(REFRESH_KEY);
  }

  async function request(method, path, { body, isRetry, headers } = {}) {
    const token = getAccessToken();
    const res = await fetch(`/api${path}`, {
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...(headers || {}),
      },
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });

    if (res.status === 401 && !isRetry && getRefreshToken()) {
      const refreshed = await tryRefresh();
      if (refreshed) return request(method, path, { body, isRetry: true, headers });
    }

    const json = await res.json().catch(() => ({ success: false, message: 'Invalid server response' }));
    if (!json.success) {
      const err = new Error(json.message || 'Request failed');
      err.status = res.status;
      err.errors = json.errors;
      throw err;
    }
    return json.data;
  }

  async function tryRefresh() {
    try {
      const res = await fetch('/api/auth/refresh', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refreshToken: getRefreshToken() }),
      });
      const json = await res.json();
      if (!json.success) throw new Error('refresh failed');
      setTokens(json.data.accessToken, null);
      return true;
    } catch {
      clearTokens();
      return false;
    }
  }

  return {
    get: (path) => request('GET', path),
    post: (path, body) => request('POST', path, { body }),
    put: (path, body) => request('PUT', path, { body }),
    del: (path) => request('DELETE', path),
    getAccessToken, getRefreshToken, setTokens, clearTokens,
  };
})();

# assets/

Static brand assets served as-is by the docs portal's Express static
middleware (same origin as everything else under `frontend/`).

- `company_logo.png` — Docsecure Eswatini logo, shown in the top bar
  next to "Docsecure Knowledge Base" on every page (`index.html`,
  `.brand-logo` in `css/styles.css`) and used as the browser-tab
  favicon. If the file is missing, the top bar falls back to the
  plain letter badge automatically — no code change needed once you
  drop the real file in here.

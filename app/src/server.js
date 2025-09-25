// app/src/server.js
const express = require('express');

const app = express();
const PORT = Number(process.env.PORT || 80);

app.get('/health', (_req, res) => res.status(200).send('OK'));

app.get('*', (_req, res) => {
  res.type('html').send(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>My Pretty App</title>
  <style>
    :root { --bg:#0b1220; --panel:#0e1628; --card:#0f1b33; --muted:#94a3b8; --text:#e2e8f0; --ring:#60a5fa; }
    *{box-sizing:border-box}
    body{margin:0;font-family:ui-sans-serif,system-ui,Segoe UI,Roboto,Apple Color Emoji,Noto Color Emoji;background:
      radial-gradient(1200px 700px at 10% 0%,#0d1b36 0%,#0b1220 40%),var(--bg);color:var(--text)}
    header{padding:28px 16px;background:linear-gradient(90deg,#7c3aed 0%,#06b6d4 100%);box-shadow:0 10px 40px rgba(0,0,0,.25)}
    h1{margin:0;font-size:28px;letter-spacing:.5px}
    .wrap{max-width:1120px;margin:36px auto;padding:0 18px}
    .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:14px}
    .btn{padding:14px 16px;border-radius:14px;border:1px solid rgba(255,255,255,.08);
      background:linear-gradient(180deg,rgba(255,255,255,.04),rgba(255,255,255,.02));
      color:var(--text);font-weight:700;cursor:pointer;transition:.2s transform,.2s box-shadow,.2s border-color}
    .btn:hover{transform:translateY(-2px);box-shadow:0 10px 30px rgba(0,0,0,.35);border-color:rgba(96,165,250,.45)}
    .card{margin-top:18px;background:linear-gradient(180deg,rgba(255,255,255,.04),rgba(255,255,255,.02));
      border:1px solid rgba(255,255,255,.08);border-radius:18px;padding:18px}
    .muted{color:var(--muted)}
    .kpis{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:14px;margin-top:14px}
    .kpi{padding:16px;border-radius:14px;background:linear-gradient(180deg,rgba(255,255,255,.03),rgba(255,255,255,.015));
      border:1px solid rgba(255,255,255,.08)}
    .kpi .v{font-size:22px;font-weight:800}
    .kpi .t{font-size:12px;color:var(--muted)}
  </style>
</head>
<body>
  <header><h1>My Pretty App ✨</h1></header>
  <div class="wrap">
    <div class="card">
      <div class="muted">Health check: <a href="/health">/health</a></div>
    </div>
    <div class="grid" style="margin-top:16px">
      ${['Dashboard', 'Users', 'Settings', 'Billing', 'Metrics', 'Deploy', 'Logs', 'Alerts', 'Audit', 'Backups', 'Workflows', 'Secrets']
      .map(x => `<button class="btn">${x}</button>`).join('')}
    </div>
    <div class="card">
      <div class="kpis">
        <div class="kpi"><div class="v">99.98%</div><div class="t">Uptime</div></div>
        <div class="kpi"><div class="v">~120ms</div><div class="t">Latency</div></div>
        <div class="kpi"><div class="v">1.2k</div><div class="t">Requests/min</div></div>
        <div class="kpi"><div class="v">0</div><div class="t">Errors</div></div>
      </div>
    </div>
  </div>
</body>
</html>`);
});

app.listen(PORT, () => console.log(`Server listening on ${PORT}`));
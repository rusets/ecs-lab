const express = require('express');
const path = require('path');

const app = express();
const PORT = Number(process.env.PORT || 80);

// если есть статика (app/public) — раздаём
app.use(express.static(path.join(__dirname, '..', 'public')));

// healthcheck для ALB
app.get('/health', (_req, res) => res.status(200).send('OK'));

// fallback: если index.html нет — простая красивая заглушка
app.get('*', (_req, res) => {
  const index = path.join(__dirname, '..', 'public', 'index.html');
  res.sendFile(index, (err) => {
    if (err) {
      res.type('html').send(`
        <!doctype html>
        <html><head><meta charset="utf-8"><title>My Pretty App</title>
        <style>body{font-family:system-ui,sans-serif;margin:0;background:#0f172a;color:#e2e8f0}
        header{padding:24px;text-align:center;background:linear-gradient(90deg,#7c3aed,#06b6d4)}</style></head>
        <body><header><h1>My Pretty App</h1></header>
        <main style="max-width:960px;margin:40px auto;padding:0 16px">
        <p>Health: <a href="/health">/health</a></p>
        <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:16px">
          ${['Dashboard', 'Users', 'Settings', 'Billing', 'Metrics', 'Deploy', 'Logs', 'Alerts']
          .map(x => `<button style="padding:14px 16px;border-radius:12px;background:#1f2937;border:1px solid #374151;color:#e2e8f0;font-weight:600">${x}</button>`).join('')}
        </div></main></body></html>
      `);
    }
  });
});

app.listen(PORT, () => {
  console.log(`Server listening on ${PORT}`);
});
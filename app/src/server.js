const express = require('express');
const os = require('os');

const app = express();
const PORT = Number(process.env.PORT || 80);

app.use(express.json());

// --------- Config & runtime info ----------
const startedAt = Date.now();
const INFO = {
  appName: process.env.APP_NAME || 'ruslan aws 🚀',
  env: process.env.APP_ENV || 'prod',
  version: process.env.APP_VERSION || '1.0.0',
  gitSha: process.env.GIT_SHA || process.env.IMAGE_SHA || process.env.GITHUB_SHA || 'unknown',
};

// in-memory "metrics/state" just for demo
const STATE = {
  deploys: 0,
  scaled: 1,            // pretend replicas
  cacheClears: 0,
  keyRotations: 0,
  lastAction: null,
};

async function getEcsMetadata() {
  try {
    const base = process.env.ECS_CONTAINER_METADATA_URI_V4 || process.env.ECS_CONTAINER_METADATA_URI;
    if (!base) return null;
    const [task, container] = await Promise.all([
      fetch(`${base}/task`).then(r => r.ok ? r.json() : null).catch(() => null),
      fetch(base).then(r => r.ok ? r.json() : null).catch(() => null),
    ]);
    return { task, container };
  } catch (_) {
    return null;
  }
}

function getLocalMetrics() {
  const mem = process.memoryUsage();
  return {
    hostname: os.hostname(),
    platform: `${os.type()} ${os.release()}`,
    arch: process.arch,
    uptimeSec: Math.round((Date.now() - startedAt) / 1000),
    cpuCount: os.cpus()?.length || 1,
    loadAvg: os.loadavg(),
    rssMB: Math.round(mem.rss / 1024 / 1024),
    heapUsedMB: Math.round(mem.heapUsed / 1024 / 1024),
    externalIpHint: process.env.AWS_EXECUTION_ENV ? 'running on AWS (Fargate/ECS)' : 'local/docker',
  };
}

// --------- API ---------
app.get('/health', (_req, res) => res.status(200).send('OK'));

app.get('/api/metrics', async (_req, res) => {
  const ecs = await getEcsMetadata();
  res.json({
    info: INFO,
    state: STATE,
    system: getLocalMetrics(),
    ecs: ecs ? {
      cluster: ecs.task?.Cluster,
      taskArn: ecs.task?.TaskARN || ecs.task?.TaskARN || ecs.task?.TaskARN,
      family: ecs.task?.Family,
      rev: ecs.task?.Revision,
      containerName: ecs.container?.Name,
    } : null,
    now: new Date().toISOString(),
  });
});

app.post('/action', (req, res) => {
  const a = (req.body?.action || '').toLowerCase();
  switch (a) {
    case 'deploy':
      STATE.deploys += 1;
      STATE.lastAction = 'Deploy started';
      return res.json({ ok: true, msg: 'Deploy started (demo)' });
    case 'scale_up':
      STATE.scaled += 1;
      STATE.lastAction = 'Scaled +1';
      return res.json({ ok: true, msg: `Scaled up to ${STATE.scaled}` });
    case 'scale_down':
      STATE.scaled = Math.max(1, STATE.scaled - 1);
      STATE.lastAction = 'Scaled -1';
      return res.json({ ok: true, msg: `Scaled down to ${STATE.scaled}` });
    case 'clear_cache':
      STATE.cacheClears += 1;
      STATE.lastAction = 'Cache cleared';
      return res.json({ ok: true, msg: 'Cache cleared (demo)' });
    case 'rotate_keys':
      STATE.keyRotations += 1;
      STATE.lastAction = 'Keys rotated';
      return res.json({ ok: true, msg: 'Keys rotation triggered (demo)' });
    case 'p95_report':
      STATE.lastAction = 'P95 report generated';
      return res.json({ ok: true, msg: 'P95 latency report ready (demo)' });
    default:
      return res.status(400).json({ ok: false, msg: 'Unknown action' });
  }
});

// --------- UI (SSR) ---------
app.get('*', (_req, res) => {
  res.type('html').send(`<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>${INFO.appName}</title>
<style>
:root{
  --bg:#05060b; --panel:#0a0d17; --card:#0b1120; --muted:#93a3b8; --text:#e5eef9;
  --ring:#60a5fa; --glow:#22d3ee; --rgb1:#ff00ea; --rgb2:#00e5ff; --rgb3:#00ff88;
}

*{box-sizing:border-box}
html,body{height:100%}
body{
  margin:0; font-family:ui-sans-serif,system-ui,Segoe UI,Roboto,Inter,Arial;
  color:var(--text); background: radial-gradient(1200px 700px at 10% -10%, #0b1220 0%, #070914 50%, var(--bg) 100%);
  overflow-x:hidden;
}

/* animated rgb aurora */
body::before, body::after{
  content:""; position:fixed; inset:-20%;
  filter:blur(40px); opacity:.35; pointer-events:none; mix-blend-mode:screen;
  background:
    radial-gradient(600px 300px at 20% 20%, var(--rgb1), transparent 60%),
    radial-gradient(600px 300px at 80% 30%, var(--rgb2), transparent 60%),
    radial-gradient(600px 300px at 50% 80%, var(--rgb3), transparent 60%);
  animation: float 18s linear infinite reverse;
}
body::after{ animation-duration: 26s; opacity:.25; transform: rotate(10deg); }

@keyframes float{
  0%{transform:translateY(0)}
  50%{transform:translateY(2%)}
  100%{transform:translateY(0)}
}

header{
  position:sticky; top:0; z-index:10;
  padding:28px 16px;
  background:
    linear-gradient(90deg, rgba(5,6,11,.8), rgba(5,6,11,.2)),
    linear-gradient(90deg, var(--rgb1), var(--rgb2), var(--rgb3));
  background-size: 100% 100%, 300% 100%;
  animation: rgbbar 12s ease-in-out infinite;
  box-shadow: 0 10px 40px rgba(0,0,0,.45);
  border-bottom: 1px solid rgba(255,255,255,.06);
}
@keyframes rgbbar{ 0%{background-position: 0 0, 0 0} 50%{background-position: 0 0, 100% 0} 100%{background-position: 0 0, 0 0} }

h1{margin:0; font-size:28px; letter-spacing:.5px; text-shadow: 0 2px 18px rgba(96,165,250,.35);}

.wrap{max-width:1180px; margin:36px auto; padding:0 18px}
.grid{display:grid; grid-template-columns:repeat(auto-fill,minmax(180px,1fr)); gap:14px}

.panel{
  background: linear-gradient(180deg, rgba(255,255,255,.07), rgba(255,255,255,.02));
  border: 1px solid rgba(255,255,255,.08);
  border-radius: 20px;
  box-shadow: 0 12px 60px rgba(0,0,0,.35), 0 0 0 1px rgba(34,211,238,.1) inset;
  padding: 22px;
  backdrop-filter: saturate(120%) blur(6px);
}

.card{
  margin-top:18px;
  background: linear-gradient(180deg, rgba(255,255,255,.05), rgba(255,255,255,.02));
  border: 1px solid rgba(255,255,255,.08);
  border-radius: 18px; padding:18px;
}

.badge{
  padding:6px 10px; border-radius:999px; background:rgba(9,10,18,.85);
  border:1px solid rgba(255,255,255,.08); font-size:12px; color:var(--muted);
  box-shadow: 0 0 0 1px rgba(34,211,238,.12) inset, 0 0 18px rgba(34,211,238,.05);
}
.row{display:flex; gap:10px; flex-wrap:wrap; align-items:center}
.muted{color:var(--muted)}

.btn{
  width:100%; padding:14px 16px; border-radius:14px;
  border:1px solid rgba(255,255,255,.08);
  background:
    radial-gradient(120% 180% at 0% 0%, rgba(255,255,255,.05), rgba(255,255,255,.02)),
    linear-gradient(90deg, rgba(255,255,255,.04), rgba(255,255,255,.02));
  color:var(--text); font-weight:800; letter-spacing:.3px; cursor:pointer;
  transition:.15s transform,.15s box-shadow,.15s border-color, .2s filter;
  text-shadow: 0 1px 10px rgba(96,165,250,.35);
  box-shadow: 0 0 0 1px rgba(34,211,238,.12) inset, 0 12px 28px rgba(0,0,0,.25);
}
.btn:hover{
  transform:translateY(-3px) scale(1.01);
  border-color: rgba(96,165,250,.55);
  filter: drop-shadow(0 0 12px rgba(96,165,250,.35));
}
.btn:active{ transform: translateY(-1px) }

.kpis{display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:14px}
.kpi{
  padding:16px; border-radius:14px;
  background: linear-gradient(180deg, rgba(255,255,255,.05), rgba(255,255,255,.02));
  border:1px solid rgba(255,255,255,.08);
  box-shadow: 0 0 0 1px rgba(34,211,238,.08) inset, 0 6px 22px rgba(0,0,0,.25);
}
.kpi .v{font-size:22px; font-weight:900; letter-spacing:.2px}
.kpi .t{font-size:12px; color:var(--muted)}

pre{
  white-space:pre-wrap; word-break:break-word; background:#070a14;
  border:1px solid rgba(255,255,255,.08); padding:12px; border-radius:12px;
  max-height:320px; overflow:auto; box-shadow: inset 0 0 0 1px rgba(34,211,238,.08);
}

@media (max-width:960px){ .kpis{grid-template-columns:repeat(2,1fr)} }
</style>
</head>
<body>
<header><h1>${INFO.appName}</h1></header>
<div class="wrap">
  <section class="panel">
    <div class="row">
      <span class="badge">Env: ${INFO.env}</span>
      <span class="badge">Version: <span id="v">${INFO.version}</span></span>
      <span class="badge">Git: <span id="sha">${INFO.gitSha.slice(0, 7)}</span></span>
      <span class="badge">Health: <span id="health">checking…</span></span>
    </div>
    <div class="kpis">
      <div class="kpi"><div class="v" id="uptime">—</div><div class="t">Uptime</div></div>
      <div class="kpi"><div class="v" id="rss">—</div><div class="t">RSS</div></div>
      <div class="kpi"><div class="v" id="heap">—</div><div class="t">Heap</div></div>
      <div class="kpi"><div class="v" id="load">—</div><div class="t">Load Avg</div></div>
    </div>
    <div class="grid" style="margin-top:16px">
      <button class="btn" data-action="deploy">Deploy</button>
      <button class="btn" data-action="scale_up">Scale +1</button>
      <button class="btn" data-action="scale_down">Scale -1</button>
      <button class="btn" data-action="p95_report">P95 Report</button>
      <button class="btn" data-action="clear_cache">Clear Cache</button>
      <button class="btn" data-action="rotate_keys">Rotate Keys</button>
    </div>
    <div class="card">
      <div class="row" style="justify-content:space-between">
        <div class="muted">Last Action: <b id="last">—</b></div>
        <a class="badge" href="/health">/health</a>
      </div>
    </div>
  </section>

  <section class="panel" style="margin-top:18px">
    <div class="row"><span class="muted">System / ECS Metadata</span></div>
    <pre id="meta">loading…</pre>
  </section>
</div>

<script>
async function pingHealth(){
  try {
    const r = await fetch('/health', {cache:'no-store'});
    document.getElementById('health').textContent = r.ok ? 'healthy' : 'unhealthy';
  } catch {
    document.getElementById('health').textContent = 'unreachable';
  }
}
function fmtSec(s){const m=Math.floor(s/60),sec=s%60; return m>0? m+'m '+sec+'s':sec+'s';}
async function loadMetrics(){
  const m = await fetch('/api/metrics', {cache:'no-store'}).then(r=>r.json());
  const sys = m.system||{};
  document.getElementById('uptime').textContent = fmtSec(sys.uptimeSec||0);
  document.getElementById('rss').textContent = (sys.rssMB||0)+' MB';
  document.getElementById('heap').textContent = (sys.heapUsedMB||0)+' MB';
  document.getElementById('load').textContent = (sys.loadAvg||[]).map(x=>x.toFixed(2)).join(' / ');
  document.getElementById('meta').textContent = JSON.stringify(m, null, 2);
  if (m.state?.lastAction) document.getElementById('last').textContent = m.state.lastAction;
}
async function sendAction(action){
  const r = await fetch('/action', {method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({action})});
  const j = await r.json();
  await loadMetrics();
  alert(j.msg || 'OK');
}
document.querySelectorAll('.btn[data-action]').forEach(b=>{
  b.addEventListener('click', ()=> sendAction(b.dataset.action));
});
pingHealth(); loadMetrics(); setInterval(()=>{pingHealth();loadMetrics()}, 5000);
</script>
</body>
</html>`);
});

// --------- start ----------
app.listen(PORT, () => console.log(`Server listening on ${PORT}`));
FROM nginx:1.25-alpine

RUN rm -rf /usr/share/nginx/html/*

# Красочный single-file app с множеством кнопок и интерактивом
COPY <<'EOF' /usr/share/nginx/html/index.html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>✨ Colorful Buttons Playground</title>
<style>
  :root{
    --bg1:#6a11cb; --bg2:#2575fc; --card:#ffffff; --text:#0f172a; --muted:#64748b;
    --btn:#111827; --btnText:#fff; --ok:#10b981; --warn:#f59e0b; --err:#ef4444;
  }
  .dark{
    --bg1:#0f172a; --bg2:#0b1020; --card:#111827; --text:#e5e7eb; --muted:#94a3b8;
    --btn:#e5e7eb; --btnText:#111827; --ok:#34d399; --warn:#fbbf24; --err:#f87171;
  }
  *{box-sizing:border-box}
  body{
    margin:0; min-height:100vh; font-family:Inter,system-ui,Segoe UI,Roboto,Arial,sans-serif;
    color:var(--text);
    background: linear-gradient(135deg,var(--bg1),var(--bg2));
    display:flex; align-items:center; justify-content:center; padding:32px;
  }
  .app{
    width:min(1100px,100%); display:grid; gap:24px;
  }
  .hero{
    background:rgba(255,255,255,.12);
    border:1px solid rgba(255,255,255,.25);
    backdrop-filter: blur(8px);
    border-radius:20px; padding:28px;
    color:#fff; box-shadow:0 10px 30px rgba(0,0,0,.25);
  }
  .hero h1{margin:0 0 8px; font-size:36px}
  .hero p{margin:0; opacity:.9}
  .grid{
    display:grid; grid-template-columns:repeat(3,1fr); gap:18px;
  }
  @media (max-width:900px){ .grid{grid-template-columns:1fr 1fr} }
  @media (max-width:640px){ .grid{grid-template-columns:1fr} }
  .card{
    background:var(--card);
    border-radius:16px; padding:20px; box-shadow:0 10px 20px rgba(0,0,0,.12);
    border:1px solid rgba(0,0,0,.05);
  }
  .card h3{margin:0 0 12px}
  .muted{color:var(--muted); font-size:14px; margin-top:6px}
  .row{display:flex; flex-wrap:wrap; gap:12px; margin-top:12px}
  button{
    border:none; border-radius:12px; padding:12px 16px; font-weight:600; cursor:pointer;
    transition: transform .12s ease, box-shadow .12s ease, opacity .12s ease;
  }
  button:hover{transform: translateY(-2px); box-shadow:0 8px 20px rgba(0,0,0,.15)}
  .btn{background:var(--btn); color:var(--btnText)}
  .btn-outline{background:transparent; color:var(--btn); border:2px solid var(--btn)}
  .btn-ok{background:var(--ok); color:#032314}
  .btn-warn{background:var(--warn); color:#3a2300}
  .btn-err{background:var(--err); color:#2f0b0b}
  .btn-ghost{background:rgba(0,0,0,.06); color:var(--text)}
  .chip{border-radius:999px; font-size:13px; padding:8px 12px; background:rgba(0,0,0,.06)}
  .counter{font-size:42px; font-weight:800}
  .kbd{font-family:ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
       background: rgba(0,0,0,.08); border-radius:8px; padding:2px 6px; font-size:12px}
  .footer{color:#fff; opacity:.85; text-align:center}
  .toast{
    position:fixed; right:24px; bottom:24px; padding:14px 16px; background:#111827; color:#fff;
    border-radius:12px; box-shadow:0 10px 25px rgba(0,0,0,.25); display:none; max-width:70vw;
  }
  .modal-backdrop{
    position:fixed; inset:0; background:rgba(0,0,0,.45); display:none; align-items:center; justify-content:center;
  }
  .modal{
    width:min(520px,94vw); background:var(--card); border-radius:16px; padding:20px;
    box-shadow:0 25px 60px rgba(0,0,0,.3); border:1px solid rgba(0,0,0,.08);
  }
  .row.split{justify-content:space-between; align-items:center}
  .switch{position:relative; width:54px; height:30px; background:rgba(0,0,0,.15); border-radius:999px}
  .switch input{opacity:0; width:0; height:0}
  .knob{
    position:absolute; top:3px; left:3px; width:24px; height:24px; border-radius:999px; background:#fff;
    transition:left .2s ease
  }
  .switch input:checked + .knob{ left:27px }
</style>
</head>
<body>
  <div class="app">
    <div class="hero">
      <h1>🎛️ Buttons Playground</h1>
      <p>Красочное демо на Docker + Nginx. Кнопки, модалки, тосты, счётчики, темы — всё тут.</p>
    </div>

    <div class="grid">
      <div class="card">
        <h3>Базовые кнопки</h3>
        <div class="row">
          <button class="btn" onclick="ping()">Primary</button>
          <button class="btn-outline" onclick="toast('Outline pressed')">Outline</button>
          <button class="btn-ghost" onclick="toast('Ghost pressed')">Ghost</button>
          <button class="chip" onclick="toast('Chip!')">Chip</button>
        </div>
        <div class="muted">Подсказка: <span class="kbd">Click</span> вызывает тост-уведомление.</div>
      </div>

      <div class="card">
        <h3>Статусы</h3>
        <div class="row">
          <button class="btn-ok" onclick="toast('Успех! Всё зелёное ✨')">Success</button>
          <button class="btn-warn" onclick="toast('Внимание: что-то требует внимания!')">Warning</button>
          <button class="btn-err" onclick="toast('Ошибка: что-то пошло не так 😅')">Error</button>
        </div>
        <div class="muted">Кнопки со статусами: ок, предупреждение, ошибка.</div>
      </div>

      <div class="card">
        <h3>Счётчик кликов</h3>
        <div class="counter" id="count">0</div>
        <div class="row">
          <button class="btn" onclick="inc()">+1</button>
          <button class="btn-outline" onclick="dec()">-1</button>
          <button class="btn-ghost" onclick="reset()">Reset</button>
        </div>
        <div class="muted">Мелочь, а приятно 🙂</div>
      </div>

      <div class="card">
        <h3>Модалка</h3>
        <div class="row">
          <button class="btn" onclick="openModal()">Открыть модалку</button>
          <button class="btn-outline" onclick="openModal('secondary')">Второй вариант</button>
        </div>
        <div class="muted">Модальное окно с кнопками действий.</div>
      </div>

      <div class="card">
        <h3>Тема (Светлая / Тёмная)</h3>
        <div class="row split">
          <span>Переключи тему</span>
          <label class="switch">
            <input type="checkbox" id="themeToggle" onchange="toggleTheme()">
            <span class="knob"></span>
          </label>
        </div>
        <div class="row" style="margin-top:16px">
          <button class="btn" onclick="setLight()">Light</button>
          <button class="btn-outline" onclick="setDark()">Dark</button>
        </div>
        <div class="muted">Тема сохранится в <span class="kbd">localStorage</span>.</div>
      </div>

      <div class="card">
        <h3>Действия</h3>
        <div class="row">
          <button class="btn" onclick="randomize()">Случайная тень</button>
          <button class="btn-outline" onclick="confetti()">Конфетти 🎉</button>
          <button class="btn-ghost" onclick="copy()">Скопировать привет</button>
        </div>
        <div class="muted" id="copyStatus">Готово к действиям.</div>
      </div>
    </div>

    <div class="footer">
      Dockerized by <b>you</b>. Ready for ECR/ECS/EKS.
    </div>
  </div>

  <div class="toast" id="toast"></div>

  <div class="modal-backdrop" id="backdrop" onclick="closeModal()">
    <div class="modal" onclick="event.stopPropagation()">
      <h3 id="modalTitle">Модальное окно</h3>
      <p>Здесь может быть ваш текст. Нажмите действие ниже.</p>
      <div class="row">
        <button class="btn-ok" onclick="toast('Сохранено!'); closeModal()">Сохранить</button>
        <button class="btn-warn" onclick="toast('Отменено'); closeModal()">Отмена</button>
      </div>
    </div>
  </div>

<script>
  const $ = (s)=>document.querySelector(s);
  const toastEl = $('#toast');
  const countEl = $('#count');
  const bdrop = $('#backdrop');
  const modalTitle = $('#modalTitle');
  let count = 0;

  function toast(text){
    toastEl.textContent = text;
    toastEl.style.display='block';
    setTimeout(()=>toastEl.style.display='none', 1800);
  }
  function ping(){ toast('Primary pressed'); }

  function inc(){ count++; update(); }
  function dec(){ count--; update(); }
  function reset(){ count=0; update(); }
  function update(){ countEl.textContent = count; }

  function openModal(kind='primary'){ modalTitle.textContent = kind==='secondary' ? 'Второй вариант' : 'Модальное окно'; bdrop.style.display='flex'; }
  function closeModal(){ bdrop.style.display='none'; }

  function setDark(){ document.documentElement.classList.add('dark'); saveTheme(); syncSwitch(); }
  function setLight(){ document.documentElement.classList.remove('dark'); saveTheme(); syncSwitch(); }
  function toggleTheme(){
    document.documentElement.classList.toggle('dark');
    saveTheme();
  }
  function saveTheme(){ localStorage.setItem('theme', document.documentElement.classList.contains('dark') ? 'dark' : 'light'); }
  function loadTheme(){ const t = localStorage.getItem('theme'); if(t==='dark') setDark(); else setLight(); }
  function syncSwitch(){ const on = document.documentElement.classList.contains('dark'); const sw = document.getElementById('themeToggle'); sw.checked = on; }

  function randomize(){
    document.querySelectorAll('.card').forEach(c=>{
      c.style.boxShadow = `0 10px 20px rgba(0,0,0,${(Math.random()*0.25+0.05).toFixed(2)})`;
    });
    toast('Стили обновлены');
  }

  async function copy(){
    try{
      await navigator.clipboard.writeText('Hello from Colorful Buttons App!');
      $('#copyStatus').textContent = 'Скопировано в буфер обмена ✅';
      toast('Скопировано!');
    }catch(e){
      $('#copyStatus').textContent = 'Не удалось скопировать ❌';
      toast('Clipboard error');
    }
  }

  function confetti(){
    // простая анимация эмодзи без доп. библиотек
    for(let i=0;i<24;i++){
      const s = document.createElement('div');
      s.textContent = '🎉';
      s.style.position='fixed';
      s.style.left = Math.random()*100+'vw';
      s.style.top = '-40px';
      s.style.fontSize = (Math.random()*24+16)+'px';
      s.style.transition='transform 1.2s ease, opacity 1.2s ease';
      document.body.appendChild(s);
      requestAnimationFrame(()=>{
        s.style.transform = `translateY(${90+Math.random()*10}vh) rotate(${Math.random()*360}deg)`;
        s.style.opacity='0';
      });
      setTimeout(()=>s.remove(), 1400);
    }
    toast('Праздник!');
  }

  // init
  loadTheme(); syncSwitch();
</script>
</body>
</html>
EOF

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

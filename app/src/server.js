const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 80;

// статические файлы (если есть красивая страница)
app.use(express.static(path.join(__dirname, '..', 'public')));

// health
app.get('/health', (_req, res) => res.status(200).send('OK'));

// fallback на index.html (SPA) или простая страница
app.get('*', (_req, res) => {
  const index = path.join(__dirname, '..', 'public', 'index.html');
  res.sendFile(index, err => {
    if (err) res.status(200).send(`<h1>My Pretty App</h1><p>It works!</p>`);
  });
});

app.listen(PORT, () => console.log(`Server listening on ${PORT}`));
const express = require('express');
const app = express();
const PORT = process.env.PORT ? parseInt(process.env.PORT, 10) : 3000;
const APP_MESSAGE = process.env.APP_MESSAGE || 'Hello from container! (APP_MESSAGE not set)';

app.get('/health', (req, res) => res.status(200).json({status: 'ok'}));

app.get('/', (req, res) => {
  res.type('html').send(`
    <html>
      <head><title>docker-ecs-deployment</title></head>
      <body style="font-family: sans-serif; max-width: 720px; margin: 40px auto;">
        <h1>🐳 App on EKS + External Secrets</h1>
        <p><strong>APP_MESSAGE</strong>: ${APP_MESSAGE}</p>
        <p>Try the health check: <a href="/health">/health</a></p>
      </body>
    </html>
  `);
});

app.listen(PORT, () => console.log('Server listening on', PORT));

const apm = require('elastic-apm-node').start({
  serviceName: 'node-apm-example',
  secretToken: '6t1Hfnd2VfS679z32K61rqkL', // se o APM Server exigir
  serverUrl: process.env.ELASTIC_APM_SERVER_URL || 'http://apm-server:8200',
  environment: process.env.NODE_ENV || 'development',
  rejectUnauthorized: false
});

const express = require('express');
const app = express();

// Rota simples
app.get('/', (req, res) => {
  res.send('Hello from Node.js with Elastic APM!');
});

// Rota que simula processamento
app.get('/work', (req, res) => {
  const span = apm.startSpan('fake-work');
  setTimeout(() => {
    if (span) span.end();
    res.send('Finished some fake work');
  }, Math.random() * 2000); // simula 0–2s de "trabalho"
});

// Rota que simula chamada a "banco de dados"
app.get('/db', (req, res) => {
  const span = apm.startSpan('db-query');
  setTimeout(() => {
    if (span) span.end();
    res.send('Simulated DB query done');
  }, 500);
});

// Rota que gera erro
app.get('/error', (req, res) => {
  try {
    throw new Error('Simulated error for APM');
  } catch (err) {
    apm.captureError(err); // manda para o APM
    res.status(500).send('Something broke! Check APM.');
  }
});


app.listen(3000, () => {
  console.log('App running on port 3000');
});

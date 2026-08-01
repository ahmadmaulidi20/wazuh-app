const express = require('express');
const app = express();
app.use(express.json());

app.post('/test', (req, res) => {
  console.log('BODY:', JSON.stringify(req.body));
  console.log('HEADERS:', JSON.stringify(req.headers));
  res.json({ received: req.body, ok: true });
});

app.use((err, req, res, next) => {
  console.log('ERR:', err.message, err.type, err.constructor.name);
  console.log('BODY_PROP:', 'body' in err, err.body ? err.body.toString() : 'no body');
  res.status(400).json({ error: err.message });
});

const server = app.listen(3099, () => {
  const http = require('http');
  const data = JSON.stringify({username: 'admin', password: 'admin123'});
  const opts = {
    hostname: 'localhost',
    port: 3099,
    path: '/test',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(data)
    }
  };
  const req = http.request(opts, res => {
    let body = '';
    res.on('data', c => body += c);
    res.on('end', () => {
      console.log('RESP:', body);
      console.log('STATUS:', res.statusCode);
      server.close();
    });
  });
  req.write(data);
  req.end();
});

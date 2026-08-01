// Test the actual running server from inside the container
const http = require('http');

const data = JSON.stringify({username: 'admin', password: 'admin123'});
const opts = {
  hostname: 'localhost',
  port: 3000,
  path: '/api/auth/login',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(data)
  }
};

console.log('Sending:', data);
const req = http.request(opts, res => {
  let body = '';
  res.on('data', c => body += c);
  res.on('end', () => {
    console.log('STATUS:', res.statusCode);
    console.log('HEADERS:', JSON.stringify(res.headers));
    console.log('RESPONSE:', body);
  });
});
req.on('error', e => console.error('ERROR:', e.message));
req.write(data);
req.end();

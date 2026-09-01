const http = require('http');
const data = JSON.stringify({username: 'admin', password: process.env.ADMIN_PASSWORD || 'CHANGE_ME'});
const opts = {
  hostname: '103.30.194.158',
  port: 3000,
  path: '/api/auth/login',
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
    console.log('STATUS:', res.statusCode);
    console.log('BODY:', body);
  });
});
req.on('error', e => console.error('ERROR:', e.message));
req.write(data);
req.end();

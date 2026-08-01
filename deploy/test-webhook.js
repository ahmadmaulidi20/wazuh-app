const http = require('http');
const data = JSON.stringify({
  id: 'test-fcm-001',
  rule: { id: '100', level: 10, description: 'FCM Test Alert' },
  agent: { id: '001', name: 'test-agent' }
});
const opts = {
  hostname: 'localhost',
  port: 3000,
  path: '/api/webhook/wazuh',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-API-Key': '0d6630a9f1c2500daec2a16419e56b666e28fefb4b8c52a6',
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

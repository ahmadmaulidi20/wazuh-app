import http from 'http';
import jwt from 'jsonwebtoken';
import { WebSocketServer, WebSocket } from 'ws';
import app from './app';
import { env } from './config/env';
import { initFirebase } from './config/firebase';
import { alertHub } from './services/alert-hub';
import { logger } from './utils/logger';

initFirebase();

const server = http.createServer(app);

const wss = new WebSocketServer({ server, path: '/ws' });

wss.on('connection', (ws: WebSocket, req: http.IncomingMessage) => {
  const url = new URL(req.url ?? '/', `http://${req.headers.host ?? 'localhost'}`);
  const token = url.searchParams.get('token');

  try {
    jwt.verify(token ?? '', env.jwtSecret);
  } catch {
    ws.close(1008, 'Unauthorized');
    return;
  }

  alertHub.addClient(ws);
});

wss.on('error', (err) => {
  logger.error(`WebSocket server error: ${err.message}`);
});

server.listen(env.port, () => {
  logger.info(`Server running on port ${env.port} (REST: /api, WS: /ws)`);
});

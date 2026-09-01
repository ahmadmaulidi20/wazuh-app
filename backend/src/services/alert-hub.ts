import { WebSocket, WebSocketServer } from 'ws';
import { logger } from '../utils/logger';

const HEARTBEAT_INTERVAL_MS = 30_000;

class AlertHub {
  private clients = new Set<WebSocket>();
  private heartbeatTimer: ReturnType<typeof setInterval> | null = null;

  addClient(ws: WebSocket) {
    this.clients.add(ws);
    (ws as any)._isAlive = true;

    ws.on('pong', () => {
      (ws as any)._isAlive = true;
    });

    ws.on('close', () => {
      this.clients.delete(ws);
      logger.info(`WS client disconnected (${this.clients.size} connected)`);
    });

    ws.on('error', (err) => {
      logger.error(`WS client error: ${err.message}`);
      this.clients.delete(ws);
    });

    logger.info(`WS client connected (${this.clients.size} connected)`);

    if (!this.heartbeatTimer) {
      this.startHeartbeat();
    }
  }

  broadcast(payload: unknown) {
    const message = JSON.stringify(payload);
    let sent = 0;
    this.clients.forEach((client) => {
      if (client.readyState === WebSocket.OPEN) {
        try {
          client.send(message);
          sent++;
        } catch (err) {
          logger.error(`WS send failed: ${(err as Error).message}`);
          this.clients.delete(client);
        }
      }
    });
    if (sent > 0) {
      logger.info(`WS alert broadcast sent to ${sent} client(s)`);
    }
  }

  get size() {
    return this.clients.size;
  }

  private startHeartbeat() {
    this.heartbeatTimer = setInterval(() => {
      this.clients.forEach((ws) => {
        if ((ws as any)._isAlive === false) {
          logger.info(`WS heartbeat: terminating dead client`);
          this.clients.delete(ws);
          try { ws.terminate(); } catch { /* already closed */ }
          return;
        }
        (ws as any)._isAlive = false;
        try { ws.ping(); } catch { /* ignore */ }
      });

      if (this.clients.size === 0 && this.heartbeatTimer) {
        clearInterval(this.heartbeatTimer);
        this.heartbeatTimer = null;
      }
    }, HEARTBEAT_INTERVAL_MS);
  }
}

export const alertHub = new AlertHub();

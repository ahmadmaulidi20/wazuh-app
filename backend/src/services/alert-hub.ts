import { WebSocket } from 'ws';
import { logger } from '../utils/logger';

class AlertHub {
  private clients = new Set<WebSocket>();

  addClient(ws: WebSocket) {
    this.clients.add(ws);
    ws.on('close', () => {
      this.clients.delete(ws);
      logger.info(`WS client disconnected (${this.clients.size} connected)`);
    });
    logger.info(`WS client connected (${this.clients.size} connected)`);
  }

  broadcast(payload: unknown) {
    const message = JSON.stringify(payload);
    let sent = 0;
    this.clients.forEach((client) => {
      if (client.readyState === WebSocket.OPEN) {
        client.send(message);
        sent++;
      }
    });
    if (sent > 0) {
      logger.info(`WS alert broadcast sent to ${sent} client(s)`);
    }
  }

  get size() {
    return this.clients.size;
  }
}

export const alertHub = new AlertHub();

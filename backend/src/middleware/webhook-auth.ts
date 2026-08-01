import { Request, Response, NextFunction } from 'express';
import { env } from '../config/env';

export function webhookAuth(req: Request, res: Response, next: NextFunction) {
  const apiKey = req.headers['x-api-key'] as string;
  if (!apiKey || apiKey !== env.webhookApiKey) {
    res.status(403).json({ error: 'Forbidden' });
    return;
  }
  next();
}

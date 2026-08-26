import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import rateLimit from 'express-rate-limit';
import routes from './routes';
import { errorHandler } from './middleware/error-handler';
import { env } from './config/env';
import { wibTodayStart } from './utils/wib';

const app = express();

app.use(helmet());
app.use(cors({
  origin: env.corsOrigin === '*' ? '*' : env.corsOrigin.split(',').map(s => s.trim()),
  methods: ['GET', 'POST', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-API-Key'],
  maxAge: 86400,
}));
app.use(morgan('combined'));
app.use(express.json({ limit: '1mb' }));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later' },
});
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many login attempts' },
});
app.use('/api/auth/login', authLimiter);

app.use('/api', limiter);

app.use('/api', routes);

app.get('/health', (_req, res) => {
  const WIB_OFFSET_MS = 7 * 60 * 60 * 1000;
  const wib = new Date(Date.now() + WIB_OFFSET_MS);
  res.json({ status: 'ok', timestamp: wib.toISOString().replace('Z', '+07:00') });
});

app.use(errorHandler);

export default app;

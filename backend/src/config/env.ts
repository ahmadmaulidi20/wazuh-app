import dotenv from 'dotenv';
dotenv.config();

function envString(key: string, fallback?: string): string {
  const val = process.env[key];
  if (!val && !fallback) throw new Error(`Missing env: ${key}`);
  return val ?? fallback!;
}

function envNumber(key: string, fallback: number): number {
  const val = process.env[key];
  return val ? Number(val) : fallback;
}

export const env = {
  port: envNumber('PORT', 3000),
  databaseUrl: envString('DATABASE_URL'),
  jwtSecret: envString('JWT_SECRET'),
  jwtExpiresIn: envString('JWT_EXPIRES_IN', '24h'),
  webhookApiKey: envString('WEBHOOK_API_KEY'),
  fcmCredentialsPath: envString('FCM_CREDENTIALS_PATH', './firebase-service-account.json'),
  corsOrigin: envString('CORS_ORIGIN', '*'),
};

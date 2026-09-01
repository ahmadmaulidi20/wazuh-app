import { applicationDefault, initializeApp, cert } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { existsSync, readFileSync } from 'fs';
import { resolve } from 'path';
import { env } from './env';

let fcmInitialized = false;

export function initFirebase() {
  if (fcmInitialized) return;
  try {
    const credentialsPath = resolve(process.cwd(), env.fcmCredentialsPath);
    if (existsSync(credentialsPath)) {
      const serviceAccount = JSON.parse(readFileSync(credentialsPath, 'utf-8'));
      initializeApp({ credential: cert(serviceAccount) });
    } else {
      initializeApp({ credential: applicationDefault() });
    }
    fcmInitialized = true;
    console.log('Firebase initialized');
  } catch (err) {
    console.warn('Firebase not configured, FCM disabled:', (err as Error).message);
    fcmInitialized = false;
  }
}

export function isFirebaseReady(): boolean {
  return fcmInitialized;
}

export { getMessaging };

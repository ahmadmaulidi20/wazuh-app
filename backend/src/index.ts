import app from './app';
import { env } from './config/env';
import { initFirebase } from './config/firebase';
import { logger } from './utils/logger';

initFirebase();

app.listen(env.port, () => {
  logger.info(`Server running on port ${env.port}`);
});

import { Request, Response } from 'express';
import { z } from 'zod';
import { prisma } from '../utils/prisma';
import { AuthPayload } from '../middleware/auth';

const deviceTokenSchema = z.object({
  token: z.string().min(1),
  platform: z.enum(['android', 'ios', 'web']),
});

export class DeviceController {
  async register(req: Request, res: Response) {
    const parsed = deviceTokenSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Validation failed', details: parsed.error.flatten() });
      return;
    }

    const user = req.user as AuthPayload;
    const { token, platform } = parsed.data;

    const device = await prisma.deviceToken.upsert({
      where: { userId_token: { userId: user.userId, token } },
      update: { platform },
      create: { userId: user.userId, token, platform },
    });

    res.json(device);
  }

  async unregister(req: Request, res: Response) {
    const user = req.user as AuthPayload;
    const { token } = req.body;

    if (!token) {
      res.status(400).json({ error: 'token required' });
      return;
    }

    await prisma.deviceToken.deleteMany({
      where: { userId: user.userId, token },
    });

    res.json({ message: 'Device unregistered' });
  }
}

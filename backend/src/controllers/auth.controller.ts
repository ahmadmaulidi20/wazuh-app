import { Request, Response } from 'express';
import { z } from 'zod';
import { AuthService } from '../services/auth.service';

const loginSchema = z.object({
  username: z.string().min(1),
  password: z.string().min(1),
});

export class AuthController {
  private authService = new AuthService();

  async login(req: Request, res: Response) {
    const parsed = loginSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Validation failed', details: parsed.error.flatten() });
      return;
    }

    const { username, password } = parsed.data;
    const result = await this.authService.login(username, password);

    if (!result) {
      res.status(401).json({ error: 'Invalid credentials' });
      return;
    }

    res.json(result);
  }
}

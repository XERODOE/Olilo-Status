// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aydan Abrahams

import { Router } from 'express';
import { z } from 'zod';
import {
  upsertDevice,
  updatePreferences,
  deactivateDevice,
} from '../repositories/devices.js';

export const devicesRouter = Router();

const preferencesSchema = z
  .object({
    incidents: z.boolean().optional(),
    maintenance: z.boolean().optional(),
    componentAlerts: z.boolean().optional(),
    networks: z.array(z.string()).optional(),
  })
  .strict();

const registerSchema = z.object({
  token: z.string().min(1),
  platform: z.enum(['ios', 'android']),
  preferences: preferencesSchema.optional(),
  locale: z.string().max(35).optional(),
  appVersion: z.string().max(50).optional(),
});

// Register (or refresh) a device for push delivery.
devicesRouter.post('/register', async (req, res, next) => {
  try {
    const input = registerSchema.parse(req.body);
    const device = await upsertDevice(input);
    res.status(201).json({ device });
  } catch (err) {
    if (err instanceof z.ZodError) return res.status(400).json({ error: err.issues });
    next(err);
  }
});

const prefsUpdateSchema = z.object({
  platform: z.enum(['ios', 'android']),
  preferences: preferencesSchema,
});

// Update just the notification preferences for an existing device.
devicesRouter.patch('/:token/preferences', async (req, res, next) => {
  try {
    const { platform, preferences } = prefsUpdateSchema.parse(req.body);
    const device = await updatePreferences(req.params.token, platform, preferences);
    if (!device) return res.status(404).json({ error: 'device not found' });
    res.json({ device });
  } catch (err) {
    if (err instanceof z.ZodError) return res.status(400).json({ error: err.issues });
    next(err);
  }
});

const unregisterSchema = z.object({ platform: z.enum(['ios', 'android']) });

// Stop delivering to a device (e.g. the user disabled notifications).
devicesRouter.delete('/:token', async (req, res, next) => {
  try {
    const { platform } = unregisterSchema.parse(req.body);
    const removed = await deactivateDevice(req.params.token, platform);
    if (!removed) return res.status(404).json({ error: 'device not found' });
    res.status(204).end();
  } catch (err) {
    if (err instanceof z.ZodError) return res.status(400).json({ error: err.issues });
    next(err);
  }
});

// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aydan Abrahams

import express from 'express';
import { config, assertConfig } from './config.js';
import { logger } from './logger.js';
import { migrate } from './db/migrate.js';
import { pool } from './db/pool.js';
import { devicesRouter } from './routes/devices.js';
import { startPolling, stopPolling, pollOnce } from './services/poller.js';
import { apns } from './push/apns.js';

assertConfig();

const app = express();
app.use(express.json({ limit: '16kb' }));

// Liveness/readiness probe - no auth so load balancers can reach it.
app.get('/health', (_req, res) => res.json({ status: 'ok' }));

// Shared-secret auth for the device API. Disabled only if API_KEY is unset.
app.use('/api', (req, res, next) => {
  if (!config.apiKey) return next();
  if (req.get('x-api-key') === config.apiKey) return next();
  res.status(401).json({ error: 'unauthorized' });
});

app.use('/api/devices', devicesRouter);

// Manually trigger a poll (useful for testing and status-page webhooks).
app.post('/api/poll', async (_req, res, next) => {
  try {
    await pollOnce();
    res.json({ status: 'ok' });
  } catch (err) {
    next(err);
  }
});

// eslint-disable-next-line no-unused-vars -- Express needs the 4-arg signature.
app.use((err, _req, res, _next) => {
  logger.error('request error', { error: err.message });
  res.status(500).json({ error: 'internal error' });
});

async function main() {
  await migrate();

  const server = app.listen(config.port, () => {
    logger.info('server listening', {
      port: config.port,
      apns: apns.enabled,
      fcm: config.fcm.enabled,
    });
  });

  startPolling();

  const shutdown = async (signal) => {
    logger.info('shutting down', { signal });
    stopPolling();
    apns.close();
    server.close();
    await pool.end().catch(() => {});
    process.exit(0);
  };
  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

main().catch((err) => {
  logger.error('fatal startup error', { error: err.message });
  process.exit(1);
});

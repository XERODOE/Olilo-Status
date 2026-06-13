// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aydan Abrahams

import { apns } from '../push/apns.js';
import { fcm } from '../push/fcm.js';
import { activeDevices, deleteTokens } from '../repositories/devices.js';
import { logger } from '../logger.js';

const providers = {
  ios: apns,
  android: fcm,
};

// Decide whether a device, given its preferences, should receive this event.
// `event.type` is one of 'incident' | 'maintenance' | 'component'.
function wants(preferences, event) {
  if (event.type === 'incident') return preferences.incidents !== false;
  if (event.type === 'maintenance') return preferences.maintenance !== false;
  if (event.type === 'component') {
    if (!preferences.componentAlerts) return false;
    const networks = preferences.networks ?? [];
    if (networks.length === 0) return true; // no filter = all networks
    const affected = event.affected ?? [];
    return affected.some((a) => networks.includes(a));
  }
  return false;
}

// Fan an event out to every eligible active device across both platforms.
// Invalid tokens reported by the providers are pruned from the database.
export async function notify(event) {
  const message = {
    title: event.title,
    body: event.body,
    data: {
      type: event.type,
      incidentId: event.incidentId,
      url: event.url,
    },
  };

  let sent = 0;
  let failed = 0;
  const deadTokens = [];

  for (const [platform, provider] of Object.entries(providers)) {
    if (!provider.enabled) continue;
    const devices = (await activeDevices(platform)).filter((d) => wants(d.preferences, event));
    if (!devices.length) continue;

    const results = await Promise.all(
      devices.map((d) => provider.send(d.token, message).then((r) => ({ token: d.token, ...r }))),
    );

    for (const r of results) {
      if (r.ok) sent++;
      else {
        failed++;
        if (r.invalid) deadTokens.push(r.token);
      }
    }
  }

  if (deadTokens.length) {
    const removed = await deleteTokens(deadTokens);
    logger.info('pruned invalid tokens', { removed });
  }

  logger.info('notification dispatched', { type: event.type, title: event.title, sent, failed });
  return { sent, failed };
}

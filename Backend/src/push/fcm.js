// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aydan Abrahams

import { initializeApp, cert } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { config } from '../config.js';
import { logger } from '../logger.js';

// Firebase Cloud Messaging client for Android delivery. Lazily initialises the
// Admin SDK from a service-account credential.

let messaging = null;

if (config.fcm.enabled) {
  try {
    const serviceAccount = JSON.parse(config.fcm.serviceAccount);
    const app = initializeApp({ credential: cert(serviceAccount) });
    messaging = getMessaging(app);
  } catch (err) {
    logger.error('failed to initialise FCM', { error: err.message });
    throw err;
  }
}

// FCM error codes that mean the token is permanently invalid.
const INVALID_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
]);

export const fcm = {
  enabled: config.fcm.enabled,
  send: sendFcm,
};

async function sendFcm(deviceToken, { title, body, data }) {
  try {
    await messaging.send({
      token: deviceToken,
      notification: { title, body },
      // FCM data values must be strings.
      data: stringifyValues(data),
      android: { priority: 'high' },
    });
    return { ok: true };
  } catch (err) {
    const invalid = INVALID_CODES.has(err.code);
    return { ok: false, reason: err.code || err.message, invalid };
  }
}

function stringifyValues(obj = {}) {
  const out = {};
  for (const [k, v] of Object.entries(obj)) {
    if (v === undefined || v === null) continue;
    out[k] = typeof v === 'string' ? v : JSON.stringify(v);
  }
  return out;
}

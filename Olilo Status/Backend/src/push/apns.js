// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aydan Abrahams

import http2 from 'node:http2';
import jwt from 'jsonwebtoken';
import { config } from '../config.js';
import { logger } from '../logger.js';

// Minimal APNs HTTP/2 client using token-based (.p8) authentication. Keeps a
// single long-lived HTTP/2 session and refreshes the provider JWT well within
// Apple's 1-hour validity window.

const HOST_PROD = 'https://api.push.apple.com';
const HOST_SANDBOX = 'https://api.sandbox.push.apple.com';
const TOKEN_TTL_MS = 50 * 60 * 1000; // refresh after 50 min (Apple allows 60)

let session = null;
let cachedToken = null;
let cachedTokenAt = 0;

export const apns = {
  enabled: config.apns.enabled,
  send: sendApns,
  close: () => {
    if (session && !session.closed) session.close();
    session = null;
  },
};

function providerToken() {
  const now = Date.now();
  if (cachedToken && now - cachedTokenAt < TOKEN_TTL_MS) return cachedToken;
  cachedToken = jwt.sign({ iss: config.apns.teamId, iat: Math.floor(now / 1000) }, config.apns.key, {
    algorithm: 'ES256',
    header: { alg: 'ES256', kid: config.apns.keyId },
  });
  cachedTokenAt = now;
  return cachedToken;
}

function getSession() {
  if (session && !session.closed && !session.destroyed) return session;
  const host = config.apns.production ? HOST_PROD : HOST_SANDBOX;
  session = http2.connect(host);
  session.on('error', (err) => logger.warn('apns session error', { error: err.message }));
  session.on('close', () => {
    session = null;
  });
  return session;
}

// Send one notification. Resolves to { ok } or { ok:false, status, reason }.
// A 410 (or 400/Unregistered) means the token is dead and should be deleted.
function sendApns(deviceToken, { title, body, data }) {
  return new Promise((resolve) => {
    const payload = JSON.stringify({
      aps: { alert: { title, body }, sound: 'default' },
      ...data,
    });

    const req = getSession().request({
      ':method': 'POST',
      ':path': `/3/device/${deviceToken}`,
      authorization: `bearer ${providerToken()}`,
      'apns-topic': config.apns.bundleId,
      'apns-push-type': 'alert',
      'apns-priority': '10',
      'content-type': 'application/json',
    });

    let status = 0;
    let responseBody = '';
    req.on('response', (headers) => {
      status = Number(headers[':status']);
    });
    req.setEncoding('utf8');
    req.on('data', (chunk) => {
      responseBody += chunk;
    });
    req.on('end', () => {
      if (status === 200) return resolve({ ok: true });
      let reason = responseBody;
      try {
        reason = JSON.parse(responseBody).reason || reason;
      } catch {
        /* keep raw body */
      }
      const invalid = status === 410 || reason === 'BadDeviceToken' || reason === 'Unregistered';
      resolve({ ok: false, status, reason, invalid });
    });
    req.on('error', (err) => resolve({ ok: false, status: 0, reason: err.message, invalid: false }));

    req.end(payload);
  });
}

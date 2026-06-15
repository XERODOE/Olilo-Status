// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aydan Abrahams

import { query } from '../db/pool.js';

// Default preferences applied when a device registers without specifying them.
// `networks` filters component-level alerts; empty means "all networks".
export const DEFAULT_PREFERENCES = {
  incidents: true,
  maintenance: true,
  componentAlerts: false,
  networks: [],
};

export function normalizePreferences(prefs = {}) {
  return {
    incidents: prefs.incidents ?? DEFAULT_PREFERENCES.incidents,
    maintenance: prefs.maintenance ?? DEFAULT_PREFERENCES.maintenance,
    componentAlerts: prefs.componentAlerts ?? DEFAULT_PREFERENCES.componentAlerts,
    networks: Array.isArray(prefs.networks) ? prefs.networks : DEFAULT_PREFERENCES.networks,
  };
}

// Insert or update a device by (token, platform). Re-registering refreshes
// preferences and reactivates a previously deactivated token.
export async function upsertDevice({ token, platform, preferences, locale, appVersion }) {
  const prefs = normalizePreferences(preferences);
  const { rows } = await query(
    `INSERT INTO devices (token, platform, preferences, locale, app_version)
     VALUES ($1, $2, $3::jsonb, $4, $5)
     ON CONFLICT (token, platform) DO UPDATE SET
       preferences  = EXCLUDED.preferences,
       locale       = EXCLUDED.locale,
       app_version  = EXCLUDED.app_version,
       active       = TRUE,
       updated_at   = now(),
       last_seen_at = now()
     RETURNING id, token, platform, preferences, locale, app_version, active`,
    [token, platform, JSON.stringify(prefs), locale ?? null, appVersion ?? null],
  );
  return rows[0];
}

export async function updatePreferences(token, platform, preferences) {
  const prefs = normalizePreferences(preferences);
  const { rows } = await query(
    `UPDATE devices SET preferences = $3::jsonb, updated_at = now(), last_seen_at = now()
     WHERE token = $1 AND platform = $2
     RETURNING id, token, platform, preferences`,
    [token, platform, JSON.stringify(prefs)],
  );
  return rows[0] ?? null;
}

export async function deactivateDevice(token, platform) {
  const { rowCount } = await query(
    `UPDATE devices SET active = FALSE, updated_at = now() WHERE token = $1 AND platform = $2`,
    [token, platform],
  );
  return rowCount > 0;
}

// Permanently drop tokens APNs/FCM reported as invalid (Unregistered / 410).
export async function deleteTokens(tokens) {
  if (!tokens.length) return 0;
  const { rowCount } = await query(`DELETE FROM devices WHERE token = ANY($1)`, [tokens]);
  return rowCount;
}

// All active devices on a platform. Targeting/filtering happens in the notifier
// so preference logic lives in one place.
export async function activeDevices(platform) {
  const { rows } = await query(
    `SELECT token, platform, preferences FROM devices WHERE active = TRUE AND platform = $1`,
    [platform],
  );
  return rows;
}

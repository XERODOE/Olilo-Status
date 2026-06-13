// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aydan Abrahams

import { config } from '../config.js';

// Thin client over the Instatus-style public API the Olilo status page exposes.
// `summary.json` carries the page status plus any active incidents and
// maintenances; `components.json` carries per-component health.

async function getJson(path) {
  const url = `${config.status.baseUrl}/${path}`;
  const res = await fetch(url, {
    headers: { accept: 'application/json', 'user-agent': 'olilo-status-notifier/0.1' },
    signal: AbortSignal.timeout(15000),
  });
  if (!res.ok) {
    throw new Error(`status page ${path} responded ${res.status}`);
  }
  return res.json();
}

export async function fetchSummary() {
  const data = await getJson('v3/summary.json');
  return {
    page: data.page ?? null,
    activeIncidents: Array.isArray(data.activeIncidents) ? data.activeIncidents : [],
    activeMaintenances: Array.isArray(data.activeMaintenances) ? data.activeMaintenances : [],
  };
}

export async function fetchComponents() {
  const data = await getJson('v3/components.json');
  return Array.isArray(data.components) ? data.components : [];
}

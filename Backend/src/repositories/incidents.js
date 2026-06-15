// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aydan Abrahams

import { query } from '../db/pool.js';

export async function getAll() {
  const { rows } = await query(`SELECT * FROM incidents`);
  const map = new Map();
  for (const row of rows) map.set(row.external_id, row);
  return map;
}

// Insert a newly observed incident/maintenance. Returns the stored row.
export async function insert(incident) {
  const { rows } = await query(
    `INSERT INTO incidents
       (external_id, kind, name, status, impact, url, affected, notified_hash, started_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
     ON CONFLICT (external_id) DO NOTHING
     RETURNING *`,
    [
      incident.externalId,
      incident.kind,
      incident.name,
      incident.status,
      incident.impact ?? null,
      incident.url ?? null,
      incident.affected ?? [],
      incident.notifiedHash ?? null,
      incident.startedAt ?? null,
    ],
  );
  return rows[0] ?? null;
}

export async function update(externalId, { status, name, impact, affected, notifiedHash }) {
  await query(
    `UPDATE incidents
       SET status = $2, name = $3, impact = $4, affected = $5, notified_hash = $6, updated_at = now()
     WHERE external_id = $1`,
    [externalId, status, name, impact ?? null, affected ?? [], notifiedHash ?? null],
  );
}

export async function markResolved(externalId) {
  await query(
    `UPDATE incidents SET resolved = TRUE, status = 'RESOLVED', updated_at = now() WHERE external_id = $1`,
    [externalId],
  );
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aydan Abrahams

import { query } from '../db/pool.js';

export async function getAll() {
  const { rows } = await query(`SELECT external_id, name, group_name, status FROM components`);
  const map = new Map();
  for (const row of rows) map.set(row.external_id, row);
  return map;
}

export async function upsert({ externalId, name, groupName, status }) {
  await query(
    `INSERT INTO components (external_id, name, group_name, status)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (external_id) DO UPDATE SET
       name = EXCLUDED.name,
       group_name = EXCLUDED.group_name,
       status = EXCLUDED.status,
       updated_at = now()`,
    [externalId, name, groupName ?? null, status],
  );
}

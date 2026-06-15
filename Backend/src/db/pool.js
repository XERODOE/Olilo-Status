// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aydan Abrahams

import pg from 'pg';
import { config } from '../config.js';

export const pool = new pg.Pool({
  connectionString: config.database.url,
  ssl: config.database.ssl,
  max: 10,
});

export function query(text, params) {
  return pool.query(text, params);
}

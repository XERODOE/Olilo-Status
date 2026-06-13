-- SPDX-License-Identifier: GPL-3.0-or-later
-- Copyright (C) 2026 Aydan Abrahams

-- Devices registered to receive push notifications.
CREATE TABLE IF NOT EXISTS devices (
  id           BIGSERIAL PRIMARY KEY,
  token        TEXT NOT NULL,
  platform     TEXT NOT NULL CHECK (platform IN ('ios', 'android')),
  -- Per-device notification preferences. See repositories/devices.js for shape.
  preferences  JSONB NOT NULL DEFAULT '{}'::jsonb,
  locale       TEXT,
  app_version  TEXT,
  active        BOOLEAN NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (token, platform)
);

CREATE INDEX IF NOT EXISTS devices_active_platform_idx ON devices (active, platform);

-- Mirror of incidents and scheduled maintenances seen on the status page.
-- Used to diff successive polls and decide what to notify about.
CREATE TABLE IF NOT EXISTS incidents (
  external_id    TEXT PRIMARY KEY,
  kind           TEXT NOT NULL CHECK (kind IN ('incident', 'maintenance')),
  name           TEXT NOT NULL,
  status         TEXT NOT NULL,
  impact         TEXT,
  url            TEXT,
  -- Names of components/groups affected, for preference-based targeting.
  affected       TEXT[] NOT NULL DEFAULT '{}',
  -- Hash of the fields we notify on, to suppress duplicate pushes.
  notified_hash  TEXT,
  started_at     TIMESTAMPTZ,
  resolved       BOOLEAN NOT NULL DEFAULT FALSE,
  first_seen_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Last-known status of each component, to detect operational transitions.
CREATE TABLE IF NOT EXISTS components (
  external_id   TEXT PRIMARY KEY,
  name          TEXT NOT NULL,
  group_name    TEXT,
  status        TEXT NOT NULL,
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Schema bookkeeping.
CREATE TABLE IF NOT EXISTS schema_migrations (
  version    TEXT PRIMARY KEY,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

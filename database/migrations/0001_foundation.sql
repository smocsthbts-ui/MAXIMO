PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS organizations (
  id TEXT PRIMARY KEY NOT NULL,
  org_code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE')),
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
) STRICT;

CREATE TABLE IF NOT EXISTS sites (
  id TEXT PRIMARY KEY NOT NULL,
  organization_id TEXT NOT NULL REFERENCES organizations(id) ON DELETE RESTRICT,
  site_code TEXT NOT NULL,
  name TEXT NOT NULL,
  timezone TEXT NOT NULL DEFAULT 'UTC',
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE')),
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE (organization_id, site_code),
  UNIQUE (id, organization_id)
) STRICT;

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT,
  full_name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','ACTIVE','INACTIVE','LOCKED')),
  email_verified_at TEXT,
  last_login_at TEXT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
) STRICT;

CREATE TABLE IF NOT EXISTS roles (
  id TEXT PRIMARY KEY NOT NULL,
  role_code TEXT NOT NULL UNIQUE CHECK (role_code IN ('ADMIN','MAINT_MANAGER','PLANNER','TECHNICIAN','REQUESTER')),
  name TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
) STRICT;

CREATE TABLE IF NOT EXISTS user_roles (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_id TEXT NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
  assigned_by TEXT REFERENCES users(id) ON DELETE RESTRICT,
  assigned_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  PRIMARY KEY (user_id, role_id)
) STRICT;

CREATE TABLE IF NOT EXISTS user_site_access (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  site_id TEXT NOT NULL REFERENCES sites(id) ON DELETE RESTRICT,
  granted_by TEXT REFERENCES users(id) ON DELETE RESTRICT,
  granted_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  PRIMARY KEY (user_id, site_id)
) STRICT;

CREATE TABLE IF NOT EXISTS system_settings (
  setting_key TEXT PRIMARY KEY NOT NULL,
  setting_value TEXT NOT NULL,
  updated_by TEXT REFERENCES users(id) ON DELETE RESTRICT,
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
) STRICT;

CREATE TABLE IF NOT EXISTS locations (
  id TEXT PRIMARY KEY NOT NULL,
  site_id TEXT NOT NULL REFERENCES sites(id) ON DELETE RESTRICT,
  location_code TEXT NOT NULL,
  parent_location_id TEXT REFERENCES locations(id) ON DELETE RESTRICT,
  description TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE')),
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE (site_id, location_code),
  CHECK (parent_location_id IS NULL OR parent_location_id <> id)
) STRICT;

CREATE TABLE IF NOT EXISTS assets (
  id TEXT PRIMARY KEY NOT NULL,
  site_id TEXT NOT NULL REFERENCES sites(id) ON DELETE RESTRICT,
  asset_code TEXT NOT NULL,
  location_id TEXT REFERENCES locations(id) ON DELETE RESTRICT,
  parent_asset_id TEXT REFERENCES assets(id) ON DELETE RESTRICT,
  description TEXT NOT NULL,
  asset_type TEXT,
  manufacturer TEXT,
  model TEXT,
  serial_number TEXT,
  install_date TEXT,
  criticality TEXT CHECK (criticality IS NULL OR criticality IN ('LOW','MEDIUM','HIGH','CRITICAL')),
  maintenance_section TEXT,
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE','RETIRED')),
  remarks TEXT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE (site_id, asset_code),
  CHECK (parent_asset_id IS NULL OR parent_asset_id <> id)
) STRICT;

CREATE TABLE IF NOT EXISTS service_requests (
  id TEXT PRIMARY KEY NOT NULL,
  sr_number TEXT NOT NULL UNIQUE,
  site_id TEXT NOT NULL REFERENCES sites(id) ON DELETE RESTRICT,
  asset_id TEXT REFERENCES assets(id) ON DELETE RESTRICT,
  location_id TEXT REFERENCES locations(id) ON DELETE RESTRICT,
  description TEXT NOT NULL,
  long_description TEXT,
  priority INTEGER NOT NULL DEFAULT 5 CHECK (priority BETWEEN 1 AND 9),
  status TEXT NOT NULL DEFAULT 'NEW' CHECK (status IN ('NEW','REVIEW','MORE_INFO','APPROVED','REJECTED','CANCELLED')),
  requested_by TEXT REFERENCES users(id) ON DELETE RESTRICT,
  reviewed_by TEXT REFERENCES users(id) ON DELETE RESTRICT,
  review_reason TEXT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
) STRICT;

CREATE TABLE IF NOT EXISTS job_plans (
  id TEXT PRIMARY KEY NOT NULL,
  job_plan_code TEXT NOT NULL,
  site_id TEXT NOT NULL REFERENCES sites(id) ON DELETE RESTRICT,
  description TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE')),
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE (site_id, job_plan_code)
) STRICT;

CREATE TABLE IF NOT EXISTS job_plan_tasks (
  id TEXT PRIMARY KEY NOT NULL,
  job_plan_id TEXT NOT NULL REFERENCES job_plans(id) ON DELETE CASCADE,
  sequence_no INTEGER NOT NULL CHECK (sequence_no > 0),
  task_description TEXT NOT NULL,
  required_skills TEXT NOT NULL DEFAULT '[]' CHECK (json_valid(required_skills)),
  UNIQUE (job_plan_id, sequence_no)
) STRICT;

CREATE TABLE IF NOT EXISTS pm_schedules (
  id TEXT PRIMARY KEY NOT NULL,
  pm_code TEXT NOT NULL,
  site_id TEXT NOT NULL REFERENCES sites(id) ON DELETE RESTRICT,
  asset_id TEXT REFERENCES assets(id) ON DELETE RESTRICT,
  location_id TEXT REFERENCES locations(id) ON DELETE RESTRICT,
  job_plan_id TEXT NOT NULL REFERENCES job_plans(id) ON DELETE RESTRICT,
  frequency TEXT NOT NULL CHECK (frequency IN ('DAILY','WEEKLY','MONTHLY','YEARLY')),
  interval_value INTEGER NOT NULL DEFAULT 1 CHECK (interval_value > 0),
  start_date TEXT NOT NULL,
  next_due_date TEXT,
  lead_days INTEGER NOT NULL DEFAULT 0 CHECK (lead_days >= 0),
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE','ON_HOLD')),
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE (site_id, pm_code),
  CHECK (asset_id IS NOT NULL OR location_id IS NOT NULL)
) STRICT;

CREATE TABLE IF NOT EXISTS work_orders (
  id TEXT PRIMARY KEY NOT NULL,
  wo_number TEXT NOT NULL UNIQUE,
  site_id TEXT NOT NULL REFERENCES sites(id) ON DELETE RESTRICT,
  sr_id TEXT REFERENCES service_requests(id) ON DELETE RESTRICT,
  asset_id TEXT REFERENCES assets(id) ON DELETE RESTRICT,
  location_id TEXT REFERENCES locations(id) ON DELETE RESTRICT,
  pm_schedule_id TEXT REFERENCES pm_schedules(id) ON DELETE RESTRICT,
  work_type TEXT NOT NULL CHECK (work_type IN ('EM','PM','CM')),
  description TEXT NOT NULL,
  long_description TEXT,
  priority INTEGER NOT NULL DEFAULT 5 CHECK (priority BETWEEN 1 AND 9),
  status TEXT NOT NULL DEFAULT 'WAPPR' CHECK (status IN ('WAPPR','APPR','INPRG','HOLD','COMP','CLOSE','CAN')),
  schedstart TEXT,
  assigned_to TEXT REFERENCES users(id) ON DELETE RESTRICT,
  created_by TEXT REFERENCES users(id) ON DELETE RESTRICT,
  emergency_reason TEXT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
) STRICT;

CREATE TABLE IF NOT EXISTS work_logs (
  id TEXT PRIMARY KEY NOT NULL,
  wo_id TEXT NOT NULL REFERENCES work_orders(id) ON DELETE RESTRICT,
  technician_id TEXT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  start_at TEXT,
  end_at TEXT,
  labor_hours REAL CHECK (labor_hours IS NULL OR labor_hours >= 0),
  repair_result TEXT,
  failure_cause TEXT,
  failure_code TEXT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  CHECK (start_at IS NULL OR end_at IS NULL OR end_at >= start_at)
) STRICT;

CREATE TABLE IF NOT EXISTS pm_occurrences (
  id TEXT PRIMARY KEY NOT NULL,
  pm_schedule_id TEXT NOT NULL REFERENCES pm_schedules(id) ON DELETE RESTRICT,
  cycle_key TEXT NOT NULL,
  due_at TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'DUE' CHECK (status IN ('DUE','GENERATED','SKIPPED','CANCELLED')),
  work_order_id TEXT UNIQUE REFERENCES work_orders(id) ON DELETE RESTRICT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  UNIQUE (pm_schedule_id, cycle_key)
) STRICT;

CREATE TABLE IF NOT EXISTS audit_logs (
  id TEXT PRIMARY KEY NOT NULL,
  actor_user_id TEXT REFERENCES users(id) ON DELETE RESTRICT,
  site_id TEXT REFERENCES sites(id) ON DELETE RESTRICT,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  before_json TEXT CHECK (before_json IS NULL OR json_valid(before_json)),
  after_json TEXT CHECK (after_json IS NULL OR json_valid(after_json)),
  request_id TEXT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
) STRICT;

CREATE INDEX IF NOT EXISTS idx_sites_org_status ON sites(organization_id, status);
CREATE INDEX IF NOT EXISTS idx_users_status_email ON users(status, email);
CREATE INDEX IF NOT EXISTS idx_user_site_access_site ON user_site_access(site_id, user_id);
CREATE INDEX IF NOT EXISTS idx_locations_parent ON locations(parent_location_id);
CREATE INDEX IF NOT EXISTS idx_assets_location_status ON assets(location_id, status);
CREATE INDEX IF NOT EXISTS idx_assets_parent ON assets(parent_asset_id);
CREATE INDEX IF NOT EXISTS idx_sr_site_status_created ON service_requests(site_id, status, created_at);
CREATE INDEX IF NOT EXISTS idx_wo_site_status_priority ON work_orders(site_id, status, priority);
CREATE INDEX IF NOT EXISTS idx_wo_assignee_status ON work_orders(assigned_to, status);
CREATE INDEX IF NOT EXISTS idx_wo_asset_created ON work_orders(asset_id, created_at);
CREATE INDEX IF NOT EXISTS idx_pm_site_due_status ON pm_schedules(site_id, next_due_date, status);
CREATE INDEX IF NOT EXISTS idx_pm_occurrences_due_status ON pm_occurrences(status, due_at);
CREATE INDEX IF NOT EXISTS idx_audit_entity_created ON audit_logs(entity_type, entity_id, created_at);
CREATE INDEX IF NOT EXISTS idx_audit_site_created ON audit_logs(site_id, created_at);

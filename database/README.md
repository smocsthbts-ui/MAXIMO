# Maximo-AI D1 database

The initial schema migration is `migrations/0001_foundation.sql`. It defines organization/site boundaries, user and role records, asset/location records, service requests, job plans, preventive-maintenance schedules, work orders, work logs, PM occurrences, audit logs, and supporting indexes.

Apply migrations only to the intended development database after reviewing the target binding. Production database configuration is intentionally separate. Do not put credentials or API tokens in this repository.

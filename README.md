# Maximo-AI — Milestone 1 Starter

Starter source code for the Maximo-AI CMMS/EAM application.

## Stack
- Frontend: React + TypeScript + Vite
- API: Cloudflare Workers + TypeScript
- Database: Cloudflare D1 (SQLite)
- Phase 1 AI integration: intentionally not connected

## Repository layout
- `apps/web`: Dashboard UI
- `apps/api`: Worker API
- `database/migrations`: D1 schema migrations

## Local development

Install dependencies in each app:

```bash
cd apps/web
npm install
npm run dev
```

In another terminal, run the API locally after configuring a local D1 database:

```bash
cd apps/api
npm install
npx wrangler dev
```

The UI reads `VITE_API_BASE_URL`. If it is unset, it calls `/api`; configure a local proxy or set the local Worker URL in `apps/web/.env.local`.

## D1 setup
The API Worker is configured in `apps/api/wrangler.jsonc`. Use separate Development and Production databases and configure secrets before production deployment.

## Important limitations
This milestone provides a dashboard shell, health endpoint, summary endpoint, and initial schema. Authentication, session management, authorization middleware, SR/WO workflows, PM scheduler, imports, notifications, and email delivery are not implemented yet. Dashboard values use demo fallback data when the API is unavailable. Do not expose this starter to production until authentication, site-level authorization, rate limiting, monitoring, migrations, backups, and security review are implemented and tested.

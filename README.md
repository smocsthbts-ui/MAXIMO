# Maximo-AI — Development Starter

Maximo-AI is a development starter for a CMMS/EAM maintenance operations application.

## Repository structure

- `apps/web`: React + TypeScript + Vite dashboard
- `apps/api`: Cloudflare Workers API
- `database/migrations`: Cloudflare D1 schema migration
- `index.html`: Standalone dashboard preview shell; the Vite application entry point is `apps/web/index.html`

## Technology

- React, TypeScript, Vite
- Cloudflare Workers
- Cloudflare D1 (SQLite)

## Run the frontend locally

Requirements: Node.js and npm.

```bash
cd apps/web
npm install
npm run dev
```

The frontend reads `VITE_API_BASE_URL`. Copy `.env.example` to `.env.local` if you need to override the development API URL.

## Run the API locally

```bash
cd apps/api
npm install
npx wrangler dev
```

The Worker configuration binds to the development D1 database. Confirm the configured account and database before running migrations or deploying.

## Cloudflare Pages build settings

For a Pages project using the Vite frontend, set:

- Production branch: `main`
- Root directory: `apps/web`
- Build command: `npm run build`
- Build output directory: `dist`

The Pages project must be connected to this GitHub repository in Cloudflare to enable automatic builds and deployments. A successful GitHub upload alone does not prove a Pages deployment succeeded.

## Current milestone and limitations

The current UI displays dashboard metrics from the API and refreshes periodically. The API currently supports health and dashboard summary endpoints. The D1 migration defines foundational organization/site, user/role, asset/location, service request, job plan, preventive maintenance, work order, work log, PM occurrence, and audit-log tables.

Authentication, session handling, role/site authorization, full SR/WO create/update workflows, PM generation, imports, notifications, email delivery, and production security hardening are not implemented. Dashboard metrics will be zero when the development database contains no matching records. Do not use this starter for production operations until security controls, workflows, data migration, backup/recovery, and operational monitoring are implemented and tested.

Never commit real passwords, API tokens, or secrets.

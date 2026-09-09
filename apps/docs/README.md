# Happy Paws documentation and feature catalog

Interactive documentation application and user story catalog for the Happy Paws platform.

## Overview

This application documents and demonstrates the end-to-end features, user stories, API endpoints, and platform support across the Happy Paws system for all user roles.

## Tech stack

- React 19
- React Router 8
- Tailwind CSS 4
- Framer Motion
- Lucide React
- Vite 8

## Development

Install dependencies from the monorepo root and start the local development server:

```bash
pnpm install
pnpm run dev:docs
```

Build the production bundle and generate client-side routing fallbacks:

```bash
pnpm run build:docs
```

Sync OpenAPI specifications from the shared contract:

```bash
pnpm --filter @happypaws/docs sync:spec
```

## Deployment

The application deploys automatically to GitHub Pages via [.github/workflows/deploy-docs.yml](../../.github/workflows/deploy-docs.yml) when changes are pushed to `main`.

### Custom domain setup

The site is served at `docs.happypawsnetwork.com`.

- The custom domain is declared in `public/CNAME`.
- In Cloudflare DNS, configure a `CNAME` record with name `docs` pointing to `happypawsnetwork.github.io`.
- Set proxy status to **DNS only** during initial certificate verification. Once GitHub finishes issuing the certificate and enforces HTTPS, proxying can be turned back on if Cloudflare SSL mode is set to **Full (strict)**.

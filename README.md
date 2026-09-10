<a href="https://github.com/happypawsnetwork/happypaws" align="center">
    <img src=".github/assets/banner.jpg" alt="Happy Paws Platform">
</a>

<p align="center">The digital platform for animal rescue and rehoming in Sri Lanka.</p>

<!-- Badges -->
<p align="center">
  <img src="https://img.shields.io/badge/Turborepo-Monorepo-EF4444?style=flat&logo=turborepo&labelColor=171717" alt="Turborepo Workspace" />
  <img src="https://img.shields.io/badge/Next.js-16-000000?style=flat&logo=nextdotjs&labelColor=171717" alt="Next.js" />
  <img src="https://img.shields.io/badge/.NET-10.0-512BD4?style=flat&logo=dotnet&labelColor=171717" alt=".NET 10" />
  <img src="https://img.shields.io/badge/Flutter-3.47-02569B?style=flat&logo=flutter&labelColor=171717" alt="Flutter" />
  <img src="https://img.shields.io/badge/PostgreSQL-18-4169E1?style=flat&logo=postgresql&labelColor=171717" alt="PostgreSQL" />
</p>

## Project overview

Happy Paws is a verified-identity platform designed to coordinate animal rescue and rehoming efforts in Sri Lanka. The platform connects rescuers, adopters, fosters, and veterinarians through a unified system. It features real-time coordination, identity verification, and AI-assisted rescue triaging so every animal receives prompt medical attention and shelter.

## Repository structure

This repository is an integrated Turborepo monorepo, containing the backend, frontend, mobile apps, and infrastructure configurations managed with `pnpm`.

```text
happypaws/
├── apps/
│   ├── api/        # ASP.NET Core 10 (Clean Architecture REST + SignalR)
│   ├── web/        # Next.js 16 (Admin Dashboard and Public Web)
│   ├── mobile/     # Flutter 3.47 (iOS and Android Client)
│   └── docs/       # Vite 8 + React 19 (Interactive Documentation and Playbook)
├── shared/         # Shared resources (OpenAPI specs and cross-app models)
├── docs/           # Architecture diagrams, user stories, and feature specs
├── docker-compose.yml # Local infrastructure (PostgreSQL, Valkey, MinIO)
├── pnpm-workspace.yaml # Workspace orchestration settings
└── turbo.json      # Turborepo caching and pipeline configuration
```

For project-specific documentation and local setup details, refer to the individual application guides:
- [API documentation](apps/api/README.md)
- [Web documentation](apps/web/README.md)
- [Mobile documentation](apps/mobile/README.md)
- [Documentation site](apps/docs/README.md)

## Prerequisites

Install the following tools before starting local development:
- **Node.js** (v20+) and **pnpm** (`npm install -g pnpm`)
- **.NET 10 SDK**
- **Flutter SDK** (v3.47+)
- **Docker** and **Docker Compose**

After cloning the repository, install workspace dependencies:
```bash
pnpm install
```

## Local development

Turborepo orchestrates commands across the entire workspace for a fast developer experience.

### Start infrastructure
Start the local PostgreSQL database, Valkey (Redis 8.0) cache, and MinIO object storage:
```bash
pnpm run dev:infra
```
MinIO automatically initializes the required `happypaws-public` and `happypaws-private` buckets on launch.

### Reset the database
To clear testing data and start with a fresh schema, run:
```bash
pnpm run db:reset
```
This command tears down existing Docker volumes, recreates the database containers, and applies Entity Framework Core migrations. On boot, the API seeds an administrator account, prints credentials to the API console, and sends a notification email via Resend.

### Run applications

Start all three applications simultaneously through Turborepo:
```bash
pnpm run dev
```

You can also run individual applications independently from the root workspace:

- **API backend**: Starts Docker infrastructure containers automatically if not already running, then launches the .NET API in watch mode:
  ```bash
  pnpm run dev:api
  ```
- **Web application**: Launches the Next.js dev server on port `3000`:
  ```bash
  pnpm run dev:web
  ```
- **Mobile application**: Launches Flutter targeting connected devices or running emulators:
  ```bash
  pnpm run dev:mobile
  ```

### Terminate processes and free ports

When stopping dev servers, background processes can linger and lock ports. Run the port-killing utility to terminate them:

```bash
# Free default dev ports (Next.js 3000, API HTTP 5197, API HTTPS 7255)
pnpm run kill-port

# Free specific custom ports
pnpm run kill-port 8080 8081

# Free dev ports and Docker infrastructure ports (5432, 6379, 9000, 9001)
pnpm run kill-port --infra

# Free all recognized dev and infrastructure ports
pnpm run kill-port --all
```

On Windows, the script terminates standard processes immediately. If a process requires administrator permissions to stop, the script automatically requests elevated privileges through a Windows UAC prompt.

### Seed accounts

When running locally in development mode, the API automatically provisions five test accounts with the default password `123`:

| Role | Email | Username | Password | Status |
| :--- | :--- | :--- | :--- | :--- |
| Adopter | `adopter@happypawsnetwork.com` | `adopter` | `123` | Unverified |
| Foster | `foster@happypawsnetwork.com` | `foster` | `123` | Verified |
| Transporter | `transporter@happypawsnetwork.com` | `transporter` | `123` | Verified |
| Veterinarian | `vet@happypawsnetwork.com` | `vet` | `123` | Verified |
| Sponsor | `sponsor@happypawsnetwork.com` | `sponsor` | `123` | Verified |

### Preview email templates

When running the API in development mode, you can preview rendered Liquid email templates directly in your browser without triggering emails:

- **Template index**: `http://localhost:5197/api/v1/dev/emails`
- **Specific template**: `http://localhost:5197/api/v1/dev/emails/{templateName}` (for example, `/api/v1/dev/emails/otp-verification` or `/api/v1/dev/emails/admin-seeded`)

Template files live in `apps/api/HappyPaws.Infrastructure/Emails/Templates/`. During development, edits to `.liquid` files reload instantly when refreshing the browser page.

The email header logo is loaded from the public CDN at `${System__CdnBaseUrl}/brand/logo.png`. To display it, upload `logo.png` to the `brand/` path in the `happypaws-public` bucket (MinIO console at `http://localhost:9001` or Cloudflare R2 dashboard).

## Common workflows

- **Linting**:
  Check code quality across TypeScript, C#, and Dart:
  ```bash
  pnpm run lint:all
  ```
- **Formatting**:
  Format files automatically with Prettier, `dotnet format`, and `dart format`:
  ```bash
  pnpm run format:all
  ```
- **Building**:
  Compile and build all workspace projects:
  ```bash
  pnpm run build
  ```
- **Git hooks**:
  Husky runs automatically after `pnpm install` so `lint-staged` formats and analyzes changed files before every commit.

## Deployment

The production platform runs on an AWS EC2 ARM64 instance managed through Coolify, with Cloudflare providing DNS and edge caching. GitHub Actions handles building multi-architecture container images and compiled mobile releases.

### GitHub Actions secrets and variables

Configure these repository secrets and variables under **Settings** -> **Secrets and variables** -> **Actions** in GitHub:

#### Secrets
- `ANDROID_KEYSTORE_BASE64`: Base64 encoded release keystore file (`happypaws-release.jks`) used to sign the Android APK.
- `ANDROID_KEYSTORE_PASSWORD`: Master password for the Android release keystore.
- `ANDROID_KEY_ALIAS`: Alias name defined inside the Android release keystore.
- `ANDROID_KEY_PASSWORD`: Password for the Android release signing key.
- `COOLIFY_API_TOKEN`: API token generated in the Coolify dashboard under Keys and tokens. Required by Coolify to authorize deployment requests to `/api/v1/deploy`.
- `COOLIFY_API_WEBHOOK`: Deploy webhook URL from the Coolify API application to trigger rolling updates.
- `COOLIFY_WEB_WEBHOOK`: Deploy webhook URL from the Coolify web application to trigger rolling updates.
- `GOOGLE_MAPS_API_KEY`: API key for Google Maps Platform, used by both mobile and web builds for map rendering and address autocompletion.
- `R2_ACCESS_KEY_ID`: Cloudflare R2 API token access key used by CI to upload release binaries to the public bucket.
- `R2_ACCOUNT_ID`: Cloudflare account identifier for the R2 storage endpoint.
- `R2_BUCKET_NAME`: Target R2 bucket name (`happypaws-public`).
- `R2_SECRET_ACCESS_KEY`: Cloudflare R2 API token secret key.
- `REGISTRY_PASSWORD`: Password for authenticating with the self-hosted Coolify Docker registry.
- `REGISTRY_URL`: Hostname of the self-hosted container registry (`registry.happypawsnetwork.com`).
- `REGISTRY_USERNAME`: Username for authenticating with the self-hosted Coolify Docker registry.

#### Variables
- `API_BASE_URL`: Public endpoint for the API (`https://api.happypawsnetwork.com`).
- `APP_URL`: Public endpoint for the web frontend (`https://happypawsnetwork.com`).

### Environment variables: build time versus runtime

Environment variables are separated based on whether client-side bundle inlining or server-side secrecy is required:

#### Build-time variables (baked into images via GitHub Actions)
Only client-side public variables for the web and mobile applications are baked into build artifacts:
- `NEXT_PUBLIC_API_URL`: The public API endpoint inlined into browser bundles during `next build`.
- `NEXT_PUBLIC_APP_URL`: The canonical web URL inlined into browser bundles during `next build`.
- `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY`: Inlined into Google Maps client components during `next build` and compiled into the mobile release APK.

#### Runtime variables (configured in Coolify)
All server-side settings, private credentials, and database secrets remain exclusively in Coolify. They are never baked into Docker images, preventing credential leaks and allowing secret rotation without rebuilding images:
- **API application**: Database connection strings (`ConnectionStrings__Database`), cache connection strings (`ConnectionStrings__Cache`), JWT signing secrets (`Jwt__SecretKey`), Cloudflare R2 / MinIO storage credentials (`Storage__*`), and Gemini API keys (`Gemini__ApiKey`).
- **Web application**: Server-to-API private routing URL (`API_URL`) for server actions and Node.js server container settings (`PORT`, `NODE_ENV`).

### Coolify application configuration

Applications deploy as Docker images pulled directly from `registry.happypawsnetwork.com`.

#### Web application (`happypawsnetwork.com`)
Refer to [`apps/web/.env.example`](apps/web/.env.example) for the standard environment variables. Add these two additional production variables in the Coolify dashboard:
- `NODE_ENV`: Set to `production` so Next.js runs optimized build outputs.
- `PORT`: Set to `3000` to match internal container routing.

#### API application (`api.happypawsnetwork.com`)
Refer to [`apps/api/HappyPaws.Api/.env.example`](apps/api/HappyPaws.Api/.env.example) for the full list of configuration keys. In Coolify:
- Point database and cache connection strings to internal container hostnames (`happypaws-db:5432` and `happypaws-redis:6379`) so traffic stays on the private Docker network.
- Configure production Cloudflare R2 storage credentials for public and private buckets.
- Set container port routing to `8080` to match ASP.NET Core runtime defaults.

#### Documentation application (`docs.happypawsnetwork.com`)
The interactive documentation site deploys to GitHub Pages via [.github/workflows/deploy-docs.yml](.github/workflows/deploy-docs.yml).

DNS routing is managed through Cloudflare:
- **Type**: `CNAME`
- **Name**: `docs`
- **Target**: `happypawsnetwork.github.io`
- **Proxy status**: Set to **DNS only** during domain verification so GitHub can complete the TLS certificate challenge. Once GitHub issues the certificate and enforces HTTPS, proxying can be turned on if Cloudflare SSL/TLS encryption mode is set to **Full (strict)**.

## Architecture references

Before contributing, review the architectural blueprints and domain rules to understand the system design:
- [System architecture](docs/architecture/system-overview.md): High-level system design, CQRS patterns, and dependency flow.
- [Feature documentation](docs/requirements/features/): Detailed specifications for rescue operations, authentication, and dual-bucket storage.
- [User stories](docs/requirements/user-stories/): Product requirements detailing how each role interacts with the platform.
- [Agent rules](.agents/rules/): Coding standards and formatting requirements enforced across the repository.

---
<p align="center"><i>Happy coding! 🐾</i></p>

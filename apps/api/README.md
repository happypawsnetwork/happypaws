# Happy Paws API

The backend for Happy Paws, built with ASP.NET Core 10 using Clean Architecture.

## Getting started

1. **Configure environment variables**
   Create a local `.env` file before running the API:
   ```bash
   cp .env.example .env
   ```
   Edit the newly created `.env` file to insert your personal variables:
   - **Email__ApiKey**: Get this from your Resend dashboard.
   - **Jwt__SecretKey**: Generate a secure 32+ character string (e.g., `openssl rand -base64 32`).
   - **ConnectionStrings__Redis**: Update this to match the Docker setup (e.g., `localhost:6379,password=happypaws_dev,abortConnect=false`).
   - Map `System__Domain` and `System__CdnBaseUrl` to your environment.

2. **Storage, CDN, and branding assets**
   The `happypaws-public` bucket (managed by MinIO locally or Cloudflare R2 in production) stores public assets such as animal pictures and branding materials.
   - **Configure CDN base URL**: Set `System__CdnBaseUrl` in `.env` (default is `http://localhost:9000/happypaws-public` for local MinIO, or `https://cdn.happypawsnetwork.com` for production Cloudflare R2).
   - **Upload email logo**: Place `logo.png` inside the `brand/` path of the `happypaws-public` bucket (key: `brand/logo.png`). The email layout template references `{{ CdnBaseUrl }}/brand/logo.png` to display the header logo.

3. **Database migrations and API documentation**
   - **Database migrations**: The API automatically applies pending Entity Framework Core migrations and seeds initial data every time it starts. In development mode, it seeds five verified test accounts (`adopter@`, `foster@`, `transporter@`, `vet@`, and `sponsor@happypawsnetwork.com`) with password `123`.
   - **API documentation**: Set `ENABLE_API_DOCS=true` in your `.env` file to enable OpenAPI endpoint generation and the Scalar API reference UI at `/scalar/v1`.

4. **Run the application**
   From the repository root, start the API using Turborepo:
   ```bash
   pnpm run dev:api
   ```
   Alternatively, run it directly from this directory using the .NET CLI:
   ```bash
   dotnet run --project HappyPaws.Api
   ```

5. **Testing the API**
   Once the API is running, verify its status and explore the endpoints:
   - **Scalar API reference**: When `ENABLE_API_DOCS=true`, navigate to the root URL in your browser. It automatically redirects to the interactive Scalar documentation at `/scalar/v1`.
   - **Health checks**: Access `/health` or `/healthz` to confirm the API is responsive.
   - **Email templates preview (development only)**: When running locally in development mode, preview rendered Liquid email templates directly in your browser:
     - Directory index: `http://localhost:5197/api/v1/dev/emails`
     - OTP verification email: `http://localhost:5197/api/v1/dev/emails/otp-verification`
     - Administrator seeded credentials email: `http://localhost:5197/api/v1/dev/emails/admin-seeded`
     In development mode, templates are read directly from the source folder `HappyPaws.Infrastructure/Emails/Templates/`, so edits to `.liquid` files reload immediately upon browser refresh.

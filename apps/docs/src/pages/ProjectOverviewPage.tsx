import { useState } from "react";
import { Link } from "react-router";
import {
  Server,
  Smartphone,
  LayoutGrid,
  Database,
  Sparkles,
  Copy,
  Check,
  ExternalLink,
  User,
  HeartHandshake,
  Truck,
  Stethoscope,
  Coins,
  ArrowRight,
  Layers,
  Globe,
  Mail,
  Power,
} from "lucide-react";

export function ProjectOverviewPage() {
  const [activeTab, setActiveTab] = useState<"all" | "api" | "web" | "mobile" | "infra">("all");
  const [copiedKey, setCopiedKey] = useState<string | null>(null);

  const handleCopy = (text: string, key: string) => {
    navigator.clipboard.writeText(text);
    setCopiedKey(key);
    setTimeout(() => setCopiedKey(null), 2000);
  };

  const seedAccounts = [
    {
      role: "Adopter",
      email: "adopter@happypawsnetwork.com",
      username: "adopter",
      password: "123",
      icon: User,
      color: "teal",
      isVerified: false,
      description: "Applies for pet adoptions, submits rescue reports, and manages adopter profile.",
    },
    {
      role: "Foster",
      email: "foster@happypawsnetwork.com",
      username: "foster",
      password: "123",
      icon: HeartHandshake,
      color: "indigo",
      isVerified: true,
      description: "Manages temporary foster placements, medical updates, and animal handovers.",
    },
    {
      role: "Transporter",
      email: "transporter@happypawsnetwork.com",
      username: "transporter",
      password: "123",
      icon: Truck,
      color: "emerald",
      isVerified: true,
      description: "Coordinates animal transit trips, verifies routes, and logs rescue pickups.",
    },
    {
      role: "Veterinarian",
      email: "vet@happypawsnetwork.com",
      username: "vet",
      password: "123",
      icon: Stethoscope,
      color: "rose",
      isVerified: true,
      description: "Reviews clinical KYC records, verifies AI urgency scores, and submits medical guidance.",
    },
    {
      role: "Sponsor",
      email: "sponsor@happypawsnetwork.com",
      username: "sponsor",
      password: "123",
      icon: Coins,
      color: "amber",
      isVerified: true,
      description: "Pledges financial donations and supplies for active rescue operations.",
    },
  ];

  return (
    <div className="space-y-12 animate-in fade-in duration-300 pb-16 max-w-5xl">
      {/* Page Header */}
      <div className="space-y-3 border-b border-slate-200/80 pb-6">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-teal-50 text-teal-800 border border-teal-200/80 text-xs font-semibold">
          <Sparkles className="w-3.5 h-3.5 text-teal-600" />
          Sri Lanka Animal Rescue & Rehoming Network
        </div>
        <h1 className="text-3xl md:text-4xl font-bold text-slate-900 tracking-tight">
          Project overview
        </h1>
        <p className="text-sm md:text-base text-slate-600 leading-relaxed max-w-3xl">
          Happy Paws is a verified identity platform designed to coordinate animal rescue and rehoming in Sri Lanka. The platform connects rescuers, adopters, fosters, transporters, and veterinarians through a unified system with real-time coordination, identity verification, and Gemini AI triage.
        </p>
      </div>

      {/* System Metrics */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="p-5 rounded-2xl bg-white border border-slate-200/80 shadow-2xs space-y-1">
          <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
            User stories
          </span>
          <p className="text-2xl md:text-3xl font-bold text-slate-900">79</p>
          <p className="text-xs text-slate-500">Verified end-to-end features</p>
        </div>

        <div className="p-5 rounded-2xl bg-white border border-slate-200/80 shadow-2xs space-y-1">
          <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
            Domain roles
          </span>
          <p className="text-2xl md:text-3xl font-bold text-slate-900">6</p>
          <p className="text-xs text-slate-500">Adopters, fosters, vets, and admins</p>
        </div>

        <div className="p-5 rounded-2xl bg-white border border-slate-200/80 shadow-2xs space-y-1">
          <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
            App stacks
          </span>
          <p className="text-2xl md:text-3xl font-bold text-slate-900">3</p>
          <p className="text-xs text-slate-500">ASP.NET Core 10, Next.js 16, Flutter 3.47</p>
        </div>

        <div className="p-5 rounded-2xl bg-white border border-slate-200/80 shadow-2xs space-y-1">
          <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
            Infrastructure
          </span>
          <p className="text-2xl md:text-3xl font-bold text-slate-900">3</p>
          <p className="text-xs text-slate-500">PostgreSQL, Valkey, MinIO S3</p>
        </div>
      </div>

      {/* Repository Structure */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-bold text-slate-900">Repository structure</h2>
          <span className="text-xs font-medium text-slate-500">Turborepo & pnpm workspace</span>
        </div>
        <p className="text-sm text-slate-600">
          The project is structured as an integrated Turborepo monorepo, keeping the backend API, web portal, mobile application, and shared specifications together in one codebase.
        </p>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-5 pt-2">
          {/* API Card */}
          <div className="p-6 rounded-2xl bg-white border border-slate-200/80 shadow-2xs space-y-4 flex flex-col justify-between">
            <div className="space-y-3">
              <div className="w-10 h-10 rounded-xl bg-purple-50 text-purple-700 border border-purple-100 flex items-center justify-center">
                <Server className="w-5 h-5" />
              </div>
              <div>
                <span className="text-[10px] font-mono uppercase px-2 py-0.5 rounded bg-purple-50 text-purple-700 font-semibold">
                  apps/api
                </span>
                <h3 className="text-base font-bold text-slate-900 mt-1">Backend API</h3>
                <p className="text-xs text-purple-700 font-medium">ASP.NET Core 10 & EF Core 10</p>
              </div>
              <p className="text-xs text-slate-600 leading-relaxed">
                Clean Architecture design using Minimal APIs, TypedResults, PostgreSQL, Valkey caching, and SignalR real-time messaging hubs.
              </p>
            </div>
            <div className="pt-3 border-t border-slate-100 text-[11px] text-slate-500 font-mono space-y-1">
              <div>HTTP: <span className="text-slate-800 font-semibold">localhost:5197</span></div>
              <div>Docs: <span className="text-slate-800 font-semibold">/scalar/v1</span></div>
            </div>
          </div>

          {/* Web Card */}
          <div className="p-6 rounded-2xl bg-white border border-slate-200/80 shadow-2xs space-y-4 flex flex-col justify-between">
            <div className="space-y-3">
              <div className="w-10 h-10 rounded-xl bg-blue-50 text-blue-700 border border-blue-100 flex items-center justify-center">
                <LayoutGrid className="w-5 h-5" />
              </div>
              <div>
                <span className="text-[10px] font-mono uppercase px-2 py-0.5 rounded bg-blue-50 text-blue-700 font-semibold">
                  apps/web
                </span>
                <h3 className="text-base font-bold text-slate-900 mt-1">Web portal</h3>
                <p className="text-xs text-blue-700 font-medium">Next.js 16 & React 19</p>
              </div>
              <p className="text-xs text-slate-600 leading-relaxed">
                Next.js App Router portal for administration, featuring live rescue coordination maps, identity KYC review, and content moderation.
              </p>
            </div>
            <div className="pt-3 border-t border-slate-100 text-[11px] text-slate-500 font-mono space-y-1">
              <div>URL: <span className="text-slate-800 font-semibold">localhost:3000</span></div>
              <div>Styling: <span className="text-slate-800 font-semibold">Tailwind CSS 4</span></div>
            </div>
          </div>

          {/* Mobile Card */}
          <div className="p-6 rounded-2xl bg-white border border-slate-200/80 shadow-2xs space-y-4 flex flex-col justify-between">
            <div className="space-y-3">
              <div className="w-10 h-10 rounded-xl bg-amber-50 text-amber-700 border border-amber-100 flex items-center justify-center">
                <Smartphone className="w-5 h-5" />
              </div>
              <div>
                <span className="text-[10px] font-mono uppercase px-2 py-0.5 rounded bg-amber-50 text-amber-700 font-semibold">
                  apps/mobile
                </span>
                <h3 className="text-base font-bold text-slate-900 mt-1">Mobile application</h3>
                <p className="text-xs text-amber-700 font-medium">Flutter 3.47 & Dart</p>
              </div>
              <p className="text-xs text-slate-600 leading-relaxed">
                Cross-platform mobile client for Android and iOS, powering field rescue reporting, GPS location tagging, pet search, and in-app chat.
              </p>
            </div>
            <div className="pt-3 border-t border-slate-100 text-[11px] text-slate-500 font-mono space-y-1">
              <div>Target: <span className="text-slate-800 font-semibold">Android & iOS</span></div>
              <div>API Host: <span className="text-slate-800 font-semibold">10.0.2.2 (Emulator)</span></div>
            </div>
          </div>
        </div>

        {/* Monorepo directory map */}
        <div className="p-5 rounded-2xl bg-slate-900 text-slate-200 font-mono text-xs overflow-x-auto shadow-inner">
          <p className="text-slate-400 mb-2 font-sans font-semibold text-[11px] uppercase tracking-wider">
            Workspace folder layout
          </p>
          <pre className="leading-relaxed">
{`happypaws/
├── apps/
│   ├── api/        # ASP.NET Core 10 (Clean Architecture REST + SignalR)
│   ├── web/        # Next.js 16 (Administration Portal and Web Client)
│   └── mobile/     # Flutter 3.47 (iOS and Android Mobile App)
├── playbook/       # Interactive demonstration and feature catalog
├── shared/         # Shared OpenAPI contracts and cross-application models
├── docs/           # System architecture, feature specifications, and rules
├── docker-compose.yml # PostgreSQL, Valkey cache, and MinIO storage
├── pnpm-workspace.yaml # Monorepo workspace configuration
└── turbo.json      # Pipeline build cache orchestration`}
          </pre>
        </div>
      </div>

      {/* Prerequisites */}
      <div className="space-y-4">
        <h2 className="text-xl font-bold text-slate-900">Prerequisites</h2>
        <p className="text-sm text-slate-600">
          Install the required runtimes and tools before starting local development:
        </p>

        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-3">
          <div className="p-4 rounded-xl bg-white border border-slate-200/80 shadow-2xs space-y-1">
            <span className="text-xs font-bold text-slate-900">Node.js & pnpm</span>
            <p className="text-xs text-slate-500">Node.js 20+ and pnpm</p>
            <code className="text-[11px] text-teal-700 font-mono block pt-1">npm i -g pnpm</code>
          </div>

          <div className="p-4 rounded-xl bg-white border border-slate-200/80 shadow-2xs space-y-1">
            <span className="text-xs font-bold text-slate-900">.NET 10 SDK</span>
            <p className="text-xs text-slate-500">C# 13 and ASP.NET Core</p>
            <code className="text-[11px] text-teal-700 font-mono block pt-1">dotnet --version</code>
          </div>

          <div className="p-4 rounded-xl bg-white border border-slate-200/80 shadow-2xs space-y-1">
            <span className="text-xs font-bold text-slate-900">Flutter SDK</span>
            <p className="text-xs text-slate-500">Version 3.47 or later</p>
            <code className="text-[11px] text-teal-700 font-mono block pt-1">flutter doctor</code>
          </div>

          <div className="p-4 rounded-xl bg-white border border-slate-200/80 shadow-2xs space-y-1">
            <span className="text-xs font-bold text-slate-900">Docker</span>
            <p className="text-xs text-slate-500">Docker Desktop and Compose</p>
            <code className="text-[11px] text-teal-700 font-mono block pt-1">docker compose up</code>
          </div>
        </div>

        <div className="p-4 rounded-xl bg-slate-50 border border-slate-200 flex items-center justify-between gap-4">
          <div className="space-y-0.5">
            <p className="text-xs font-semibold text-slate-800">Install workspace dependencies</p>
            <p className="text-xs text-slate-500">Run this once after cloning the repository to link all packages.</p>
          </div>
          <button
            type="button"
            onClick={() => handleCopy("pnpm install", "pnpm-install")}
            className="px-3 py-1.5 rounded-lg bg-white hover:bg-slate-100 border border-slate-200 text-xs font-mono text-slate-700 flex items-center gap-1.5 transition cursor-pointer shadow-2xs shrink-0"
          >
            {copiedKey === "pnpm-install" ? (
              <Check className="w-3.5 h-3.5 text-teal-600" />
            ) : (
              <Copy className="w-3.5 h-3.5 text-slate-400" />
            )}
            <span>pnpm install</span>
          </button>
        </div>
      </div>

      {/* Local Development Guide with Tab Switcher */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-xl font-bold text-slate-900">Local development</h2>
            <p className="text-sm text-slate-500">
              Follow these commands to start local services, run individual apps, or test the full stack.
            </p>
          </div>
        </div>

        {/* Tab Pills */}
        <div className="flex items-center gap-2 border-b border-slate-200/80 pb-3 overflow-x-auto">
          {[
            { id: "all", label: "Full workspace", icon: Layers },
            { id: "api", label: "API backend", icon: Server },
            { id: "web", label: "Web portal", icon: LayoutGrid },
            { id: "mobile", label: "Mobile client", icon: Smartphone },
            { id: "infra", label: "Infrastructure", icon: Database },
          ].map((tab) => {
            const Icon = tab.icon;
            const isSelected = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                type="button"
                onClick={() => setActiveTab(tab.id as "all" | "api" | "web" | "mobile" | "infra")}
                className={`px-3.5 py-1.5 rounded-xl text-xs font-medium flex items-center gap-2 transition cursor-pointer shrink-0 ${
                  isSelected
                    ? "bg-teal-700 text-white shadow-2xs font-semibold"
                    : "bg-slate-100 text-slate-600 hover:bg-slate-200/70"
                }`}
              >
                <Icon className="w-3.5 h-3.5" />
                <span>{tab.label}</span>
              </button>
            );
          })}
        </div>

        {/* Tab 1: Full Workspace */}
        {activeTab === "all" && (
          <div className="space-y-4 animate-in fade-in duration-150">
            <div className="p-5 rounded-2xl bg-white border border-slate-200/80 shadow-2xs space-y-4">
              <div className="space-y-1">
                <h3 className="text-sm font-bold text-slate-900">Step 1: Start local infrastructure</h3>
                <p className="text-xs text-slate-600">
                  Launches PostgreSQL, Valkey cache, and MinIO object storage in background Docker containers.
                </p>
              </div>
              <div className="p-3 rounded-xl bg-slate-900 text-slate-100 font-mono text-xs flex items-center justify-between">
                <code>pnpm run dev:infra</code>
                <button
                  type="button"
                  onClick={() => handleCopy("pnpm run dev:infra", "cmd-infra")}
                  className="p-1 rounded text-slate-400 hover:text-white transition cursor-pointer"
                  title="Copy command"
                >
                  {copiedKey === "cmd-infra" ? <Check className="w-3.5 h-3.5 text-teal-400" /> : <Copy className="w-3.5 h-3.5" />}
                </button>
              </div>
            </div>

            <div className="p-5 rounded-2xl bg-white border border-slate-200/80 shadow-2xs space-y-4">
              <div className="space-y-1">
                <h3 className="text-sm font-bold text-slate-900">Step 2: Reset the database and apply migrations</h3>
                <p className="text-xs text-slate-600">
                  Recreates containers, executes Entity Framework Core migrations, and automatically provisions five test accounts.
                </p>
              </div>
              <div className="p-3 rounded-xl bg-slate-900 text-slate-100 font-mono text-xs flex items-center justify-between">
                <code>pnpm run db:reset</code>
                <button
                  type="button"
                  onClick={() => handleCopy("pnpm run db:reset", "cmd-db-reset")}
                  className="p-1 rounded text-slate-400 hover:text-white transition cursor-pointer"
                  title="Copy command"
                >
                  {copiedKey === "cmd-db-reset" ? <Check className="w-3.5 h-3.5 text-teal-400" /> : <Copy className="w-3.5 h-3.5" />}
                </button>
              </div>
            </div>

            <div className="p-5 rounded-2xl bg-white border border-slate-200/80 shadow-2xs space-y-4">
              <div className="space-y-1">
                <h3 className="text-sm font-bold text-slate-900">Step 3: Run all applications simultaneously</h3>
                <p className="text-xs text-slate-600">
                  Starts the backend API, the Next.js web application, and the Flutter mobile client together through Turborepo.
                </p>
              </div>
              <div className="p-3 rounded-xl bg-slate-900 text-slate-100 font-mono text-xs flex items-center justify-between">
                <code>pnpm run dev</code>
                <button
                  type="button"
                  onClick={() => handleCopy("pnpm run dev", "cmd-dev-all")}
                  className="p-1 rounded text-slate-400 hover:text-white transition cursor-pointer"
                  title="Copy command"
                >
                  {copiedKey === "cmd-dev-all" ? <Check className="w-3.5 h-3.5 text-teal-400" /> : <Copy className="w-3.5 h-3.5" />}
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Tab 2: API Backend */}
        {activeTab === "api" && (
          <div className="space-y-4 animate-in fade-in duration-150">
            <div className="p-5 rounded-2xl bg-white border border-slate-200/80 shadow-2xs space-y-4">
              <div className="space-y-1">
                <h3 className="text-sm font-bold text-slate-900">Configure API environment</h3>
                <p className="text-xs text-slate-600">
                  Create a local environment file in <code className="font-mono text-teal-800">apps/api/HappyPaws.Api/.env</code>:
                </p>
              </div>
              <div className="p-3 rounded-xl bg-slate-900 text-slate-100 font-mono text-xs flex items-center justify-between">
                <code>cp apps/api/HappyPaws.Api/.env.example apps/api/HappyPaws.Api/.env</code>
                <button
                  type="button"
                  onClick={() => handleCopy("cp apps/api/HappyPaws.Api/.env.example apps/api/HappyPaws.Api/.env", "cp-api-env")}
                  className="p-1 rounded text-slate-400 hover:text-white transition cursor-pointer"
                >
                  {copiedKey === "cp-api-env" ? <Check className="w-3.5 h-3.5 text-teal-400" /> : <Copy className="w-3.5 h-3.5" />}
                </button>
              </div>
              <ul className="text-xs text-slate-600 space-y-1 list-disc list-inside">
                <li><strong className="text-slate-800">Email__ApiKey</strong>: API key from your Resend dashboard.</li>
                <li><strong className="text-slate-800">Jwt__SecretKey</strong>: A secure string of 32 or more characters.</li>
                <li><strong className="text-slate-800">ConnectionStrings__Redis</strong>: Defaults to local Valkey container.</li>
                <li><strong className="text-slate-800">ENABLE_API_DOCS</strong>: Set to true to enable interactive Scalar docs.</li>
              </ul>
            </div>

            <div className="p-5 rounded-2xl bg-white border border-slate-200/80 shadow-2xs space-y-4">
              <div className="space-y-1">
                <h3 className="text-sm font-bold text-slate-900">Run the API</h3>
                <p className="text-xs text-slate-600">
                  Starts Docker infrastructure if not already running, then launches the .NET API in watch mode:
                </p>
              </div>
              <div className="p-3 rounded-xl bg-slate-900 text-slate-100 font-mono text-xs flex items-center justify-between">
                <code>pnpm run dev:api</code>
                <button
                  type="button"
                  onClick={() => handleCopy("pnpm run dev:api", "cmd-api-run")}
                  className="p-1 rounded text-slate-400 hover:text-white transition cursor-pointer"
                >
                  {copiedKey === "cmd-api-run" ? <Check className="w-3.5 h-3.5 text-teal-400" /> : <Copy className="w-3.5 h-3.5" />}
                </button>
              </div>
              <p className="text-xs text-slate-500">
                You can also run directly from the API directory using <code className="font-mono text-slate-700">dotnet run --project HappyPaws.Api</code>.
              </p>
            </div>
          </div>
        )}

        {/* Tab 3: Web Portal */}
        {activeTab === "web" && (
          <div className="space-y-4 animate-in fade-in duration-150">
            <div className="p-5 rounded-2xl bg-white border border-slate-200/80 shadow-2xs space-y-4">
              <div className="space-y-1">
                <h3 className="text-sm font-bold text-slate-900">Configure web environment</h3>
                <p className="text-xs text-slate-600">
                  Create a local environment file in <code className="font-mono text-teal-800">apps/web/.env.local</code>:
                </p>
              </div>
              <div className="p-3 rounded-xl bg-slate-900 text-slate-100 font-mono text-xs flex items-center justify-between">
                <code>cp apps/web/.env.example apps/web/.env.local</code>
                <button
                  type="button"
                  onClick={() => handleCopy("cp apps/web/.env.example apps/web/.env.local", "cp-web-env")}
                  className="p-1 rounded text-slate-400 hover:text-white transition cursor-pointer"
                >
                  {copiedKey === "cp-web-env" ? <Check className="w-3.5 h-3.5 text-teal-400" /> : <Copy className="w-3.5 h-3.5" />}
                </button>
              </div>
              <p className="text-xs text-slate-500">
                This configures <code className="font-mono text-slate-700">NEXT_PUBLIC_API_URL</code> so client-side components communicate with the local API.
              </p>
            </div>

            <div className="p-5 rounded-2xl bg-white border border-slate-200/80 shadow-2xs space-y-4">
              <div className="space-y-1">
                <h3 className="text-sm font-bold text-slate-900">Start Next.js dev server</h3>
                <p className="text-xs text-slate-600">
                  Launches the Next.js development server on port 3000:
                </p>
              </div>
              <div className="p-3 rounded-xl bg-slate-900 text-slate-100 font-mono text-xs flex items-center justify-between">
                <code>pnpm run dev:web</code>
                <button
                  type="button"
                  onClick={() => handleCopy("pnpm run dev:web", "cmd-web-run")}
                  className="p-1 rounded text-slate-400 hover:text-white transition cursor-pointer"
                >
                  {copiedKey === "cmd-web-run" ? <Check className="w-3.5 h-3.5 text-teal-400" /> : <Copy className="w-3.5 h-3.5" />}
                </button>
              </div>
              <p className="text-xs text-slate-500">
                Navigate to <a href="http://localhost:3000" target="_blank" rel="noreferrer" className="text-teal-700 hover:underline font-semibold">http://localhost:3000</a> to view the web portal.
              </p>
            </div>
          </div>
        )}

        {/* Tab 4: Mobile Client */}
        {activeTab === "mobile" && (
          <div className="space-y-4 animate-in fade-in duration-150">
            <div className="p-5 rounded-2xl bg-white border border-slate-200/80 shadow-2xs space-y-4">
              <div className="space-y-1">
                <h3 className="text-sm font-bold text-slate-900">Configure mobile network host</h3>
                <p className="text-xs text-slate-600">
                  Create a <code className="font-mono text-teal-800">.env</code> file in <code className="font-mono text-teal-800">apps/mobile/.env</code>:
                </p>
              </div>
              <div className="p-3 rounded-xl bg-slate-900 text-slate-100 font-mono text-xs flex items-center justify-between">
                <code>cp apps/mobile/.env.example apps/mobile/.env</code>
                <button
                  type="button"
                  onClick={() => handleCopy("cp apps/mobile/.env.example apps/mobile/.env", "cp-mobile-env")}
                  className="p-1 rounded text-slate-400 hover:text-white transition cursor-pointer"
                >
                  {copiedKey === "cp-mobile-env" ? <Check className="w-3.5 h-3.5 text-teal-400" /> : <Copy className="w-3.5 h-3.5" />}
                </button>
              </div>
              <div className="text-xs text-slate-600 space-y-1">
                <p>For an <strong>Android emulator</strong> communicating with your local API, set:</p>
                <code className="block p-2 rounded bg-slate-100 font-mono text-[11px] text-slate-800">API_BASE_URL=http://10.0.2.2:5197</code>
                <p className="pt-1">For an <strong>iOS simulator or physical phone</strong>, replace with your development machine LAN IP address.</p>
              </div>
            </div>

            <div className="p-5 rounded-2xl bg-white border border-slate-200/80 shadow-2xs space-y-4">
              <div className="space-y-1">
                <h3 className="text-sm font-bold text-slate-900">Launch Flutter client</h3>
                <p className="text-xs text-slate-600">
                  Starts the mobile app on your connected device or running simulator:
                </p>
              </div>
              <div className="p-3 rounded-xl bg-slate-900 text-slate-100 font-mono text-xs flex items-center justify-between">
                <code>pnpm run dev:mobile</code>
                <button
                  type="button"
                  onClick={() => handleCopy("pnpm run dev:mobile", "cmd-mobile-run")}
                  className="p-1 rounded text-slate-400 hover:text-white transition cursor-pointer"
                >
                  {copiedKey === "cmd-mobile-run" ? <Check className="w-3.5 h-3.5 text-teal-400" /> : <Copy className="w-3.5 h-3.5" />}
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Tab 5: Infrastructure */}
        {activeTab === "infra" && (
          <div className="space-y-4 animate-in fade-in duration-150">
            <div className="p-5 rounded-2xl bg-white border border-slate-200/80 shadow-2xs space-y-3">
              <h3 className="text-sm font-bold text-slate-900">Local Docker services</h3>
              <p className="text-xs text-slate-600">
                The local infrastructure includes three services managed via <code className="font-mono text-slate-800">docker-compose.yml</code>:
              </p>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 pt-1">
                <div className="p-3 rounded-xl bg-slate-50 border border-slate-200 space-y-1">
                  <span className="text-xs font-bold text-slate-800">PostgreSQL 18</span>
                  <p className="text-[11px] font-mono text-slate-500">Port: 5432</p>
                  <p className="text-[11px] text-slate-500">Database: happypaws</p>
                </div>
                <div className="p-3 rounded-xl bg-slate-50 border border-slate-200 space-y-1">
                  <span className="text-xs font-bold text-slate-800">Valkey Cache</span>
                  <p className="text-[11px] font-mono text-slate-500">Port: 6379</p>
                  <p className="text-[11px] text-slate-500">Redis 8.0 drop-in</p>
                </div>
                <div className="p-3 rounded-xl bg-slate-50 border border-slate-200 space-y-1">
                  <span className="text-xs font-bold text-slate-800">MinIO Storage</span>
                  <p className="text-[11px] font-mono text-slate-500">API: 9000 | Web: 9001</p>
                  <p className="text-[11px] text-slate-500">Public & private S3</p>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Port Management Utility */}
      <div className="p-6 rounded-2xl bg-white border border-slate-200/80 shadow-2xs space-y-3">
        <div className="flex items-center gap-2 text-slate-900 font-bold text-base">
          <Power className="w-5 h-5 text-teal-700" />
          <h3>Terminate lingering processes and free ports</h3>
        </div>
        <p className="text-xs text-slate-600 leading-relaxed">
          Background development servers can hold onto network ports when closed. Run the workspace port killer to release them without restarting your computer:
        </p>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 pt-1 font-mono text-xs">
          <div className="p-3 rounded-xl bg-slate-50 border border-slate-200 flex items-center justify-between">
            <div>
              <p className="font-semibold text-slate-800">pnpm run kill-port</p>
              <p className="text-[10px] text-slate-500 font-sans">Ports 3000, 5197, 7255</p>
            </div>
            <button
              type="button"
              onClick={() => handleCopy("pnpm run kill-port", "kill-default")}
              className="p-1 rounded text-slate-400 hover:text-slate-700 transition cursor-pointer"
            >
              {copiedKey === "kill-default" ? <Check className="w-3.5 h-3.5 text-teal-600" /> : <Copy className="w-3.5 h-3.5" />}
            </button>
          </div>

          <div className="p-3 rounded-xl bg-slate-50 border border-slate-200 flex items-center justify-between">
            <div>
              <p className="font-semibold text-slate-800">pnpm run kill-port --infra</p>
              <p className="text-[10px] text-slate-500 font-sans">Ports 5432, 6379, 9000</p>
            </div>
            <button
              type="button"
              onClick={() => handleCopy("pnpm run kill-port --infra", "kill-infra")}
              className="p-1 rounded text-slate-400 hover:text-slate-700 transition cursor-pointer"
            >
              {copiedKey === "kill-infra" ? <Check className="w-3.5 h-3.5 text-teal-600" /> : <Copy className="w-3.5 h-3.5" />}
            </button>
          </div>

          <div className="p-3 rounded-xl bg-slate-50 border border-slate-200 flex items-center justify-between">
            <div>
              <p className="font-semibold text-slate-800">pnpm run kill-port --all</p>
              <p className="text-[10px] text-slate-500 font-sans">All recognized dev ports</p>
            </div>
            <button
              type="button"
              onClick={() => handleCopy("pnpm run kill-port --all", "kill-all")}
              className="p-1 rounded text-slate-400 hover:text-slate-700 transition cursor-pointer"
            >
              {copiedKey === "kill-all" ? <Check className="w-3.5 h-3.5 text-teal-600" /> : <Copy className="w-3.5 h-3.5" />}
            </button>
          </div>
        </div>
      </div>

      {/* Seeded Development Accounts */}
      <div className="space-y-4">
        <div>
          <h2 className="text-xl font-bold text-slate-900">Seeded test accounts</h2>
          <p className="text-sm text-slate-500">
            During local development, five test accounts are provisioned with password <code className="font-mono text-teal-800 font-semibold">123</code>.
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
          {seedAccounts.map((acc) => {
            const Icon = acc.icon;
            return (
              <div
                key={acc.role}
                className="p-4 rounded-2xl bg-white border border-slate-200/80 shadow-2xs space-y-3 flex flex-col justify-between"
              >
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <div className="p-1.5 rounded-lg bg-teal-50 text-teal-700 border border-teal-100">
                        <Icon className="w-4 h-4" />
                      </div>
                      <span className="text-sm font-bold text-slate-900">{acc.role}</span>
                    </div>
                    <span
                      className={`text-[10px] font-mono px-2 py-0.5 rounded-full font-semibold border ${
                        acc.isVerified
                          ? "bg-emerald-50 text-emerald-700 border-emerald-200/60"
                          : "bg-amber-50 text-amber-700 border-amber-200/60"
                      }`}
                    >
                      {acc.isVerified ? "Verified" : "Unverified"}
                    </span>
                  </div>
                  <p className="text-xs text-slate-500 line-clamp-2">{acc.description}</p>
                </div>

                <div className="pt-2 border-t border-slate-100 space-y-1.5 text-xs font-mono">
                  <div className="flex items-center justify-between bg-slate-50 p-1.5 rounded-lg border border-slate-200/60">
                    <span className="text-slate-600 truncate">{acc.email}</span>
                    <button
                      type="button"
                      onClick={() => handleCopy(acc.email, `email-${acc.role}`)}
                      className="p-1 text-slate-400 hover:text-slate-700 transition cursor-pointer"
                      title="Copy email"
                    >
                      {copiedKey === `email-${acc.role}` ? <Check className="w-3 h-3 text-teal-600" /> : <Copy className="w-3 h-3" />}
                    </button>
                  </div>
                  <div className="flex items-center justify-between text-[11px] text-slate-500 px-1">
                    <span>Password: <strong className="text-slate-800">123</strong></span>
                    <span>User: <strong className="text-slate-800">{acc.username}</strong></span>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Developer Tooling & Inspection */}
      <div className="space-y-4">
        <h2 className="text-xl font-bold text-slate-900">Developer tooling & inspection</h2>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          {/* Scalar API Documentation */}
          <div className="p-5 rounded-2xl bg-white border border-slate-200/80 shadow-2xs space-y-3">
            <div className="flex items-center gap-2 text-teal-800 font-bold text-sm">
              <Globe className="w-4 h-4 text-teal-600" />
              <h3>Interactive Scalar API reference</h3>
            </div>
            <p className="text-xs text-slate-600 leading-relaxed">
              When <code className="font-mono text-slate-800">ENABLE_API_DOCS=true</code> is configured in the API environment, the API automatically mounts an interactive Scalar documentation portal at <code className="font-mono text-teal-800">/scalar/v1</code>.
            </p>
            <div className="pt-2">
              <a
                href="http://localhost:5197/scalar/v1"
                target="_blank"
                rel="noreferrer"
                className="inline-flex items-center gap-1.5 text-xs font-semibold text-teal-700 hover:text-teal-800 hover:underline"
              >
                <span>Open Scalar reference UI</span>
                <ExternalLink className="w-3.5 h-3.5" />
              </a>
            </div>
          </div>

          {/* Liquid Email Template Previews */}
          <div className="p-5 rounded-2xl bg-white border border-slate-200/80 shadow-2xs space-y-3">
            <div className="flex items-center gap-2 text-purple-800 font-bold text-sm">
              <Mail className="w-4 h-4 text-purple-600" />
              <h3>Liquid email template previews</h3>
            </div>
            <p className="text-xs text-slate-600 leading-relaxed">
              Preview rendered transactional emails directly in your browser without sending test emails. Templates reload live on browser refresh:
            </p>
            <div className="space-y-1 text-xs font-mono">
              <a
                href="http://localhost:5197/api/v1/dev/emails"
                target="_blank"
                rel="noreferrer"
                className="block text-teal-700 hover:underline"
              >
                &rarr; /api/v1/dev/emails (Template directory)
              </a>
              <a
                href="http://localhost:5197/api/v1/dev/emails/otp-verification"
                target="_blank"
                rel="noreferrer"
                className="block text-teal-700 hover:underline"
              >
                &rarr; /api/v1/dev/emails/otp-verification
              </a>
            </div>
          </div>
        </div>
      </div>

      {/* Common Workflows */}
      <div className="space-y-4">
        <h2 className="text-xl font-bold text-slate-900">Common developer workflows</h2>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="p-4 rounded-xl bg-white border border-slate-200/80 shadow-2xs space-y-2">
            <span className="text-xs font-bold text-slate-900">Linting</span>
            <p className="text-xs text-slate-500">Runs ESLint, dotnet format analyzer, and dart analyze.</p>
            <code className="text-[11px] text-teal-800 font-mono block bg-slate-50 p-1.5 rounded border border-slate-200/60">
              pnpm run lint:all
            </code>
          </div>

          <div className="p-4 rounded-xl bg-white border border-slate-200/80 shadow-2xs space-y-2">
            <span className="text-xs font-bold text-slate-900">Formatting</span>
            <p className="text-xs text-slate-500">Formats files with Prettier, dotnet format, and dart format.</p>
            <code className="text-[11px] text-teal-800 font-mono block bg-slate-50 p-1.5 rounded border border-slate-200/60">
              pnpm run format:all
            </code>
          </div>

          <div className="p-4 rounded-xl bg-white border border-slate-200/80 shadow-2xs space-y-2">
            <span className="text-xs font-bold text-slate-900">Building</span>
            <p className="text-xs text-slate-500">Compiles and builds all workspace packages with Turborepo.</p>
            <code className="text-[11px] text-teal-800 font-mono block bg-slate-50 p-1.5 rounded border border-slate-200/60">
              pnpm run build
            </code>
          </div>
        </div>
      </div>

      {/* Deployment & Cloud Architecture */}
      <div className="p-6 rounded-2xl bg-white border border-slate-200/80 shadow-2xs space-y-4">
        <div className="space-y-1">
          <h2 className="text-xl font-bold text-slate-900">Production deployment</h2>
          <p className="text-xs text-slate-600">
            The platform is deployed on an AWS EC2 ARM64 server running Coolify, backed by Cloudflare DNS, Cloudflare R2 object storage, and automated GitHub Actions pipelines.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 pt-1">
          <div className="p-4 rounded-xl bg-slate-50 border border-slate-200/80 space-y-1.5">
            <span className="text-xs font-bold text-slate-900">Build-time variables</span>
            <p className="text-xs text-slate-600 leading-relaxed">
              Public client variables (<code className="font-mono text-slate-800">NEXT_PUBLIC_API_URL</code> and <code className="font-mono text-slate-800">NEXT_PUBLIC_APP_URL</code>) are inlined into browser bundles during GitHub Actions image compilation.
            </p>
          </div>

          <div className="p-4 rounded-xl bg-slate-50 border border-slate-200/80 space-y-1.5">
            <span className="text-xs font-bold text-slate-900">Runtime secrets</span>
            <p className="text-xs text-slate-600 leading-relaxed">
              Database connection strings, JWT signing keys, and Gemini AI credentials remain exclusively in Coolify. Secrets are never baked into Docker images.
            </p>
          </div>
        </div>
      </div>

      {/* Next step prompt */}
      <div className="p-6 rounded-2xl bg-gradient-to-r from-teal-50 to-emerald-50 border border-teal-200/80 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div className="space-y-1">
          <h3 className="text-base font-bold text-teal-950">Explore user roles</h3>
          <p className="text-xs text-teal-800">
            Review detailed user stories, demo steps, and technical viva talking points for all 6 platform roles.
          </p>
        </div>
        <Link
          to="/user-roles"
          className="px-4 py-2.5 rounded-xl bg-teal-700 hover:bg-teal-800 text-white text-xs font-semibold transition flex items-center gap-2 shrink-0 shadow-2xs"
        >
          <span>Explore 6 user roles</span>
          <ArrowRight className="w-4 h-4" />
        </Link>
      </div>
    </div>
  );
}

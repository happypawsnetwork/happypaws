# Agent directives (Happy Paws)

You are operating within the Happy Paws polyglot monorepo. When you are invoked in this project root or any of its subdirectories, you must strictly obey the rules and contexts outlined below.

## Writing style

Whenever you generate text (such as code comments, OpenAPI metadata, markdown documentation, PR descriptions, or chat responses), you must read and adhere to:
- [Writing style guide](.agents/rules/writing-style.md)

Key constraints: Plain language only. No em dashes. No semicolons. Use the Oxford comma. Sentence case for all headings and labels. No filler phrases ("leverage", "utilize", "ensure", "streamline"). Explain why, not what.

## Workspace Hygiene

You must maintain a clean and production-ready workspace. Do NOT leave stray files, temporary scripts, leftover logs, or unused artifacts in the repository. Clean up any files generated during agentic coding or testing (e.g., `scratch/`, `tmp/`, one-off scripts) before completing your tasks. Ensure no hardcoded secrets or passwords are inadvertently committed.

## Progress tracking

You must proactively track your progress by updating the documentation. When you complete a feature or user story, read and adhere to:
- [Progress tracking rules](.agents/rules/progress-tracking.md)

## Project-specific coding standards

This repository contains multiple applications built on different technology stacks. You must apply the correct coding standard for the specific application you are modifying:

- **API (ASP.NET Core 10)**: Before touching anything in `apps/api/`, read and strictly enforce [API coding style](docs/standards/coding-style.md). It mandates Clean Architecture, Minimal APIs, TypedResults, Scalar OpenAPI metadata, and specific EF Core patterns.
- **Web (Next.js 16)**: Before touching anything in `apps/web/`, read [Web coding style](.agents/rules/coding-style-web.md). It mandates Server Components by default, Zod-validated Server Actions, route-gating middleware, and accessibility standards.
- **Mobile (Flutter 3.47)**: Before touching anything in `apps/mobile/`, read [Mobile coding style](.agents/rules/coding-style-mobile.md). It mandates clean feature-first layering, secure token storage caching, explicit controller disposal, and responsive widget design.

## Domain knowledge and architecture context

Do not guess business rules, database schemas, or architectural patterns. Before implementing features, use your file-reading tools to consult the official documentation in the `docs/` directory:

- **System architecture**: Read `docs/architecture/system-overview.md` to understand layer responsibilities, CQRS patterns, and dependencies.
- **Storage and buckets**: Read `docs/requirements/features/storage.md` to understand the public versus private bucket architecture (MinIO and Cloudflare R2) and presigned URL rules.
- **Features and user stories**: Read the relevant files in `docs/requirements/features/` and `docs/requirements/user-stories/` before implementing core logic for adoptions, emergency rescues, or user authentication.

## Shared resources and API specifications

The `shared/api-specs/` directory stores OpenAPI specifications and schema definitions shared across applications:

- **Backend agents**: When creating or modifying endpoints in `apps/api/`, export or refresh the OpenAPI contract in `shared/api-specs/swagger.json`.
- **Frontend and mobile agents**: Consult `shared/api-specs/` to inspect endpoint paths, request payloads, query parameters, and response structures directly without running the backend API.


## Agent skills

Use your installed agent skills in `.agents/skills/` to maintain code quality and follow best practices:
- **Database and schema design**: Use `postgresql-table-design`, `postgresql-optimization`, `database-schema-designer`, and `domain-driven-design` when creating or modifying database schemas, table constraints, indexes, and domain models.
- **Backend (.NET and EF Core)**: Use `minimal-api` and `ef-core` when writing API endpoints, configuring Entity Framework Core entities, or structuring Clean Architecture layers.
- **Frontend (Next.js)**: Use `frontend-design` for visual and styling guidelines.
- **Mobile (Flutter and Dart)**: Use the installed `dart-*` and `flutter-*` skills when working on the mobile app. This includes skills for testing (`dart-add-unit-test`, `flutter-add-widget-test`, `flutter-add-integration-test`, `dart-collect-coverage`, `dart-generate-test-mocks`, `dart-migrate-to-checks-package`), UI and layout (`flutter-build-responsive-layout`, `flutter-fix-layout-issues`, `flutter-add-widget-preview`), architecture and setup (`flutter-apply-architecture-best-practices`, `flutter-setup-declarative-routing`, `flutter-setup-localization`, `flutter-implement-json-serialization`, `flutter-use-http-package`), Dart syntax and patterns (`dart-use-pattern-matching`, `dart-use-primary-constructors`, `dart-write-documentation`, `dart-use-doc-examples`), CLI and FFI (`dart-build-cli-app`, `dart-setup-ffi-assets`, `dart-use-ffigen`), and tooling (`dart-run-static-analysis`, `dart-fix-runtime-errors`, `dart-resolve-package-conflicts`).

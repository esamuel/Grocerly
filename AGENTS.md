# Repository Guidelines

## Project Structure & Module Organization
- `apps/mobile` (Expo + React Native) and `apps/web` (Next.js) are the runnable apps.
- `packages/ui`, `packages/utils`, `packages/i18n`, `packages/api` contain shared code (TypeScript modules).
- `packages/tsconfig/tsconfig.json` sets strict TS + path aliases.
- `infra/` houses infra config (e.g., Supabase). Native iOS stubs live in `Grocerly.xcodeproj/`.

## Build, Test, and Development Commands
- Install: `pnpm install` (Node 20+, Corepack recommended).
- Dev (both): `pnpm dev` (runs web and mobile concurrently).
- Dev (web): `pnpm dev:web` or `pnpm --filter @grocerly/web dev` → http://localhost:3000.
- Dev (mobile): `pnpm dev:mobile` or `pnpm --filter @grocerly/mobile start` (then `i`/`a`).
- Lint/Types/Test: `pnpm lint` | `pnpm typecheck` | `pnpm test` (runs across workspaces; tests may be empty initially).
- Build: `pnpm build` (recursively builds all packages/apps).

## Coding Style & Naming Conventions
- Language: TypeScript (strict). Indentation: 2 spaces.
- Linting: ESLint (`eslint .` inside apps). Add rules per app as needed.
- Exports: prefer named exports from shared packages.
- Naming: components `PascalCase.tsx`, hooks `useX.ts`, utilities `kebab-case.ts`.
- Paths: use TS aliases from `packages/tsconfig` (e.g., `@grocerly/ui`).

## Testing Guidelines
- Framework: not yet configured; prefer Vitest or Jest + React Testing Library.
- Location: co-locate as `*.test.ts[x]` or `__tests__/file.test.ts`.
- Scope: cover pure utils (`packages/utils`), API wrappers, and critical UI.
- Run: `pnpm test` (CI runs with `--ci`). Skip-heavy packages should print "tests skipped".

## Commit & Pull Request Guidelines
- Commits: Conventional prefixes — `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`.
- PRs: small, focused; include description, linked issues, and screenshots/video for UI.
- CI: must be green (lint/typecheck/test/build). The workflow auto no-ops where not applicable.

## Security & Configuration Tips
- Env vars: copy `.env.example` → `.env` (Expo) and `.env.local` (Next.js). Never commit secrets.
- Supabase: set `EXPO_PUBLIC_*` and `NEXT_PUBLIC_*` keys per `.env.example`.
- Dependencies: use `pnpm` and workspace versions (`workspace:*`) to avoid drift.

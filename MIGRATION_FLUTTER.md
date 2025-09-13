# Grocerly → Flutter Migration Plan

This document maps the current product scope to a fresh Flutter codebase and outlines a safe, stepwise migration. No destructive actions occur until explicitly approved.

## Goals
- Rebuild Grocerly as a first‑class Flutter app targeting iOS, Android, and Web.
- Preserve product scope, data model, and infra (Supabase) from the README.
- Keep the repo maintainable with clear modules and CI.

## High‑Level Architecture (Flutter)
- UI: Flutter (Material 3), responsive layouts, light/dark themes.
- Routing: `go_router` for declarative navigation (web‑friendly URLs).
- State: `riverpod` (or `hooks_riverpod`) + `flutter_riverpod` for DI and state.
- Models: `freezed` + `json_serializable` for immutable models and serialization.
- Backend: `supabase_flutter` (Auth, PostgREST, Realtime, Storage).
- Offline cache: `isar` (or `hive`) for local persistence and optimistic UI.
- Voice input: `speech_to_text` (voice → text), optional `permission_handler`.
- i18n: `flutter_localizations` + `intl` with ARB message files; RTL support.
- Theming: system light/dark, user accent color, font presets.
- Testing: `flutter_test`, `mocktail`, `integration_test`.

## Packages (initial set)
- Core:
  - `flutter`, `cupertino_icons`, `material` (built‑in)
  - `go_router`, `flutter_riverpod`/`hooks_riverpod`, `freezed`, `json_serializable`, `build_runner`
  - `supabase_flutter`, `uuid`, `equatable`
  - `isar`, `isar_flutter_libs` (or `hive`, `hive_flutter`)
  - `speech_to_text`, `permission_handler`
  - `intl`, `flutter_localizations`
- Dev:
  - `flutter_lints`, `very_good_analysis` (optional), `mocktail`

## Project Structure (proposed)
```
apps/
  grocerly_flutter/            # Primary Flutter app
packages/
  domain/                      # Pure Dart models, validators, mappers
  data/                        # Repositories (Supabase, cache, realtime)
  ui/                          # Design system widgets, theming, icons
  i18n/                        # ARB locales + i18n tooling
infra/
  supabase/                    # Existing DB schema, RLS policies, migrations
```

Optionally manage multi‑package with `melos` (can be added later).

## Feature Mapping (from README)
- Lists & Items: `ListRepository` and `ListItemRepository` backed by Supabase; realtime listeners map to Riverpod streams; optimistic updates with local cache.
- Voice Add: `speech_to_text` → parse → categorize (local rules + server function). Provide “confirm add” UX.
- Categorization: lightweight local rules + server‑side function (e.g., edge function) for improved accuracy.
- Budgets & Totals: compute on device from item prices; persist to `budgets` table; currency via `intl`.
- Pantry Sync: on item check‑off, increment pantry quantities and update local cache.
- Recipe Import: server function to parse; client collects URL/text and confirms mapped ingredients.
- Store Order Templates: store preference in `store_order_templates`; apply to list order; respect manual overrides.
- Realtime: subscribe to space/list channels for presence & updates.
- i18n: ARB files per locale; pluralization via `intl`; RTL where applicable.
- Accessibility: large text, contrast, semantics, focus, haptics.

## Data Model (from README)
Tables: `profiles`, `spaces`, `space_members`, `lists`, `list_items`, `pantry_items`, `products`, `prices`, `stores`, `store_order_templates`, `recipes`, `recipe_ingredients`, `budgets`, `reminders`.

Client models mirror tables with `freezed` and `json_serializable`. Repositories handle mapping and policy constraints (RLS).

## Screens (MVP)
- Auth & Space Selection
- Lists (space switcher, create list)
- List Detail (add item voice/text, categories, check‑off)
- Budget Bar + Running Total
- Pantry Overview
- Settings (profile, locale, theme)

## Routing (GoRouter)
`/auth`, `/spaces`, `/lists`, `/lists/:id`, `/pantry`, `/settings` (web‑friendly, deep‑linkable).

## Offline Strategy
- Cache essential tables (`lists`, `list_items`, `pantry_items`, `products`, `stores`).
- Write‑through cache with optimistic updates; reconcile on reconnect.
- Persist minimal session/auth for quick start.

## Testing Strategy
- Unit: domain models, utils, categorization rules.
- Widget: list screen, adding items, budget bar.
- Integration: auth flow, realtime updates basic path.

## CI Outline
- `flutter --version` check and cache
- `flutter pub get`
- `dart run build_runner build --delete-conflicting-outputs`
- `flutter analyze` and `flutter test`
- Optional: build iOS/Android/Web on release tags

## Migration Steps (safe path)
1) Approve destructive reset scope:
   - Keep `infra/` and Xcode stubs? Tag current repo? Create archive branch?
2) Create Flutter workspace skeleton:
   - `apps/grocerly_flutter` with `pubspec.yaml`, `lib/main.dart`, theming, routing skeleton.
   - `packages/domain`, `packages/data`, `packages/ui`, `packages/i18n` as Dart/Flutter packages.
3) Wire Supabase:
   - Add `supabase_flutter`; set env vars; session init; auth screens.
4) Implement Lists & Realtime:
   - Repositories, providers, screens; optimistic add/check‑off.
5) Voice Add & Categorization:
   - Local rules; edge function hook; UX affordances.
6) Budgets & Pantry Sync:
   - Running totals, simple budgets; pantry update on check‑off.
7) Recipes (basic):
   - Input, parse hook to server, confirm mapping.
8) Polish + i18n + accessibility; web tweaks; CI build.

## Deep Linking (Auth)
- Package: `uni_links` handles incoming URIs on iOS/Android. The app calls `Supabase.instance.client.auth.getSessionFromUrl(uri)` to set the session.
- Env defines the expected scheme/host:
  - `--dart-define=DEEP_LINK_SCHEME=grocerly --dart-define=DEEP_LINK_HOST=auth-callback`
  - Example redirect: `grocerly://auth-callback`.
- Supabase: set `Auth > URL configuration > Redirect URLs` to include the deep link, e.g. `grocerly://auth-callback` and any web callback you use.
- iOS (ios/Runner/Info.plist):
  - Add URL types: URL Schemes = `grocerly`.
  - Associated domains only if using universal links (optional).
- Android (android/app/src/main/AndroidManifest.xml):
  - Add intent filter for scheme/host:
    ```xml
    <intent-filter android:autoVerify="true">
      <action android:name="android.intent.action.VIEW" />
      <category android:name="android.intent.category.DEFAULT" />
      <category android:name="android.intent.category.BROWSABLE" />
      <data android:scheme="grocerly" android:host="auth-callback" />
    </intent-filter>
    ```
- Web: Supabase will redirect to the current origin; ensure router can strip tokens or rely on `supabase_flutter` web handling.

To generate platform folders, run inside `apps/grocerly_flutter`:
```
flutter create .
```
Then apply the iOS/Android edits above.

## Destructive Reset Options
- Option A (recommended):
  - Create archive branch `pre-flutter-mono` and tag `pre-flutter-<date>`.
  - Remove `apps/*` and `packages/*` JS/TS code; keep `infra/`.
  - Scaffold Flutter app and packages.
- Option B (non‑destructive):
  - Keep existing code; add Flutter under `apps/grocerly_flutter/` and new Dart `packages/`.
  - Deprecate JS/TS later after parity.

## Open Questions
- Keep `infra/` as‑is and continue Supabase? (default: yes)
- Prefer `isar` or `hive` for cache? (default: `isar`)
- Riverpod vs Bloc? (default: Riverpod)
- Single app vs melos multi‑package? (default: multi‑package)

## Next Actions (awaiting approval)
- Confirm reset option (A or B) and what to preserve.
- If A: archive branch + delete TS apps/packages; commit.
- Scaffold Flutter skeleton and add CI config.

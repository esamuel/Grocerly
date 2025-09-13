# Grocerly

grocery shop helper

Smart, shared, and delightful grocery lists that think ahead. Voice input, real‑time sync, budgeting, pantry inventory, and recipe‑to‑list—localized for 40+ languages.

Note: The project is migrating to Flutter. See `MIGRATION_FLUTTER.md` for the new architecture and steps.

## Status
- Planning and scaffolding stage. This README defines scope, architecture, and delivery workflow. CI is included and will no‑op until code exists.

## Vision
- Make shopping effortless: speak or type items and Grocerly auto‑categorizes (Produce, Pantry, etc.).
- Keep families in sync across iOS, Android, and web with real‑time updates.
- Help people save money with budgets, prices, and smart suggestions.
- Offer power without clutter: advanced features when you want them, a “Lite UI” when you don’t.

## Core Features
- Voice Input + Intelligent Sorting: dictate or type; items auto‑sorted into store sections.
- Family Sharing & Web Access: collaborative lists with presence and conflict‑free syncing.
- Product Catalog + Budget Tools: item prices, running totals, monthly budget views, price history.
- Unlimited Lists and Localization: many lists, localized products, 40+ languages.

## Brilliant Ideas (Product Enhancements)
- Keep Custom Order Intact: never override unless user toggles; store‑specific order templates.
- Budget Planner & Price Totals: instant running total; budget progress and alerts.
- Pantry Inventory Sync: auto‑update pantry from purchased/checked items; avoid duplicates.
- Recipe → Shopping: import via link/text; extract ingredients and auto‑categorize with quantities.
- Advanced Dark Mode & Themes: light/dark, accent colors, fonts, and themes.
- Intelligent Suggestions: history/season/location based recommendations (e.g., sunscreen in summer).
- Smart Reminders: time or location triggers (near store == remind bananas).
- Multi‑Platform Access: mobile + web; optional Mac Catalyst and watchOS.
- Lightweight Mode: “Lite UI” toggle hides advanced panels for minimalists.

---

## Product Scope
- MVP (0.1)
  - Create account, join family space.
  - Create unlimited lists, add items (voice/text), auto‑categorize.
  - Real‑time sync; basic web UI.
  - Price input per item; running total; simple budget per list.
  - Pantry inventory linked to list check‑offs.
  - Import one recipe → extract ingredients to list.
  - English + basic i18n framework.
- v1.0
  - Store‑specific order templates; multi‑store.
  - Full recipe box, parser improvements, ingredient normalization.
  - Advanced budgets, price history & insights.
  - 20+ languages; watchOS glance + voice add.
  - Suggestions, reminders, theming, Lite UI.

## Personas & Key Jobs
- Busy parent: share lists, plan budget, avoid duplicates.
- Student/roommates: split responsibilities, minimal UI, quick capture.
- Foodies: recipe‑to‑list, pantry management, seasonal suggestions.

---

## Recommended Architecture
- App: Flutter (Material 3) with GoRouter; iOS, Android, and Web targets.
- Backend: Supabase (Postgres + Auth + Realtime) with Row‑Level Security.
- APIs: PostgREST, edge functions for heavier tasks.
- AI: categorization and parsing via server functions; pluggable provider.
- Voice: `speech_to_text` for on‑device capture.
- i18n: `intl` with ARB messages; RTL support.
- State: Riverpod for DI/state; optimistic updates with local cache.
- Notifications: native notifications; location geofencing where supported.
- Theming: system light/dark, user accent color, font presets.

### Data Model (high‑level)
- profiles(id, email, display_name, locale)
- spaces(id, name) — family/workspace; space_members(space_id, user_id, role)
- lists(id, space_id, name, store_id, currency)
- list_items(id, list_id, product_id?, name, quantity, unit, note, category, price, is_checked)
- pantry_items(id, space_id, product_id?, name, quantity, unit, location, expires_at)
- products(id, canonical_name, synonyms[], default_category)
- prices(id, product_id, store_id?, amount, currency, recorded_at)
- stores(id, space_id, name); store_order_templates(id, store_id, section_order[])
- recipes(id, space_id, title, url?, servings, notes); recipe_ingredients(id, recipe_id, name, qty, unit)
- budgets(id, space_id, period, limit_amount, currency)
- reminders(id, list_id, type, at_time?, geofence?)

### Security & Privacy
- Row‑Level Security: users can access data only within their spaces.
- Token‑based auth; no cross‑space leakage.
- Minimal telemetry, opt‑in analytics; no sale of data.
- Encryption at rest (DB) and TLS in transit.

---

## Key Flows
- Add Item (voice): speech → text → categorize (AI + rules) → item created → optimistic UI.
- Check‑off Item: item marked → pantry increment/update → price captured → total updated.
- Recipe Import: paste link/text → parse → ingredient normalization → user confirmation → add to list.
- Store Order: apply template to list; drag to customize; save per store.
- Budgeting: set limit → show running total + remaining; monthly roll‑up and price history.

## Internationalization
- Localized product names and categories per locale.
- Units and currency per space; flexible quantity parsing (e.g., “1kg”, “2 cans”).
- RTL support and pluralization rules via i18next.

## Accessibility
- VoiceOver/TalkBack; high contrast; large text.
- Haptic feedback and clear focus states.
- Color‑blind safe category palette.

---

## Development Setup (Flutter)
- Requirements: Flutter 3.22+, Dart 3.3+, Xcode + Android Studio, Supabase project, Git.
- Clone: `git clone <repo> && cd Grocerly`
- Get deps: `flutter pub get` (run inside `apps/grocerly_flutter` and each `packages/*` as needed)
- Run: `flutter run` (inside `apps/grocerly_flutter`)
- Analyze/Test: `flutter analyze` | `flutter test`

### Suggested Project Structure
```
apps/
  mobile/           # Expo app (iOS/Android/Web)
  web/              # Next.js (optional if not using Expo Web)
packages/
  ui/               # Shared design system
  api/              # tRPC/router types
  utils/            # Shared helpers
  i18n/             # Locales and i18n config
infra/
  supabase/         # DB schema, RLS policies, migrations
```

---

## Delivery Workflow
- Branching: `main` (stable), feature branches (`feat/...`), short‑lived.
- PRs: small, focused, with screenshots/video for UI; require green CI.
- CI: install, lint, typecheck, test, build; caches pnpm. No‑op if no JS project yet.
- Code Quality: ESLint + Prettier + TypeScript strict; unit tests for logic; component tests for critical UI.
- Releases: tag `vX.Y.Z`; TestFlight/internal testing; staged rollout.
- Secrets: store in GitHub Envs/Actions secrets; never commit.

## Milestones
- M0 – Repo + CI + Schema draft
- M1 – MVP list + realtime + voice basic + budget total
- M2 – Pantry sync + recipe import + web UI stable
- M3 – Store templates + reminders + themes + suggestions
- M4 – Localization 20+ languages + watchOS + Lite UI

## Contributing
- Open issues with context and acceptance criteria.
- Follow commit convention: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`.
- Add tests for new logic; update docs when behavior changes.

## License
- TBD.

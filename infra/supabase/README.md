# Supabase Infra

This folder contains SQL migrations for Grocerly (Postgres on Supabase) and suggested RLS policies.

## Prereqs
- Supabase project created (URL + anon key).
- Supabase CLI installed (optional but recommended).

## Apply migrations (local or remote)

Using Supabase CLI (local dev):
- supabase start
- supabase db reset

Using psql (remote):
- psql "$SUPABASE_DB_URL" -f migrations/0001_init.sql

## Notes
- RLS is enabled on all user data tables.
- Access is restricted to members of a space via `space_members`.
- Adjust policies as needed once app roles evolve.


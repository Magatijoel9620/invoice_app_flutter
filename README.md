# InvoiceEasy V3.0 — merged offline-first + Supabase cloud build

This build combines the richer InvoiceEasy V2.5/phase UI and platform targets with the V3.0 offline-first Supabase authentication, profile, cloud sync, account management, and delete-account Edge Function.

## What was merged

- V2.5/phase UI and business setup flow
- V3.0 Supabase authentication
- Offline local storage remains the source used by the UI
- Persistent sync queue for customers, products, invoices and business profile
- Last-write-wins style timestamp merge
- Supabase Row Level Security (one authenticated user -> one business)
- Account profile, sign-out, password reset and cloud account deletion
- Sync status banner and manual sync
- Reports/export and the existing platform targets
- Supabase migration consolidated into `supabase/migrations/20260912_v3_cloud_foundation.sql`

## Important architecture decision

The cloud schema stores the app's JSON models in `data` columns instead of duplicating every InvoiceEasy model field as a SQL column. This keeps the cloud layer compatible with the existing offline models while still enforcing ownership and business isolation through relational metadata + RLS.

Only the consolidated V3 SQL migration is shipped. Earlier phase migrations defined incompatible schemas and must not be applied to the same fresh V3 database.

## Run locally without cloud

```bash
flutter pub get
flutter run
```

If `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` are omitted, InvoiceEasy runs as a local/offline app.

## Run with Supabase

```bash
flutter pub get
flutter run   --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co   --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
```

Never put a Supabase secret key/service-role key in Flutter code or `--dart-define` values shipped to users.

See `SUPABASE_SETUP.md` for the complete setup walkthrough.

## V3.0 implementation status

### V3.0.1 — Supabase foundation
- Email/password authentication and persistent sessions
- Account profile
- One authenticated user -> one business
- Cloud repositories/mapping
- RLS and automatic profile creation

### V3.0.2 — Sync
- Offline-first local writes
- Account-scoped local storage
- Persistent pending queue
- Push/pull synchronization
- Three-attempt transient retry
- Last-write-wins conflict strategy
- Cloud tombstones for deletes
- First-login local/cloud bootstrap

### V3.0.3 — Account
- Account profile screen
- Business data persisted through the cloud sync layer
- Manual sync and status
- Password reset
- Sign out
- Cloud account deletion through the Edge Function

See `SUPABASE_SETUP.md` for deployment and migration instructions.

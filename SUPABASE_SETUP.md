# InvoiceEasy V3.0 Supabase setup

InvoiceEasy V3 uses an offline-first client with Supabase as the cloud layer.
The ownership model is deliberately simple:

**one authenticated user → one business profile → that business's customers, catalog and invoices.**

There is no workspace, team, membership or business switcher model.

## 1. Create a Supabase project

Create a project in the Supabase dashboard and copy its Project URL and Publishable Key.

Do not put a secret/service-role key in Flutter.

## 2. Apply the schema

For a fresh V3 project, run only:

`supabase/migrations/20260912_v3_cloud_foundation.sql`

The migration creates:

- `profiles`
- `businesses`
- `customers`
- `products`
- `invoices`
- automatic profile creation on signup
- updated-at triggers
- soft-delete tombstones
- RLS for every cloud table
- one-business-per-user enforcement

The older phase migrations are intentionally excluded from the final V3 build because they use incompatible normalized schemas.

## 3. Configure Flutter

Run from `invoice_app_flutter`:

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

For a release build, provide the same two compile-time values through your CI/build configuration.

## 4. Email authentication

Enable Email authentication in Supabase Authentication settings. If email confirmation is enabled, a new user must confirm the email before a session is created.

Configure the password-reset redirect/deep-link for each platform you ship. The app calls `resetPasswordForEmail()` and Supabase handles the email delivery.

## 5. Account deletion

Deploy the Edge Function:

```bash
supabase functions deploy delete-account
```

The function validates the caller's JWT and then uses the server-side Supabase secret to delete the authenticated user. Never expose that secret in Flutter.

## 6. Sync behavior

Local writes are saved immediately and added to a small persistent sync queue. When authenticated, InvoiceEasy:

1. resolves the user's single cloud business;
2. pulls cloud records;
3. applies last-write-wins using timestamps;
4. pushes pending local changes;
5. pulls again so all devices converge on the server state.

Transient failures retry up to three times. A failed queue item remains pending for the next manual/automatic sync.

Deletes are soft-deleted in the cloud so another device cannot resurrect a deleted record merely because it did not receive the delete at the same moment.

## 7. Local account isolation

V3 namespaces local SharedPreferences data by authenticated user ID. Existing pre-V3 local data is placed into an anonymous migration scope and is migrated into the first signed-in user's scope when appropriate. This prevents a second account on the same device from seeing another account's local invoices.

## 8. First login

If the device already has a configured local business and the cloud account has no business, the local business is adopted by the authenticated account. If the cloud account already has a business, the cloud business wins on first bootstrap rather than being overwritten by the local placeholder. Local legacy invoice business IDs are rebound to the authenticated business before sync.

# InvoiceEasy safe merge — 30 October 2026

## Source of truth
Built against the uploaded `invoice_easy_project.zip`. The four uploaded change archives were reviewed. Only targeted changes were merged; no migration, database schema, Edge Function, Payment Engine contract, provider secret, or plan price was changed.

## Root causes identified

1. **Business setup reappearing after restart:** `SyncService.start()` kicked off `sync()` without awaiting it. `SyncService.bootstrap()` then called `sync()` again, but the `_running` guard returned immediately. The authenticated startup gate could therefore invalidate/read the business provider before cloud business restoration completed. The merged single-flight sync makes concurrent callers await the same in-flight sync.
2. **Duplicate local scope switching:** `AuthService.signIn/signUp` switched the local scope while the auth-state listener also switched it in `_AuthenticatedHome`. Scope ownership is now exclusively in `_AuthenticatedHome`, avoiding competing scope migrations.
3. **New-account billing bootstrap ordering:** `invoiceeasy-billing-bridge` requires an existing cloud `businesses` row. Startup previously called `subscriptionBootstrapProvider` before `SyncService.bootstrap()`, so a first-login snapshot could fail with `InvoiceEasy business not found`. Startup now restores/syncs the business first, then bootstraps billing only when a configured business exists. Business setup completion retries billing bootstrap only after successful online sync.
4. **Plan catalogue retry after offline setup:** plan loading now waits for a configured business's sync when online before requesting the billing snapshot. It watches connectivity so the provider can be retried when connectivity changes.

## Additional safe error handling merged
- Centralized customer-facing error classification.
- Authentication screen uses friendly errors and adds confirmation resend.
- Subscription screen no longer exposes raw billing exceptions in the main payment actions.
- Subscription bootstrap and business profile gates display friendly errors.
- Sync failures are reported with customer-friendly text while queued local data is retained.

## Files included
- `lib/main.dart`
- `lib/services/auth_service.dart`
- `lib/services/sync_service.dart`
- `lib/core/providers/subscription_providers.dart`
- `lib/core/errors/app_error.dart`
- `lib/screens/auth/auth_screen.dart`
- `lib/screens/subscription_screen.dart`
- `lib/core/widgets/subscription_bootstrap_gate.dart`

## Preserved
- No local data deletion or scope reset.
- No trial reset or trial-date modification.
- No subscription/payment table or migration changes.
- No Payment Engine request/response contract changes.
- No business ownership or RLS changes.
- No Farmora files or backend changes.
- Existing InvoiceEasy monthly KES 200 pricing and current plan configuration remain untouched.

## Validation
The source changes were reviewed and merged. Flutter/Dart SDK is not available in the build environment used to prepare this patch, so `flutter analyze`, `flutter test`, and an APK build have NOT been run. Run the commands in the project after applying the patch.

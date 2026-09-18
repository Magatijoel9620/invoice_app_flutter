# InvoiceEasy subscription hardening — 2.6

Implemented from the Landlord Ledger subscription architecture, adapted to InvoiceEasy's one-user/one-business model.

## Plans

- **Free Trial:** 14 days, full access.
- **Monthly:** **KSh 200 / month**.
- **Yearly:** **KSh 2,000 / year** (KSh 400 saving versus 12 monthly payments).

## Supabase hardening

Migration:

`supabase/migrations/20260914_invoice_easy_subscription_hardening.sql`

It creates:

- `subscription_plans`
- `subscriptions`
- `payment_transactions`
- RLS policies for subscription data
- `create_trial_subscription()`
- `refresh_subscription_status()`
- `create_payment_intent(plan_code)`
- `has_invoice_easy_write_access()` — server-authoritative write gate

The important security rule is that the Flutter client **cannot insert/update/delete subscriptions or mark a payment completed**. Paid access is granted only by trusted server-side payment verification/admin tooling.

InvoiceEasy business/customer/product/invoice cloud writes are also protected by subscription access at the database policy level. Expired users retain read access so they can inspect existing records and open the subscription screen.

## Apply the migration

From the InvoiceEasy project:

```bash
npx supabase db push
```

If the Supabase project is already linked, this will apply the new migration. Do not manually edit the migration history table.

## Client behavior

- Authenticated startup provisions/refreshes the trial.
- Subscription status is refreshed from Supabase.
- The subscription panel is available from the top-bar premium icon and the menu.
- When access expires, the UI redirects write actions to the subscription panel.
- Offline writes remain local/queued; sync does not repeatedly attempt cloud writes while the account is read-only.
- Existing records remain readable after expiry.
- Payment requests are recorded as `pending`; activation must happen after server-side verification.

## Payment flow note

The UI uses M-Pesa Till **1658309** and creates a server-side pending payment intent. This package deliberately does not pretend that a payment is successful. To automate activation, connect the pending transaction to a trusted M-Pesa callback/verification Edge Function and have that server-side code complete the transaction and extend the subscription.

## Verification

Run:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
```

The provided build environment may not have Flutter installed; if `flutter analyze` reports `command not found`, run the verification on the machine/CI environment that has the Flutter SDK.

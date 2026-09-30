# InvoiceEasy → Payment Engine v3 integration

## Product identity

```text
product_code = invoice_easy
resource_type = business
resource_id = businesses.id
external_owner_id = auth.users.id
```

InvoiceEasy keeps its own Supabase project and authentication. The Payment Engine remains in its own Billing Supabase project.

## Server-side secrets

Set these on the **InvoiceEasy Supabase Edge Function** environment:

```text
PAYMENT_ENGINE_URL=https://<payment-engine-project>.supabase.co
PAYMENT_ENGINE_SERVICE_ROLE_KEY=<payment-engine-service-role-key>
PAYMENT_ENGINE_BRIDGE_SECRET=<shared-random-bridge-secret>
```

Optional manual-payment configuration:

```text
INVOICE_EASY_TILL_NUMBER=<InvoiceEasy billing till>
INVOICE_EASY_TILL_NAME=InvoiceEasy
INVOICE_EASY_TILL_INSTRUCTIONS=Pay the exact plan amount, then submit the M-Pesa transaction reference.
```

Set the matching `PAYMENT_ENGINE_BRIDGE_SECRET` on the Payment Engine `start-payment` and `verify-provider-payment` functions. Existing `FARMORA_BILLING_BRIDGE_SECRET` remains supported for Farmora compatibility.

Never place any of these values in Flutter, `--dart-define`, or the application repository.

## Payment Engine deployment

Apply the existing certified migrations first, then:

```text
supabase/migrations/0005_external_consumer_invoice_easy.sql
```

This migration adds only InvoiceEasy product catalog/routing configuration:

- KSh 200 monthly
- KSh 2,000 annual
- 14-day trial configuration
- IntaSend enabled
- manual M-Pesa enabled

## InvoiceEasy deployment

Apply:

```text
supabase/migrations/20260929_payment_engine_billing_bridge.sql
```

Deploy:

```text
supabase/functions/payment-engine-billing-bridge
```

Then run the Flutter app with its normal InvoiceEasy Supabase configuration.

## Runtime flow

```text
InvoiceEasy Flutter
      ↓ authenticated user JWT
InvoiceEasy billing bridge
      ↓ server-to-server service role
Payment Engine Billing Supabase
      ↓
central account / plan / intent
      ↓
Payment Engine start-payment
      ↓
IntaSend hosted checkout
      ↓
IntaSend webhook
      ↓
Payment Engine verification
      ↓
subscription + entitlements
      ↓
InvoiceEasy bridge snapshot
      ↓
local subscription/payment projection
      ↓
existing InvoiceEasy access/RLS
```

Manual M-Pesa follows the same central model. Submitting a reference only moves the central intent into verification/pending state; it does not activate access.

## Important

Do not delete the existing InvoiceEasy subscription tables yet. They are now the application-side projection/cache and continue to satisfy existing local RLS/access assumptions while the Payment Engine becomes authoritative.

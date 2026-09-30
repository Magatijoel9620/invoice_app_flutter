# InvoiceEasy Payment Engine v3 patch manifest

## InvoiceEasy files

```text
pubspec.yaml
pubspec.lock
lib/core/providers/subscription_providers.dart
lib/screens/subscription_screen.dart
lib/data/supabase/payment_engine_subscription_repository.dart
supabase/migrations/20260929_payment_engine_billing_bridge.sql
supabase/functions/payment-engine-billing-bridge/index.ts
docs/INVOICE_EASY_PAYMENT_ENGINE_INTEGRATION.md
```

## Payment Engine files

```text
supabase/migrations/0005_external_consumer_invoice_easy.sql
supabase/functions/start-payment/index.ts
supabase/functions/verify-provider-payment/index.ts
```

## No secrets included

The patch intentionally contains no `.env`, service-role keys, provider keys, or bridge-secret values.

## Deployment order

1. Apply Payment Engine migrations through `0005_external_consumer_invoice_easy.sql`.
2. Deploy Payment Engine `start-payment` and `verify-provider-payment`.
3. Configure Payment Engine `PAYMENT_ENGINE_BRIDGE_SECRET` while retaining the existing Farmora secret if Farmora is already deployed.
4. Apply InvoiceEasy migration `20260929_payment_engine_billing_bridge.sql`.
5. Configure InvoiceEasy Edge Function secrets.
6. Deploy InvoiceEasy `payment-engine-billing-bridge`.
7. Run `flutter pub get`, `flutter analyze`, `flutter test`.
8. Test trial → plan → IntaSend checkout → webhook → subscription → projection → access before removing any old billing code.

# InvoiceEasy V2.7 — Supabase migration fix

## Why V2.6 failed

The previous subscription migration assumed `public.businesses` already existed.
Some InvoiceEasy environments still use the earlier `business_profiles` schema, so
running the subscription SQL directly produced:

`ERROR: 42P01: relation "public.businesses" does not exist`

## What V2.7 changes

`20260914_invoice_easy_subscription_hardening.sql` is now self-healing:

1. Ensures the canonical `public.businesses` table exists.
2. If `public.business_profiles` exists, bootstraps the canonical business row from it.
3. Normalizes existing `customers`, `products`, and `invoices` tables with the
   fields required by InvoiceEasy cloud sync.
4. Creates/updates subscription plans:
   - Monthly: KSh 200
   - Yearly: KSh 2,000
   - Trial: 14 days
5. Keeps subscription/payment writes server-authoritative.
6. Makes business data read-only after subscription expiry while retaining reads.
7. Leaves the historical 20260909–20260912 migration files in place so migration
   history is not rewritten.

## Apply

From the project root:

```bash
npx supabase db push
```

Do **not** manually paste the subscription migration into the SQL editor if
`supabase db push` is available. Supabase migration history should remain the
source of truth.

After deployment, verify:

```sql
select code, price, duration_days, is_active
from public.subscription_plans
order by price;

select routine_name
from information_schema.routines
where routine_schema = 'public'
  and routine_name in (
    'create_trial_subscription',
    'refresh_subscription_status',
    'create_payment_intent',
    'has_invoice_easy_write_access'
  );
```

Payment completion is intentionally not client-controlled. A trusted server-side
M-Pesa callback/verification function must update `payment_transactions` and
activate/extend `subscriptions`.

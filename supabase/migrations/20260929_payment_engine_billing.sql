-- InvoiceEasy -> Payment Engine projection.
-- This migration does not remove the existing local billing tables or functions.
-- The local tables remain the authorization/projection cache during migration.

alter table public.subscriptions
  add column if not exists payment_engine_account_id text,
  add column if not exists payment_engine_subscription_id text,
  add column if not exists payment_engine_plan_id text,
  add column if not exists payment_engine_entitlements jsonb not null default '[]'::jsonb,
  add column if not exists payment_engine_synced_at timestamptz;

alter table public.payment_transactions
  add column if not exists payment_engine_payment_intent_id text,
  add column if not exists payment_engine_payment_id text,
  add column if not exists checkout_url text,
  add column if not exists provider_receipt text;

create unique index if not exists subscriptions_payment_engine_account_uidx
  on public.subscriptions(payment_engine_account_id);

create unique index if not exists payment_transactions_payment_engine_intent_uidx
  on public.payment_transactions(payment_engine_payment_intent_id);

create index if not exists payment_transactions_payment_engine_created_idx
  on public.payment_transactions(owner_id, created_at desc);

-- The application bridge is the only trusted writer of the projection.
-- No authenticated grant is added for direct projection writes.

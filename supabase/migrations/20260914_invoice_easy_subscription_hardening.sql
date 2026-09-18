-- InvoiceEasy V2.7 subscription hardening
-- This migration is deliberately self-healing across the InvoiceEasy cloud
-- schema versions that were shipped before V2.7.
--
-- Pricing: KSh 200/month or KSh 2,000/year.
-- IMPORTANT: clients can create payment intents, but only trusted server-side
-- payment verification may mark a payment completed or activate a subscription.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- 1. Subscription foundation
--
-- IMPORTANT: Subscription hardening is intentionally independent of the
-- InvoiceEasy business/customer/product/invoice schema. Older deployments
-- may use public.businesses, business_profiles, farm_id, user_id, or other
-- legacy columns. A billing migration must never rewrite those tables just
-- to install subscriptions. This avoids destructive type/FK assumptions and
-- allows the subscription layer to be deployed safely on every tenant.
-- ---------------------------------------------------------------------------

-- No dependency on public.businesses or any application data table is needed.
-- Subscription ownership is anchored directly to auth.users(id).

-- ---------------------------------------------------------------------------
-- 2. Subscription data.
-- ---------------------------------------------------------------------------

create table if not exists public.subscription_plans (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text,
  duration_days integer,
  price numeric(12,2) not null check (price >= 0),
  currency text not null default 'KES',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint subscription_plans_duration_check check (duration_days is null or duration_days > 0)
);

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null unique references auth.users(id) on delete cascade,
  plan_id uuid not null references public.subscription_plans(id),
  status text not null default 'trialing' check (status in ('trialing','active','expired','cancelled','past_due')),
  started_at timestamptz not null default now(),
  expires_at timestamptz,
  cancelled_at timestamptz,
  auto_renew boolean not null default false,
  trial_ends_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payment_transactions (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  subscription_id uuid references public.subscriptions(id) on delete set null,
  plan_id uuid references public.subscription_plans(id) on delete set null,
  provider text not null default 'mpesa_manual',
  provider_transaction_id text,
  provider_reference text,
  amount numeric(12,2) not null check (amount > 0),
  currency text not null default 'KES',
  status text not null default 'pending' check (status in ('pending','completed','failed','cancelled','refunded')),
  payment_method text,
  paid_at timestamptz,
  failure_reason text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists subscriptions_owner_status_idx
  on public.subscriptions(owner_id, status);
create index if not exists payment_transactions_owner_created_idx
  on public.payment_transactions(owner_id, created_at desc);
create unique index if not exists payment_transactions_one_pending_plan_idx
  on public.payment_transactions(owner_id, plan_id)
  where status = 'pending';

insert into public.subscription_plans
  (code, name, description, duration_days, price, currency, is_active)
values
  ('trial', 'Free Trial', '14 days of full InvoiceEasy access.', 14, 0, 'KES', true),
  ('monthly', 'Monthly', 'Full InvoiceEasy access billed every month.', 30, 200, 'KES', true),
  ('annual', 'Yearly', 'Full access for one year. Save KSh 400 compared with monthly billing.', 365, 2000, 'KES', true)
on conflict (code) do update set
  name = excluded.name,
  description = excluded.description,
  duration_days = excluded.duration_days,
  price = excluded.price,
  currency = excluded.currency,
  is_active = excluded.is_active,
  updated_at = now();

create or replace function public.touch_subscription_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists subscription_plans_touch_updated_at on public.subscription_plans;
create trigger subscription_plans_touch_updated_at
before update on public.subscription_plans
for each row execute function public.touch_subscription_updated_at();

drop trigger if exists subscriptions_touch_updated_at on public.subscriptions;
create trigger subscriptions_touch_updated_at
before update on public.subscriptions
for each row execute function public.touch_subscription_updated_at();

drop trigger if exists payment_transactions_touch_updated_at on public.payment_transactions;
create trigger payment_transactions_touch_updated_at
before update on public.payment_transactions
for each row execute function public.touch_subscription_updated_at();

-- ---------------------------------------------------------------------------
-- 3. Authoritative subscription functions.
-- ---------------------------------------------------------------------------

create or replace function public.has_invoice_easy_write_access(target_owner_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.subscriptions s
    where s.owner_id = target_owner_id
      and s.status in ('trialing', 'active')
      and (
        (s.status = 'trialing' and (s.trial_ends_at is null or s.trial_ends_at > now()))
        or
        (s.status = 'active' and (s.expires_at is null or s.expires_at > now()))
      )
  );
$$;

revoke all on function public.has_invoice_easy_write_access(uuid) from public;
grant execute on function public.has_invoice_easy_write_access(uuid) to authenticated;

create or replace function public.create_trial_subscription()
returns public.subscriptions
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  trial_plan public.subscription_plans;
  result public.subscriptions;
begin
  if uid is null then raise exception 'Authentication required'; end if;

  select * into trial_plan
  from public.subscription_plans
  where code = 'trial' and is_active = true
  limit 1;

  if trial_plan.id is null then raise exception 'Trial plan is not configured'; end if;

  insert into public.subscriptions(owner_id, plan_id, status, started_at, trial_ends_at, auto_renew)
  values (uid, trial_plan.id, 'trialing', now(),
          now() + make_interval(days => trial_plan.duration_days), false)
  on conflict (owner_id) do nothing;

  select * into result from public.subscriptions where owner_id = uid;
  return result;
end;
$$;

create or replace function public.refresh_subscription_status()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  result text;
begin
  if uid is null then raise exception 'Authentication required'; end if;

  update public.subscriptions
  set status = 'expired', updated_at = now()
  where owner_id = uid
    and (
      (status = 'trialing' and trial_ends_at is not null and trial_ends_at <= now())
      or
      (status = 'active' and expires_at is not null and expires_at <= now())
    );

  select status into result
  from public.subscriptions
  where owner_id = uid;

  return coalesce(result, 'none');
end;
$$;

create or replace function public.create_payment_intent(requested_plan_code text)
returns public.payment_transactions
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  plan public.subscription_plans;
  sub public.subscriptions;
  result public.payment_transactions;
begin
  if uid is null then raise exception 'Authentication required'; end if;

  select * into plan
  from public.subscription_plans
  where code = requested_plan_code
    and is_active = true
    and price > 0
  limit 1;

  if plan.id is null then raise exception 'Invalid subscription plan'; end if;

  select * into sub from public.subscriptions where owner_id = uid;

  insert into public.payment_transactions
    (owner_id, subscription_id, plan_id, provider, amount, currency, status, payment_method, metadata)
  values
    (uid, sub.id, plan.id, 'mpesa_manual', plan.price, plan.currency,
     'pending', 'M-Pesa', jsonb_build_object('plan_code', plan.code))
  on conflict (owner_id, plan_id) where status = 'pending'
  do update set updated_at = now()
  returning * into result;

  return result;
end;
$$;

-- Only trusted server-side verification should complete payments or activate
-- subscriptions. Authenticated clients receive read access only.
revoke all on public.subscriptions from anon, authenticated;
revoke all on public.payment_transactions from anon, authenticated;
grant select on public.subscriptions to authenticated;
grant select on public.payment_transactions to authenticated;
grant execute on function public.create_trial_subscription() to authenticated;
grant execute on function public.refresh_subscription_status() to authenticated;
grant execute on function public.create_payment_intent(text) to authenticated;

alter table public.subscription_plans enable row level security;
alter table public.subscriptions enable row level security;
alter table public.payment_transactions enable row level security;

drop policy if exists subscription_plans_select_authenticated on public.subscription_plans;
create policy subscription_plans_select_authenticated
on public.subscription_plans
for select to authenticated
using (is_active = true);

drop policy if exists subscriptions_select_own on public.subscriptions;
create policy subscriptions_select_own
on public.subscriptions
for select to authenticated
using (owner_id = auth.uid());

drop policy if exists payment_transactions_select_own on public.payment_transactions;
create policy payment_transactions_select_own
on public.payment_transactions
for select to authenticated
using (owner_id = auth.uid());

-- ---------------------------------------------------------------------------
-- 4. Optional hardening of canonical V3 tables.
--
-- This section is deliberately conditional. Subscription deployment must
-- succeed even when the installed InvoiceEasy database has no public.businesses
-- table or uses a legacy customer/product/invoice schema. If the canonical V3
-- tables are present, their writes are additionally gated by subscription
-- status. Otherwise the existing application RLS remains untouched.
-- ---------------------------------------------------------------------------

do $$
declare
  t text;
  has_owner_id boolean;
  has_business_id boolean;
begin
  if to_regclass('public.businesses') is null then
    return;
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='businesses' and column_name='owner_id'
  ) then
    return;
  end if;

  -- Define the helper only when its dependency exists.
  execute $fn$
    create or replace function public.is_business_owner(target_business_id text)
    returns boolean
    language sql
    stable
    security definer
    set search_path = public
    as $body$
      select exists (
        select 1 from public.businesses
        where id::text = target_business_id
          and owner_id = auth.uid()
      );
    $body$;
  $fn$;

  execute 'revoke all on function public.is_business_owner(text) from public';
  execute 'grant execute on function public.is_business_owner(text) to authenticated';

  -- Businesses itself may have a different primary-key type in older builds;
  -- only install policies when the columns needed by these predicates exist.
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='businesses' and column_name='id') then
    execute 'alter table public.businesses enable row level security';

    execute 'drop policy if exists businesses_insert_own on public.businesses';
    execute $pol$
      create policy businesses_insert_own on public.businesses
      for insert to authenticated
      with check (owner_id = auth.uid() and public.has_invoice_easy_write_access(auth.uid()))
    $pol$;

    execute 'drop policy if exists businesses_update_own on public.businesses';
    execute $pol$
      create policy businesses_update_own on public.businesses
      for update to authenticated
      using (owner_id = auth.uid() and public.has_invoice_easy_write_access(auth.uid()))
      with check (owner_id = auth.uid() and public.has_invoice_easy_write_access(auth.uid()))
    $pol$;

    execute 'drop policy if exists businesses_delete_own on public.businesses';
    execute $pol$
      create policy businesses_delete_own on public.businesses
      for delete to authenticated
      using (owner_id = auth.uid() and public.has_invoice_easy_write_access(auth.uid()))
    $pol$;
  end if;

  foreach t in array array['customers','products','invoices'] loop
    if to_regclass(format('public.%s', t)) is null then
      continue;
    end if;

    select exists(select 1 from information_schema.columns where table_schema='public' and table_name=t and column_name='owner_id') into has_owner_id;
    select exists(select 1 from information_schema.columns where table_schema='public' and table_name=t and column_name='business_id') into has_business_id;

    -- Do not touch legacy tables that do not expose the canonical ownership
    -- columns. In particular, schemas using farm_id/user_id are left alone.
    if not (has_owner_id and has_business_id) then
      continue;
    end if;

    execute format('alter table public.%I enable row level security', t);

    execute format('drop policy if exists %I_select_own on public.%I', t, t);
    execute format(
      'create policy %I_select_own on public.%I for select to authenticated using (owner_id = auth.uid() and public.is_business_owner(business_id::text))',
      t, t
    );

    execute format('drop policy if exists %I_insert_own on public.%I', t, t);
    execute format(
      'create policy %I_insert_own on public.%I for insert to authenticated with check (owner_id = auth.uid() and public.is_business_owner(business_id::text) and public.has_invoice_easy_write_access(auth.uid()))',
      t, t
    );

    execute format('drop policy if exists %I_update_own on public.%I', t, t);
    execute format(
      'create policy %I_update_own on public.%I for update to authenticated using (owner_id = auth.uid() and public.is_business_owner(business_id::text) and public.has_invoice_easy_write_access(auth.uid())) with check (owner_id = auth.uid() and public.is_business_owner(business_id::text) and public.has_invoice_easy_write_access(auth.uid()))',
      t, t
    );

    execute format('drop policy if exists %I_delete_own on public.%I', t, t);
    execute format(
      'create policy %I_delete_own on public.%I for delete to authenticated using (owner_id = auth.uid() and public.is_business_owner(business_id::text) and public.has_invoice_easy_write_access(auth.uid()))',
      t, t
    );
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 5. Compatibility note for operators.
-- ---------------------------------------------------------------------------
-- Existing local migration files from 20260909-20260912 are retained for
-- migration-history compatibility. This migration itself no longer assumes
-- that public.businesses was created by an earlier migration.

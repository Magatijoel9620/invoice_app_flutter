-- InvoiceEasy: safe first-business onboarding and Payment Engine subscription projection.
-- Apply ONLY to the InvoiceEasy Supabase project.
-- This migration preserves existing business, subscription, trial and payment rows.

-- A user may create exactly their first business before a subscription exists.
-- This does not grant write access to customers, products, invoices, or an
-- already-existing business. The business ID must equal the authenticated UID.
create or replace function public.can_create_invoice_easy_initial_business(
  target_owner_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select target_owner_id = auth.uid()
    and not exists (
      select 1
      from public.businesses b
      where b.owner_id = target_owner_id
    );
$$;

revoke all on function public.can_create_invoice_easy_initial_business(uuid)
  from public, anon;
grant execute on function public.can_create_invoice_easy_initial_business(uuid)
  to authenticated;

-- Replace only the INSERT policy. Existing SELECT/UPDATE/DELETE policies remain
-- subscription-gated. This permits the initial business row only.
drop policy if exists businesses_insert_own on public.businesses;
create policy businesses_insert_own
on public.businesses
for insert to authenticated
with check (
  owner_id = auth.uid()
  and id = auth.uid()::text
  and (
    public.has_invoice_easy_write_access(auth.uid())
    or public.can_create_invoice_easy_initial_business(auth.uid())
  )
);

-- Trusted app Edge Function only: copy the central Payment Engine subscription
-- into the existing local authorization/projection row. No client write grant.
create or replace function public.invoice_easy_project_payment_engine_subscription(
  p_owner_id uuid,
  p_account_id text,
  p_subscription_id text,
  p_engine_plan_id text,
  p_plan_code text,
  p_status text,
  p_started_at timestamptz,
  p_expires_at timestamptz,
  p_trial_ends_at timestamptz,
  p_cancelled_at timestamptz,
  p_auto_renew boolean,
  p_entitlements jsonb default '[]'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_plan_id uuid;
  v_status text;
  v_row public.subscriptions%rowtype;
begin
  if current_setting('request.jwt.claim.role', true) <> 'service_role' then
    raise exception 'Payment Engine projection requires service role';
  end if;

  if p_owner_id is null
    or nullif(btrim(coalesce(p_account_id, '')), '') is null
    or nullif(btrim(coalesce(p_subscription_id, '')), '') is null
    or nullif(btrim(coalesce(p_engine_plan_id, '')), '') is null
    or nullif(btrim(coalesce(p_plan_code, '')), '') is null then
    raise exception 'Incomplete Payment Engine subscription projection';
  end if;

  v_status := case lower(coalesce(p_status, ''))
    when 'trial' then 'trialing'
    when 'trialing' then 'trialing'
    when 'active' then 'active'
    when 'past_due' then 'past_due'
    when 'expired' then 'expired'
    when 'cancelled' then 'cancelled'
    else null
  end;

  if v_status is null then
    raise exception 'Unsupported Payment Engine subscription status: %', p_status;
  end if;

  select id into v_plan_id
  from public.subscription_plans
  where code = p_plan_code
  limit 1;

  if v_plan_id is null then
    raise exception 'No local InvoiceEasy plan maps to Payment Engine plan code: %', p_plan_code;
  end if;

  insert into public.subscriptions (
    owner_id,
    plan_id,
    status,
    started_at,
    expires_at,
    cancelled_at,
    auto_renew,
    trial_ends_at,
    payment_engine_account_id,
    payment_engine_subscription_id,
    payment_engine_plan_id,
    payment_engine_entitlements,
    payment_engine_synced_at
  ) values (
    p_owner_id,
    v_plan_id,
    v_status,
    coalesce(p_started_at, now()),
    p_expires_at,
    p_cancelled_at,
    coalesce(p_auto_renew, false),
    p_trial_ends_at,
    p_account_id,
    p_subscription_id,
    p_engine_plan_id,
    coalesce(p_entitlements, '[]'::jsonb),
    now()
  )
  on conflict (owner_id) do update set
    plan_id = excluded.plan_id,
    status = excluded.status,
    started_at = excluded.started_at,
    expires_at = excluded.expires_at,
    cancelled_at = excluded.cancelled_at,
    auto_renew = excluded.auto_renew,
    trial_ends_at = excluded.trial_ends_at,
    payment_engine_account_id = excluded.payment_engine_account_id,
    payment_engine_subscription_id = excluded.payment_engine_subscription_id,
    payment_engine_plan_id = excluded.payment_engine_plan_id,
    payment_engine_entitlements = excluded.payment_engine_entitlements,
    payment_engine_synced_at = now(),
    updated_at = now()
  returning * into v_row;

  return jsonb_build_object(
    'owner_id', v_row.owner_id,
    'status', v_row.status,
    'plan_id', v_row.plan_id,
    'payment_engine_account_id', v_row.payment_engine_account_id,
    'payment_engine_subscription_id', v_row.payment_engine_subscription_id,
    'payment_engine_synced_at', v_row.payment_engine_synced_at
  );
end;
$$;

revoke all on function public.invoice_easy_project_payment_engine_subscription(
  uuid, text, text, text, text, text, timestamptz, timestamptz, timestamptz,
  timestamptz, boolean, jsonb
) from public, anon, authenticated;
grant execute on function public.invoice_easy_project_payment_engine_subscription(
  uuid, text, text, text, text, text, timestamptz, timestamptz, timestamptz,
  timestamptz, boolean, jsonb
) to service_role;

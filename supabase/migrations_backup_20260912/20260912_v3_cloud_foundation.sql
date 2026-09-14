-- InvoiceEasy V3.0 Cloud Foundation
-- One authenticated user -> exactly one business.
-- Cross-business means business-neutral, not multi-business accounts.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text not null default '',
  phone text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.businesses (
  id text primary key,
  owner_id uuid not null unique references auth.users(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint businesses_id_matches_owner check (id = owner_id::text)
);

create table if not exists public.customers (
  id text primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  business_id text not null references public.businesses(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.products (
  id text primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  business_id text not null references public.businesses(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.invoices (
  id text primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  business_id text not null references public.businesses(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists customers_business_updated_idx
  on public.customers(business_id, updated_at);
create index if not exists products_business_updated_idx
  on public.products(business_id, updated_at);
create index if not exists invoices_business_updated_idx
  on public.invoices(business_id, updated_at);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;


drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at before update on public.profiles
for each row execute function public.touch_updated_at();

drop trigger if exists businesses_touch_updated_at on public.businesses;
create trigger businesses_touch_updated_at before update on public.businesses
for each row execute function public.touch_updated_at();

drop trigger if exists customers_touch_updated_at on public.customers;
create trigger customers_touch_updated_at before update on public.customers
for each row execute function public.touch_updated_at();

drop trigger if exists products_touch_updated_at on public.products;
create trigger products_touch_updated_at before update on public.products
for each row execute function public.touch_updated_at();

drop trigger if exists invoices_touch_updated_at on public.invoices;
create trigger invoices_touch_updated_at before update on public.invoices
for each row execute function public.touch_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', '')
  )
  on conflict (id) do update
    set email = excluded.email,
        updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.is_business_owner(target_business_id text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.businesses
    where id = target_business_id
      and owner_id = auth.uid()
      and deleted_at is null
  );
$$;

alter table public.profiles enable row level security;
alter table public.businesses enable row level security;
alter table public.customers enable row level security;
alter table public.products enable row level security;
alter table public.invoices enable row level security;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
  for select to authenticated using (id = auth.uid());
drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own on public.profiles
  for insert to authenticated with check (id = auth.uid());
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists businesses_select_own on public.businesses;
create policy businesses_select_own on public.businesses
  for select to authenticated using (owner_id = auth.uid());
drop policy if exists businesses_insert_own on public.businesses;
create policy businesses_insert_own on public.businesses
  for insert to authenticated
  with check (owner_id = auth.uid() and id = auth.uid()::text);
drop policy if exists businesses_update_own on public.businesses;
create policy businesses_update_own on public.businesses
  for update to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid() and id = auth.uid()::text);
drop policy if exists businesses_delete_own on public.businesses;
create policy businesses_delete_own on public.businesses
  for delete to authenticated using (owner_id = auth.uid());

-- Child records are scoped through the authenticated user's one business.
create or replace function public.install_child_policies(target_table text)
returns void
language plpgsql
as $$
begin
  execute format('drop policy if exists %I_select_own on public.%I', target_table, target_table);
  execute format($policy$
    create policy %I_select_own on public.%I
    for select to authenticated
    using (owner_id = auth.uid() and public.is_business_owner(business_id))
  $policy$, target_table, target_table);

  execute format('drop policy if exists %I_insert_own on public.%I', target_table, target_table);
  execute format($policy$
    create policy %I_insert_own on public.%I
    for insert to authenticated
    with check (owner_id = auth.uid() and public.is_business_owner(business_id))
  $policy$, target_table, target_table);

  execute format('drop policy if exists %I_update_own on public.%I', target_table, target_table);
  execute format($policy$
    create policy %I_update_own on public.%I
    for update to authenticated
    using (owner_id = auth.uid() and public.is_business_owner(business_id))
    with check (owner_id = auth.uid() and public.is_business_owner(business_id))
  $policy$, target_table, target_table);

  execute format('drop policy if exists %I_delete_own on public.%I', target_table, target_table);
  execute format($policy$
    create policy %I_delete_own on public.%I
    for delete to authenticated
    using (owner_id = auth.uid() and public.is_business_owner(business_id))
  $policy$, target_table, target_table);
end;
$$;

select public.install_child_policies('customers');
select public.install_child_policies('products');
select public.install_child_policies('invoices');
drop function public.install_child_policies(text);

grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.businesses to authenticated;
grant select, insert, update, delete on public.customers to authenticated;
grant select, insert, update, delete on public.products to authenticated;
grant select, insert, update, delete on public.invoices to authenticated;

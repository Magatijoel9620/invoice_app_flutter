-- InvoiceEasy V3.0 cloud foundation
-- One authenticated user owns exactly one business.
-- Business-neutral: the business can be a freelancer, shop, contractor, consultant, etc.

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
  deleted_at timestamptz
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

create index if not exists customers_business_id_idx on public.customers(business_id);
create index if not exists products_business_id_idx on public.products(business_id);
create index if not exists invoices_business_id_idx on public.invoices(business_id);
create index if not exists customers_updated_at_idx on public.customers(updated_at);
create index if not exists products_updated_at_idx on public.products(updated_at);
create index if not exists invoices_updated_at_idx on public.invoices(updated_at);

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
create trigger profiles_touch_updated_at before update on public.profiles for each row execute function public.touch_updated_at();

drop trigger if exists businesses_touch_updated_at on public.businesses;
create trigger businesses_touch_updated_at before update on public.businesses for each row execute function public.touch_updated_at();

drop trigger if exists customers_touch_updated_at on public.customers;
create trigger customers_touch_updated_at before update on public.customers for each row execute function public.touch_updated_at();

drop trigger if exists products_touch_updated_at on public.products;
create trigger products_touch_updated_at before update on public.products for each row execute function public.touch_updated_at();

drop trigger if exists invoices_touch_updated_at on public.invoices;
create trigger invoices_touch_updated_at before update on public.invoices for each row execute function public.touch_updated_at();

create or replace function public.is_business_owner(target_business_id text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.businesses
    where id = target_business_id and owner_id = auth.uid() and deleted_at is null
  );
$$;

alter table public.profiles enable row level security;
alter table public.businesses enable row level security;
alter table public.customers enable row level security;
alter table public.products enable row level security;
alter table public.invoices enable row level security;

-- Profiles: a user can only read/write their own profile.
drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles for select to authenticated using (id = auth.uid());
drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own on public.profiles for insert to authenticated with check (id = auth.uid());
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- One business per authenticated account.
drop policy if exists businesses_select_own on public.businesses;
create policy businesses_select_own on public.businesses for select to authenticated using (owner_id = auth.uid());
drop policy if exists businesses_insert_own on public.businesses;
create policy businesses_insert_own on public.businesses for insert to authenticated with check (owner_id = auth.uid());
drop policy if exists businesses_update_own on public.businesses;
create policy businesses_update_own on public.businesses for update to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());
drop policy if exists businesses_delete_own on public.businesses;
create policy businesses_delete_own on public.businesses for delete to authenticated using (owner_id = auth.uid());

-- Child records are scoped to the single owned business.
create or replace function public.create_business_scoped_policies(table_name text) returns void
language plpgsql as $$
begin
  execute format('drop policy if exists %I_select_own on public.%I', table_name, table_name);
  execute format('create policy %I_select_own on public.%I for select to authenticated using (owner_id = auth.uid() and public.is_business_owner(business_id))', table_name, table_name);
  execute format('drop policy if exists %I_insert_own on public.%I', table_name, table_name);
  execute format('create policy %I_insert_own on public.%I for insert to authenticated with check (owner_id = auth.uid() and public.is_business_owner(business_id))', table_name, table_name);
  execute format('drop policy if exists %I_update_own on public.%I', table_name, table_name);
  execute format('create policy %I_update_own on public.%I for update to authenticated using (owner_id = auth.uid() and public.is_business_owner(business_id)) with check (owner_id = auth.uid() and public.is_business_owner(business_id))', table_name, table_name);
  execute format('drop policy if exists %I_delete_own on public.%I', table_name, table_name);
  execute format('create policy %I_delete_own on public.%I for delete to authenticated using (owner_id = auth.uid() and public.is_business_owner(business_id))', table_name, table_name);
end;
$$;

select public.create_business_scoped_policies('customers');
select public.create_business_scoped_policies('products');
select public.create_business_scoped_policies('invoices');
drop function public.create_business_scoped_policies(text);

grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.businesses to authenticated;
grant select, insert, update, delete on public.customers to authenticated;
grant select, insert, update, delete on public.products to authenticated;
grant select, insert, update, delete on public.invoices to authenticated;

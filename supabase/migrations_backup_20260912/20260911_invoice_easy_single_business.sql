-- InvoiceEasy cloud foundation: ONE USER -> ONE BUSINESS.
-- This is intentionally not a multi-business/workspace schema.
create table if not exists public.businesses (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null unique references auth.users(id) on delete cascade,
  name text not null,
  business_type text not null default 'Other',
  phone text default '', email text default '', address text default '', kra_pin text default '',
  currency text not null default 'KES', invoice_prefix text not null default 'INV',
  next_invoice_number integer not null default 1, default_due_days integer not null default 14,
  vat_registered boolean not null default false, vat_rate numeric(6,2) not null default 16,
  mpesa_till text default '', paybill text default '', bank_name text default '', bank_account text default '',
  thank_you_message text default 'Thank you for your business!',
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

alter table public.businesses enable row level security;
create policy "owner can manage business" on public.businesses for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null, phone text default '', email text default '', address text default '', tax_id text default '',
  created_at timestamptz not null default now()
);
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null, type text not null default 'service', price numeric(14,2) not null default 0, unit text not null default 'item', taxable boolean not null default false,
  created_at timestamptz not null default now()
);
create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
  customer_id uuid, customer_name text not null, number text not null, issue_date date not null, due_date date not null,
  status text not null default 'draft', discount numeric(14,2) not null default 0, vat_enabled boolean not null default false, vat_rate numeric(6,2) not null default 16,
  notes text default '', archived boolean not null default false, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique(business_id, number)
);
create table if not exists public.invoice_lines (
  id uuid primary key default gen_random_uuid(), invoice_id uuid not null references public.invoices(id) on delete cascade,
  description text not null, quantity numeric(14,3) not null default 1, unit_price numeric(14,2) not null default 0, unit text not null default 'item', taxable boolean not null default false
);
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(), invoice_id uuid not null references public.invoices(id) on delete cascade,
  payment_date timestamptz not null default now(), amount numeric(14,2) not null, method text not null default 'mpesa', reference text default '', note text default ''
);

alter table public.customers enable row level security; alter table public.products enable row level security; alter table public.invoices enable row level security; alter table public.invoice_lines enable row level security; alter table public.payments enable row level security;
create or replace function public.is_business_owner(bid uuid) returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.businesses where id=bid and owner_id=auth.uid()); $$;
create policy "owner customers" on public.customers for all using (public.is_business_owner(business_id)) with check (public.is_business_owner(business_id));
create policy "owner products" on public.products for all using (public.is_business_owner(business_id)) with check (public.is_business_owner(business_id));
create policy "owner invoices" on public.invoices for all using (public.is_business_owner(business_id)) with check (public.is_business_owner(business_id));
create policy "owner invoice lines" on public.invoice_lines for all using (exists(select 1 from public.invoices i where i.id=invoice_id and public.is_business_owner(i.business_id))) with check (exists(select 1 from public.invoices i where i.id=invoice_id and public.is_business_owner(i.business_id)));
create policy "owner payments" on public.payments for all using (exists(select 1 from public.invoices i where i.id=invoice_id and public.is_business_owner(i.business_id))) with check (exists(select 1 from public.invoices i where i.id=invoice_id and public.is_business_owner(i.business_id)));

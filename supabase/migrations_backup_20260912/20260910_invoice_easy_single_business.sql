-- InvoiceEasy cloud foundation
-- One authenticated user -> one business profile/workspace.
-- Cross-business means business-neutral, not multi-business accounts.

create extension if not exists pgcrypto;

create table if not exists public.business_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  name text not null default 'My Business',
  business_type text not null default 'Other',
  phone text default '',
  email text default '',
  address text default '',
  kra_pin text default '',
  currency text not null default 'KES',
  invoice_prefix text not null default 'INV',
  next_invoice_number integer not null default 1,
  default_due_days integer not null default 14,
  vat_registered boolean not null default false,
  vat_rate numeric(5,2) not null default 16,
  logo_path text default '',
  thank_you_message text default 'Thank you for your business!',
  mpesa_till text default '',
  paybill text default '',
  bank_name text default '',
  bank_account text default '',
  updated_at timestamptz not null default now()
);

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  phone text default '',
  email text default '',
  address text default '',
  tax_id text default '',
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  type text not null default 'service',
  price numeric(14,2) not null default 0,
  unit text not null default 'item',
  taxable boolean not null default false,
  created_at timestamptz not null default now()
);

create type public.invoice_status as enum ('draft','sent','viewed','partiallyPaid','paid','overdue','cancelled');
create type public.payment_method as enum ('mpesa','bank','cash','card','other');

create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  customer_id uuid references public.customers(id) on delete set null,
  customer_name text not null,
  number text not null,
  issue_date date not null,
  due_date date not null,
  status public.invoice_status not null default 'draft',
  discount numeric(14,2) not null default 0,
  notes text default '',
  archived boolean not null default false,
  created_at timestamptz not null default now(),
  unique(user_id, number)
);

create table if not exists public.invoice_lines (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  description text not null,
  quantity numeric(14,3) not null default 1,
  unit_price numeric(14,2) not null default 0,
  taxable boolean not null default false
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  payment_date date not null default current_date,
  amount numeric(14,2) not null,
  method public.payment_method not null default 'other',
  reference text default '',
  note text default ''
);

alter table public.business_profiles enable row level security;
alter table public.customers enable row level security;
alter table public.products enable row level security;
alter table public.invoices enable row level security;
alter table public.invoice_lines enable row level security;
alter table public.payments enable row level security;

create policy "owner business profile" on public.business_profiles for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "owner customers" on public.customers for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "owner products" on public.products for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "owner invoices" on public.invoices for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "owner invoice lines" on public.invoice_lines for all using (
  exists (select 1 from public.invoices i where i.id = invoice_id and i.user_id = auth.uid())
) with check (
  exists (select 1 from public.invoices i where i.id = invoice_id and i.user_id = auth.uid())
);
create policy "owner payments" on public.payments for all using (
  exists (select 1 from public.invoices i where i.id = invoice_id and i.user_id = auth.uid())
) with check (
  exists (select 1 from public.invoices i where i.id = invoice_id and i.user_id = auth.uid())
);

create index if not exists customers_user_id_idx on public.customers(user_id);
create index if not exists products_user_id_idx on public.products(user_id);
create index if not exists invoices_user_id_issue_date_idx on public.invoices(user_id, issue_date desc);
create index if not exists invoice_lines_invoice_id_idx on public.invoice_lines(invoice_id);
create index if not exists payments_invoice_id_idx on public.payments(invoice_id);

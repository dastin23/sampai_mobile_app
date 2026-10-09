-- Data aplikasi per user (rencana gaji, anggaran, dan transaksi).
-- Jalankan di SQL Editor Supabase (atau via `supabase db push`) setelah
-- proyek auth aktif. Row Level Security: tiap user hanya melihat datanya.

create extension if not exists pgcrypto;

create table public.plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  net_income integer not null default 0,
  payday_day integer not null default 25,
  next_payday date,
  savings_target integer not null default 0,
  safety_buffer integer not null default 0,
  updated_at timestamptz not null default now()
);

create table public.plan_bills (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.plans(id) on delete cascade,
  name text not null default '',
  amount integer not null default 0,
  due_day integer not null default 1,
  active boolean not null default true,
  sort_order integer not null default 0
);
create index plan_bills_plan_idx on public.plan_bills (plan_id);

create table public.budgets (
  user_id uuid not null references auth.users(id) on delete cascade,
  category text not null,
  limit_amount integer not null default 0,
  primary key (user_id, category)
);

create table public.transactions (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  category text not null,
  amount integer not null,
  date date not null,
  counts_toward_flexible boolean not null default true,
  is_income boolean not null default false
);
create index transactions_user_date_idx on public.transactions (user_id, date desc);

alter table public.plans enable row level security;
alter table public.plan_bills enable row level security;
alter table public.budgets enable row level security;
alter table public.transactions enable row level security;

create policy "users manage own plan" on public.plans
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "users manage own plan bills" on public.plan_bills
  for all to authenticated
  using (
    exists (
      select 1 from public.plans p
      where p.id = plan_id and p.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.plans p
      where p.id = plan_id and p.user_id = auth.uid()
    )
  );

create policy "users manage own budgets" on public.budgets
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "users manage own transactions" on public.transactions
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
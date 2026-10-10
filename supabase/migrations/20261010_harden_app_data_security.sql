-- Harden keamanan data pribadi SAMPAI (roadmap: amankan database).
-- Jalankan via `supabase db push` atau SQL Editor setelah migration pertama.
--
-- 1) FORCE ROW LEVEL SECURITY: pemilik tabel pun tunduk pada RLS
--    (superuser/service_role tetap bypass — itu memang haknya).
-- 2) Cabut akses role `anon` (data privat: tanpa login = tidak boleh apa-apa).
--    Role `authenticated` tetap mendapat DML eksplisit.
-- 3) Default privileges: tabel baru di schema public juga tertutup anon.
-- 4) Indeks pendukung query milik-user (breakdown anggaran per kategori).

-- Pastikan RLS aktif & paksa berlaku untuk semua tabel pribadi.
alter table public.plans force row level security;
alter table public.plan_bills force row level security;
alter table public.budgets force row level security;
alter table public.transactions force row level security;

-- Defense-in-depth: tanpa JWT (role anon) sama sekali tidak punya akses.
revoke all on table public.plans from anon;
revoke all on table public.plan_bills from anon;
revoke all on table public.budgets from anon;
revoke all on table public.transactions from anon;

-- Status login (authenticated) memegang izin DML; RLS membatasinya ke pemilik.
grant select, insert, update, delete on table public.plans to authenticated;
grant select, insert, update, delete on table public.plan_bills to authenticated;
grant select, insert, update, delete on table public.budgets to authenticated;
grant select, insert, update, delete on table public.transactions to authenticated;

-- Tabel baru ke depan ikut tertutup secara default.
alter default privileges in schema public revoke all on tables from anon;
alter default privileges in schema public
  grant select, insert, update, delete on tables to authenticated;

-- Pemakaian anggaran dikelompokkan per kategori dalam satu siklus.
create index if not exists transactions_user_category_idx
  on public.transactions (user_id, category);

-- Ringkasan audit (migration 20261009 sudah meng-cover sisanya):
--   * RLS aktif di plans, plan_bills, budgets, transactions ✓
--   * Policy hanya untuk pemilik (auth.uid() = user_id, bills via plans) ✓
--   * FK: plans/budgets/transactions -> auth.users(id) ON DELETE CASCADE,
--     plan_bills -> plans(id) ON DELETE CASCADE ✓
--   * Indeks: plans(user_id) unik, plan_bills(plan_id),
--     budgets PK (user_id, category), transactions(user_id, date desc) ✓
--   * service_role/secret key tidak pernah dipakai di aplikasi Flutter ✓
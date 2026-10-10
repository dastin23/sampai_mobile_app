-- UJI ROW LEVEL SECURITY untuk tabel data pribadi SAMPAI.
-- Jalankan di SQL Editor Supabase (role postgres/superuser).
--
-- Seluruh isi dibungkus BEGIN...ROLLBACK: TIDAK ADA DATA YANG TERSIMPAN
-- PERMANEN. Kalau semua ASSERT lolos, muncul:
--     SEMUA PENYAKINAN RLS LOLOS. (transaksi di-rollback)
--
-- Skenario:
--   1) anon (tanpa login) tidak bisa membaca apa pun.
--   2) User A bisa menulis & membaca datanya sendiri.
--   3) User B tidak bisa membaca/mengubah/menghapus/menyisipkan data A.
--   4) Data A tidak berubah akibat aksi B.
--   5) Hapus user A → semua datanya ikut terhapus (cascade).

begin;

do $$
declare
  uid_a uuid := '00000000-0000-0000-0000-000000000001';
  uid_b uuid := '00000000-0000-0000-0000-000000000002';
  plan_a uuid := '10000000-0000-0000-0000-000000000001';
  claims_a text;
  claims_b text;
begin
  claims_a := format('{"sub": "%s", "role": "authenticated"}', uid_a);
  claims_b := format('{"sub": "%s", "role": "authenticated"}', uid_b);

  -- Bersihkan sisa data uji (hanya UUID sintetis, bukan data user asli).
  delete from public.transactions where user_id in (uid_a, uid_b);
  delete from public.budgets where user_id in (uid_a, uid_b);
  delete from public.plan_bills
    where plan_id in (select id from public.plans where user_id in (uid_a, uid_b));
  delete from public.plans where user_id in (uid_a, uid_b);
  delete from auth.users where id in (uid_a, uid_b);

  insert into auth.users (id, email, aud, role)
    values (uid_a, 'a@scan-sampai.test', 'authenticated', 'authenticated'),
           (uid_b, 'b@scan-sampai.test', 'authenticated', 'authenticated');

  raise notice '[1/5] anon tidak boleh melihat data privat';
  set role anon;
  perform set_config('request.jwt.claims', '', true);
  assert (select count(*) from public.plans) = 0,     'anon membaca plans!';
  assert (select count(*) from public.plan_bills) = 0, 'anon membaca plan_bills!';
  assert (select count(*) from public.budgets) = 0,   'anon membaca budgets!';
  assert (select count(*) from public.transactions) = 0, 'anon membaca transactions!';
  reset role;

  raise notice '[2/5] user A bisa menulis & membaca datanya sendiri';
  set role authenticated;
  perform set_config('request.jwt.claims', claims_a, true);
  insert into public.plans (id, user_id, net_income, payday_day, savings_target)
    values (plan_a, uid_a, 8000000, 25, 1000000);
  insert into public.plan_bills (plan_id, name, amount, due_day)
    values (plan_a, 'Kos', 1500000, 1);
  insert into public.budgets (user_id, category, limit_amount)
    values (uid_a, 'Makan', 1200000);
  insert into public.transactions
    (id, user_id, title, category, amount, date, counts_toward_flexible, is_income)
    values ('tx-a-1', uid_a, 'Makan siang', 'Makan', 45000, current_date, true, false);
  assert (select count(*) from public.plans where user_id = uid_a) = 1;
  assert (select count(*) from public.plan_bills
          where plan_id in (select id from public.plans where user_id = uid_a)) = 1;
  assert (select count(*) from public.budgets where user_id = uid_a) = 1;
  assert (select count(*) from public.transactions where user_id = uid_a) = 1;
  reset role;

  raise notice '[3/5] user B tidak bisa mengakses data A';
  set role authenticated;
  perform set_config('request.jwt.claims', claims_b, true);
  assert (select count(*) from public.plans) = 0, 'B membaca plans A!';
  assert (select count(*) from public.plan_bills) = 0, 'B membaca bills A!';
  assert (select count(*) from public.budgets) = 0, 'B membaca budgets A!';
  assert (select count(*) from public.transactions) = 0, 'B membaca transaksi A!';

  -- B mengarahkan UPDATE/DELETE ke baris A → tidak boleh menyentuh apa pun.
  update public.plans set net_income = 123 where user_id = uid_a;
  assert (select count(*) from public.plans) = 0, 'B mengubah plans A!';
  delete from public.transactions where user_id = uid_a;
  assert (select count(*) from public.transactions) = 0, 'B menghapus transaksi A!';

  -- B menyisipkan data atas nama A → wajib ditolak (RLS: with check gagal,
  -- error Postgres 42501 / insufficient_privilege).
  begin
    insert into public.transactions
      (id, user_id, title, category, amount, date)
      values ('tx-evil', uid_a, 'Curi', 'Lainnya', 1, current_date);
    raise exception 'GAGAL: user B berhasil menyisipkan data atas nama A';
  exception
    when insufficient_privilege then
      raise notice '  OK: sisipan atas nama user lain ditolak';
  end;
  reset role;

  raise notice '[4/5] data A tidak berubah akibat aksi B';
  set role authenticated;
  perform set_config('request.jwt.claims', claims_a, true);
  assert (select net_income from public.plans where user_id = uid_a) = 8000000,
    'Data A berubah oleh B!';
  assert (select count(*) from public.transactions where user_id = uid_a) = 1,
    'Transaksi A hilang karena DELETE B!';
  assert (select count(*) from public.budgets where user_id = uid_a) = 1;
  reset role;

  raise notice '[5/5] hapus user A → semua datanya terhapus (cascade)';
  delete from auth.users where id = uid_a;
  assert (select count(*) from public.plans) = 0, 'plan tidak cascade!';
  assert (select count(*) from public.plan_bills) = 0, 'plan_bills tidak cascade!';
  assert (select count(*) from public.budgets) = 0, 'budgets tidak cascade!';
  assert (select count(*) from public.transactions) = 0, 'transactions tidak cascade!';

  raise notice 'SEMUA PENYAKINAN RLS LOLOS. (transaksi di-rollback, tidak ada data tersimpan)';
exception
  when others then
    raise notice 'GAGAL: %', sqlerrm;
    raise;
end $$;

-- Batalkan: tidak ada satu pun perubahan di atas yang tersimpan.
rollback;
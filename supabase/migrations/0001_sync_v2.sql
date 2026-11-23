-- Roastmate — Sinkronisasi v2 (D-32)
--
-- Reproduksi perubahan cloud Fase 1 yang sudah diterapkan project saat ini
-- lewat SQL Editor. Aman dijalankan ulang (if not exists / create or replace).
-- Catatan: policy UPDATE/ALL pada tabel data harus sudah ada dari skema D-29.
-- Supabase CLI tidak dipakai; file ini sebagai catatan kanonik & bootstrap.

-- 1. Kolom rating & penanda waktu server ------------------------------------
alter table public.analyses
  add column if not exists personal_rating integer
    check (personal_rating is null or personal_rating between 1 and 5),
  add column if not exists personal_rating_note text,
  add column if not exists updated_at timestamptz not null default now();

alter table public.user_brew_recipes
  add column if not exists updated_at timestamptz not null default now();

-- 2. Tombstone penghapusan ---------------------------------------------------
create table if not exists public.deleted_records (
  uuid       text primary key,
  user_id    uuid not null references auth.users(id) on delete cascade,
  table_name text not null check (table_name in ('analyses','user_brew_recipes')),
  deleted_at timestamptz not null default now()
);

create index if not exists idx_deleted_user
  on public.deleted_records(user_id, deleted_at);

-- 3. updated_at dari server (last-write-wins) --------------------------------
create or replace function public.set_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists trg_analyses_updated on public.analyses;
create trigger trg_analyses_updated before update on public.analyses
  for each row execute function public.set_updated_at();

drop trigger if exists trg_recipes_updated on public.user_brew_recipes;
create trigger trg_recipes_updated before update on public.user_brew_recipes
  for each row execute function public.set_updated_at();

-- 4. RLS tombstone & index pull ----------------------------------------------
alter table public.deleted_records enable row level security;

drop policy if exists "own tombstones" on public.deleted_records;
create policy "own tombstones" on public.deleted_records
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create index if not exists idx_recipes_user
  on public.user_brew_recipes(user_id);

-- 5. Verifikasi (opsional, dijalankan manual di SQL Editor) ------------------
-- select
--   (select count(*) from information_schema.columns
--     where table_name='analyses' and column_name in
--       ('personal_rating','personal_rating_note','updated_at')) as kolom_analyses,
--   (select count(*) from pg_tables where tablename='deleted_records') as tombstone,
--   (select count(*) from pg_trigger where tgname like 'trg_%_updated') as trigger;

-- Run this once in Supabase Dashboard → SQL Editor → New query.
create extension if not exists pgcrypto;

create table if not exists public.books (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 180),
  author text check (author is null or char_length(author) <= 160),
  location text check (location is null or char_length(location) <= 120),
  cover_url text,
  created_at timestamptz not null default now()
);

create index if not exists books_title_lower_idx on public.books (lower(title));
alter table public.books enable row level security;
revoke all on table public.books from anon, authenticated;
grant select on table public.books to anon, authenticated;

drop policy if exists "Anyone can view the public catalog" on public.books;
create policy "Anyone can view the public catalog"
  on public.books for select to anon, authenticated using (true);
-- There are deliberately no client insert, update, or delete policies. The Netlify
-- function performs writes with the server-only Supabase service-role key.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('book-covers', 'book-covers', true, 3750000, array['image/webp','image/jpeg','image/png'])
on conflict (id) do update set public = true, file_size_limit = 3750000,
  allowed_mime_types = array['image/webp','image/jpeg','image/png'];

drop policy if exists "Anyone can view book covers" on storage.objects;
create policy "Anyone can view book covers"
  on storage.objects for select to anon, authenticated using (bucket_id = 'book-covers');
-- No Storage write policies are granted to anon/authenticated clients.

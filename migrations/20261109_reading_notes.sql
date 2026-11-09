-- Run this migration in Supabase SQL Editor before deploying the reading notes feature.
create table if not exists public.reading_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  book_title text not null check (length(book_title) between 1 and 160),
  body text not null check (length(body) between 1 and 1600),
  photos jsonb not null default '[]'::jsonb
    check (jsonb_typeof(photos) = 'array' and jsonb_array_length(photos) <= 3),
  created_at timestamptz not null default now()
);

create index if not exists reading_notes_created_at_idx
  on public.reading_notes(created_at desc);

alter table public.reading_notes enable row level security;
-- Access is through the Cloudflare Worker service key; do not add anon policies.

create table if not exists public.reading_note_likes (
  id uuid primary key default gen_random_uuid(),
  reading_note_id uuid not null references public.reading_notes(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (reading_note_id, user_id)
);

create table if not exists public.reading_note_comments (
  id uuid primary key default gen_random_uuid(),
  reading_note_id uuid not null references public.reading_notes(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  body text not null check (length(body) between 1 and 600),
  created_at timestamptz not null default now()
);

create index if not exists reading_note_comments_note_idx
  on public.reading_note_comments(reading_note_id, created_at);

alter table public.reading_note_likes enable row level security;
alter table public.reading_note_comments enable row level security;

create table if not exists public.private_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  book_title text not null default '' check (length(book_title) <= 160),
  body text not null check (length(body) between 1 and 3000),
  created_at timestamptz not null default now()
);

create index if not exists private_notes_owner_created_idx
  on public.private_notes(user_id, created_at desc);

alter table public.private_notes enable row level security;

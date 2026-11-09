alter table public.events
  add column if not exists book_description text not null default '';

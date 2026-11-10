alter table public.events
  add column if not exists description_images text[] not null default '{}';

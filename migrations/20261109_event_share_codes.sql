alter table public.events
  add column if not exists share_code text;

update public.events
set share_code = substr(replace(id::text, '-', ''), 1, 12)
where share_code is null or share_code = '';

alter table public.events
  alter column share_code set default substr(replace(gen_random_uuid()::text, '-', ''), 1, 12);

alter table public.events
  alter column share_code set not null;

create unique index if not exists events_share_code_unique_idx
  on public.events (share_code);

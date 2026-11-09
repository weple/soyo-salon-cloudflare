-- Existing databases may have a UNIQUE constraint/index on events.title.
-- Event titles identify a recurring series (for example, "대작 읽는 시간"),
-- so multiple events may use the same title and distinguish themselves by book/date.

do $$
declare
  item record;
  title_attnum smallint;
begin
  select attnum into title_attnum
  from pg_attribute
  where attrelid = 'public.events'::regclass
    and attname = 'title'
    and not attisdropped;

  for item in
    select conname as object_name, 'constraint' as object_kind
    from pg_constraint
    where conrelid = 'public.events'::regclass
      and contype = 'u'
      and conkey = array[title_attnum]::smallint[]
    union all
    select index_class.relname as object_name, 'index' as object_kind
    from pg_index idx
    join pg_class index_class on index_class.oid = idx.indexrelid
    where idx.indrelid = 'public.events'::regclass
      and idx.indisunique
      and not idx.indisprimary
      and idx.indnkeyatts = 1
      and idx.indkey[0] = title_attnum
      and not exists (
        select 1 from pg_constraint c where c.conindid = idx.indexrelid
      )
  loop
    if item.object_kind = 'constraint' then
      execute format('alter table public.events drop constraint %I', item.object_name);
    else
      execute format('drop index public.%I', item.object_name);
    end if;
  end loop;
end $$;

-- Keep event registration compatible with the fields used by the current form.
alter table public.events add column if not exists author text not null default '';
alter table public.events add column if not exists place_address text not null default '';
alter table public.events add column if not exists cover_url text not null default '';
alter table public.events add column if not exists book_description text not null default '';
alter table public.events add column if not exists yes24_url text not null default '';
alter table public.events add column if not exists share_code text;

update public.events
set share_code = substr(replace(id::text, '-', ''), 1, 12)
where share_code is null or share_code = '';

alter table public.events
  alter column share_code set default substr(replace(gen_random_uuid()::text, '-', ''), 1, 12);
alter table public.events alter column share_code set not null;
create unique index if not exists events_share_code_unique_idx on public.events (share_code);

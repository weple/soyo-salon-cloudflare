alter table public.applications
  add column if not exists depositor_name text not null default '';

drop function if exists public.apply_to_event(uuid, uuid);

create or replace function public.apply_to_event(
  p_user_id uuid,
  p_event_id uuid,
  p_depositor_name text default ''
) returns uuid
language plpgsql
security invoker
as $$
declare
  v_event public.events%rowtype;
  v_existing public.applications%rowtype;
  v_id uuid;
begin
  select * into v_event from public.events where id = p_event_id for update;
  if not found or v_event.status <> 'open' or v_event.date <= now() then
    raise exception '신청할 수 없는 모임입니다.';
  end if;

  select * into v_existing from public.applications
  where user_id = p_user_id and event_id = p_event_id for update;
  if found and v_existing.status <> 'cancelled' then
    raise exception '이미 신청한 모임입니다.';
  end if;

  if (select count(*) from public.applications
      where event_id = p_event_id and status in ('pending', 'confirmed')) >= v_event.capacity then
    raise exception '모집이 마감되었습니다.';
  end if;

  if v_existing.id is not null then
    update public.applications
      set status = 'pending', depositor_name = coalesce(p_depositor_name, ''), created_at = now()
      where id = v_existing.id returning id into v_id;
  else
    insert into public.applications(user_id, event_id, status, depositor_name)
      values(p_user_id, p_event_id, 'pending', coalesce(p_depositor_name, '')) returning id into v_id;
  end if;
  return v_id;
end;
$$;

revoke all on function public.apply_to_event(uuid, uuid, text) from public, anon, authenticated;
grant execute on function public.apply_to_event(uuid, uuid, text) to service_role;

-- The Worker includes depositor_name only in its admin-only applications endpoint.

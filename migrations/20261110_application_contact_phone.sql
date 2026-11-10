-- 신청자가 선택 제공하고 명시 동의한 연락처를 운영자에게만 공개합니다.
alter table public.applications
  add column if not exists contact_phone text not null default '',
  add column if not exists contact_consent_at timestamptz;

drop function if exists public.apply_to_event(uuid, uuid, text);
create or replace function public.apply_to_event(
  p_user_id uuid,
  p_event_id uuid,
  p_depositor_name text default '',
  p_contact_phone text default '',
  p_contact_consent boolean default false
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
      set status = 'pending',
          depositor_name = coalesce(p_depositor_name, ''),
          contact_phone = case when p_contact_consent then coalesce(p_contact_phone, '') else '' end,
          contact_consent_at = case when p_contact_consent then now() else null end,
          created_at = now()
      where id = v_existing.id returning id into v_id;
  else
    insert into public.applications(user_id, event_id, status, depositor_name, contact_phone, contact_consent_at)
      values (p_user_id, p_event_id, 'pending', coalesce(p_depositor_name, ''),
              case when p_contact_consent then coalesce(p_contact_phone, '') else '' end,
              case when p_contact_consent then now() else null end)
      returning id into v_id;
  end if;
  return v_id;
end;
$$;

revoke all on function public.apply_to_event(uuid, uuid, text, text, boolean) from public, anon, authenticated;
grant execute on function public.apply_to_event(uuid, uuid, text, text, boolean) to service_role;

-- contact_phone and consent timestamp are returned only by the Worker admin endpoint.

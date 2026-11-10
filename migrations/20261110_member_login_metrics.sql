-- 회원 관리 화면의 로그인 지표. 기존 로그인 횟수는 소급할 수 없어 적용 시점부터 집계합니다.
alter table public.users
  add column if not exists login_count integer not null default 0 check (login_count >= 0);
alter table public.users
  add column if not exists last_login_at timestamptz;

create or replace function public.record_user_login(p_user_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update public.users
     set login_count = login_count + 1,
         last_login_at = now()
   where id = p_user_id;
$$;

revoke all on function public.record_user_login(uuid) from public, anon, authenticated;
grant execute on function public.record_user_login(uuid) to service_role;

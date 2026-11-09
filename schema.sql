-- Supabase SQL Editor에서 실행. service_role 키는 브라우저에 노출하지 마세요.
create extension if not exists pgcrypto;
create table if not exists public.users(id uuid primary key default gen_random_uuid(),kakao_id text not null unique,nickname text not null,created_at timestamptz not null default now());
create table if not exists public.events(id uuid primary key default gen_random_uuid(),title text not null,book text not null default '',category text not null default '문학',date timestamptz not null,end_time text not null default '',place text not null,description text not null default '',capacity int not null check(capacity between 1 and 100),color text not null default '#4055D8',accent text not null default '#D66A48',status text not null default 'open' check(status in ('open','closed','soon')),created_at timestamptz not null default now());
create table if not exists public.applications(id uuid primary key default gen_random_uuid(),event_id uuid not null references public.events(id) on delete cascade,user_id uuid not null references public.users(id) on delete cascade,status text not null default 'pending' check(status in ('pending','confirmed','waitlist','cancelled')),created_at timestamptz not null default now(),unique(event_id,user_id));
alter table public.events add column if not exists cover_url text not null default '';
create table if not exists public.reviews(id uuid primary key default gen_random_uuid(),event_id uuid not null references public.events(id) on delete cascade,user_id uuid not null references public.users(id) on delete cascade,rating int not null check(rating between 1 and 5),body text not null check(length(body) between 1 and 3000),created_at timestamptz not null default now(),unique(event_id,user_id));
create table if not exists public.book_reviews(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.users(id) on delete cascade,book_title text not null check(length(book_title) between 1 and 160),body text not null check(length(body) between 1 and 3000),created_at timestamptz not null default now());
create index if not exists applications_event_status_idx on public.applications(event_id,status);
alter table public.users enable row level security;
alter table public.events enable row level security;
alter table public.applications enable row level security;
alter table public.reviews enable row level security;
alter table public.book_reviews enable row level security;
-- 공개 anon 정책 없음. 모든 데이터 접근은 인증된 Cloudflare Worker의 service_role을 통해서만.
create or replace function public.apply_to_event(p_user_id uuid,p_event_id uuid) returns uuid language plpgsql security invoker as $$
declare v_event public.events%rowtype; v_existing public.applications%rowtype; v_id uuid;
begin
 select * into v_event from public.events where id=p_event_id for update;
 if not found or v_event.status<>'open' or v_event.date<=now() then raise exception '신청할 수 없는 모임입니다.'; end if;
 select * into v_existing from public.applications where user_id=p_user_id and event_id=p_event_id for update;
 if found and v_existing.status<>'cancelled' then raise exception '이미 신청한 모임입니다.'; end if;
 if (select count(*) from public.applications where event_id=p_event_id and status in ('pending','confirmed')) >= v_event.capacity then raise exception '모집이 마감되었습니다.'; end if;
 if v_existing.id is not null then update public.applications set status='pending',created_at=now() where id=v_existing.id returning id into v_id;
 else insert into public.applications(user_id,event_id,status) values(p_user_id,p_event_id,'pending') returning id into v_id;end if;
 return v_id;
end $$;
create or replace function public.set_application_status(p_application_id uuid,p_status text) returns void language plpgsql security invoker as $$
declare v_a public.applications%rowtype; v_e public.events%rowtype;
begin
 if p_status not in ('confirmed','cancelled','waitlist') then raise exception 'Invalid status'; end if;
 select * into v_a from public.applications where id=p_application_id;
 if not found then raise exception 'Application not found'; end if;
 select * into v_e from public.events where id=v_a.event_id for update;
 if p_status='confirmed' and (select count(*) from public.applications where event_id=v_a.event_id and status='confirmed' and id<>p_application_id)>=v_e.capacity then raise exception 'Capacity exceeded'; end if;
 update public.applications set status=p_status where id=p_application_id;
end $$;
revoke all on function public.apply_to_event(uuid,uuid) from public,anon,authenticated;
revoke all on function public.set_application_status(uuid,text) from public,anon,authenticated;
grant execute on function public.apply_to_event(uuid,uuid) to service_role;
grant execute on function public.set_application_status(uuid,text) to service_role;

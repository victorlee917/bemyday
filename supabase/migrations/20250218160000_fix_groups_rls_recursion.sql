-- RLS 무한 재귀 수정: groups ↔ group_members 상호 참조를 SECURITY DEFINER 함수로 분리
-- groups 정책 → group_members 조회 → group_members 정책 → groups 조회 → 무한 재귀

-- 1. SECURITY DEFINER 함수 생성 (RLS 우회)
create or replace function public.get_user_owned_group_ids()
returns setof uuid
language sql
security definer
stable
set search_path = public
as $$
  select id from public.groups
  where owner_id = auth.uid() and deleted_at is null;
$$;

create or replace function public.get_user_member_group_ids()
returns setof uuid
language sql
security definer
stable
set search_path = public
as $$
  select group_id from public.group_members
  where user_id = auth.uid();
$$;

-- 2. 기존 정책 삭제
drop policy if exists "Members can view their groups" on public.group_members;
drop policy if exists "Owners can manage members" on public.group_members;
drop policy if exists "Users can view groups they belong to" on public.groups;

-- 3. 정책 재생성 (함수 사용으로 재귀 제거)
create policy "Members can view their groups"
  on public.group_members for select
  using (
    user_id = auth.uid()
    or group_id in (select public.get_user_owned_group_ids())
  );

create policy "Owners can manage members"
  on public.group_members for all
  using (
    group_id in (select public.get_user_owned_group_ids())
  );

create policy "Users can view groups they belong to"
  on public.groups for select
  using (
    deleted_at is null
    and (
      owner_id = auth.uid()
      or id in (select public.get_user_member_group_ids())
    )
  );

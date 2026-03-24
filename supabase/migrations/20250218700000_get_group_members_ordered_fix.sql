-- get_group_members_ordered: 현재 유저를 마지막에 오도록 정렬 명시
create or replace function public.get_group_members_ordered(p_group_id uuid)
returns table (
  user_id uuid,
  nickname text,
  avatar_url text
)
language sql
security definer
stable
set search_path = public
as $$
  select p.id as user_id, p.nickname, p.avatar_url
  from public.group_members gm
  join public.profiles p on p.id = gm.user_id
  where gm.group_id = p_group_id
    and p.deleted_at is null
    and trim(coalesce(p.nickname, '')) != ''
    and (exists (select 1 from public.groups g where g.id = p_group_id and g.owner_id = auth.uid())
         or exists (select 1 from public.group_members gm2 where gm2.group_id = p_group_id and gm2.user_id = auth.uid()))
  order by (gm.user_id = auth.uid()) asc nulls last, gm.joined_at asc  -- 다른 멤버 먼저, 현재 유저 마지막
$$;

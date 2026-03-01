-- 속한 그룹(owner + member) 목록을 반환하는 RPC
-- group_members와 groups를 조인해 명시적으로 "속한" 그룹만 조회
create or replace function public.get_user_groups()
returns table (
  id uuid,
  owner_id uuid,
  successor_id uuid,
  weekday smallint,
  name text,
  week_boundary_timezone text,
  post_count int,
  streak int,
  streak_updated_at timestamptz
)
language sql
security definer
stable
set search_path = public
as $$
  -- owner이거나 group_members에 있는 그룹
  select g.id, g.owner_id, g.successor_id, g.weekday, g.name,
         g.week_boundary_timezone, g.post_count, g.streak, g.streak_updated_at
  from public.groups g
  where g.deleted_at is null
    and (
      g.owner_id = auth.uid()
      or g.id in (select gm.group_id from public.group_members gm where gm.user_id = auth.uid())
    )
  order by g.weekday;
$$;

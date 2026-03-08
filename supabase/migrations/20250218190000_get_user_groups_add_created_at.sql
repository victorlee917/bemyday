-- get_user_groups RPC에 created_at 컬럼 추가 + post_count를 posts 테이블에서 실시간 집계
drop function if exists public.get_user_groups();

create function public.get_user_groups()
returns table (
  id uuid,
  owner_id uuid,
  successor_id uuid,
  weekday smallint,
  name text,
  week_boundary_timezone text,
  post_count int,
  streak int,
  streak_updated_at timestamptz,
  created_at timestamptz
)
language sql
security definer
stable
set search_path = public
as $$
  select g.id, g.owner_id, g.successor_id, g.weekday, g.name,
         g.week_boundary_timezone,
         (select count(*)::int from public.posts p where p.group_id = g.id and p.deleted_at is null) as post_count,
         g.streak, g.streak_updated_at,
         g.created_at
  from public.groups g
  where g.deleted_at is null
    and (
      g.owner_id = auth.uid()
      or g.id in (select gm.group_id from public.group_members gm where gm.user_id = auth.uid())
    )
  order by g.weekday;
$$;

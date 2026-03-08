-- 그룹의 현재 주차 계산 (Dart groupWeekNumber 로직과 동일)
-- p_weekday: 1=Mon ~ 7=Sun (ISODOW 기준)
-- p_created_at: 그룹 생성일시
create or replace function public.compute_current_week(p_weekday int, p_created_at timestamptz)
returns int
language plpgsql stable
as $$
declare
  v_create_date date;
  v_created_dow int;
  v_days_to_first int;
  v_first_boundary date;
  v_now_date date;
begin
  v_create_date := p_created_at::date;
  v_created_dow := extract(isodow from p_created_at)::int;
  v_days_to_first := (p_weekday - v_created_dow + 7) % 7;
  v_first_boundary := v_create_date + v_days_to_first + 1;
  v_now_date := current_date;

  if v_now_date < v_first_boundary then
    return 1;
  end if;

  return 2 + ((v_now_date - v_first_boundary) / 7);
end;
$$;

-- 그룹의 연속 포스팅 streak 계산
-- 현재 주차부터 역순으로 연속 게시글이 있는 주 수를 카운트
-- 현재 주차에 게시글이 없으면 직전 주차부터 카운트 시작 (진행 중일 수 있으므로)
create or replace function public.compute_group_streak(p_group_id uuid, p_current_week int)
returns int
language plpgsql stable security definer
set search_path = public
as $$
declare
  v_streak int := 0;
  v_week int;
  v_has_posts boolean;
begin
  v_week := p_current_week;

  select exists(
    select 1 from public.posts
    where group_id = p_group_id and week_index = v_week and deleted_at is null
  ) into v_has_posts;

  if not v_has_posts and v_week > 1 then
    v_week := v_week - 1;
  end if;

  loop
    exit when v_week < 1;

    select exists(
      select 1 from public.posts
      where group_id = p_group_id and week_index = v_week and deleted_at is null
    ) into v_has_posts;

    exit when not v_has_posts;

    v_streak := v_streak + 1;
    v_week := v_week - 1;
  end loop;

  return v_streak;
end;
$$;

-- get_user_groups RPC 업데이트: streak를 동적으로 계산
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
         public.compute_group_streak(g.id, public.compute_current_week(g.weekday, g.created_at)) as streak,
         g.streak_updated_at,
         g.created_at
  from public.groups g
  where g.deleted_at is null
    and (
      g.owner_id = auth.uid()
      or g.id in (select gm.group_id from public.group_members gm where gm.user_id = auth.uid())
    )
  order by g.weekday;
$$;

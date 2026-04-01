-- 1) 요일 언락 푸시: alarm_daily_reminder(오후 10시 로컬 알림 토글)에 묶이면 대부분 발송 안 됨 → push_enabled만 요구
-- 2) compute_current_week가 UTC current_date를 쓰면 그룹 TZ 기준 월요일 00:00에 주차가 하루 어긋날 수 있음 → 그룹 로컬 날짜로 주차 계산

create or replace function public.compute_current_week_at_date(
  p_weekday int,
  p_created_at timestamptz,
  p_ref_date date
)
returns int
language plpgsql
stable
set search_path = public
as $$
declare
  v_create_date date;
  v_created_dow int;
  v_days_to_first int;
  v_first_boundary date;
begin
  v_create_date := p_created_at::date;
  v_created_dow := extract(isodow from p_created_at)::int;
  v_days_to_first := (p_weekday - v_created_dow + 7) % 7;
  v_first_boundary := v_create_date + v_days_to_first + 1;

  if p_ref_date < v_first_boundary then
    return 1;
  end if;

  return 2 + ((p_ref_date - v_first_boundary) / 7);
end;
$$;

create or replace function public.enqueue_weekday_unlock_notifications()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int := 0;
  v_group record;
  v_week int;
  v_weekday_name text;
  v_local_ts timestamp without time zone;
  v_local_date date;
  v_local_hour int;
  v_local_dow int;
begin
  for v_group in
    select g.id, g.weekday, g.week_boundary_timezone, g.created_at
    from public.groups g
    where g.deleted_at is null
  loop
    begin
      v_local_ts := (now() at time zone coalesce(nullif(trim(v_group.week_boundary_timezone), ''), 'UTC'));
    exception when others then
      continue;
    end;

    v_local_date := v_local_ts::date;
    v_local_hour := extract(hour from v_local_ts)::int;
    v_local_dow := extract(isodow from v_local_ts)::int;

    if v_local_hour <> 0 or v_local_dow <> v_group.weekday then
      continue;
    end if;

    v_week := public.compute_current_week_at_date(
      v_group.weekday,
      v_group.created_at,
      v_local_date
    );

    if exists (
      select 1 from public.weekday_unlock_sent
      where group_id = v_group.id and week_index = v_week
    ) then
      continue;
    end if;

    v_weekday_name := public.weekday_name(v_group.weekday);

    insert into public.notification_queue (recipient_user_id, notification_type, payload)
    select gm.user_id, 'daily_reminder', jsonb_build_object(
      'group_id', v_group.id,
      'weekday_name', v_weekday_name,
      'is_weekday_unlock', true
    )
    from public.group_members gm
    join public.profiles p on p.id = gm.user_id and p.push_enabled
    where gm.group_id = v_group.id;

    insert into public.weekday_unlock_sent (group_id, week_index)
    values (v_group.id, v_week);

    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

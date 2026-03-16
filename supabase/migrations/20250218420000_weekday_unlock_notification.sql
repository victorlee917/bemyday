-- 요일 언락 알림: 그룹 기준 시간 00:00에 해당 요일 도래 시 푸시 발송 (Daily Reminder에 포함)
-- 예: 화요일 그룹 → 화요일 00:00 (그룹 timezone)에 "{Tuesday} Unlocked! Make your besties' day."
-- alarm_daily_reminder=true인 멤버에게 발송

-- 1. 중복 발송 방지용 테이블
create table if not exists public.weekday_unlock_sent (
  group_id uuid not null references public.groups(id) on delete cascade,
  week_index int not null,
  created_at timestamptz not null default now(),
  primary key (group_id, week_index)
);

comment on table public.weekday_unlock_sent is '요일 언락 알림 발송 이력 (그룹별 주차당 1회)';

alter table public.weekday_unlock_sent enable row level security;

create policy "Service role only"
  on public.weekday_unlock_sent for all using (false);

-- 4. 요일명 매핑 (1=Mon .. 7=Sun)
create or replace function public.weekday_name(p_weekday int)
returns text
language sql immutable
as $$
  select (array['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'])[p_weekday];
$$;

-- 5. 요일 언락 알림 enqueue RPC
-- 그룹 timezone 기준 00:00이고 해당 요일인 그룹에 대해, 아직 발송 안 한 주차면 notification_queue에 삽입
create or replace function public.enqueue_weekday_unlock_notifications()
returns int
language plpgsql security definer
set search_path = public
as $$
declare
  v_count int := 0;
  v_group record;
  v_week int;
  v_weekday_name text;
  v_local_ts timestamptz;
  v_local_hour int;
  v_local_dow int;
begin
  for v_group in
    select g.id, g.weekday, g.week_boundary_timezone, g.created_at
    from public.groups g
    where g.deleted_at is null
  loop
    begin
      v_local_ts := now() at time zone coalesce(nullif(trim(v_group.week_boundary_timezone), ''), 'UTC');
    exception when others then
      continue;
    end;
    v_local_hour := extract(hour from v_local_ts)::int;
    v_local_dow := extract(isodow from v_local_ts)::int;

    if v_local_hour <> 0 or v_local_dow <> v_group.weekday then
      continue;
    end if;

    v_week := public.compute_current_week(v_group.weekday, v_group.created_at);

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
    join public.profiles p on p.id = gm.user_id and p.push_enabled and p.alarm_daily_reminder
    where gm.group_id = v_group.id;

    insert into public.weekday_unlock_sent (group_id, week_index)
    values (v_group.id, v_week);

    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

-- 6. Cron: 매시 5분에 weekday-unlock Edge Function 호출
select cron.schedule(
  'weekday-unlock-hourly',
  '5 * * * *',
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'daily_reminder_project_url') || '/functions/v1/weekday-unlock',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'daily_reminder_anon_key')
    ),
    body := '{}'::jsonb
  ) as request_id;
  $$
);

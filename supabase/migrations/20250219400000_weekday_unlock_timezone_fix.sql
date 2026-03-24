-- 요일 언락 알림: 그룹 기준 시간(week_boundary_timezone)에 맞게 알림 발송
-- 1. 그룹 생성 시 owner(inviter) 프로필의 timezone을 week_boundary_timezone으로 설정
-- 2. 기존 그룹 중 UTC인 경우 owner 프로필 timezone으로 백필

-- 1. join_group_by_invite_token: 새 그룹 생성 시 week_boundary_timezone 설정
create or replace function public.join_group_by_invite_token(invite_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invitation record;
  v_user_id uuid;
  v_new_group_id uuid;
  v_invitee_nickname text;
  v_weekday_name text;
  v_weekday_names text[] := array['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
  v_tz text;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception '로그인이 필요합니다';
  end if;

  select i.id, i.group_id, i.inviter_id, i.weekday, g.weekday as g_weekday
  into v_invitation
  from public.invitations i
  left join public.groups g on g.id = i.group_id
  where i.token = invite_token and i.expires_at > now();

  if v_invitation is null then
    raise exception '유효하지 않거나 만료된 초대입니다';
  end if;

  select coalesce(trim(nickname), 'Someone') into v_invitee_nickname
  from public.profiles where id = v_user_id;

  v_weekday_name := v_weekday_names[coalesce(v_invitation.g_weekday, v_invitation.weekday, 1)];

  if v_invitation.group_id is not null then
    insert into public.group_members (group_id, user_id)
    values (v_invitation.group_id, v_user_id)
    on conflict (group_id, user_id) do nothing;

    insert into public.notification_queue (recipient_user_id, notification_type, payload)
    select gm.user_id, 'new_member', jsonb_build_object(
      'group_id', v_invitation.group_id,
      'invitee_nickname', v_invitee_nickname,
      'weekday_name', v_weekday_name
    )
    from public.group_members gm
    join public.profiles p on p.id = gm.user_id and p.push_enabled
    where gm.group_id = v_invitation.group_id
      and gm.user_id != v_user_id;

    return jsonb_build_object('group_id', v_invitation.group_id);
  end if;

  if v_invitation.weekday is null then
    raise exception '초대 정보가 올바르지 않습니다';
  end if;

  -- owner(inviter) 프로필의 timezone을 week_boundary_timezone으로 사용
  select coalesce(nullif(trim(p.timezone), ''), 'UTC')
  into v_tz from public.profiles p where p.id = v_invitation.inviter_id;

  insert into public.groups (owner_id, weekday, week_boundary_timezone)
  values (v_invitation.inviter_id, v_invitation.weekday, coalesce(v_tz, 'UTC'))
  returning id into v_new_group_id;

  insert into public.group_members (group_id, user_id)
  values (v_new_group_id, v_user_id)
  on conflict (group_id, user_id) do nothing;

  update public.invitations
  set group_id = v_new_group_id
  where id = v_invitation.id;

  insert into public.notification_queue (recipient_user_id, notification_type, payload)
  select v_invitation.inviter_id, 'new_member', jsonb_build_object(
    'group_id', v_new_group_id,
    'invitee_nickname', v_invitee_nickname,
    'weekday_name', v_weekday_names[v_invitation.weekday]
  )
  from public.profiles p
  where p.id = v_invitation.inviter_id and p.push_enabled;

  return jsonb_build_object('group_id', v_new_group_id);
end;
$$;

-- 2. 기존 그룹: week_boundary_timezone이 UTC 또는 비어있으면 owner 프로필 timezone으로 백필
update public.groups g
set week_boundary_timezone = coalesce(
  nullif(trim(p.timezone), ''),
  'UTC'
)
from public.profiles p
where p.id = g.owner_id
  and g.deleted_at is null
  and (
    g.week_boundary_timezone is null
    or trim(coalesce(g.week_boundary_timezone, '')) = ''
    or g.week_boundary_timezone = 'UTC'
  );

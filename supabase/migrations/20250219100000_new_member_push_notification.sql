-- 새 멤버 그룹 가입 시 기존 멤버들에게 푸시 알림
-- 메시지: "{invitee_nickname} is your {weekday}" (초대자 = 초대 받은 사람 = 새로 가입한 멤버)

-- 1. notification_type에 'new_member' 추가
alter table public.notification_queue
  drop constraint if exists notification_queue_notification_type_check;

alter table public.notification_queue
  add constraint notification_queue_notification_type_check
  check (notification_type in ('daily_reminder', 'new_post', 'new_comment', 'new_like', 'new_member'));

-- 2. join_group_by_invite_token: 멤버 추가 후 기존 멤버들에게 알림 삽입
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

  -- 초대자 = 초대 받은 사람 = 새로 가입한 멤버(v_user_id)의 닉네임
  select coalesce(trim(nickname), 'Someone') into v_invitee_nickname
  from public.profiles where id = v_user_id;

  v_weekday_name := v_weekday_names[coalesce(v_invitation.g_weekday, v_invitation.weekday, 1)];

  -- 기존 그룹이 있으면 멤버만 추가
  if v_invitation.group_id is not null then
    insert into public.group_members (group_id, user_id)
    values (v_invitation.group_id, v_user_id)
    on conflict (group_id, user_id) do nothing;

    -- 기존 멤버(본인 제외) 중 push_enabled에게 알림
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

  -- group_id 없음: 그룹 생성 후 inviter + accepter 추가
  if v_invitation.weekday is null then
    raise exception '초대 정보가 올바르지 않습니다';
  end if;

  insert into public.groups (owner_id, weekday)
  values (v_invitation.inviter_id, v_invitation.weekday)
  returning id into v_new_group_id;

  -- handle_new_group 트리거가 owner를 group_members에 추가함
  -- accepter 추가
  insert into public.group_members (group_id, user_id)
  values (v_new_group_id, v_user_id)
  on conflict (group_id, user_id) do nothing;

  -- invitation에 group_id 기록 (선택, 추적용)
  update public.invitations
  set group_id = v_new_group_id
  where id = v_invitation.id;

  -- 새 그룹: owner(inviter)가 유일한 기존 멤버. accepter(초대 받은 사람)가 join → owner에게 알림
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

-- get_invitation_by_token: inviter_in_other_group_on_weekday 필드 추가
-- 초대자가 같은 요일에 다른 그룹에 참여 중이면 true (가입 불가)
create or replace function public.get_invitation_by_token(invite_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row record;
  v_result jsonb;
  v_weekday smallint;
  v_group_name text;
  v_inviter_in_other_group boolean;
begin
  select i.id, i.group_id, i.inviter_id, i.weekday, i.expires_at, i.metadata, i.gradient_colors,
         p.nickname as inviter_nickname, p.avatar_url as inviter_avatar_url,
         g.weekday as g_weekday, g.name as g_name, g.deleted_at as g_deleted
  into v_row
  from public.invitations i
  join public.profiles p on p.id = i.inviter_id
  left join public.groups g on g.id = i.group_id
  where i.token = invite_token and i.expires_at > now();

  if v_row is null then
    return null;
  end if;

  v_weekday := coalesce(v_row.g_weekday, v_row.weekday);
  v_group_name := v_row.g_name;

  if v_row.group_id is not null and v_row.g_deleted is not null then
    return null;
  end if;

  -- 초대자가 같은 요일에 다른 그룹에 참여 중인지 확인
  -- group_id 있음: 초대 그룹이 아닌 다른 그룹에 참여 중
  -- group_id 없음: 해당 요일에 이미 참여 중인 그룹 존재
  select exists (
    select 1 from public.group_members gm
    join public.groups g on g.id = gm.group_id and g.deleted_at is null
    where gm.user_id = v_row.inviter_id
      and g.weekday = v_weekday
      and (v_row.group_id is null or gm.group_id != v_row.group_id)
  ) into v_inviter_in_other_group;

  v_result := jsonb_build_object(
    'id', v_row.id,
    'group_id', v_row.group_id,
    'inviter_id', v_row.inviter_id,
    'inviter_nickname', v_row.inviter_nickname,
    'inviter_avatar_url', v_row.inviter_avatar_url,
    'weekday', v_weekday,
    'group_name', v_group_name,
    'expires_at', v_row.expires_at,
    'metadata', coalesce(v_row.metadata, '{}'::jsonb),
    'gradient_colors', v_row.gradient_colors,
    'inviter_in_other_group_on_weekday', v_inviter_in_other_group
  );
  return v_result;
end;
$$;

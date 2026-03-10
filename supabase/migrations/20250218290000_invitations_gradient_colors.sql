-- invitations: 초대장 카드 그라데이션 색상 저장 (앱·웹 동일 UI용)
-- - [dark, base, light] 3색, hex 문자열 배열. 예: ["#1a2b3c", "#4d5e6f", "#7e8f9a"]

alter table public.invitations
  add column gradient_colors jsonb;

comment on column public.invitations.gradient_colors is '초대장 카드 그라데이션 색상 [dark, base, light]. hex 문자열 배열. null이면 기본 배경 사용';

-- get_invitation_by_token: gradient_colors 반환 추가
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
    'gradient_colors', v_row.gradient_colors
  );
  return v_result;
end;
$$;

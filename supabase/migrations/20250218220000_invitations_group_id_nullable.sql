-- invitations: group_id nullable, weekday 추가
-- - group_id 있음: 기존 그룹 초대 (해당 요일 그룹 이미 존재)
-- - group_id 없음: 승낙 시 그룹 생성 (inviter=owner, accepter=멤버)

-- 1. group_id nullable, weekday 추가
alter table public.invitations
  alter column group_id drop not null,
  add column weekday smallint,
  add constraint invitations_weekday_range check (weekday is null or (weekday >= 1 and weekday <= 7));

-- group_id 없을 때 weekday 필수
alter table public.invitations
  add constraint invitations_weekday_required_when_no_group
  check (group_id is not null or weekday is not null);

-- 기존 row: group_id 있으면 weekday를 groups에서 채움
update public.invitations i
set weekday = g.weekday
from public.groups g
where i.group_id = g.id and i.weekday is null;

-- group_id 없는 row는 없을 테지만, weekday 기본값
comment on column public.invitations.weekday is 'group_id 없을 때 필수. 1=월~7=일';

-- 2. RLS 정책 재생성
drop policy if exists "Members can create invitations" on public.invitations;
drop policy if exists "Members can view group invitations" on public.invitations;

-- INSERT: group_id 있으면 그룹 멤버만, group_id 없으면 본인만 (새 그룹용 초대)
create policy "Members can create invitations"
  on public.invitations for insert
  with check (
    (group_id is not null and group_id in (
      select id from public.groups where owner_id = auth.uid()
      union
      select group_id from public.group_members where user_id = auth.uid()
    ))
    or (group_id is null and inviter_id = auth.uid())
  );

-- SELECT: group_id 있으면 그룹 멤버, group_id 없으면 초대한 본인만
create policy "Members can view group invitations"
  on public.invitations for select
  using (
    (group_id is not null and group_id in (
      select id from public.groups where owner_id = auth.uid()
      union
      select group_id from public.group_members where user_id = auth.uid()
    ))
    or (group_id is null and inviter_id = auth.uid())
  );

-- 3. join_group_by_invite_token: group_id 없으면 그룹 생성 후 참여
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
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception '로그인이 필요합니다';
  end if;

  select id, group_id, inviter_id, weekday
  into v_invitation
  from public.invitations
  where token = invite_token and expires_at > now();

  if v_invitation is null then
    raise exception '유효하지 않거나 만료된 초대입니다';
  end if;

  -- 기존 그룹이 있으면 멤버만 추가
  if v_invitation.group_id is not null then
    insert into public.group_members (group_id, user_id)
    values (v_invitation.group_id, v_user_id)
    on conflict (group_id, user_id) do nothing;
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

  return jsonb_build_object('group_id', v_new_group_id);
end;
$$;

-- 4. get_invitation_by_token: group_id 없을 때도 조회 가능
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
  select i.id, i.group_id, i.inviter_id, i.weekday, i.expires_at, i.metadata,
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

  -- group_id 있으면 groups에서, 없으면 invitation.weekday
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
    'metadata', coalesce(v_row.metadata, '{}'::jsonb)
  );
  return v_result;
end;
$$;

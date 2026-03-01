-- invitations 테이블로 전환 (group_invite_links 대체)
-- - token 기반, 메타데이터(JSONB) 확장 가능
-- - 그룹 멤버도 초대 생성 가능

-- 1. 기존 함수 및 테이블 제거
drop function if exists public.join_group_by_invite_code(text);
drop table if exists public.group_invite_links;

-- 2. invitations 테이블 생성
create table public.invitations (
  id uuid primary key default gen_random_uuid(),
  token text not null unique,
  group_id uuid not null references public.groups(id) on delete cascade,
  inviter_id uuid not null references public.profiles(id) on delete cascade,
  expires_at timestamptz not null,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  constraint token_min_length check (char_length(token) >= 8)
);

create index idx_invitations_token on public.invitations(token);
create index idx_invitations_expires_at on public.invitations(expires_at);

comment on table public.invitations is '그룹 초대 (메타데이터 포함, 1회성)';
comment on column public.invitations.metadata is 'OG, 커스텀 메시지 등 확장용. 예: {"message":"...", "og":{"title":"...","description":"...","image_url":"..."}}';

-- 3. RLS
alter table public.invitations enable row level security;

-- 그룹 소유자 또는 멤버가 초대 생성 가능
create policy "Members can create invitations"
  on public.invitations for insert
  with check (
    group_id in (
      select id from public.groups where owner_id = auth.uid()
      union
      select group_id from public.group_members where user_id = auth.uid()
    )
  );

-- 그룹 멤버가 해당 그룹의 초대 목록 조회 가능
create policy "Members can view group invitations"
  on public.invitations for select
  using (
    group_id in (
      select id from public.groups where owner_id = auth.uid()
      union
      select group_id from public.group_members where user_id = auth.uid()
    )
  );

-- 본인이 만든 초대만 수정/삭제
create policy "Inviter can update own invitations"
  on public.invitations for update using (inviter_id = auth.uid());

create policy "Inviter can delete own invitations"
  on public.invitations for delete using (inviter_id = auth.uid());

-- 4. 토큰으로 그룹 참여 (인증된 유저만)
create or replace function public.join_group_by_invite_token(invite_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_group_id uuid;
  v_user_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception '로그인이 필요합니다';
  end if;
  select group_id into v_group_id
  from public.invitations
  where token = invite_token and expires_at > now();
  if v_group_id is null then
    raise exception '유효하지 않거나 만료된 초대입니다';
  end if;
  insert into public.group_members (group_id, user_id)
  values (v_group_id, v_user_id)
  on conflict (group_id, user_id) do nothing;
  return jsonb_build_object('group_id', v_group_id);
end;
$$;

-- 5. 토큰으로 초대 정보 조회 (딥링크/웹 OG용, 익명 허용)
create or replace function public.get_invitation_by_token(invite_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row record;
  v_result jsonb;
begin
  select i.id, i.group_id, i.inviter_id, i.expires_at, i.metadata,
         p.nickname as inviter_nickname, p.avatar_url as inviter_avatar_url,
         g.weekday, g.name as group_name
  into v_row
  from public.invitations i
  join public.profiles p on p.id = i.inviter_id
  join public.groups g on g.id = i.group_id
  where i.token = invite_token
    and i.expires_at > now()
    and g.deleted_at is null;
  if v_row is null then
    return null;
  end if;
  v_result := jsonb_build_object(
    'id', v_row.id,
    'group_id', v_row.group_id,
    'inviter_id', v_row.inviter_id,
    'inviter_nickname', v_row.inviter_nickname,
    'inviter_avatar_url', v_row.inviter_avatar_url,
    'weekday', v_row.weekday,
    'group_name', v_row.group_name,
    'expires_at', v_row.expires_at,
    'metadata', coalesce(v_row.metadata, '{}'::jsonb)
  );
  return v_result;
end;
$$;

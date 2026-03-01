-- Be My Day - Initial Schema
-- Run this in Supabase SQL Editor or: supabase db push

-- ============================================================
-- 1. profiles
-- ============================================================
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nickname text not null,
  avatar_url text,
  auth_provider text not null,
  email text,
  timezone text,
  push_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint nickname_length check (char_length(trim(nickname)) >= 1)
);

create unique index profiles_nickname_key on public.profiles (lower(trim(nickname)));

comment on table public.profiles is '회원 프로필';

-- updated_at trigger
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function public.handle_updated_at();

-- Auto-create profile on auth signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, nickname, auth_provider, email, timezone)
  values (
    new.id,
    'user_' || substr(replace(new.id::text, '-', ''), 1, 8),
    coalesce((new.raw_app_meta_data->>'provider')::text, 'email'),
    new.email,
    coalesce((new.raw_user_meta_data->>'timezone')::text, 'UTC')
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- RLS
alter table public.profiles enable row level security;

create policy "Users can view all profiles"
  on public.profiles for select using (true);

create policy "Users can update own profile"
  on public.profiles for update using (auth.uid() = id);

-- ============================================================
-- 2. groups
-- ============================================================
create table public.groups (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  successor_id uuid references public.profiles(id) on delete set null,
  weekday smallint not null,
  name text,
  week_boundary_timezone text not null default 'UTC',
  post_count int not null default 0,
  streak int not null default 0,
  streak_updated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint weekday_range check (weekday >= 1 and weekday <= 7)
);

create index idx_groups_owner on public.groups(owner_id);
create index idx_groups_weekday on public.groups(owner_id, weekday) where deleted_at is null;

create trigger groups_updated_at
  before update on public.groups
  for each row execute function public.handle_updated_at();

-- ============================================================
-- 3. group_members (created before groups RLS - policy references this)
-- ============================================================
create table public.group_members (
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

create index idx_group_members_user on public.group_members(user_id);

alter table public.group_members enable row level security;

create policy "Members can view their groups"
  on public.group_members for select
  using (
    user_id = auth.uid()
    or group_id in (select id from public.groups where owner_id = auth.uid())
  );

create policy "Owners can manage members"
  on public.group_members for all
  using (
    group_id in (select id from public.groups where owner_id = auth.uid())
  );

create policy "Users can leave group"
  on public.group_members for delete
  using (user_id = auth.uid());

-- groups RLS (after group_members exists)
alter table public.groups enable row level security;

create policy "Users can view groups they belong to"
  on public.groups for select
  using (
    deleted_at is null
    and (
      owner_id = auth.uid()
      or id in (select group_id from public.group_members where user_id = auth.uid())
    )
  );

create policy "Owners can manage their groups"
  on public.groups for all
  using (owner_id = auth.uid());

-- ============================================================
-- 4. group_invite_links
-- ============================================================
create table public.group_invite_links (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  code text not null,
  created_by_id uuid not null references public.profiles(id) on delete cascade,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  constraint invite_code_unique unique (code)
);

create index idx_invite_links_code on public.group_invite_links(code);

alter table public.group_invite_links enable row level security;

create policy "Owners can manage invite links"
  on public.group_invite_links for all
  using (
    group_id in (select id from public.groups where owner_id = auth.uid())
  );

-- 초대 링크로 그룹 참여 (인증된 유저만 호출)
create or replace function public.join_group_by_invite_code(invite_code text)
returns void
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
  from public.group_invite_links
  where code = invite_code
    and (expires_at is null or expires_at > now());
  if v_group_id is null then
    raise exception '유효하지 않거나 만료된 초대 링크입니다';
  end if;
  insert into public.group_members (group_id, user_id)
  values (v_group_id, v_user_id)
  on conflict (group_id, user_id) do nothing;
end;
$$;

-- ============================================================
-- 5. posts
-- ============================================================
create table public.posts (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  week_index int not null,
  photo_url text not null,
  caption text,
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index idx_posts_group_week on public.posts(group_id, week_index);
create index idx_posts_group on public.posts(group_id);
create index idx_posts_author on public.posts(author_id);

alter table public.posts enable row level security;

create policy "Members can view posts"
  on public.posts for select
  using (
    group_id in (select group_id from public.group_members where user_id = auth.uid())
    or author_id = auth.uid()
  );

create policy "Members can create posts"
  on public.posts for insert
  with check (
    author_id = auth.uid()
    and group_id in (select group_id from public.group_members where user_id = auth.uid())
  );

create policy "Authors can update own posts"
  on public.posts for update
  using (author_id = auth.uid());

create policy "Authors can delete own posts"
  on public.posts for delete
  using (author_id = auth.uid());

-- ============================================================
-- 6. post_likes
-- ============================================================
create table public.post_likes (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create index idx_post_likes_user on public.post_likes(user_id);

alter table public.post_likes enable row level security;

create policy "Members can view likes"
  on public.post_likes for select
  using (
    post_id in (
      select id from public.posts
      where group_id in (select group_id from public.group_members where user_id = auth.uid())
    )
  );

create policy "Members can like posts"
  on public.post_likes for all
  using (
    user_id = auth.uid()
    and post_id in (
      select id from public.posts
      where group_id in (select group_id from public.group_members where user_id = auth.uid())
    )
  );

-- ============================================================
-- 7. comments
-- ============================================================
create table public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index idx_comments_post on public.comments(post_id);

alter table public.comments enable row level security;

create policy "Members can view comments"
  on public.comments for select
  using (
    post_id in (
      select id from public.posts
      where group_id in (select group_id from public.group_members where user_id = auth.uid())
    )
  );

create policy "Members can create comments"
  on public.comments for insert
  with check (
    author_id = auth.uid()
    and post_id in (
      select id from public.posts
      where group_id in (select group_id from public.group_members where user_id = auth.uid())
    )
  );

create policy "Authors can update own comments"
  on public.comments for update
  using (author_id = auth.uid());

create policy "Authors can delete own comments"
  on public.comments for delete
  using (author_id = auth.uid());

-- ============================================================
-- 8. device_tokens
-- ============================================================
create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  token text not null,
  platform text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint token_unique unique (token),
  constraint platform_check check (platform in ('ios', 'android'))
);

create index idx_device_tokens_user on public.device_tokens(user_id);

create trigger device_tokens_updated_at
  before update on public.device_tokens
  for each row execute function public.handle_updated_at();

alter table public.device_tokens enable row level security;

create policy "Users can manage own device tokens"
  on public.device_tokens for all
  using (user_id = auth.uid());

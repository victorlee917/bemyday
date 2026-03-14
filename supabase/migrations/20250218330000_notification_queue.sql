-- 푸시 알림 대기열
-- 트리거에서 삽입 후, Edge Function(cron) 또는 워커가 FCM 발송
-- 메시지 내용은 이후 결정, payload에 nickname 등 전달

create table if not exists public.notification_queue (
  id uuid primary key default gen_random_uuid(),
  recipient_user_id uuid not null references public.profiles(id) on delete cascade,
  notification_type text not null check (notification_type in ('daily_reminder', 'new_post', 'new_comment', 'new_like')),
  payload jsonb default '{}',
  created_at timestamptz not null default now(),
  sent_at timestamptz
);

create index idx_notification_queue_recipient on public.notification_queue(recipient_user_id);
create index idx_notification_queue_pending on public.notification_queue(recipient_user_id, created_at)
  where sent_at is null;

alter table public.notification_queue enable row level security;

-- 서비스 롤만 접근 (Edge Function 등)
create policy "Service role only"
  on public.notification_queue for all
  using (false);

-- ============================================================
-- New Post: 그룹 멤버(본인 제외) 중 alarm_new_post=true
-- ============================================================
create or replace function public.notify_on_new_post()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notification_queue (recipient_user_id, notification_type, payload)
  select gm.user_id, 'new_post', jsonb_build_object(
    'post_id', new.id,
    'group_id', new.group_id,
    'author_nickname', (select nickname from profiles where id = new.author_id)
  )
  from public.group_members gm
  join public.profiles p on p.id = gm.user_id and p.push_enabled and p.alarm_new_post
  where gm.group_id = new.group_id
    and gm.user_id != new.author_id;
  return new;
end;
$$;

create trigger on_post_insert_notify
  after insert on public.posts
  for each row execute function public.notify_on_new_post();

-- ============================================================
-- New Comment: 포스트 작성자(댓글 작성자 제외) 중 alarm_new_comment=true
-- ============================================================
create or replace function public.notify_on_new_comment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notification_queue (recipient_user_id, notification_type, payload)
  select p.author_id, 'new_comment', jsonb_build_object(
    'post_id', new.post_id,
    'comment_id', new.id,
    'author_nickname', (select nickname from profiles where id = new.author_id)
  )
  from public.posts p
  join public.profiles pr on pr.id = p.author_id and pr.push_enabled and pr.alarm_new_comment
  where p.id = new.post_id
    and p.author_id != new.author_id;
  return new;
end;
$$;

create trigger on_comment_insert_notify
  after insert on public.comments
  for each row execute function public.notify_on_new_comment();

-- ============================================================
-- New Like: 포스트 작성자(좋아요 누른 사람 제외) 중 alarm_new_like=true
-- ============================================================
create or replace function public.notify_on_new_like()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notification_queue (recipient_user_id, notification_type, payload)
  select p.author_id, 'new_like', jsonb_build_object(
    'post_id', new.post_id,
    'liker_nickname', (select nickname from profiles where id = new.user_id)
  )
  from public.posts p
  join public.profiles pr on pr.id = p.author_id and pr.push_enabled and pr.alarm_new_like
  where p.id = new.post_id
    and p.author_id != new.user_id;
  return new;
end;
$$;

create trigger on_post_like_insert_notify
  after insert on public.post_likes
  for each row execute function public.notify_on_new_like();

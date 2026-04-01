-- 본인 행위에 대한 푸시 방지: payload에 actor ID 명시 + Edge send-push에서 이중 필터
-- (기존 트리거는 이미 author 제외 조건이 있으나, 큐 오염·구버전 대비)

-- New post: 그룹 멤버(본인 제외)
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
    'author_id', new.author_id,
    'author_nickname', (select nickname from profiles where id = new.author_id)
  )
  from public.group_members gm
  join public.profiles p on p.id = gm.user_id and p.push_enabled and p.alarm_new_post
  where gm.group_id = new.group_id
    and gm.user_id != new.author_id;
  return new;
end;
$$;

-- New like: 포스트 작성자(좋아요 누른 사람 제외)
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
    'liker_user_id', new.user_id,
    'liker_nickname', (select nickname from profiles where id = new.user_id)
  )
  from public.posts p
  join public.profiles pr on pr.id = p.author_id and pr.push_enabled and pr.alarm_new_like
  where p.id = new.post_id
    and p.author_id != new.user_id;
  return new;
end;
$$;

-- New comment + mention (기존 로직 유지, payload에 행위자 id 추가)
create or replace function public.notify_on_new_comment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_post_author_id uuid;
  v_group_id uuid;
  v_author_nickname text;
begin
  insert into public.notification_queue (recipient_user_id, notification_type, payload)
  select p.author_id, 'new_comment', jsonb_build_object(
    'post_id', new.post_id,
    'comment_id', new.id,
    'comment_author_id', new.author_id,
    'author_nickname', (select nickname from profiles where id = new.author_id)
  )
  from public.posts p
  join public.profiles pr on pr.id = p.author_id and pr.push_enabled and pr.alarm_new_comment
  where p.id = new.post_id
    and p.author_id != new.author_id;

  select p.author_id, p.group_id
  into v_post_author_id, v_group_id
  from public.posts p
  where p.id = new.post_id;

  if v_group_id is null then
    return new;
  end if;

  select nickname into v_author_nickname from public.profiles where id = new.author_id;

  insert into public.notification_queue (recipient_user_id, notification_type, payload)
  select distinct on (gm.user_id)
    gm.user_id,
    'comment_mention',
    jsonb_build_object(
      'post_id', new.post_id,
      'comment_id', new.id,
      'mentioner_user_id', new.author_id,
      'mentioner_nickname', coalesce(nullif(trim(v_author_nickname), ''), 'Someone'),
      'group_id', v_group_id
    )
  from public.extract_mention_tokens(new.content) as t
  join public.group_members gm on gm.group_id = v_group_id
  join public.profiles pr on pr.id = gm.user_id and pr.push_enabled and pr.alarm_comment_mention
  where lower(trim(coalesce(pr.nickname, ''))) = lower(trim(t.mention))
    and trim(t.mention) != ''
    and gm.user_id != new.author_id
    and not (
      gm.user_id = v_post_author_id
      and new.author_id != v_post_author_id
    )
  order by gm.user_id;

  return new;
end;
$$;

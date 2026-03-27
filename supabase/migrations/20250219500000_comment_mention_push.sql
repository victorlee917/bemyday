-- 댓글 본문의 @nickname 멘션에 대해 수신자에게 푸시 (comment_mention)
-- - 그룹 멤버 중 닉네임이 일치하는 유저 (대소문자 무시)
-- - push_enabled + alarm_comment_mention
-- - 댓글 작성자 본인 제외
-- - 포스트 작성자는 다른 사람이 댓글 달 때 이미 new_comment로 알림 → 멘션 중복 방지

alter table public.profiles
  add column if not exists alarm_comment_mention boolean not null default true;

comment on column public.profiles.alarm_comment_mention is 'Notify when someone @mentions you in a group comment';

alter table public.notification_queue
  drop constraint if exists notification_queue_notification_type_check;

alter table public.notification_queue
  add constraint notification_queue_notification_type_check
  check (notification_type in (
    'daily_reminder',
    'new_post',
    'new_comment',
    'new_like',
    'new_member',
    'comment_mention'
  ));

-- 댓글에서 @토큰 목록 (공백/@ 전까지)
-- regexp_matches는 setof text[] — FROM 별칭으로 regexp_matches 컬럼 접근이 환경마다 깨질 수 있어 루프 사용
create or replace function public.extract_mention_tokens(p_content text)
returns table (mention text)
language plpgsql
stable
set search_path = public
as $$
declare
  r text[];
  seen text[] := array[]::text[];
  v text;
begin
  for r in select regexp_matches(coalesce(p_content, ''), '@([^\s@]+)', 'g')
  loop
    v := trim(r[1]);
    if v = '' then
      continue;
    end if;
    if v = any(seen) then
      continue;
    end if;
    seen := array_append(seen, v);
    mention := v;
    return next;
  end loop;
  return;
end;
$$;

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

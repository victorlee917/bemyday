-- 알람 설정 컬럼 추가 (푸시 알림 발송 대상 판별용)
-- - alarm_daily_reminder: 매일 오후 10시 Daily Reminder
-- - alarm_new_post: 소속 그룹 새 포스트 (본인 제외)
-- - alarm_new_comment: 내 포스트에 새 댓글 (본인 제외)
-- - alarm_new_like: 내 포스트에 새 좋아요 (본인 제외)

alter table public.profiles
  add column if not exists alarm_daily_reminder boolean not null default false,
  add column if not exists alarm_new_post boolean not null default false,
  add column if not exists alarm_new_comment boolean not null default false,
  add column if not exists alarm_new_like boolean not null default false;

comment on column public.profiles.alarm_daily_reminder is 'Daily reminder at 10 PM';
comment on column public.profiles.alarm_new_post is 'Notify when someone posts in user''s group';
comment on column public.profiles.alarm_new_comment is 'Notify when someone comments on user''s post';
comment on column public.profiles.alarm_new_like is 'Notify when someone likes user''s post';

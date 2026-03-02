-- expires_at을 DB에서 설정 (클라이언트 시계/타임존 의존 제거)
-- - 기존: 클라이언트가 DateTime.now().add(1h).toUtc() 전송
-- - 변경: default (now() + interval '1 hour') → 항상 서버(UTC) 기준 1시간

alter table public.invitations
  alter column expires_at set default (now() + interval '1 hour');

-- 초대장 만료 기간: 1시간 → 1일
alter table public.invitations
  alter column expires_at set default (now() + interval '1 day');

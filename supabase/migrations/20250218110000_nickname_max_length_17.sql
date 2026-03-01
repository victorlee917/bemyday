-- 닉네임 최대 길이 13 → 17로 확대 (UUID 앞 12자 사용 가능, 충돌 확률 감소)

alter table public.profiles
  drop constraint if exists nickname_format_check;

alter table public.profiles
  add constraint nickname_format_check check (
    nickname ~ '^[a-zA-Z0-9._]{1,17}$'
  );

-- 닉네임 형식 제약: 영문, 숫자, 마침표(.), 언더스코어(_)만 허용, 1~13자
-- 기존 nickname_length 제약 제거 후 새 제약 추가

alter table public.profiles
  drop constraint if exists nickname_length;

alter table public.profiles
  add constraint nickname_format_check check (
    nickname ~ '^[a-zA-Z0-9._]{1,13}$'
  );

-- Supabase Dashboard → SQL Editor에서 실행
-- 프로필 없을 때 생성 (soft delete 후 재가입 등)

create or replace function public.ensure_profile()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_exists boolean;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception '로그인이 필요합니다';
  end if;

  select exists(select 1 from public.profiles where id = v_user_id) into v_exists;
  if not v_exists then
    insert into public.profiles (id, nickname, auth_provider, email, timezone)
    select
      v_user_id,
      'user_' || substr(replace(v_user_id::text, '-', ''), 1, 8),
      coalesce(
        (select raw_app_meta_data->>'provider' from auth.users where id = v_user_id),
        'email'
      ),
      (select email from auth.users where id = v_user_id),
      coalesce(
        (select raw_user_meta_data->>'timezone' from auth.users where id = v_user_id),
        'UTC'
      );
  end if;
end;
$$;

grant execute on function public.ensure_profile() to authenticated;

-- Supabase Dashboard → SQL Editor에서 이 파일 전체를 복사해 실행하세요.
-- MCP가 다른 DB에 적용할 수 있어, 직접 실행해야 합니다.

drop function if exists public.prepare_user_deletion();

create function public.prepare_user_deletion()
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_group record;
  v_remaining_count int;
  v_new_owner_id uuid;
  v_new_successor_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception '로그인이 필요합니다';
  end if;

  for v_group in
    select id, owner_id, successor_id
    from public.groups
    where owner_id = v_user_id and deleted_at is null
  loop
    delete from public.group_members
    where group_id = v_group.id and user_id = v_user_id;

    select count(*),
           (array_agg(user_id order by joined_at))[1],
           (array_agg(user_id order by joined_at))[2]
    into v_remaining_count, v_new_owner_id, v_new_successor_id
    from public.group_members
    where group_id = v_group.id;

    if v_remaining_count = 0 then
      update public.groups set deleted_at = now() where id = v_group.id;
    else
      update public.groups
      set owner_id = v_new_owner_id, successor_id = v_new_successor_id
      where id = v_group.id;
    end if;
  end loop;

  delete from public.group_members where user_id = v_user_id;
  delete from public.posts where author_id = v_user_id;
  delete from public.post_likes where user_id = v_user_id;
  delete from public.comment_likes where user_id = v_user_id;
  delete from public.comments where author_id = v_user_id;
  delete from public.invitations where inviter_id = v_user_id;
  delete from public.notification_queue where recipient_user_id = v_user_id;
  delete from public.profiles where id = v_user_id;
  return true;
end;
$$;

grant execute on function public.prepare_user_deletion() to authenticated;

notify pgrst, 'reload schema';

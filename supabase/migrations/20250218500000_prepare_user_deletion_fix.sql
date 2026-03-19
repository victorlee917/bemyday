-- 계정 삭제 전 데이터 정리 RPC 수정
-- invitations, notification_queue 정리 추가
-- profile 수동 삭제 추가 (auth.users 삭제 시 FK cascade 이슈 방지)
create or replace function public.prepare_user_deletion()
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

  -- 1. owner인 그룹 처리
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

  -- 2. member인 그룹에서 제거
  delete from public.group_members where user_id = v_user_id;

  -- 3. 게시글 삭제 (post_likes, comments cascade)
  delete from public.posts where author_id = v_user_id;

  -- 4. 좋아요 기록 삭제
  delete from public.post_likes where user_id = v_user_id;
  delete from public.comment_likes where user_id = v_user_id;

  -- 5. 댓글 삭제
  delete from public.comments where author_id = v_user_id;

  -- 6. 본인이 만든 초대 삭제
  delete from public.invitations where inviter_id = v_user_id;

  -- 7. 알림 대기열에서 제거
  delete from public.notification_queue where recipient_user_id = v_user_id;

  -- 8. profile 삭제 (auth.users 삭제 전 public 스키마 정리)
  delete from public.profiles where id = v_user_id;
  return true;
end;
$$;

-- authenticated 역할이 RPC 호출 가능하도록 권한 부여
grant execute on function public.prepare_user_deletion() to authenticated;

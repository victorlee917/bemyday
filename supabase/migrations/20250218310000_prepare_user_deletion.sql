-- 계정 삭제 전 데이터 정리 RPC
-- 호출: auth.uid()로 로그인한 유저만 자신의 계정 삭제 준비 가능
--
-- 1. owner인 그룹: 다른 멤버에게 승계 또는 멤버 없으면 그룹 삭제
-- 2. group_members에서 제거
-- 3. 해당 유저가 올린 게시글 삭제 (post_likes, comments는 cascade)
-- 4. 해당 유저의 좋아요 기록 삭제 (post_likes where user_id = 유저)
create or replace function public.prepare_user_deletion()
returns void
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
    -- group_members에서 유저 제거
    delete from public.group_members
    where group_id = v_group.id and user_id = v_user_id;

    -- 남은 멤버 수 및 1,2번째 멤버
    select count(*),
           max(case when rn = 1 then user_id end),
           max(case when rn = 2 then user_id end)
    into v_remaining_count, v_new_owner_id, v_new_successor_id
    from (
      select user_id, row_number() over (order by joined_at) as rn
      from public.group_members
      where group_id = v_group.id
    ) t;

    if v_remaining_count = 0 then
      -- 다른 멤버 없음 → 그룹 삭제 (soft delete)
      update public.groups set deleted_at = now() where id = v_group.id;
    else
      -- 첫 번째 멤버에게 owner 승계, 두 번째에게 successor
      update public.groups
      set owner_id = v_new_owner_id, successor_id = v_new_successor_id
      where id = v_group.id;
    end if;
  end loop;

  -- 2. member인 그룹에서 제거 (owner가 아닌 그룹)
  delete from public.group_members where user_id = v_user_id;

  -- 3. 해당 유저가 올린 게시글 삭제 (post_likes, comments는 cascade)
  delete from public.posts where author_id = v_user_id;

  -- 4. 해당 유저의 좋아요 기록 삭제 (게시글/댓글)
  delete from public.post_likes where user_id = v_user_id;
  delete from public.comment_likes where user_id = v_user_id;

  -- 5. 해당 유저가 작성한 댓글 삭제
  delete from public.comments where author_id = v_user_id;
end;
$$;

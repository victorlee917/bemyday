-- 클라이언트에서 leave 순서(delete → update) 시 탈퇴 후 RLS로 groups.update 실패·
-- 비오너는 group_members 전체 조회 불가로 successor 계산 오류가 남.
-- SECURITY DEFINER로 탈퇴 + successor_id 갱신을 원자적으로 처리.

create or replace function public.leave_group(p_group_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_new_successor uuid;
  v_remaining int;
begin
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;

  if not exists (
    select 1 from public.group_members gm
    where gm.group_id = p_group_id and gm.user_id = v_user_id
  ) then
    raise exception 'not a member of this group';
  end if;

  delete from public.group_members
  where group_id = p_group_id and user_id = v_user_id;

  select count(*)::int into v_remaining
  from public.group_members
  where group_id = p_group_id;

  if v_remaining >= 2 then
    select user_id into v_new_successor
    from (
      select user_id, row_number() over (order by joined_at asc) as rn
      from public.group_members
      where group_id = p_group_id
    ) sub
    where rn = 2;
  else
    v_new_successor := null;
  end if;

  update public.groups
  set successor_id = v_new_successor
  where id = p_group_id;
end;
$$;

grant execute on function public.leave_group(uuid) to authenticated;

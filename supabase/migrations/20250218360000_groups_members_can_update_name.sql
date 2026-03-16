-- 그룹 멤버도 group.name 업데이트 가능
-- 기존: owner만 "Owners can manage their groups"로 UPDATE 가능
-- 추가: group_members에 있는 유저도 name 등 업데이트 가능
create policy "Members can update their groups"
  on public.groups for update
  using (
    id in (select group_id from public.group_members where user_id = auth.uid())
  )
  with check (
    id in (select group_id from public.group_members where user_id = auth.uid())
  );

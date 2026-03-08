-- groups INSERT: 초대 수락 시 group_id 없을 때 accepter가 그룹 생성 가능하도록
-- "Owners can manage their groups"는 owner_id = auth.uid()만 허용 → accepter가 inviter 소유 그룹 생성 시 차단됨

create policy "Users can create groups when accepting invitation"
  on public.groups for insert
  with check (
    owner_id != auth.uid()
    and exists (
      select 1 from public.invitations
      where inviter_id = owner_id
        and group_id is null
        and expires_at > now()
    )
  );

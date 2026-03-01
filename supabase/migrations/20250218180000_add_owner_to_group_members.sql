-- groups INSERT 시 owner를 group_members에 자동 추가
create or replace function public.handle_new_group()
returns trigger as $$
begin
  insert into public.group_members (group_id, user_id)
  values (new.id, new.owner_id)
  on conflict (group_id, user_id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_group_created
  after insert on public.groups
  for each row execute function public.handle_new_group();

-- 기존 그룹: owner가 group_members에 없으면 추가
insert into public.group_members (group_id, user_id)
  select g.id, g.owner_id
  from public.groups g
  where g.deleted_at is null
    and not exists (
      select 1 from public.group_members gm
      where gm.group_id = g.id and gm.user_id = g.owner_id
    )
on conflict (group_id, user_id) do nothing;

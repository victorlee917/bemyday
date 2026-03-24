-- groups 테이블을 Realtime publication에 추가
-- 새 그룹 생성 시 FriendsScreen 등 실시간 반영
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'groups'
  ) then
    alter publication supabase_realtime add table public.groups;
  end if;
end $$;

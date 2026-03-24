-- posts, group_members 테이블을 Realtime publication에 추가
-- 새 게시글/멤버 추가 시 앱에서 실시간 반영
-- 이미 추가된 경우 에러 발생 가능 → Supabase 대시보드 Publications에서 수동 확인
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'posts'
  ) then
    alter publication supabase_realtime add table public.posts;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'group_members'
  ) then
    alter publication supabase_realtime add table public.group_members;
  end if;
end $$;

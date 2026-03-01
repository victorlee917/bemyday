-- Storage posts 버킷 RLS 정책
-- 버킷은 Dashboard에서 미리 생성 (public, 이름: posts)

-- 업로드: 그룹 멤버만 (경로: {groupId}/{userId}_{timestamp}.jpg)
create policy "Members can upload posts"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'posts' and
  (storage.foldername(name))[1] in (
    select id::text from public.groups
    where owner_id = auth.uid()
    or id in (select group_id from public.group_members where user_id = auth.uid())
  )
);

-- 조회: 그룹 멤버만
create policy "Members can view posts"
on storage.objects for select
to authenticated
using (
  bucket_id = 'posts' and
  (storage.foldername(name))[1] in (
    select id::text from public.groups
    where owner_id = auth.uid()
    or id in (select group_id from public.group_members where user_id = auth.uid())
  )
);

-- 삭제: 본인이 올린 파일만 (경로에 userId 포함)
create policy "Authors can delete own posts"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'posts' and
  (storage.filename(name)) like auth.uid()::text || '_%'
);

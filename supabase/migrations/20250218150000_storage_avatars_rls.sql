-- Storage avatars 버킷 RLS 정책
-- 버킷은 Dashboard에서 미리 생성되어 있어야 함

-- 업로드: 본인 경로에만 (예: {userId}/avatar.jpg)
create policy "Users can upload own avatar"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'avatars' and
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 조회: 누구나 (public 버킷)
create policy "Public avatar access"
on storage.objects for select
to public
using (bucket_id = 'avatars');

-- 수정: 본인 파일만 (upsert 시)
create policy "Users can update own avatar"
on storage.objects for update
to authenticated
using ((storage.foldername(name))[1] = auth.uid()::text)
with check ((storage.foldername(name))[1] = auth.uid()::text);

-- 삭제: 본인 파일만
create policy "Users can delete own avatar"
on storage.objects for delete
to authenticated
using ((storage.foldername(name))[1] = auth.uid()::text);

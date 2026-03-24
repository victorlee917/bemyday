-- posts 테이블에 REPLICA IDENTITY FULL 설정
-- Supabase Realtime DELETE 이벤트가 동작하려면 필수
-- https://github.com/supabase/realtime/issues/212
ALTER TABLE public.posts REPLICA IDENTITY FULL;

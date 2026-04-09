-- ============================================================
-- content_reports: 콘텐츠/사용자 신고
-- ============================================================
CREATE TABLE public.content_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  target_type text NOT NULL CHECK (target_type IN ('post', 'comment', 'user')),
  target_id text NOT NULL,
  reason text NOT NULL CHECK (reason IN (
    'harassment', 'hate_speech', 'violence', 'sexual_content',
    'spam', 'self_harm', 'impersonation', 'other'
  )),
  description text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed')),
  created_at timestamptz NOT NULL DEFAULT now(),
  reviewed_at timestamptz
);

-- 인덱스
CREATE INDEX idx_content_reports_status ON public.content_reports(status);
CREATE INDEX idx_content_reports_target ON public.content_reports(target_type, target_id);
CREATE INDEX idx_content_reports_reporter ON public.content_reports(reporter_id);

-- RLS
ALTER TABLE public.content_reports ENABLE ROW LEVEL SECURITY;

-- 본인의 신고만 INSERT 가능
CREATE POLICY "Users can create reports"
  ON public.content_reports FOR INSERT
  TO authenticated
  WITH CHECK (reporter_id = auth.uid());

-- 본인의 신고만 조회 가능
CREATE POLICY "Users can view own reports"
  ON public.content_reports FOR SELECT
  TO authenticated
  USING (reporter_id = auth.uid());

-- ============================================================
-- user_blocks: 사용자 차단
-- ============================================================
CREATE TABLE public.user_blocks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  blocked_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (blocker_id, blocked_id),
  CHECK (blocker_id != blocked_id)
);

CREATE INDEX idx_user_blocks_blocker ON public.user_blocks(blocker_id);
CREATE INDEX idx_user_blocks_blocked ON public.user_blocks(blocked_id);

-- RLS
ALTER TABLE public.user_blocks ENABLE ROW LEVEL SECURITY;

-- 본인의 차단만 INSERT 가능
CREATE POLICY "Users can create blocks"
  ON public.user_blocks FOR INSERT
  TO authenticated
  WITH CHECK (blocker_id = auth.uid());

-- 본인의 차단 목록 조회 가능
CREATE POLICY "Users can view own blocks"
  ON public.user_blocks FOR SELECT
  TO authenticated
  USING (blocker_id = auth.uid());

-- 본인의 차단만 삭제(해제) 가능
CREATE POLICY "Users can delete own blocks"
  ON public.user_blocks FOR DELETE
  TO authenticated
  USING (blocker_id = auth.uid());

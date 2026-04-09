-- Prevent duplicate reports from the same user on the same target
ALTER TABLE public.content_reports
  ADD CONSTRAINT unique_report_per_user_target
  UNIQUE (reporter_id, target_type, target_id);

-- Limit description length
ALTER TABLE public.content_reports
  ADD CONSTRAINT description_max_length
  CHECK (description IS NULL OR length(description) <= 1000);

-- Validate target_id is UUID format
ALTER TABLE public.content_reports
  ADD CONSTRAINT target_id_uuid_format
  CHECK (target_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

-- user_blocks INSERT 시 send-report-alert Edge Function 호출 (차단 알림)
CREATE OR REPLACE FUNCTION public.notify_block_alert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  edge_url text;
  service_key text;
BEGIN
  edge_url := current_setting('app.settings.supabase_url', true);
  service_key := current_setting('app.settings.service_role_key', true);

  IF edge_url IS NULL OR edge_url = '' THEN
    edge_url := 'https://qnpikfodyfefbimdbjae.supabase.co';
  END IF;

  PERFORM net.http_post(
    url := edge_url || '/functions/v1/send-report-alert',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || COALESCE(service_key, current_setting('supabase.service_role_key', true))
    ),
    body := jsonb_build_object(
      'record', jsonb_build_object(
        'id', NEW.id,
        'reporter_id', NEW.blocker_id,
        'target_type', 'user',
        'target_id', NEW.blocked_id,
        'reason', 'user_blocked',
        'description', 'User blocked another user',
        'created_at', NEW.created_at
      )
    )
  );

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_user_block_insert
  AFTER INSERT ON public.user_blocks
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_block_alert();

-- content_reports INSERT 시 send-report-alert Edge Function 호출
CREATE OR REPLACE FUNCTION public.notify_report_alert()
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
        'reporter_id', NEW.reporter_id,
        'target_type', NEW.target_type,
        'target_id', NEW.target_id,
        'reason', NEW.reason,
        'description', NEW.description,
        'created_at', NEW.created_at
      )
    )
  );

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_content_report_insert
  AFTER INSERT ON public.content_reports
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_report_alert();

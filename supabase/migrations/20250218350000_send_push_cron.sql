-- send-push Cron: 매분마다 notification_queue 처리 → FCM 발송
-- daily_reminder_project_url, daily_reminder_anon_key Vault 시크릿 사용

select cron.schedule(
  'send-push-every-minute',
  '* * * * *',
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'daily_reminder_project_url') || '/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'daily_reminder_anon_key')
    ),
    body := '{}'::jsonb
  ) as request_id;
  $$
);

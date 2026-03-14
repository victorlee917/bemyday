-- Daily Reminder Cron: 매일 13:00 UTC (22:00 KST)에 daily-reminder Edge Function 호출
--
-- 사전 준비 (SQL Editor에서 1회 실행):
-- 1. Extensions: pg_net, vault 활성화 (Dashboard → Database → Extensions)
-- 2. Vault 시크릿 생성:
--    select vault.create_secret('https://qnpikfodyfefbimdbjae.supabase.co', 'daily_reminder_project_url');
--    select vault.create_secret('YOUR_ANON_KEY', 'daily_reminder_anon_key');
--    (YOUR_ANON_KEY: Dashboard → Settings → API → anon public)

create extension if not exists pg_net with schema extensions;

select cron.schedule(
  'daily-reminder-10pm',
  '0 13 * * *',
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'daily_reminder_project_url') || '/functions/v1/daily-reminder',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'daily_reminder_anon_key')
    ),
    body := '{}'::jsonb
  ) as request_id;
  $$
);

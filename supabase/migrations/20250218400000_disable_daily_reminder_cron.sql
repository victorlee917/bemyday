-- Daily reminder를 클라이언트 로컬 알림으로 전환.
-- 서버 cron 비활성화 (daily-reminder Edge Function 호출 중단).
select cron.unschedule('daily-reminder-10pm');

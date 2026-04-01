-- 요일 언락 큐 적재: Edge(HTTP) 경유 Cron은 Vault/네트워크/콜드스타트 실패 시 그 로컬 0시대에 재시도 없음
-- → pg_cron에서 enqueue_weekday_unlock_notifications() 직접 호출 (5분마다, 같은 로컬 0시대에 재시도 가능)

do $$
begin
  perform cron.unschedule('weekday-unlock-hourly');
exception
  when others then
    null;
end;
$$;

do $$
begin
  perform cron.unschedule('enqueue-weekday-unlock-every-five-min');
exception
  when others then
    null;
end;
$$;

select cron.schedule(
  'enqueue-weekday-unlock-every-five-min',
  '*/5 * * * *',
  $$
  select public.enqueue_weekday_unlock_notifications();
  $$
);

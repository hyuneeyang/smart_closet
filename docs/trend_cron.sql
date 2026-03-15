create extension if not exists pg_cron;

select cron.schedule(
  'trend-signals-sync-daily',
  '0 6 * * *',
  $$
  select net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/trend-signals-sync',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.supabase_anon_key')
    ),
    body := '{"region":"KR"}'::jsonb
  );
  $$
);

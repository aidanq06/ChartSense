-- ⏰ Set up unified 15-minute cron jobs for all candle data
-- Run this AFTER running cleanup_cron_jobs.sql

-- Step 1: Show current cron jobs (should be clean)
SELECT '=== CURRENT CRON JOBS (SHOULD BE CLEAN) ===' as info;
SELECT jobid, jobname, schedule, active FROM cron.job ORDER BY jobname;

-- Step 2: Create unified cron job for market hours (every 15 minutes)
-- This single job will fetch 5m, 1d, AND 1h candles efficiently
SELECT '=== CREATING UNIFIED MARKET HOURS JOB ===' as info;
SELECT cron.schedule(
  'unified-candles-ingest',
  '*/15 9-16 * * 1-5',  -- Every 15 minutes, 9 AM to 4 PM, Monday to Friday
  $$
  SELECT net.http_post(
    url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/ingest-candles',
    headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY", "Content-Type": "application/json"}',
    body := '{}'
  );
  $$
) as market_hours_job_created;

-- Step 3: Create after-hours job for extended trading (optional)
SELECT '=== CREATING AFTER-HOURS JOB ===' as info;
SELECT cron.schedule(
  'unified-candles-after-hours',
  '0 17,18,19,20,21,22 * * 1-5',  -- 5 PM to 10 PM, Monday to Friday
  $$
  SELECT net.http_post(
    url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/ingest-candles',
    headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY", "Content-Type": "application/json"}',
    body := '{}'
  );
  $$
) as after_hours_job_created;

-- Step 4: Verify the new cron jobs
SELECT '=== VERIFICATION: NEW UNIFIED JOBS ===' as info;
SELECT jobid, jobname, schedule, active 
FROM cron.job 
WHERE jobname LIKE '%unified%' OR jobname LIKE '%candles%'
ORDER BY jobname;

-- Step 5: Show all cron jobs
SELECT '=== ALL CRON JOBS ===' as info;
SELECT jobid, jobname, schedule, active FROM cron.job ORDER BY jobname;

-- Step 6: Test the function manually (optional)
-- Uncomment the line below to test the function immediately
-- SELECT net.http_post(
--   url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/ingest-candles',
--   headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY", "Content-Type": "application/json"}',
--   body := '{}'
-- );

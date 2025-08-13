-- 🔧 Safe cleanup of ALL existing candle-related cron jobs
-- This script handles missing jobs gracefully without errors

-- Step 1: Show all current cron jobs
SELECT '=== CURRENT CRON JOBS ===' as info;
SELECT jobid, jobname, schedule, active FROM cron.job ORDER BY jobname;

-- Step 2: Show candle-related cron jobs specifically
SELECT '=== CANDLE-RELATED CRON JOBS ===' as info;
SELECT jobid, jobname, schedule, active 
FROM cron.job 
WHERE jobname ILIKE '%candle%' 
   OR jobname ILIKE '%ingest%' 
   OR jobname ILIKE '%fetch%' 
   OR jobname ILIKE '%market%'
ORDER BY jobname;

-- Step 3: Safely remove existing candle-related cron jobs
-- We'll use a function to handle missing jobs gracefully
CREATE OR REPLACE FUNCTION safe_unschedule_job(job_name text)
RETURNS text AS $$
BEGIN
  BEGIN
    PERFORM cron.unschedule(job_name);
    RETURN 'Removed: ' || job_name;
  EXCEPTION WHEN OTHERS THEN
    RETURN 'Not found: ' || job_name;
  END;
END;
$$ LANGUAGE plpgsql;

-- Step 4: Remove all possible candle-related jobs safely
SELECT '=== SAFELY REMOVING CANDLE-RELATED JOBS ===' as info;

SELECT safe_unschedule_job('ingest-candles') as result;
SELECT safe_unschedule_job('ingest-candles-5m-1d-1h') as result;
SELECT safe_unschedule_job('ingest-candles-after-hours') as result;
SELECT safe_unschedule_job('fetch-candles') as result;
SELECT safe_unschedule_job('fetch-stock-data') as result;
SELECT safe_unschedule_job('update-candles') as result;
SELECT safe_unschedule_job('update-market-data') as result;
SELECT safe_unschedule_job('candles-ingest') as result;
SELECT safe_unschedule_job('market-data-ingest') as result;
SELECT safe_unschedule_job('stock-data-ingest') as result;

-- Step 5: Clean up the helper function
DROP FUNCTION IF EXISTS safe_unschedule_job(text);

-- Step 6: Show remaining cron jobs
SELECT '=== REMAINING CRON JOBS ===' as info;
SELECT jobid, jobname, schedule, active FROM cron.job ORDER BY jobname;

-- Step 7: Verify no candle-related jobs remain
SELECT '=== VERIFICATION: NO CANDLE JOBS SHOULD REMAIN ===' as info;
SELECT jobid, jobname, schedule, active 
FROM cron.job 
WHERE jobname ILIKE '%candle%' 
   OR jobname ILIKE '%ingest%' 
   OR jobname ILIKE '%fetch%' 
   OR jobname ILIKE '%market%'
ORDER BY jobname;

-- 🔧 Clean up ALL existing candle-related cron jobs
-- Run this first to see what cron jobs exist and remove them safely

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

-- Step 3: Remove ALL possible candle-related cron jobs
-- (This is safe - unschedule will just return false if job doesn't exist)

SELECT '=== REMOVING CANDLE-RELATED JOBS ===' as info;

-- Remove ingest-candles jobs
SELECT cron.unschedule('ingest-candles') as removed_ingest_candles;
SELECT cron.unschedule('ingest-candles-5m-1d-1h') as removed_ingest_candles_5m_1d_1h;
SELECT cron.unschedule('ingest-candles-after-hours') as removed_ingest_candles_after_hours;

-- Remove fetch-candles jobs
SELECT cron.unschedule('fetch-candles') as removed_fetch_candles;
SELECT cron.unschedule('fetch-stock-data') as removed_fetch_stock_data;

-- Remove update-candles jobs
SELECT cron.unschedule('update-candles') as removed_update_candles;
SELECT cron.unschedule('update-market-data') as removed_update_market_data;

-- Remove any other variations
SELECT cron.unschedule('candles-ingest') as removed_candles_ingest;
SELECT cron.unschedule('market-data-ingest') as removed_market_data_ingest;
SELECT cron.unschedule('stock-data-ingest') as removed_stock_data_ingest;

-- Step 4: Show remaining cron jobs
SELECT '=== REMAINING CRON JOBS ===' as info;
SELECT jobid, jobname, schedule, active FROM cron.job ORDER BY jobname;

-- Step 5: Verify no candle-related jobs remain
SELECT '=== VERIFICATION: NO CANDLE JOBS SHOULD REMAIN ===' as info;
SELECT jobid, jobname, schedule, active 
FROM cron.job 
WHERE jobname ILIKE '%candle%' 
   OR jobname ILIKE '%ingest%' 
   OR jobname ILIKE '%fetch%' 
   OR jobname ILIKE '%market%'
ORDER BY jobname;

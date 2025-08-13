-- 🕐 Complete 1-Hour Candles Setup Script
-- Run this entire script in your Supabase SQL Editor to set up 1-hour candles

-- Step 1: Create the candles_1h table
begin;

-- Drop existing table if it exists (to ensure clean setup)
drop table if exists public.candles_1h cascade;

-- Create candles_1h table with identical structure to candles_5m
create table public.candles_1h (
  symbol text references public.symbols(symbol) on delete cascade,
  ts timestamptz not null,
  open numeric not null,
  high numeric not null,
  low numeric not null,
  close numeric not null,
  volume bigint,
  primary key(symbol, ts)
);

-- Create indexes (mirror candles_5m exactly)
create index idx_candles_1h_ts on public.candles_1h(ts);
create index idx_candles_1h_symbol_ts on public.candles_1h(symbol, ts);

-- Enable RLS
alter table public.candles_1h enable row level security;

-- Create RLS policies (mirror candles_5m exactly)
drop policy if exists market_read_c1h on public.candles_1h;
create policy market_read_c1h on public.candles_1h for select using (auth.role() = 'authenticated');

-- Also create anonymous read policy (mirror the pattern from candles_5m)
drop policy if exists market_read_c1h_anon on public.candles_1h;
create policy market_read_c1h_anon on public.candles_1h for select to anon using (true);

-- Grant necessary permissions
grant select on public.candles_1h to anon, authenticated;
grant insert, update on public.candles_1h to service_role;

commit;

-- Step 2: Insert sample data for testing
insert into public.candles_1h (symbol, ts, open, high, low, close, volume)
select 
  'AAPL',
  generate_series(
    date_trunc('hour', now() - interval '30 days'),
    date_trunc('hour', now()),
    interval '1 hour'
  ) as ts,
  150.0 + random() * 10 as open,
  150.0 + random() * 15 as high,
  150.0 + random() * 5 as low,
  150.0 + random() * 10 as close,
  1000000 + random() * 5000000 as volume
on conflict (symbol, ts) do nothing;

-- Step 3: Clean up ALL existing candle-related cron jobs and create unified 15-minute schedule
-- First, let's see what cron jobs currently exist
SELECT 'Current cron jobs:' as info, jobname, schedule FROM cron.job;

-- Remove ALL existing candle-related cron jobs (be thorough)
SELECT cron.unschedule('ingest-candles');
SELECT cron.unschedule('ingest-candles-5m-1d-1h');
SELECT cron.unschedule('ingest-candles-after-hours');
SELECT cron.unschedule('fetch-candles');
SELECT cron.unschedule('update-candles');
SELECT cron.unschedule('candles-ingest');
SELECT cron.unschedule('market-data-ingest');

-- Create a single unified cron job that runs every 15 minutes during market hours
-- This will fetch 5m, 1d, AND 1h candles in one go (much more efficient)
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
);

-- Also create an after-hours job for extended trading (optional)
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
);

-- Step 4: Verify setup
-- Check table structure
SELECT 'Table created successfully' as status, 
       COUNT(*) as column_count 
FROM information_schema.columns 
WHERE table_name = 'candles_1h';

-- Check indexes
SELECT 'Indexes created' as status, 
       COUNT(*) as index_count 
FROM pg_indexes 
WHERE tablename = 'candles_1h';

-- Check RLS policies
SELECT 'RLS policies configured' as status, 
       COUNT(*) as policy_count 
FROM pg_policies 
WHERE tablename = 'candles_1h';

-- Check sample data
SELECT 'Sample data inserted' as status, 
       COUNT(*) as row_count 
FROM public.candles_1h;

-- Check cron jobs (should show only the new unified jobs)
SELECT 'Unified cron jobs scheduled' as status, 
       jobname,
       schedule
FROM cron.job 
WHERE jobname LIKE '%candles%' OR jobname LIKE '%unified%';

-- Test query
SELECT 'Test query successful' as status,
       COUNT(*) as recent_candles
FROM public.candles_1h 
WHERE symbol = 'AAPL' 
  AND ts > NOW() - INTERVAL '7 days';

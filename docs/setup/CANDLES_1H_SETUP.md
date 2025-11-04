# 🕐 Complete 1-Hour Candles Setup Guide

This guide will help you set up 1-hour candles that work **exactly** like the 5m and 1d candles, including proper database schema, cron jobs, and Supabase integration.

## 📋 **What This Guide Covers**

- ✅ Database table creation with proper indexes
- ✅ Row Level Security (RLS) policies
- ✅ Cron job configuration for data ingestion
- ✅ Edge function updates
- ✅ iOS app integration
- ✅ Testing and verification

## 🗄️ **Step 1: Database Schema Setup**

### 1.1 Apply the Migration

Run this SQL in your Supabase Dashboard SQL Editor:

```sql
-- Complete candles_1h setup - mirrors candles_5m exactly
-- This migration ensures 1h candles work identically to 5m and 1d candles

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
```

### 1.2 Verify Table Creation

Check that the table was created correctly:

```sql
-- Verify table exists
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'candles_1h' 
ORDER BY ordinal_position;

-- Verify indexes
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'candles_1h';

-- Verify RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'candles_1h';
```

## 🔄 **Step 2: Edge Function Setup**

### 2.1 Update the Ingest Function

The `supabase/functions/ingest-candles/index.ts` file already includes 1-hour candle fetching. Verify it contains this section:

```typescript
// 1h: last 1 month (for 1W/1M charting)
const hourly = await fetchYahooChart(symbol, '1h', '1mo', true)
const rows1h = hourly.map(c => ({
  symbol,
  ts: new Date(c.t * 1000).toISOString(),
  open: c.o,
  high: c.h,
  low: c.l,
  close: c.c,
  volume: c.v,
}))
if (rows1h.length > 0) {
  await chunkedUpsert(rows1h, 400, async (chunk) => {
    await admin.from('candles_1h').upsert(chunk)
  })
  updated1h += rows1h.length
}
```

### 2.2 Deploy the Function

```bash
# Deploy the updated function
supabase functions deploy ingest-candles
```

## ⏰ **Step 3: Cron Job Configuration**

### 3.1 Enable pg_cron Extension

1. Go to your Supabase Dashboard
2. Navigate to **Database** → **Extensions**
3. Search for "pg_cron" and enable it

### 3.2 Set Up Cron Jobs

Run this SQL in your Supabase SQL Editor:

```sql
-- Remove existing cron jobs if they exist
SELECT cron.unschedule('ingest-candles-5m-1d-1h');

-- Schedule the ingest-candles function to run every 15 minutes
SELECT cron.schedule(
  'ingest-candles-5m-1d-1h',
  '*/15 9-16 * * 1-5',  -- Every 15 minutes, 9 AM to 4 PM, Monday to Friday
  $$
  SELECT net.http_post(
    url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/ingest-candles',
    headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY", "Content-Type": "application/json"}',
    body := '{}'
  );
  $$
);

-- Also schedule for after-hours data (optional)
SELECT cron.schedule(
  'ingest-candles-after-hours',
  '0 17,18,19,20,21,22 * * 1-5',  -- 5 PM to 10 PM, Monday to Friday
  $$
  SELECT net.http_post(
    url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/ingest-candles',
    headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY", "Content-Type": "application/json"}',
    body := '{}'
  );
  $$
);
```

**Important**: Replace `YOUR_PROJECT_REF` and `YOUR_SERVICE_ROLE_KEY` with your actual values.

### 3.3 Verify Cron Jobs

```sql
-- Check scheduled jobs
SELECT * FROM cron.job;

-- Check recent job runs
SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 10;
```

## 📱 **Step 4: iOS App Integration**

### 4.1 Verify SupabaseService.swift

The `fetchCandles1h` function should already exist in your `SupabaseService.swift`:

```swift
func fetchCandles1h(symbol: String, hoursBack: Int = 24 * 31) async throws -> [(Date, Double)] {
    guard let supabaseURL = supabaseURL, let supabaseAnonKey = supabaseAnonKey else { throw SupabaseError.networkError }
    let fromISO: String = ISO8601DateFormatter().string(from: Date().addingTimeInterval(Double(-hoursBack) * 3600))
    let url = URL(string: "\(supabaseURL)/rest/v1/candles_1h?symbol=eq.\(symbol.uppercased())&ts=gt.\(fromISO)&select=ts,close&order=ts.asc")!
    var req = URLRequest(url: url)
    if let token = self.accessToken { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
    req.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
    let (data, resp) = try await URLSession.shared.data(for: req)
    guard let http = resp as? HTTPURLResponse, http.statusCode == 200,
          let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { throw SupabaseError.invalidResponse }
    let iso = ISO8601DateFormatter()
    return arr.compactMap { row in
        guard let tsStr = row["ts"] as? String, let close = row["close"] as? Double, let d = iso.date(from: tsStr) else { return nil }
        return (d, close)
    }
}
```

### 4.2 Verify ChartComponents.swift

The chart loading logic should use 1-hour candles for 1W and 1M ranges:

```swift
case .oneWeek:
    // Use 1-hour candles for 1W (168 hours = 7 days)
    series = try await svc.fetchCandles1h(symbol: stock.symbol, hoursBack: 24 * 7)
case .oneMonth:
    // Use 1-hour candles for 1M (744 hours = 31 days)
    series = try await svc.fetchCandles1h(symbol: stock.symbol, hoursBack: 24 * 31)
```

## 🧪 **Step 5: Testing and Verification**

### 5.1 Test Database Access

```sql
-- Test inserting sample data
INSERT INTO public.candles_1h (symbol, ts, open, high, low, close, volume)
VALUES 
  ('AAPL', '2024-01-15 10:00:00+00', 150.00, 151.50, 149.80, 151.20, 1000000),
  ('AAPL', '2024-01-15 11:00:00+00', 151.20, 152.30, 150.90, 152.10, 1200000)
ON CONFLICT (symbol, ts) DO UPDATE SET
  open = EXCLUDED.open,
  high = EXCLUDED.high,
  low = EXCLUDED.low,
  close = EXCLUDED.close,
  volume = EXCLUDED.volume;

-- Test querying data
SELECT * FROM public.candles_1h WHERE symbol = 'AAPL' ORDER BY ts DESC LIMIT 5;
```

### 5.2 Test Edge Function

```bash
# Test the function manually
curl -X POST "https://YOUR_PROJECT_REF.supabase.co/functions/v1/ingest-candles" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{}'
```

### 5.3 Test iOS App

1. Build and run your iOS app
2. Navigate to a stock detail view
3. Switch to 1W or 1M timeframe
4. Verify the chart loads with 1-hour data

## 🔍 **Step 6: Monitoring and Troubleshooting**

### 6.1 Monitor Data Ingestion

```sql
-- Check recent data ingestion
SELECT 
  symbol,
  COUNT(*) as candle_count,
  MIN(ts) as earliest_ts,
  MAX(ts) as latest_ts
FROM public.candles_1h 
WHERE ts > NOW() - INTERVAL '7 days'
GROUP BY symbol
ORDER BY candle_count DESC;

-- Check for missing data
SELECT 
  symbol,
  COUNT(*) as gaps
FROM (
  SELECT 
    symbol,
    ts,
    LAG(ts) OVER (PARTITION BY symbol ORDER BY ts) as prev_ts
  FROM public.candles_1h 
  WHERE ts > NOW() - INTERVAL '7 days'
) t
WHERE prev_ts IS NOT NULL AND ts - prev_ts > INTERVAL '2 hours'
GROUP BY symbol;
```

### 6.2 Monitor Cron Jobs

```sql
-- Check cron job status
SELECT * FROM cron.job WHERE jobname LIKE '%candles%';

-- Check recent runs
SELECT 
  jobname,
  start_time,
  end_time,
  return_message,
  status
FROM cron.job_run_details 
WHERE jobname LIKE '%candles%'
ORDER BY start_time DESC 
LIMIT 10;
```

### 6.3 Common Issues and Solutions

#### Issue: No data in candles_1h table
**Solution**: 
1. Check if the cron job is running: `SELECT * FROM cron.job;`
2. Check function logs in Supabase Dashboard
3. Verify Yahoo Finance API is accessible
4. Test function manually with curl

#### Issue: iOS app shows no data for 1W/1M
**Solution**:
1. Verify RLS policies are correct
2. Check if user is authenticated
3. Verify the fetchCandles1h function is being called
4. Check network requests in Xcode debugger

#### Issue: Performance problems
**Solution**:
1. Verify indexes are created: `SELECT * FROM pg_indexes WHERE tablename = 'candles_1h';`
2. Check query performance: `EXPLAIN ANALYZE SELECT * FROM candles_1h WHERE symbol = 'AAPL' AND ts > NOW() - INTERVAL '7 days';`
3. Consider adding more specific indexes if needed

## ✅ **Verification Checklist**

- [ ] Database table `candles_1h` created with proper structure
- [ ] Indexes created for performance
- [ ] RLS policies configured correctly
- [ ] Edge function deployed and working
- [ ] Cron jobs scheduled and running
- [ ] Sample data inserted for testing
- [ ] iOS app can fetch 1-hour candles
- [ ] 1W and 1M charts display correctly
- [ ] Data ingestion working automatically
- [ ] Performance acceptable

## 🚀 **Next Steps**

Once 1-hour candles are working:

1. **Monitor Performance**: Watch for any performance issues with larger datasets
2. **Optimize Queries**: Add additional indexes if needed
3. **Scale Up**: Add more symbols to the baseline list
4. **Add Features**: Consider adding 30-minute or 2-hour candles for more granularity

## 📞 **Support**

If you encounter issues:

1. Check the Supabase Dashboard logs
2. Verify all SQL commands executed successfully
3. Test each component individually
4. Check the troubleshooting section above

The 1-hour candles should now work **exactly** like the 5m and 1d candles, with the same reliability and performance characteristics.

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

-- Add some sample data for testing (optional)
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

commit;

begin;

-- Optional: Allow anon reads for market data so the app can show prices before login
-- Comment out if you prefer to require user auth for reads.
do $$ begin
  -- symbols
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'symbols' and policyname = 'market_read_symbols_anon'
  ) then
    create policy market_read_symbols_anon on public.symbols for select to anon using (true);
  end if;

  -- quotes_latest
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'quotes_latest' and policyname = 'market_read_quotes_anon'
  ) then
    create policy market_read_quotes_anon on public.quotes_latest for select to anon using (true);
  end if;

  -- candles_5m
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'candles_5m' and policyname = 'market_read_c5_anon'
  ) then
    create policy market_read_c5_anon on public.candles_5m for select to anon using (true);
  end if;

  -- candles_1d
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'candles_1d' and policyname = 'market_read_c1_anon'
  ) then
    create policy market_read_c1_anon on public.candles_1d for select to anon using (true);
  end if;

  -- derived_metrics
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'derived_metrics' and policyname = 'market_read_dm_anon'
  ) then
    create policy market_read_dm_anon on public.derived_metrics for select to anon using (true);
  end if;

  -- sentiment_scores
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'sentiment_scores' and policyname = 'market_read_ss_anon'
  ) then
    create policy market_read_ss_anon on public.sentiment_scores for select to anon using (true);
  end if;

  -- news
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'news' and policyname = 'market_read_news_anon'
  ) then
    create policy market_read_news_anon on public.news for select to anon using (true);
  end if;
end $$;

commit;



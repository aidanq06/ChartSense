begin;

alter table public.quotes_latest
  add column if not exists premarket_price numeric,
  add column if not exists premarket_ts timestamptz,
  add column if not exists premarket_source text;

commit;



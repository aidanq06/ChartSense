begin;

alter table public.quotes_latest
  add column if not exists extended_price numeric,
  add column if not exists extended_ts timestamptz,
  add column if not exists price_source text,
  add column if not exists extended_source text,
  add column if not exists session text; -- regular | extended | premarket | unknown

commit;



begin;

-- Create a convenience view to compute a single display price and timestamp
create or replace view public.quotes_display as
select
  q.symbol,
  -- choose a display price based on session preference, else fallback to most recent available
  coalesce(
    case when q.session = 'extended' then q.extended_price end,
    case when q.session = 'premarket' then q.premarket_price end,
    q.price,
    greatest(q.price, coalesce(q.extended_price, 0), coalesce(q.premarket_price, 0))
  ) as display_price,
  coalesce(
    case when q.session = 'extended' then q.extended_ts end,
    case when q.session = 'premarket' then q.premarket_ts end,
    q.ts,
    greatest(q.ts, coalesce(q.extended_ts, 'epoch'::timestamptz), coalesce(q.premarket_ts, 'epoch'::timestamptz))
  ) as display_ts,
  q.session,
  q.previous_close
from public.quotes_latest q;

-- Expose read access to authenticated role; anon can be optionally enabled below
alter view public.quotes_display owner to postgres;
grant select on public.quotes_display to authenticated;

commit;



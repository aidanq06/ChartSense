-- Rebuild quotes_display to be robust:
-- - Always pick the newest row per symbol from quotes_latest
-- - Fallback to candles_1d for previous_close when missing

drop view if exists public.quotes_display cascade;

create view public.quotes_display as
with latest_q as (
  select distinct on (symbol)
    symbol,
    price,
    extended_price,
    premarket_price,
    previous_close,
    ts,
    extended_ts,
    premarket_ts,
    session
  from public.quotes_latest
  order by symbol, ts desc
),
resolved as (
  select
    l.symbol,
    l.price,
    l.extended_price,
    l.premarket_price,
    l.ts,
    l.extended_ts,
    l.premarket_ts,
    l.session,
    -- Determine the display timestamp and the previous trading day's close relative to it
    case
      when l.premarket_price is not null then l.premarket_ts
      when l.extended_price  is not null then l.extended_ts
      else l.ts
    end as display_ts_internal,
    coalesce(
      l.previous_close,
      (
        select c.close
        from public.candles_1d c
        where c.symbol = l.symbol
          and c.day < (case
                          when l.premarket_price is not null then (l.premarket_ts at time zone 'America/New_York')::date
                          when l.extended_price  is not null then (l.extended_ts  at time zone 'America/New_York')::date
                          else (l.ts at time zone 'America/New_York')::date
                        end)
        order by c.day desc
        limit 1
      )
    ) as effective_previous_close
  from latest_q l
)
select
  r.symbol,
  coalesce(r.premarket_price, r.extended_price, r.price) as display_price,
  r.display_ts_internal as display_ts,
  r.session,
  r.effective_previous_close as previous_close,
  case
    when r.effective_previous_close is not null and r.effective_previous_close <> 0 then
      ((coalesce(r.premarket_price, r.extended_price, r.price) - r.effective_previous_close) / r.effective_previous_close) * 100.0
    else null
  end as display_change_percent,
  case
    when r.effective_previous_close is not null then
      (coalesce(r.premarket_price, r.extended_price, r.price) - r.effective_previous_close)
    else null
  end as display_change
from resolved r;

grant select on public.quotes_display to anon, authenticated;



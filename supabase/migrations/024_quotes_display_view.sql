begin;

drop view if exists public.quotes_display cascade;

create view public.quotes_display as
select
  q.symbol,
  coalesce(q.premarket_price, q.extended_price, q.price) as display_price,
  case
    when q.premarket_price is not null then q.premarket_ts
    when q.extended_price  is not null then q.extended_ts
    else q.ts
  end as display_ts,
  q.session,
  q.previous_close,
  case
    when q.previous_close is not null and q.previous_close <> 0 then
      ((coalesce(q.premarket_price, q.extended_price, q.price) - q.previous_close) / q.previous_close) * 100.0
    else null
  end as display_change_percent,
  case
    when q.previous_close is not null then
      (coalesce(q.premarket_price, q.extended_price, q.price) - q.previous_close)
    else null
  end as display_change
from public.quotes_latest q;

grant select on public.quotes_display to anon, authenticated;

commit;



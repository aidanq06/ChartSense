begin;

create index if not exists idx_candles_5m_symbol_ts on public.candles_5m(symbol, ts);
create index if not exists idx_candles_1d_symbol_day on public.candles_1d(symbol, day);

commit;



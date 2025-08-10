-- ChartSense Supabase Backend v2
-- Requires: Supabase Postgres (auth schema exists)

begin;

-- Utility
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end; $$;

-- Enums
do $$ begin
  if not exists (select 1 from pg_type where typname = 'subscription_tier') then
    create type public.subscription_tier as enum ('free', 'premium', 'pro');
  end if;
  if not exists (select 1 from pg_type where typname = 'alert_type') then
    create type public.alert_type as enum ('price_above', 'price_below', 'percent_change_day', 'rsi_cross', 'sma_cross');
  end if;
  if not exists (select 1 from pg_type where typname = 'delivery_channel') then
    create type public.delivery_channel as enum ('push', 'email');
  end if;
end $$;

-- Profiles (mirror of auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at before update on public.profiles
for each row execute function public.set_updated_at();

-- Subscriptions
create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  tier public.subscription_tier not null,
  provider text not null,
  product_id text,
  status text not null default 'active',
  expires_at timestamptz,
  renewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_subscriptions_user on public.subscriptions(user_id);
drop trigger if exists trg_subscriptions_updated_at on public.subscriptions;
create trigger trg_subscriptions_updated_at before update on public.subscriptions
for each row execute function public.set_updated_at();

-- AI chat usage
create table if not exists public.ai_chat_usage_daily (
  user_id uuid not null references auth.users(id) on delete cascade,
  day date not null,
  used integer not null default 0,
  daily_limit integer not null default 20,
  primary key(user_id, day)
);
create index if not exists idx_ai_chat_usage_daily_user on public.ai_chat_usage_daily(user_id);

-- Preferences
create table if not exists public.user_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  currency text default 'USD',
  timezone text default 'UTC',
  theme text default 'system',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
drop trigger if exists trg_user_preferences_updated_at on public.user_preferences;
create trigger trg_user_preferences_updated_at before update on public.user_preferences
for each row execute function public.set_updated_at();

-- Devices (push)
create table if not exists public.devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  platform text not null,
  push_token text unique not null,
  locale text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_devices_user on public.devices(user_id);
drop trigger if exists trg_devices_updated_at on public.devices;
create trigger trg_devices_updated_at before update on public.devices
for each row execute function public.set_updated_at();

-- Notification settings
create table if not exists public.notification_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  push_enabled boolean not null default true,
  email_enabled boolean not null default false,
  quiet_hours_start time,
  quiet_hours_end time,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
drop trigger if exists trg_notification_settings_updated_at on public.notification_settings;
create trigger trg_notification_settings_updated_at before update on public.notification_settings
for each row execute function public.set_updated_at();

-- Watchlists
create table if not exists public.watchlists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null default 'Watchlist',
  is_default boolean not null default false,
  position integer not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists idx_watchlists_user on public.watchlists(user_id);

create table if not exists public.watchlist_items (
  watchlist_id uuid not null references public.watchlists(id) on delete cascade,
  symbol text not null,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  primary key (watchlist_id, symbol)
);
create index if not exists idx_watchlist_items_symbol on public.watchlist_items(symbol);

-- Alerts
create table if not exists public.alert_rules (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  symbol text not null,
  type public.alert_type not null,
  threshold numeric not null,
  window_minutes integer,
  active boolean not null default true,
  channel public.delivery_channel[] not null default '{push}',
  snooze_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_alert_rules_user on public.alert_rules(user_id);
create index if not exists idx_alert_rules_symbol on public.alert_rules(symbol);
drop trigger if exists trg_alert_rules_updated_at on public.alert_rules;
create trigger trg_alert_rules_updated_at before update on public.alert_rules
for each row execute function public.set_updated_at();

create table if not exists public.alert_deliveries (
  id uuid primary key default gen_random_uuid(),
  alert_rule_id uuid not null references public.alert_rules(id) on delete cascade,
  scheduled_for timestamptz not null,
  delivered_at timestamptz,
  status text not null default 'pending',
  error text
);
create index if not exists idx_alert_deliveries_rule on public.alert_deliveries(alert_rule_id);

-- Market data
create table if not exists public.symbols (
  symbol text primary key,
  name text,
  exchange text,
  currency text,
  sector text,
  updated_at timestamptz not null default now()
);

create table if not exists public.quotes_latest (
  symbol text primary key references public.symbols(symbol) on delete cascade,
  price numeric not null,
  open numeric,
  high numeric,
  low numeric,
  previous_close numeric,
  change numeric,
  change_percent numeric,
  volume bigint,
  ts timestamptz not null
);
create index if not exists idx_quotes_latest_ts on public.quotes_latest(ts);

create table if not exists public.candles_5m (
  symbol text references public.symbols(symbol) on delete cascade,
  ts timestamptz not null,
  open numeric not null,
  high numeric not null,
  low numeric not null,
  close numeric not null,
  volume bigint,
  primary key(symbol, ts)
);
create index if not exists idx_candles_5m_ts on public.candles_5m(ts);

create table if not exists public.candles_1d (
  symbol text references public.symbols(symbol) on delete cascade,
  day date not null,
  open numeric,
  high numeric,
  low numeric,
  close numeric,
  volume bigint,
  primary key(symbol, day)
);

create table if not exists public.derived_metrics (
  symbol text references public.symbols(symbol) on delete cascade,
  metric text not null,
  value numeric not null,
  ts timestamptz not null,
  primary key(symbol, metric, ts)
);
create index if not exists idx_derived_metrics_metric_ts on public.derived_metrics(metric, ts);

create table if not exists public.sentiment_scores (
  symbol text references public.symbols(symbol) on delete cascade,
  ts timestamptz not null,
  source text not null,
  score numeric not null,
  sample_size integer,
  primary key(symbol, ts, source)
);
create index if not exists idx_sentiment_scores_symbol_ts on public.sentiment_scores(symbol, ts);

create table if not exists public.news (
  id bigserial primary key,
  symbol text references public.symbols(symbol) on delete cascade,
  ts timestamptz not null,
  source text,
  title text,
  url text,
  summary text,
  sentiment_score numeric
);
create index if not exists idx_news_symbol_ts on public.news(symbol, ts);

create table if not exists public.ingest_runs (
  id uuid primary key default gen_random_uuid(),
  job_name text not null,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  status text not null default 'running',
  details jsonb
);

-- RLS: enable + policies
alter table public.profiles enable row level security;
alter table public.subscriptions enable row level security;
alter table public.ai_chat_usage_daily enable row level security;
alter table public.user_preferences enable row level security;
alter table public.devices enable row level security;
alter table public.notification_settings enable row level security;
alter table public.watchlists enable row level security;
alter table public.watchlist_items enable row level security;
alter table public.alert_rules enable row level security;
alter table public.alert_deliveries enable row level security;

-- profiles: owner can read/write
drop policy if exists profiles_rw on public.profiles;
create policy profiles_rw on public.profiles
  for all using (auth.uid() = id)
  with check (auth.uid() = id);

-- subscriptions: owner can read; writes via server only (service role)
drop policy if exists subscriptions_read_own on public.subscriptions;
create policy subscriptions_read_own on public.subscriptions for select using (auth.uid() = user_id);

-- ai_chat_usage_daily: owner can read; writes via server only
drop policy if exists ai_chat_usage_read_own on public.ai_chat_usage_daily;
create policy ai_chat_usage_read_own on public.ai_chat_usage_daily for select using (auth.uid() = user_id);

-- user_preferences
drop policy if exists user_prefs_rw on public.user_preferences;
create policy user_prefs_rw on public.user_preferences for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- devices
drop policy if exists devices_rw on public.devices;
create policy devices_rw on public.devices for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- notification_settings
drop policy if exists notif_settings_rw on public.notification_settings;
create policy notif_settings_rw on public.notification_settings for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- watchlists
drop policy if exists watchlists_rw on public.watchlists;
create policy watchlists_rw on public.watchlists for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- watchlist_items (through parent ownership)
drop policy if exists watchlist_items_select on public.watchlist_items;
create policy watchlist_items_select on public.watchlist_items
  for select using (exists (select 1 from public.watchlists w where w.id = watchlist_id and w.user_id = auth.uid()));

drop policy if exists watchlist_items_write on public.watchlist_items;
create policy watchlist_items_write on public.watchlist_items
  for all using (exists (select 1 from public.watchlists w where w.id = watchlist_id and w.user_id = auth.uid()))
  with check (exists (select 1 from public.watchlists w where w.id = watchlist_id and w.user_id = auth.uid()));

-- alert_rules
drop policy if exists alert_rules_rw on public.alert_rules;
create policy alert_rules_rw on public.alert_rules for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- alert_deliveries: readable by owner of parent rule
drop policy if exists alert_deliveries_read on public.alert_deliveries;
create policy alert_deliveries_read on public.alert_deliveries for select using (
  exists (
    select 1 from public.alert_rules r where r.id = alert_rule_id and r.user_id = auth.uid()
  )
);

-- Market tables: read for authenticated users; writes via service role
alter table public.symbols enable row level security;
alter table public.quotes_latest enable row level security;
alter table public.candles_5m enable row level security;
alter table public.candles_1d enable row level security;
alter table public.derived_metrics enable row level security;
alter table public.sentiment_scores enable row level security;
alter table public.news enable row level security;

drop policy if exists market_read on public.symbols;
create policy market_read on public.symbols for select using (auth.role() = 'authenticated');
drop policy if exists market_read_q on public.quotes_latest;
create policy market_read_q on public.quotes_latest for select using (auth.role() = 'authenticated');
drop policy if exists market_read_c5 on public.candles_5m;
create policy market_read_c5 on public.candles_5m for select using (auth.role() = 'authenticated');
drop policy if exists market_read_c1 on public.candles_1d;
create policy market_read_c1 on public.candles_1d for select using (auth.role() = 'authenticated');
drop policy if exists market_read_dm on public.derived_metrics;
create policy market_read_dm on public.derived_metrics for select using (auth.role() = 'authenticated');
drop policy if exists market_read_ss on public.sentiment_scores;
create policy market_read_ss on public.sentiment_scores for select using (auth.role() = 'authenticated');
drop policy if exists market_read_news on public.news;
create policy market_read_news on public.news for select using (auth.role() = 'authenticated');

-- RPC to increment AI chat usage atomically
create or replace function public.increment_ai_chat_usage(p_user_id uuid, p_limit integer)
returns boolean language plpgsql as $$
declare
  r public.ai_chat_usage_daily;
begin
  insert into public.ai_chat_usage_daily(user_id, day, used, daily_limit)
  values (p_user_id, current_date, 0, p_limit)
  on conflict(user_id, day) do update set daily_limit = excluded.daily_limit;

  update public.ai_chat_usage_daily
  set used = used + 1
  where user_id = p_user_id and day = current_date and used < daily_limit
  returning * into r;

  if not found then
    return false;
  end if;
  return true;
end; $$;
grant execute on function public.increment_ai_chat_usage(uuid, integer) to anon, authenticated;

commit;



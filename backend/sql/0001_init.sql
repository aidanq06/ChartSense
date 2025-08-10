-- ChartSense Backend v2 - Initial schema
-- Postgres 15+

begin;

-- Extensions
create extension if not exists pgcrypto;

-- Enums
do $$ begin
  if not exists (select 1 from pg_type where typname = 'subscription_tier') then
    create type subscription_tier as enum ('free', 'premium', 'pro');
  end if;
  if not exists (select 1 from pg_type where typname = 'alert_type') then
    create type alert_type as enum ('price_above', 'price_below', 'percent_change_day', 'rsi_cross', 'sma_cross');
  end if;
  if not exists (select 1 from pg_type where typname = 'delivery_channel') then
    create type delivery_channel as enum ('push', 'email');
  end if;
end $$;

-- Users and auth
create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  password_hash text, -- nullable if using OAuth/IAP only
  display_name text,
  auth_provider text not null default 'password', -- password | apple | google | custom
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Simple updated_at trigger
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end; $$;

drop trigger if exists trg_users_updated_at on users;
create trigger trg_users_updated_at before update on users
for each row execute function set_updated_at();

-- Auth sessions (refresh token store)
create table if not exists auth_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  refresh_token_hash text not null,
  user_agent text,
  ip inet,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  revoked_at timestamptz
);
create index if not exists idx_auth_sessions_user on auth_sessions(user_id);

-- Subscriptions / premium
create table if not exists subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  tier subscription_tier not null,
  provider text not null, -- app_store | stripe | revenuecat
  product_id text,
  status text not null default 'active', -- active | inactive | past_due | trialing | canceled
  expires_at timestamptz,
  renewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_subscriptions_user on subscriptions(user_id);

drop trigger if exists trg_subscriptions_updated_at on subscriptions;
create trigger trg_subscriptions_updated_at before update on subscriptions
for each row execute function set_updated_at();

-- Daily AI chat usage (per user per UTC day)
create table if not exists ai_chat_usage_daily (
  user_id uuid not null references users(id) on delete cascade,
  day date not null,
  used integer not null default 0,
  daily_limit integer not null default 20,
  primary key(user_id, day)
);
create index if not exists idx_ai_chat_usage_daily_user on ai_chat_usage_daily(user_id);

-- User preferences
create table if not exists user_preferences (
  user_id uuid primary key references users(id) on delete cascade,
  currency text default 'USD',
  timezone text default 'UTC',
  theme text default 'system',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_user_preferences_updated_at on user_preferences;
create trigger trg_user_preferences_updated_at before update on user_preferences
for each row execute function set_updated_at();

-- Device registry (for push notifications)
create table if not exists devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  platform text not null, -- ios | android | web
  push_token text unique not null,
  locale text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_devices_user on devices(user_id);

drop trigger if exists trg_devices_updated_at on devices;
create trigger trg_devices_updated_at before update on devices
for each row execute function set_updated_at();

-- Notification settings
create table if not exists notification_settings (
  user_id uuid primary key references users(id) on delete cascade,
  push_enabled boolean not null default true,
  email_enabled boolean not null default false,
  quiet_hours_start time,
  quiet_hours_end time,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_notification_settings_updated_at on notification_settings;
create trigger trg_notification_settings_updated_at before update on notification_settings
for each row execute function set_updated_at();

-- Watchlists
create table if not exists watchlists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  name text not null default 'Watchlist',
  is_default boolean not null default false,
  position integer not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists idx_watchlists_user on watchlists(user_id);

create table if not exists watchlist_items (
  watchlist_id uuid not null references watchlists(id) on delete cascade,
  symbol text not null,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  primary key (watchlist_id, symbol)
);
create index if not exists idx_watchlist_items_symbol on watchlist_items(symbol);

-- Alert rules
create table if not exists alert_rules (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  symbol text not null,
  type alert_type not null,
  threshold numeric not null,
  window_minutes integer,
  active boolean not null default true,
  channel delivery_channel[] not null default '{push}',
  snooze_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_alert_rules_user on alert_rules(user_id);
create index if not exists idx_alert_rules_symbol on alert_rules(symbol);

drop trigger if exists trg_alert_rules_updated_at on alert_rules;
create trigger trg_alert_rules_updated_at before update on alert_rules
for each row execute function set_updated_at();

create table if not exists alert_deliveries (
  id uuid primary key default gen_random_uuid(),
  alert_rule_id uuid not null references alert_rules(id) on delete cascade,
  scheduled_for timestamptz not null,
  delivered_at timestamptz,
  status text not null default 'pending', -- pending | sent | failed | skipped
  error text
);
create index if not exists idx_alert_deliveries_rule on alert_deliveries(alert_rule_id);

-- Market reference + cache
create table if not exists symbols (
  symbol text primary key,
  name text,
  exchange text,
  currency text,
  sector text,
  updated_at timestamptz not null default now()
);

create table if not exists quotes_latest (
  symbol text primary key references symbols(symbol) on delete cascade,
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
create index if not exists idx_quotes_latest_ts on quotes_latest(ts);

create table if not exists candles_5m (
  symbol text references symbols(symbol) on delete cascade,
  ts timestamptz not null,
  open numeric not null,
  high numeric not null,
  low numeric not null,
  close numeric not null,
  volume bigint,
  primary key(symbol, ts)
);
create index if not exists idx_candles_5m_ts on candles_5m(ts);

create table if not exists candles_1d (
  symbol text references symbols(symbol) on delete cascade,
  day date not null,
  open numeric,
  high numeric,
  low numeric,
  close numeric,
  volume bigint,
  primary key(symbol, day)
);

-- Derived metrics and sentiment
create table if not exists derived_metrics (
  symbol text references symbols(symbol) on delete cascade,
  metric text not null,
  value numeric not null,
  ts timestamptz not null,
  primary key(symbol, metric, ts)
);
create index if not exists idx_derived_metrics_metric_ts on derived_metrics(metric, ts);

create table if not exists sentiment_scores (
  symbol text references symbols(symbol) on delete cascade,
  ts timestamptz not null,
  source text not null,
  score numeric not null,
  sample_size integer,
  primary key(symbol, ts, source)
);
create index if not exists idx_sentiment_scores_symbol_ts on sentiment_scores(symbol, ts);

create table if not exists news (
  id bigserial primary key,
  symbol text references symbols(symbol) on delete cascade,
  ts timestamptz not null,
  source text,
  title text,
  url text,
  summary text,
  sentiment_score numeric
);
create index if not exists idx_news_symbol_ts on news(symbol, ts);

-- Ingest runs (observability)
create table if not exists ingest_runs (
  id uuid primary key default gen_random_uuid(),
  job_name text not null,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  status text not null default 'running',
  details jsonb
);

commit;



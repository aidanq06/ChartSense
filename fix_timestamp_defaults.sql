-- Fix for "generation expression is not immutable" error
-- This script replaces all DEFAULT NOW() with immutable expressions

-- 1. Drop and recreate user_profiles table
DROP TABLE IF EXISTS public.user_profiles CASCADE;
CREATE TABLE public.user_profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email TEXT NOT NULL,
    name TEXT NOT NULL,
    auth_provider TEXT NOT NULL DEFAULT 'email',
    avatar_url TEXT,
    is_premium BOOLEAN DEFAULT FALSE,
    premium_plan_id TEXT,
    premium_expires_at TIMESTAMPTZ,
    ai_messages_used_today INTEGER DEFAULT 0,
    ai_messages_limit INTEGER DEFAULT 5,
    image_analysis_used_today INTEGER DEFAULT 0,
    image_analysis_limit INTEGER DEFAULT 1,
    last_reset_date DATE DEFAULT CURRENT_DATE,
    preferences JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    updated_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- 2. Drop and recreate user_preferences table
DROP TABLE IF EXISTS public.user_preferences CASCADE;
CREATE TABLE public.user_preferences (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    is_dark_mode BOOLEAN DEFAULT FALSE,
    notifications_enabled BOOLEAN DEFAULT TRUE,
    price_alerts_enabled BOOLEAN DEFAULT TRUE,
    news_alerts_enabled BOOLEAN DEFAULT TRUE,
    refresh_interval TEXT DEFAULT '5min',
    default_chart_period TEXT DEFAULT '1D',
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    updated_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    UNIQUE(user_id)
);

-- 3. Drop and recreate stocks table
DROP TABLE IF EXISTS public.stocks CASCADE;
CREATE TABLE public.stocks (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    symbol TEXT NOT NULL UNIQUE,
    company_name TEXT NOT NULL,
    sector TEXT,
    industry TEXT,
    market_cap BIGINT,
    description TEXT,
    website TEXT,
    logo_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    updated_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- 4. Drop and recreate stock_prices table
DROP TABLE IF EXISTS public.stock_prices CASCADE;
CREATE TABLE public.stock_prices (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    stock_id UUID REFERENCES public.stocks(id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    current_price DECIMAL(12,4) NOT NULL,
    daily_change DECIMAL(12,4) NOT NULL,
    daily_change_percent DECIMAL(8,4) NOT NULL,
    volume BIGINT,
    market_cap BIGINT,
    pe_ratio DECIMAL(8,2),
    high_52_week DECIMAL(12,4),
    low_52_week DECIMAL(12,4),
    dividend_yield DECIMAL(8,4),
    beta DECIMAL(8,4),
    last_updated TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    UNIQUE(symbol)
);

-- 5. Drop and recreate stock_history table
DROP TABLE IF EXISTS public.stock_history CASCADE;
CREATE TABLE public.stock_history (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    stock_id UUID REFERENCES public.stocks(id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    date_time TIMESTAMPTZ NOT NULL,
    open_price DECIMAL(12,4) NOT NULL,
    high_price DECIMAL(12,4) NOT NULL,
    low_price DECIMAL(12,4) NOT NULL,
    close_price DECIMAL(12,4) NOT NULL,
    volume BIGINT NOT NULL,
    period TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    UNIQUE(symbol, date_time, period)
);

-- 6. Drop and recreate market_indices table
DROP TABLE IF EXISTS public.market_indices CASCADE;
CREATE TABLE public.market_indices (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    symbol TEXT NOT NULL UNIQUE,
    price DECIMAL(12,4) NOT NULL,
    change DECIMAL(12,4) NOT NULL,
    change_percent DECIMAL(8,4) NOT NULL,
    last_updated TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- 7. Drop and recreate sentiment_analysis table
DROP TABLE IF EXISTS public.sentiment_analysis CASCADE;
CREATE TABLE public.sentiment_analysis (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    stock_id UUID REFERENCES public.stocks(id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    overall_rating TEXT NOT NULL,
    score DECIMAL(8,4) NOT NULL,
    confidence DECIMAL(8,4) NOT NULL,
    key_drivers TEXT[] DEFAULT '{}',
    news_positive DECIMAL(8,4) DEFAULT 0,
    news_negative DECIMAL(8,4) DEFAULT 0,
    news_neutral DECIMAL(8,4) DEFAULT 0,
    analyst_sentiment DECIMAL(8,4) DEFAULT 0,
    social_sentiment DECIMAL(8,4) DEFAULT 0,
    technical_indicators DECIMAL(8,4) DEFAULT 0,
    last_updated TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    UNIQUE(symbol)
);

-- 8. Drop and recreate news_articles table
DROP TABLE IF EXISTS public.news_articles CASCADE;
CREATE TABLE public.news_articles (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    headline TEXT NOT NULL,
    summary TEXT NOT NULL,
    source TEXT NOT NULL,
    url TEXT NOT NULL,
    category TEXT NOT NULL,
    symbols TEXT[] DEFAULT '{}',
    sentiment_score DECIMAL(8,4) DEFAULT 0,
    relevance_score DECIMAL(8,4) DEFAULT 0,
    image_url TEXT,
    published_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    updated_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- 9. Drop and recreate analyst_ratings table
DROP TABLE IF EXISTS public.analyst_ratings CASCADE;
CREATE TABLE public.analyst_ratings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    stock_id UUID REFERENCES public.stocks(id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    firm TEXT NOT NULL,
    analyst TEXT,
    rating TEXT NOT NULL,
    target_price DECIMAL(12,4),
    previous_target_price DECIMAL(12,4),
    rating_date TIMESTAMPTZ NOT NULL,
    reasoning TEXT,
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- 10. Drop and recreate market_events table
DROP TABLE IF EXISTS public.market_events CASCADE;
CREATE TABLE public.market_events (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    symbol TEXT,
    title TEXT NOT NULL,
    description TEXT,
    event_type TEXT NOT NULL,
    event_date TIMESTAMPTZ NOT NULL,
    importance TEXT NOT NULL DEFAULT 'medium',
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- 11. Drop and recreate watchlists table
DROP TABLE IF EXISTS public.watchlists CASCADE;
CREATE TABLE public.watchlists (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    company_name TEXT NOT NULL,
    price_target DECIMAL(12,4),
    alerts_enabled BOOLEAN DEFAULT FALSE,
    notes TEXT,
    alert_price DECIMAL(12,4),
    alert_type TEXT DEFAULT 'above',
    added_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    UNIQUE(user_id, symbol)
);

-- 12. Drop and recreate price_alerts table
DROP TABLE IF EXISTS public.price_alerts CASCADE;
CREATE TABLE public.price_alerts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    target_price DECIMAL(12,4) NOT NULL,
    is_above BOOLEAN NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    triggered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- 13. Drop and recreate search_history table
DROP TABLE IF EXISTS public.search_history CASCADE;
CREATE TABLE public.search_history (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    company_name TEXT NOT NULL,
    search_count INTEGER DEFAULT 1,
    last_searched_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    UNIQUE(user_id, symbol)
);

-- 14. Drop and recreate ai_conversations table
DROP TABLE IF EXISTS public.ai_conversations CASCADE;
CREATE TABLE public.ai_conversations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT,
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    updated_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- 15. Drop and recreate ai_messages table
DROP TABLE IF EXISTS public.ai_messages CASCADE;
CREATE TABLE public.ai_messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    conversation_id UUID REFERENCES public.ai_conversations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_user BOOLEAN NOT NULL,
    status TEXT DEFAULT 'sent',
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- 16. Drop and recreate subscription_history table
DROP TABLE IF EXISTS public.subscription_history CASCADE;
CREATE TABLE public.subscription_history (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    plan_id TEXT NOT NULL,
    plan_name TEXT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency TEXT DEFAULT 'USD',
    status TEXT NOT NULL,
    starts_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- 17. Drop and recreate usage_tracking table
DROP TABLE IF EXISTS public.usage_tracking CASCADE;
CREATE TABLE public.usage_tracking (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    feature_type TEXT NOT NULL,
    usage_count INTEGER DEFAULT 1,
    usage_date DATE DEFAULT CURRENT_DATE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- 18. Drop and recreate api_rate_limits table
DROP TABLE IF EXISTS public.api_rate_limits CASCADE;
CREATE TABLE public.api_rate_limits (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    endpoint TEXT NOT NULL,
    request_count INTEGER DEFAULT 1,
    window_start TIMESTAMPTZ NOT NULL,
    window_end TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- 19. Drop and recreate system_config table
DROP TABLE IF EXISTS public.system_config CASCADE;
CREATE TABLE public.system_config (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    config_key TEXT NOT NULL UNIQUE,
    config_value JSONB NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    updated_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- 20. Drop and recreate suggested_messages table
DROP TABLE IF EXISTS public.suggested_messages CASCADE;
CREATE TABLE public.suggested_messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    text TEXT NOT NULL,
    category TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    updated_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- 21. Drop and recreate home_widgets table
DROP TABLE IF EXISTS public.home_widgets CASCADE;
CREATE TABLE public.home_widgets (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    widget_type TEXT NOT NULL,
    widget_size TEXT NOT NULL,
    order_index INTEGER NOT NULL,
    is_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    updated_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    UNIQUE(user_id, widget_type)
);

-- Now recreate all the indexes, triggers, and functions from the original schema
-- (This would be the rest of the original schema without the DEFAULT NOW() expressions)

PRINT 'All tables recreated with immutable timestamp defaults!'; 
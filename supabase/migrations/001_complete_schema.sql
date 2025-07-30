-- ChartSense Complete Database Schema
-- This schema supports all iOS app features including authentication, stock data, sentiment analysis, news, watchlists, AI chat, and premium subscriptions

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_cron";

-- ============================================================================
-- AUTHENTICATION & USER MANAGEMENT
-- ============================================================================

-- User profiles (extends Supabase auth.users)
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

-- User preferences table
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

-- ============================================================================
-- STOCK DATA & MARKET DATA
-- ============================================================================

-- Stock symbols and company information
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
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Real-time stock prices
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
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(symbol)
);

-- Historical stock data for charts
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
    period TEXT NOT NULL, -- '1m', '5m', '1h', '1d', etc.
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(symbol, date_time, period)
);

-- Market indices (S&P 500, NASDAQ, DOW)
CREATE TABLE public.market_indices (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    symbol TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    current_value DECIMAL(12,4) NOT NULL,
    daily_change DECIMAL(12,4) NOT NULL,
    daily_change_percent DECIMAL(8,4) NOT NULL,
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- SENTIMENT ANALYSIS & NEWS
-- ============================================================================

-- Sentiment analysis data
CREATE TABLE public.sentiment_analysis (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    stock_id UUID REFERENCES public.stocks(id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    overall_rating TEXT NOT NULL, -- 'stronglyBullish', 'bullish', etc.
    score DECIMAL(4,3) NOT NULL, -- -1.0 to 1.0
    confidence DECIMAL(4,3) NOT NULL,
    key_drivers TEXT[] DEFAULT '{}',
    news_positive DECIMAL(4,3) DEFAULT 0,
    news_negative DECIMAL(4,3) DEFAULT 0,
    news_neutral DECIMAL(4,3) DEFAULT 0,
    analyst_sentiment DECIMAL(4,3) DEFAULT 0,
    social_sentiment DECIMAL(4,3) DEFAULT 0,
    technical_indicators DECIMAL(4,3) DEFAULT 0,
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(symbol)
);

-- News articles
CREATE TABLE public.news_articles (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    headline TEXT NOT NULL,
    summary TEXT,
    content TEXT,
    source TEXT NOT NULL,
    author TEXT,
    url TEXT NOT NULL UNIQUE,
    image_url TEXT,
    published_at TIMESTAMPTZ NOT NULL,
    category TEXT NOT NULL, -- 'earnings', 'product', 'analyst', etc.
    sentiment_score DECIMAL(4,3) DEFAULT 0,
    relevance_score DECIMAL(4,3) DEFAULT 0,
    symbols TEXT[] DEFAULT '{}', -- Related stock symbols
    is_featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Analyst ratings and revisions
CREATE TABLE public.analyst_ratings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    stock_id UUID REFERENCES public.stocks(id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    firm TEXT NOT NULL,
    analyst_name TEXT,
    rating TEXT NOT NULL, -- 'Buy', 'Hold', 'Sell', etc.
    price_target DECIMAL(12,4),
    previous_rating TEXT,
    previous_price_target DECIMAL(12,4),
    reasoning TEXT,
    published_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Market events (earnings, product launches, etc.)
CREATE TABLE public.market_events (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    stock_id UUID REFERENCES public.stocks(id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    event_type TEXT NOT NULL, -- 'earnings', 'productLaunch', 'conference', etc.
    importance TEXT NOT NULL, -- 'high', 'medium', 'low'
    event_date TIMESTAMPTZ NOT NULL,
    is_upcoming BOOLEAN GENERATED ALWAYS AS (event_date > NOW()) STORED,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- USER FEATURES (WATCHLISTS, SEARCH HISTORY, ALERTS)
-- ============================================================================

-- User watchlists
CREATE TABLE public.watchlists (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    stock_id UUID REFERENCES public.stocks(id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    company_name TEXT NOT NULL,
    alerts_enabled BOOLEAN DEFAULT FALSE,
    price_target DECIMAL(12,4),
    notes TEXT,
    added_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, stock_id)
);

-- Price alerts
CREATE TABLE public.price_alerts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    stock_id UUID REFERENCES public.stocks(id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    target_price DECIMAL(12,4) NOT NULL,
    is_above BOOLEAN NOT NULL, -- TRUE for "alert when above", FALSE for "alert when below"
    is_active BOOLEAN DEFAULT TRUE,
    triggered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User search history
CREATE TABLE public.search_history (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    company_name TEXT NOT NULL,
    search_count INTEGER DEFAULT 1,
    last_searched_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, symbol)
);

-- ============================================================================
-- AI CHAT & PREMIUM FEATURES
-- ============================================================================

-- AI chat conversations
CREATE TABLE public.ai_conversations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- AI chat messages
CREATE TABLE public.ai_messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    conversation_id UUID REFERENCES public.ai_conversations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_user BOOLEAN NOT NULL,
    message_type TEXT DEFAULT 'text', -- 'text', 'image_analysis', 'chart_analysis'
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Premium subscription tracking
CREATE TABLE public.subscription_history (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    plan_id TEXT NOT NULL,
    status TEXT NOT NULL, -- 'active', 'cancelled', 'expired'
    started_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    amount DECIMAL(10,2),
    currency TEXT DEFAULT 'USD',
    payment_provider TEXT, -- 'apple', 'google', 'stripe'
    external_id TEXT, -- Store transaction ID
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Usage tracking for premium features
CREATE TABLE public.usage_tracking (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    feature_type TEXT NOT NULL, -- 'ai_message', 'image_analysis', 'price_alert'
    usage_date DATE NOT NULL,
    usage_count INTEGER DEFAULT 1,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, feature_type, usage_date)
);

-- ============================================================================
-- SYSTEM TABLES
-- ============================================================================

-- API rate limiting
CREATE TABLE public.api_rate_limits (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    endpoint TEXT NOT NULL,
    request_count INTEGER DEFAULT 1,
    window_start TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, endpoint, window_start)
);

-- System configuration
CREATE TABLE public.system_config (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    key TEXT NOT NULL UNIQUE,
    value JSONB NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Stock data indexes
CREATE INDEX idx_stock_prices_symbol ON public.stock_prices(symbol);
CREATE INDEX idx_stock_prices_updated ON public.stock_prices(last_updated);
CREATE INDEX idx_stock_history_symbol_date ON public.stock_history(symbol, date_time DESC);
CREATE INDEX idx_stock_history_period ON public.stock_history(period, date_time DESC);

-- News and sentiment indexes
CREATE INDEX idx_news_published ON public.news_articles(published_at DESC);
CREATE INDEX idx_news_symbols ON public.news_articles USING GIN(symbols);
CREATE INDEX idx_news_category ON public.news_articles(category);
CREATE INDEX idx_sentiment_symbol ON public.sentiment_analysis(symbol);
CREATE INDEX idx_sentiment_updated ON public.sentiment_analysis(last_updated);

-- User feature indexes
CREATE INDEX idx_watchlists_user ON public.watchlists(user_id);
CREATE INDEX idx_search_history_user ON public.search_history(user_id, last_searched_at DESC);
CREATE INDEX idx_price_alerts_active ON public.price_alerts(is_active, symbol) WHERE is_active = TRUE;
CREATE INDEX idx_ai_messages_conversation ON public.ai_messages(conversation_id, created_at);

-- Usage tracking indexes
CREATE INDEX idx_usage_tracking_user_date ON public.usage_tracking(user_id, usage_date);
CREATE INDEX idx_usage_tracking_feature ON public.usage_tracking(feature_type, usage_date);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all user-specific tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.watchlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.price_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.search_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usage_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_rate_limits ENABLE ROW LEVEL SECURITY;

-- User profile policies
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

-- User preferences policies
CREATE POLICY "Users can manage own preferences" ON public.user_preferences
    FOR ALL USING (auth.uid() = user_id);

-- Watchlist policies
CREATE POLICY "Users can manage own watchlists" ON public.watchlists
    FOR ALL USING (auth.uid() = user_id);

-- Price alert policies
CREATE POLICY "Users can manage own alerts" ON public.price_alerts
    FOR ALL USING (auth.uid() = user_id);

-- Search history policies
CREATE POLICY "Users can manage own search history" ON public.search_history
    FOR ALL USING (auth.uid() = user_id);

-- AI chat policies
CREATE POLICY "Users can manage own conversations" ON public.ai_conversations
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own messages" ON public.ai_messages
    FOR ALL USING (auth.uid() = user_id);

-- Subscription and usage policies
CREATE POLICY "Users can view own subscription history" ON public.subscription_history
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own usage tracking" ON public.usage_tracking
    FOR SELECT USING (auth.uid() = user_id);

-- Rate limiting policies
CREATE POLICY "Users can view own rate limits" ON public.api_rate_limits
    FOR SELECT USING (auth.uid() = user_id);

-- Public read access for market data
CREATE POLICY "Public read access to stocks" ON public.stocks
    FOR SELECT USING (true);

CREATE POLICY "Public read access to stock prices" ON public.stock_prices
    FOR SELECT USING (true);

CREATE POLICY "Public read access to stock history" ON public.stock_history
    FOR SELECT USING (true);

CREATE POLICY "Public read access to market indices" ON public.market_indices
    FOR SELECT USING (true);

CREATE POLICY "Public read access to sentiment analysis" ON public.sentiment_analysis
    FOR SELECT USING (true);

CREATE POLICY "Public read access to news articles" ON public.news_articles
    FOR SELECT USING (true);

CREATE POLICY "Public read access to analyst ratings" ON public.analyst_ratings
    FOR SELECT USING (true);

CREATE POLICY "Public read access to market events" ON public.market_events
    FOR SELECT USING (true);

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON public.user_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_stocks_updated_at BEFORE UPDATE ON public.stocks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_news_articles_updated_at BEFORE UPDATE ON public.news_articles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ai_conversations_updated_at BEFORE UPDATE ON public.ai_conversations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_system_config_updated_at BEFORE UPDATE ON public.system_config
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to reset daily usage counters
CREATE OR REPLACE FUNCTION reset_daily_usage()
RETURNS void AS $$
BEGIN
    UPDATE public.user_profiles 
    SET 
        ai_messages_used_today = 0,
        image_analysis_used_today = 0,
        last_reset_date = CURRENT_DATE
    WHERE last_reset_date < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, name, auth_provider)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
        CASE 
            WHEN NEW.app_metadata->>'provider' = 'apple' THEN 'apple'
            WHEN NEW.app_metadata->>'provider' = 'google' THEN 'google'
            ELSE 'email'
        END
    );
    
    INSERT INTO public.user_preferences (user_id)
    VALUES (NEW.id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user registration
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Function to increment usage tracking
CREATE OR REPLACE FUNCTION increment_usage_tracking(
    p_user_id UUID,
    p_feature_type TEXT,
    p_metadata JSONB DEFAULT '{}'
)
RETURNS void AS $$
BEGIN
    INSERT INTO public.usage_tracking (user_id, feature_type, usage_date, usage_count, metadata)
    VALUES (p_user_id, p_feature_type, CURRENT_DATE, 1, p_metadata)
    ON CONFLICT (user_id, feature_type, usage_date)
    DO UPDATE SET 
        usage_count = usage_tracking.usage_count + 1,
        metadata = p_metadata;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- INITIAL DATA
-- ============================================================================

-- Insert popular stocks
INSERT INTO public.stocks (symbol, company_name, sector, industry) VALUES
('AAPL', 'Apple Inc.', 'Technology', 'Consumer Electronics'),
('MSFT', 'Microsoft Corporation', 'Technology', 'Software'),
('GOOGL', 'Alphabet Inc.', 'Technology', 'Internet Content & Information'),
('AMZN', 'Amazon.com Inc.', 'Consumer Discretionary', 'Internet & Direct Marketing Retail'),
('TSLA', 'Tesla, Inc.', 'Consumer Discretionary', 'Automobiles'),
('NVDA', 'NVIDIA Corporation', 'Technology', 'Semiconductors'),
('META', 'Meta Platforms, Inc.', 'Communication Services', 'Interactive Media & Services'),
('NFLX', 'Netflix, Inc.', 'Communication Services', 'Entertainment'),
('V', 'Visa Inc.', 'Information Technology', 'IT Services'),
('JNJ', 'Johnson & Johnson', 'Health Care', 'Pharmaceuticals')
ON CONFLICT (symbol) DO NOTHING;

-- Insert market indices
INSERT INTO public.market_indices (symbol, name, current_value, daily_change, daily_change_percent) VALUES
('^GSPC', 'S&P 500', 4850.25, 45.30, 0.94),
('^IXIC', 'NASDAQ Composite', 15250.75, 125.50, 0.83),
('^DJI', 'Dow Jones Industrial Average', 38250.40, 180.20, 0.47)
ON CONFLICT (symbol) DO NOTHING;

-- Insert system configuration
INSERT INTO public.system_config (key, value, description) VALUES
('api_rate_limits', '{"default": 100, "premium": 1000, "window_minutes": 60}', 'API rate limiting configuration'),
('premium_features', '{"ai_messages_limit": 5, "image_analysis_limit": 1, "price_alerts_limit": 5}', 'Premium feature limits'),
('data_refresh_intervals', '{"stock_prices": 60, "sentiment": 3600, "news": 1800}', 'Data refresh intervals in seconds'),
('market_hours', '{"open": "09:30", "close": "16:00", "timezone": "America/New_York"}', 'Market trading hours')
ON CONFLICT (key) DO NOTHING;

-- ============================================================================
-- CRON JOBS (Requires pg_cron extension)
-- ============================================================================

-- Reset daily usage counters at midnight
SELECT cron.schedule('reset-daily-usage', '0 0 * * *', 'SELECT reset_daily_usage();');

-- Clean up old data (optional)
SELECT cron.schedule('cleanup-old-data', '0 2 * * 0', $$
    DELETE FROM public.stock_history WHERE created_at < NOW() - INTERVAL '1 year' AND period IN ('1m', '5m');
    DELETE FROM public.usage_tracking WHERE usage_date < CURRENT_DATE - INTERVAL '90 days';
    DELETE FROM public.api_rate_limits WHERE created_at < NOW() - INTERVAL '7 days';
$$);

-- ============================================================================
-- GRANTS AND PERMISSIONS
-- ============================================================================

-- Grant necessary permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Grant read-only access to anonymous users for public data
GRANT SELECT ON public.stocks TO anon;
GRANT SELECT ON public.stock_prices TO anon;
GRANT SELECT ON public.stock_history TO anon;
GRANT SELECT ON public.market_indices TO anon;
GRANT SELECT ON public.sentiment_analysis TO anon;
GRANT SELECT ON public.news_articles TO anon;
GRANT SELECT ON public.analyst_ratings TO anon;
GRANT SELECT ON public.market_events TO anon;

-- Enable realtime for specific tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.stock_prices;
ALTER PUBLICATION supabase_realtime ADD TABLE public.sentiment_analysis;
ALTER PUBLICATION supabase_realtime ADD TABLE public.news_articles;
ALTER PUBLICATION supabase_realtime ADD TABLE public.watchlists;
ALTER PUBLICATION supabase_realtime ADD TABLE public.price_alerts; 
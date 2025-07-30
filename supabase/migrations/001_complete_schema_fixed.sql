-- ChartSense Complete Database Schema (FIXED VERSION)
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
    subscription_status TEXT DEFAULT 'free',
    subscription_expires_at TIMESTAMPTZ,
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
    exchange TEXT DEFAULT 'NASDAQ',
    currency TEXT DEFAULT 'USD',
    is_etf BOOLEAN DEFAULT FALSE,
    is_index BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    updated_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- Real-time stock prices
CREATE TABLE public.stock_prices (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    stock_id UUID REFERENCES public.stocks(id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    current_price DECIMAL(12,4) NOT NULL,
    daily_change DECIMAL(12,4) NOT NULL,
    daily_change_percent DECIMAL(8,4) NOT NULL,
    open_price DECIMAL(12,4),
    high_price DECIMAL(12,4),
    low_price DECIMAL(12,4),
    previous_close DECIMAL(12,4),
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
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    UNIQUE(symbol, date_time, period)
);

-- Market indices (S&P 500, NASDAQ, etc.)
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

-- ============================================================================
-- SENTIMENT & ANALYSIS
-- ============================================================================

-- Sentiment analysis results
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

-- News articles
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

-- Analyst ratings and recommendations
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

-- Market events (earnings, product launches, etc.)
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

-- ============================================================================
-- USER FEATURES
-- ============================================================================

-- User watchlists
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

-- Price alerts
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

-- Search history
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

-- ============================================================================
-- AI CHAT
-- ============================================================================

-- AI conversations
CREATE TABLE public.ai_conversations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT,
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    updated_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- AI messages
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

-- ============================================================================
-- PREMIUM & SUBSCRIPTIONS
-- ============================================================================

-- Subscription history
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

-- Usage tracking
CREATE TABLE public.usage_tracking (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    feature_type TEXT NOT NULL,
    usage_count INTEGER DEFAULT 1,
    usage_date DATE DEFAULT CURRENT_DATE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- ============================================================================
-- SYSTEM & CONFIGURATION
-- ============================================================================

-- API rate limiting
CREATE TABLE public.api_rate_limits (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    endpoint TEXT NOT NULL,
    request_count INTEGER DEFAULT 1,
    window_start TIMESTAMPTZ NOT NULL,
    window_end TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- System configuration
CREATE TABLE public.system_config (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    config_key TEXT NOT NULL UNIQUE,
    config_value JSONB NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    updated_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- ============================================================================
-- ADDITIONAL TABLES FOR SWIFT COMPATIBILITY
-- ============================================================================

-- Suggested messages for AI chat
CREATE TABLE public.suggested_messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    text TEXT NOT NULL,
    category TEXT NOT NULL, -- 'analysis', 'education', 'portfolio', 'news'
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    updated_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- Home widgets for user customization
CREATE TABLE public.home_widgets (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    widget_type TEXT NOT NULL, -- 'search', 'news', 'watchlist', 'ai', 'market_overview', 'trending_stocks'
    widget_size TEXT NOT NULL, -- 'small', 'medium', 'large'
    order_index INTEGER NOT NULL,
    is_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    updated_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'UTC'),
    UNIQUE(user_id, widget_type)
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

-- User data indexes
CREATE INDEX idx_watchlists_user ON public.watchlists(user_id);
CREATE INDEX idx_search_history_user ON public.search_history(user_id, last_searched_at DESC);
CREATE INDEX idx_price_alerts_active ON public.price_alerts(is_active, symbol) WHERE is_active = TRUE;

-- AI chat indexes
CREATE INDEX idx_ai_messages_conversation ON public.ai_messages(conversation_id, created_at);

-- Usage tracking indexes
CREATE INDEX idx_usage_tracking_user_date ON public.usage_tracking(user_id, usage_date);
CREATE INDEX idx_usage_tracking_feature ON public.usage_tracking(feature_type, usage_date);

-- Additional indexes for new fields
CREATE INDEX idx_user_profiles_subscription ON public.user_profiles(subscription_status, subscription_expires_at);
CREATE INDEX idx_stocks_exchange ON public.stocks(exchange, is_active);
CREATE INDEX idx_stock_prices_open_high_low ON public.stock_prices(open_price, high_price, low_price);
CREATE INDEX idx_sentiment_breakdown ON public.sentiment_analysis(news_positive, news_negative, analyst_sentiment);
CREATE INDEX idx_news_relevance ON public.news_articles(relevance_score DESC);
CREATE INDEX idx_watchlists_alert ON public.watchlists(alert_price, alert_type);
CREATE INDEX idx_ai_messages_status ON public.ai_messages(status);
CREATE INDEX idx_search_count ON public.search_history(search_count DESC);
CREATE INDEX idx_suggested_messages_category ON public.suggested_messages(category, is_active);
CREATE INDEX idx_market_indices_symbol ON public.market_indices(symbol);
CREATE INDEX idx_home_widgets_user_order ON public.home_widgets(user_id, order_index);

-- ============================================================================
-- TRIGGERS & FUNCTIONS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = (NOW() AT TIME ZONE 'UTC');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
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

-- Function to handle new user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert user profile
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
    
    -- Insert user preferences
    INSERT INTO public.user_preferences (user_id)
    VALUES (NEW.id);
    
    -- Insert default home widgets
    INSERT INTO public.home_widgets (user_id, widget_type, widget_size, order_index) VALUES
        (NEW.id, 'search', 'large', 1),
        (NEW.id, 'watchlist', 'medium', 2),
        (NEW.id, 'news', 'medium', 3),
        (NEW.id, 'ai', 'medium', 4),
        (NEW.id, 'market_overview', 'small', 5),
        (NEW.id, 'trending_stocks', 'small', 6);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user creation
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
    INSERT INTO public.usage_tracking (user_id, feature_type, metadata)
    VALUES (p_user_id, p_feature_type, p_metadata)
    ON CONFLICT (user_id, feature_type, usage_date)
    DO UPDATE SET 
        usage_count = public.usage_tracking.usage_count + 1,
        metadata = public.usage_tracking.metadata || p_metadata;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.watchlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.search_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.price_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usage_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_rate_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.home_widgets ENABLE ROW LEVEL SECURITY;

-- Public read access for market data
ALTER TABLE public.stocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.market_indices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sentiment_analysis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.news_articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analyst_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.market_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suggested_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_config ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can view own profile
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

-- Users can update own profile
CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

-- Users can view own preferences
CREATE POLICY "Users can view own preferences" ON public.user_preferences
    FOR ALL USING (auth.uid() = user_id);

-- Public read access to stocks
CREATE POLICY "Public read access to stocks" ON public.stocks
    FOR SELECT USING (true);

-- Public read access to stock prices
CREATE POLICY "Public read access to stock prices" ON public.stock_prices
    FOR SELECT USING (true);

-- Public read access to stock history
CREATE POLICY "Public read access to stock history" ON public.stock_history
    FOR SELECT USING (true);

-- Public read access to market indices
CREATE POLICY "Public read access to market indices" ON public.market_indices
    FOR SELECT USING (true);

-- Public read access to sentiment analysis
CREATE POLICY "Public read access to sentiment analysis" ON public.sentiment_analysis
    FOR SELECT USING (true);

-- Public read access to news articles
CREATE POLICY "Public read access to news articles" ON public.news_articles
    FOR SELECT USING (true);

-- Public read access to analyst ratings
CREATE POLICY "Public read access to analyst ratings" ON public.analyst_ratings
    FOR SELECT USING (true);

-- Public read access to market events
CREATE POLICY "Public read access to market events" ON public.market_events
    FOR SELECT USING (true);

-- Public read access to suggested messages
CREATE POLICY "Public read access to suggested messages" ON public.suggested_messages
    FOR SELECT USING (true);

-- Public read access to system config
CREATE POLICY "Public read access to system config" ON public.system_config
    FOR SELECT USING (true);

-- Users can manage own watchlists
CREATE POLICY "Users can manage own watchlists" ON public.watchlists
    FOR ALL USING (auth.uid() = user_id);

-- Users can manage own search history
CREATE POLICY "Users can manage own search history" ON public.search_history
    FOR ALL USING (auth.uid() = user_id);

-- Users can manage own price alerts
CREATE POLICY "Users can manage own price alerts" ON public.price_alerts
    FOR ALL USING (auth.uid() = user_id);

-- Users can manage own AI conversations
CREATE POLICY "Users can manage own AI conversations" ON public.ai_conversations
    FOR ALL USING (auth.uid() = user_id);

-- Users can manage own AI messages
CREATE POLICY "Users can manage own AI messages" ON public.ai_messages
    FOR ALL USING (auth.uid() = user_id);

-- Users can view own subscription history
CREATE POLICY "Users can view own subscription history" ON public.subscription_history
    FOR SELECT USING (auth.uid() = user_id);

-- Users can view own usage tracking
CREATE POLICY "Users can view own usage tracking" ON public.usage_tracking
    FOR SELECT USING (auth.uid() = user_id);

-- Users can manage own API rate limits
CREATE POLICY "Users can manage own API rate limits" ON public.api_rate_limits
    FOR ALL USING (auth.uid() = user_id);

-- Users can manage own home widgets
CREATE POLICY "Users can manage own home widgets" ON public.home_widgets
    FOR ALL USING (auth.uid() = user_id);

-- ============================================================================
-- REAL-TIME REPLICATION
-- ============================================================================

-- Enable real-time for key tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.stock_prices;
ALTER PUBLICATION supabase_realtime ADD TABLE public.sentiment_analysis;
ALTER PUBLICATION supabase_realtime ADD TABLE public.news_articles;
ALTER PUBLICATION supabase_realtime ADD TABLE public.watchlists;
ALTER PUBLICATION supabase_realtime ADD TABLE public.price_alerts;

-- ============================================================================
-- INITIAL DATA
-- ============================================================================

-- Insert popular stocks
INSERT INTO public.stocks (symbol, company_name, sector, industry) VALUES
('AAPL', 'Apple Inc.', 'Technology', 'Consumer Electronics'),
('MSFT', 'Microsoft Corporation', 'Technology', 'Software'),
('GOOGL', 'Alphabet Inc.', 'Technology', 'Internet Services'),
('AMZN', 'Amazon.com Inc.', 'Consumer Cyclical', 'Internet Retail'),
('TSLA', 'Tesla Inc.', 'Consumer Cyclical', 'Auto Manufacturers'),
('NVDA', 'NVIDIA Corporation', 'Technology', 'Semiconductors'),
('META', 'Meta Platforms Inc.', 'Technology', 'Internet Services'),
('NFLX', 'Netflix Inc.', 'Communication Services', 'Entertainment'),
('JPM', 'JPMorgan Chase & Co.', 'Financial Services', 'Banks'),
('JNJ', 'Johnson & Johnson', 'Healthcare', 'Drug Manufacturers')
ON CONFLICT (symbol) DO NOTHING;

-- Insert market indices
INSERT INTO public.market_indices (name, symbol, price, change, change_percent) VALUES
('S&P 500', '^GSPC', 4500.00, 25.50, 0.57),
('Dow Jones Industrial Average', '^DJI', 35000.00, 150.00, 0.43),
('NASDAQ Composite', '^IXIC', 14000.00, 75.00, 0.54),
('Russell 2000', '^RUT', 1800.00, 12.00, 0.67)
ON CONFLICT (symbol) DO UPDATE SET
    price = EXCLUDED.price,
    change = EXCLUDED.change,
    change_percent = EXCLUDED.change_percent,
    last_updated = (NOW() AT TIME ZONE 'UTC');

-- Insert suggested messages
INSERT INTO public.suggested_messages (text, category) VALUES
('Can you analyze Apple''s stock performance and provide insights?', 'analysis'),
('What are the current market trends and which sectors are performing well?', 'analysis'),
('I''m looking to diversify my portfolio. What sectors should I consider?', 'portfolio'),
('Explain the difference between technical and fundamental analysis', 'education'),
('What''s the latest news affecting tech stocks?', 'news'),
('How do I read a candlestick chart?', 'education'),
('What are the best stocks for beginners?', 'portfolio'),
('Explain the P/E ratio and why it matters', 'education')
ON CONFLICT DO NOTHING;

-- Insert system configuration
INSERT INTO public.system_config (config_key, config_value, description) VALUES
('finnhub_api_key', '"your_finnhub_api_key_here"', 'Finnhub API key for stock data'),
('openai_api_key', '"your_openai_api_key_here"', 'OpenAI API key for AI chat'),
('default_ai_message_limit', '5', 'Default daily AI message limit for free users'),
('default_image_analysis_limit', '1', 'Default daily image analysis limit for free users'),
('stock_data_refresh_interval', '300', 'Stock data refresh interval in seconds'),
('sentiment_analysis_interval', '14400', 'Sentiment analysis refresh interval in seconds')
ON CONFLICT (config_key) DO NOTHING;

-- ============================================================================
-- CRON JOBS FOR AUTOMATION
-- ============================================================================

-- Reset daily usage counters (runs daily at midnight)
SELECT cron.schedule('reset-daily-usage', '0 0 * * *', $$
    SELECT reset_daily_usage();
$$);

-- Fetch popular stocks data (runs every 5 minutes during market hours)
SELECT cron.schedule('fetch-popular-stocks', '* 9-16 * * 1-5', $$
    SELECT net.http_post(
        url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/fetch-stock-data',
        headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY", "Content-Type": "application/json"}',
        body := '{"symbols": ["AAPL", "TSLA", "GOOGL", "MSFT", "NVDA", "META", "AMZN", "NFLX"]}'
    );
$$);

-- Generate sentiment analysis (runs every 4 hours)
SELECT cron.schedule('generate-sentiment', '0 */4 * * *', $$
    SELECT net.http_post(
        url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/fetch-sentiment-data',
        headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY", "Content-Type": "application/json"}',
        body := '{"symbols": ["AAPL", "TSLA", "GOOGL", "MSFT", "NVDA"]}'
    );
$$);

-- ============================================================================
-- COMPLETION MESSAGE
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE 'ChartSense database schema created successfully!';
    RAISE NOTICE 'All tables, indexes, triggers, and policies are in place.';
    RAISE NOTICE 'Remember to update the cron job URLs with your actual project reference and service role key.';
END $$; 
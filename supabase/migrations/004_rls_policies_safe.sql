-- Safe Row Level Security Policies for ChartSense
-- This migration safely adds RLS policies by dropping existing ones first

-- ============================================================================
-- DROP EXISTING POLICIES (if they exist)
-- ============================================================================

-- User Profiles
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;

-- User Preferences
DROP POLICY IF EXISTS "Users can view own preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Users can update own preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Users can insert own preferences" ON public.user_preferences;

-- Watchlists
DROP POLICY IF EXISTS "Users can view own watchlist" ON public.watchlists;
DROP POLICY IF EXISTS "Users can insert own watchlist" ON public.watchlists;
DROP POLICY IF EXISTS "Users can update own watchlist" ON public.watchlists;
DROP POLICY IF EXISTS "Users can delete own watchlist" ON public.watchlists;

-- Search History
DROP POLICY IF EXISTS "Users can view own search history" ON public.search_history;
DROP POLICY IF EXISTS "Users can insert own search history" ON public.search_history;
DROP POLICY IF EXISTS "Users can update own search history" ON public.search_history;
DROP POLICY IF EXISTS "Users can delete own search history" ON public.search_history;

-- Price Alerts
DROP POLICY IF EXISTS "Users can view own price alerts" ON public.price_alerts;
DROP POLICY IF EXISTS "Users can insert own price alerts" ON public.price_alerts;
DROP POLICY IF EXISTS "Users can update own price alerts" ON public.price_alerts;
DROP POLICY IF EXISTS "Users can delete own price alerts" ON public.price_alerts;

-- AI Conversations
DROP POLICY IF EXISTS "Users can view own conversations" ON public.ai_conversations;
DROP POLICY IF EXISTS "Users can insert own conversations" ON public.ai_conversations;
DROP POLICY IF EXISTS "Users can update own conversations" ON public.ai_conversations;
DROP POLICY IF EXISTS "Users can delete own conversations" ON public.ai_conversations;

-- AI Messages
DROP POLICY IF EXISTS "Users can view own messages" ON public.ai_messages;
DROP POLICY IF EXISTS "Users can insert own messages" ON public.ai_messages;
DROP POLICY IF EXISTS "Users can update own messages" ON public.ai_messages;
DROP POLICY IF EXISTS "Users can delete own messages" ON public.ai_messages;

-- Usage Tracking
DROP POLICY IF EXISTS "Users can view own usage" ON public.usage_tracking;
DROP POLICY IF EXISTS "Users can insert own usage" ON public.usage_tracking;
DROP POLICY IF EXISTS "Users can update own usage" ON public.usage_tracking;
DROP POLICY IF EXISTS "Users can delete own usage" ON public.usage_tracking;

-- Home Widgets
DROP POLICY IF EXISTS "Users can view own widgets" ON public.home_widgets;
DROP POLICY IF EXISTS "Users can insert own widgets" ON public.home_widgets;
DROP POLICY IF EXISTS "Users can update own widgets" ON public.home_widgets;
DROP POLICY IF EXISTS "Users can delete own widgets" ON public.home_widgets;

-- ============================================================================
-- ENABLE RLS ON TABLES
-- ============================================================================

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.watchlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.search_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.price_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usage_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.home_widgets ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- CREATE NEW POLICIES
-- ============================================================================

-- User Profiles
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- User Preferences
CREATE POLICY "Users can view own preferences" ON public.user_preferences
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences" ON public.user_preferences
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own preferences" ON public.user_preferences
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Watchlists
CREATE POLICY "Users can view own watchlist" ON public.watchlists
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own watchlist" ON public.watchlists
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own watchlist" ON public.watchlists
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own watchlist" ON public.watchlists
    FOR DELETE USING (auth.uid() = user_id);

-- Search History
CREATE POLICY "Users can view own search history" ON public.search_history
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own search history" ON public.search_history
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own search history" ON public.search_history
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own search history" ON public.search_history
    FOR DELETE USING (auth.uid() = user_id);

-- Price Alerts
CREATE POLICY "Users can view own price alerts" ON public.price_alerts
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own price alerts" ON public.price_alerts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own price alerts" ON public.price_alerts
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own price alerts" ON public.price_alerts
    FOR DELETE USING (auth.uid() = user_id);

-- AI Conversations
CREATE POLICY "Users can view own conversations" ON public.ai_conversations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own conversations" ON public.ai_conversations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own conversations" ON public.ai_conversations
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own conversations" ON public.ai_conversations
    FOR DELETE USING (auth.uid() = user_id);

-- AI Messages
CREATE POLICY "Users can view own messages" ON public.ai_messages
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own messages" ON public.ai_messages
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own messages" ON public.ai_messages
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own messages" ON public.ai_messages
    FOR DELETE USING (auth.uid() = user_id);

-- Usage Tracking
CREATE POLICY "Users can view own usage" ON public.usage_tracking
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own usage" ON public.usage_tracking
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own usage" ON public.usage_tracking
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own usage" ON public.usage_tracking
    FOR DELETE USING (auth.uid() = user_id);

-- Home Widgets
CREATE POLICY "Users can view own widgets" ON public.home_widgets
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own widgets" ON public.home_widgets
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own widgets" ON public.home_widgets
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own widgets" ON public.home_widgets
    FOR DELETE USING (auth.uid() = user_id); 
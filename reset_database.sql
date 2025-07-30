-- ChartSense Database Reset Script
-- Run this in your Supabase SQL Editor to completely clean your database

-- Disable triggers temporarily
SET session_replication_role = replica;

-- Drop all existing tables (in reverse dependency order)
DROP TABLE IF EXISTS public.usage_tracking CASCADE;
DROP TABLE IF EXISTS public.subscription_history CASCADE;
DROP TABLE IF EXISTS public.ai_messages CASCADE;
DROP TABLE IF EXISTS public.ai_conversations CASCADE;
DROP TABLE IF EXISTS public.search_history CASCADE;
DROP TABLE IF EXISTS public.price_alerts CASCADE;
DROP TABLE IF EXISTS public.watchlists CASCADE;
DROP TABLE IF EXISTS public.market_events CASCADE;
DROP TABLE IF EXISTS public.analyst_ratings CASCADE;
DROP TABLE IF EXISTS public.news_articles CASCADE;
DROP TABLE IF EXISTS public.sentiment_analysis CASCADE;
DROP TABLE IF EXISTS public.market_indices CASCADE;
DROP TABLE IF EXISTS public.stock_history CASCADE;
DROP TABLE IF EXISTS public.stock_prices CASCADE;
DROP TABLE IF EXISTS public.stocks CASCADE;
DROP TABLE IF EXISTS public.user_preferences CASCADE;
DROP TABLE IF EXISTS public.user_profiles CASCADE;
DROP TABLE IF EXISTS public.api_rate_limits CASCADE;
DROP TABLE IF EXISTS public.system_config CASCADE;

-- Drop all functions
DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS public.reset_daily_usage() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.increment_usage_tracking(UUID, TEXT, JSONB) CASCADE;

-- Re-enable triggers
SET session_replication_role = DEFAULT;

-- Clean up any remaining objects
DO $$
DECLARE
    r RECORD;
BEGIN
    -- Drop any remaining tables
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') 
    LOOP
        EXECUTE 'DROP TABLE IF EXISTS public.' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
    
    -- Drop any remaining sequences
    FOR r IN (SELECT sequencename FROM pg_sequences WHERE schemaname = 'public') 
    LOOP
        EXECUTE 'DROP SEQUENCE IF EXISTS public.' || quote_ident(r.sequencename) || ' CASCADE';
    END LOOP;
END $$;

-- Verify cleanup
SELECT 
    'Tables' as object_type,
    count(*) as count
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE'
UNION ALL
SELECT 
    'Functions' as object_type,
    count(*) as count
FROM information_schema.routines 
WHERE routine_schema = 'public';

-- Print completion message
DO $$
BEGIN
    RAISE NOTICE 'Database reset complete! All tables and data have been removed.';
    RAISE NOTICE 'You can now run the complete schema migration.';
END $$; 
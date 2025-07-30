-- Fix RLS trigger issue for user profile creation
-- The problem is that the trigger function needs to run with proper authentication context

-- Drop the existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- Create a new function that handles user creation with proper RLS context
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- This function will be called by the trigger, but the actual profile creation
    -- should happen in the application layer with proper authentication context
    -- For now, we'll just return the new user record
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Add a policy to allow service role to manage user profiles (for edge functions)
CREATE POLICY "Service role can manage user profiles" ON public.user_profiles
    FOR ALL USING (auth.role() = 'service_role');

-- Add a policy to allow service role to manage user preferences
CREATE POLICY "Service role can manage user preferences" ON public.user_preferences
    FOR ALL USING (auth.role() = 'service_role');

-- Add a policy to allow service role to manage home widgets
CREATE POLICY "Service role can manage home widgets" ON public.home_widgets
    FOR ALL USING (auth.role() = 'service_role');

-- Add a policy to allow service role to manage watchlists
CREATE POLICY "Service role can manage watchlists" ON public.watchlists
    FOR ALL USING (auth.role() = 'service_role');

-- Add a policy to allow service role to manage search history
CREATE POLICY "Service role can manage search history" ON public.search_history
    FOR ALL USING (auth.role() = 'service_role');

-- Add a policy to allow service role to manage price alerts
CREATE POLICY "Service role can manage price alerts" ON public.price_alerts
    FOR ALL USING (auth.role() = 'service_role');

-- Add a policy to allow service role to manage AI conversations
CREATE POLICY "Service role can manage AI conversations" ON public.ai_conversations
    FOR ALL USING (auth.role() = 'service_role');

-- Add a policy to allow service role to manage AI messages
CREATE POLICY "Service role can manage AI messages" ON public.ai_messages
    FOR ALL USING (auth.role() = 'service_role');

-- Add a policy to allow service role to manage usage tracking
CREATE POLICY "Service role can manage usage tracking" ON public.usage_tracking
    FOR ALL USING (auth.role() = 'service_role');

-- Also add a policy to allow authenticated users to create their own profiles
-- This is needed for the iOS app to create user profiles
CREATE POLICY "Authenticated users can create own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id AND auth.role() = 'authenticated');

-- Allow authenticated users to create their own preferences
CREATE POLICY "Authenticated users can create own preferences" ON public.user_preferences
    FOR INSERT WITH CHECK (auth.uid() = user_id AND auth.role() = 'authenticated');

-- Allow authenticated users to create their own home widgets
CREATE POLICY "Authenticated users can create own widgets" ON public.home_widgets
    FOR INSERT WITH CHECK (auth.uid() = user_id AND auth.role() = 'authenticated');

-- Allow authenticated users to manage their own watchlists
CREATE POLICY "Authenticated users can manage own watchlists" ON public.watchlists
    FOR ALL USING (auth.uid() = user_id AND auth.role() = 'authenticated');

-- Allow authenticated users to manage their own search history
CREATE POLICY "Authenticated users can manage own search history" ON public.search_history
    FOR ALL USING (auth.uid() = user_id AND auth.role() = 'authenticated');

-- Allow authenticated users to manage their own price alerts
CREATE POLICY "Authenticated users can manage own price alerts" ON public.price_alerts
    FOR ALL USING (auth.uid() = user_id AND auth.role() = 'authenticated');

-- Allow authenticated users to manage their own AI conversations
CREATE POLICY "Authenticated users can manage own AI conversations" ON public.ai_conversations
    FOR ALL USING (auth.uid() = user_id AND auth.role() = 'authenticated');

-- Allow authenticated users to manage their own AI messages
CREATE POLICY "Authenticated users can manage own AI messages" ON public.ai_messages
    FOR ALL USING (auth.uid() = user_id AND auth.role() = 'authenticated');

-- Allow authenticated users to manage their own usage tracking
CREATE POLICY "Authenticated users can manage own usage tracking" ON public.usage_tracking
    FOR ALL USING (auth.uid() = user_id AND auth.role() = 'authenticated'); 
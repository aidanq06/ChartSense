# Watchlist Foreign Key Constraint Fix

## Problem
You're getting this error when trying to add stocks to your watchlist:
```
❌ Add to watchlist error response: {"code":"23503","details":"Key is not present in table \"user_profiles\".","hint":null,"message":"insert or update on table \"watchlists\" violates foreign key constraint \"watchlists_user_id_fkey\""}
```

## Root Cause
The issue is that when users sign up or sign in, the `handle_new_user()` trigger function should automatically create a record in the `user_profiles` table, but it's not working properly. This causes the foreign key constraint to fail when trying to add items to the watchlist.

## Comprehensive Fix

### Step 1: Apply the Database Migration

1. **If you have Supabase CLI installed:**
   ```bash
   cd /Users/aidan/Documents/ChartSense
   supabase db reset
   supabase db push
   ```

2. **If you don't have Supabase CLI, apply the migration manually:**
   - Go to your Supabase dashboard
   - Navigate to the SQL Editor
   - Run the contents of `supabase/migrations/005_fix_user_profile_creation.sql`

### Step 2: Verify the Fix

After applying the migration, you should see output like:
```
✅ handle_new_user function exists
✅ on_auth_user_created trigger exists
✅ Created missing profile for user [user-id]
✅ All users have profiles!
```

### Step 3: Test the Fix

1. **Sign out and sign back in** to your app
2. **Try adding a stock to your watchlist**
3. **Check the console logs** - you should see:
   ```
   ✅ User profile exists for [user-id]
   ✅ Added [SYMBOL] to watchlist for user [user-id]
   ```

## What the Fix Does

### Database Level (Migration 005)
1. **Recreates the trigger function** with better error handling
2. **Creates missing user profiles** for existing users
3. **Adds fallback mechanisms** to ensure profiles exist
4. **Updates RLS policies** to handle missing profiles gracefully

### App Level (SupabaseService.swift)
1. **Checks for user profile existence** before adding to watchlist
2. **Automatically creates missing profiles** if needed
3. **Retries the operation** after creating the profile
4. **Creates user preferences and home widgets** automatically

## Manual Verification

If you want to manually check your database:

```sql
-- Check if all users have profiles
SELECT 
    COUNT(*) as auth_users,
    (SELECT COUNT(*) FROM public.user_profiles) as profiles,
    COUNT(*) - (SELECT COUNT(*) FROM public.user_profiles) as missing
FROM auth.users;

-- Check specific user
SELECT 
    au.id,
    au.email,
    CASE WHEN up.id IS NOT NULL THEN '✅' ELSE '❌' END as has_profile
FROM auth.users au
LEFT JOIN public.user_profiles up ON au.id = up.id
WHERE au.email = 'your-email@example.com';
```

## Troubleshooting

### If the migration fails:
1. **Check your Supabase permissions** - you need admin access
2. **Verify the trigger exists:**
   ```sql
   SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';
   ```

### If users still can't add to watchlist:
1. **Check the console logs** for detailed error messages
2. **Verify the user is authenticated** properly
3. **Check if the user profile was created:**
   ```sql
   SELECT * FROM public.user_profiles WHERE id = 'your-user-id';
   ```

### If you need to manually create a profile:
```sql
INSERT INTO public.user_profiles (id, email, name, auth_provider)
SELECT 
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'name', au.email),
    'email'
FROM auth.users au
WHERE au.id = 'your-user-id'
ON CONFLICT (id) DO NOTHING;
```

## Prevention

The fix includes:
- **Automatic profile creation** for new users
- **Fallback mechanisms** for existing users
- **Error handling** that retries operations
- **Comprehensive logging** for debugging

This should completely resolve the watchlist foreign key constraint error and prevent it from happening in the future. 
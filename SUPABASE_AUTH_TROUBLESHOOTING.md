# Supabase Authentication Troubleshooting Guide

## Current Issue: "No API key found in request"

The error suggests that the Supabase Swift SDK is not properly sending the API key to the auth endpoint. Here's how to fix it:

## Step 1: Check Supabase Project Settings

### 1.1 Authentication Settings
1. Go to your Supabase dashboard: https://supabase.com/dashboard
2. Select your project: `tkdkvxlzbfhswgviuasa`
3. Navigate to **Authentication** → **Configuration**

### 1.2 Disable Email Confirmations (for testing)
1. In Authentication Configuration, find **"General user signup"**
2. Look for **"Enable email confirmations"** and **Turn this OFF** for now
3. This will allow users to sign up without email verification

### 1.3 Configure Site URL
1. In Authentication Configuration, find **"General user signup"**
2. Look for **"Site URL"** and set it to: `https://tkdkvxlzbfhswgviuasa.supabase.co`
3. Or for development: `http://localhost:3000`

### 1.4 Check Email Restrictions
1. In Authentication Configuration, look for **"General user signup"**
2. Check for any **"Email restrictions"** or **"Allowed email domains"**
3. Make sure there are no restrictions that would block test emails
4. If there are restrictions, temporarily remove them for testing

## Step 2: Test the Configuration

After making these changes:

1. **Build and run your app**
2. **Try to sign up with a real email** (not test@example.com)
3. **Check the console logs** for detailed error messages

## Step 3: Alternative Solutions

If the issue persists, try these alternatives:

### Option A: Use Manual HTTP Requests
The app already includes a fallback `manualSignUp` method that uses direct HTTP requests instead of the SDK.

### Option B: Check API Key Format
Make sure your API key doesn't have any extra spaces or characters. The current key should be:
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRrZGt2eGx6YmZoc3dndml1YXNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyOTM3NTYsImV4cCI6MjA2ODg2OTc1Nn0.3EvodICwXuH0joVxB0cEAVblOPCx_4Qf-Sh2lT50FuY
```

### Option C: Recreate the Project
If all else fails, you can:
1. Create a new Supabase project
2. Copy the new URL and anon key
3. Update your `Config.plist`
4. Run the migration again

## Step 4: Verify the Fix

Once you've made the changes:

1. **Sign up should work** without email confirmation
2. **Users should appear** in Authentication → Users in your Supabase dashboard
3. **No more "No API key found" errors**

## Common Issues and Solutions

### Issue: "Email address is invalid"
- **Solution**: Use a real email format (e.g., `user@example.com`)
- **Solution**: Check email domain restrictions in Supabase settings

### Issue: "Email confirmation required"
- **Solution**: Disable email confirmations in Authentication Settings

### Issue: "Site URL not configured"
- **Solution**: Set the Site URL in Authentication Settings

### Issue: "API key not found"
- **Solution**: Check that the API key is correctly formatted without extra spaces
- **Solution**: Verify the project is active and not paused

## Next Steps

After fixing authentication:

1. **Enable email confirmations** for production
2. **Set up proper email templates**
3. **Configure social authentication** (Google, Apple)
4. **Set up Row Level Security (RLS)** policies
5. **Deploy Edge Functions** for stock data

## Debug Information

The app includes extensive debug logging. Check the console for:
- `🔍 Debug Configuration:` - Shows URL and key info
- `📊 Response status:` - Shows HTTP status codes
- `📊 Response data:` - Shows server responses
- `❌ Error details:` - Shows detailed error information 
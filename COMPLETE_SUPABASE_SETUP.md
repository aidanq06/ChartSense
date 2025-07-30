# 🚀 Complete ChartSense Supabase Backend Setup Guide

This guide will help you set up a complete, production-ready Supabase backend for your ChartSense iOS app. The backend includes authentication, real-time stock data, sentiment analysis, AI chat, and premium features.

## 📋 **Prerequisites**

- [ ] Node.js 18+ installed
- [ ] Supabase CLI installed (`npm install -g supabase`)
- [ ] Git installed
- [ ] Finnhub API key (free at [finnhub.io](https://finnhub.io))
- [ ] OpenAI API key (optional, for real AI responses)
- [ ] Apple Developer Account (for Apple Sign-In)
- [ ] Google Cloud Console Account (for Google Sign-In)

## 🏗️ **Step 1: Create New Supabase Project**

### Option A: Using Supabase Dashboard (Recommended)

1. Go to [supabase.com](https://supabase.com) and sign in
2. Click "New Project"
3. Choose your organization
4. Fill in project details:
   - **Name**: `chartsense-backend`
   - **Database Password**: Generate a strong password (save it!)
   - **Region**: Choose closest to your users
   - **Pricing Plan**: Start with Free tier
5. Click "Create new project"
6. Wait 2-3 minutes for project creation

### Option B: Using Supabase CLI

```bash
# Login to Supabase
supabase login

# Create new project
supabase projects create chartsense-backend

# Link to your local development
supabase init
supabase link --project-ref YOUR_PROJECT_REF
```

## 🗄️ **Step 2: Set Up Database Schema**

### Apply the Complete Schema

1. In your Supabase Dashboard, go to **SQL Editor**
2. Copy the entire contents of `supabase/migrations/001_complete_schema.sql`
3. Paste it into a new query and click **Run**
4. Verify all tables were created successfully

### Alternative: Using CLI

```bash
# Apply migrations
supabase db reset

# Or push specific migration
supabase db push
```

### Verify Database Setup

In the Supabase Dashboard, go to **Table Editor** and verify these tables exist:
- `user_profiles`
- `stocks`
- `stock_prices`
- `sentiment_analysis`
- `news_articles`
- `watchlists`
- `ai_conversations`
- `ai_messages`
- And 10 more tables...

## 🔐 **Step 3: Configure Authentication**

### Enable Authentication Providers

1. Go to **Authentication** → **Providers** in your Supabase Dashboard

### Email Authentication
- Email is enabled by default
- **Confirm email**: Disable for development, enable for production
- **Secure email change**: Enable for production

### Apple Sign-In Setup

1. **In Apple Developer Console:**
   - Create a new App ID or use existing
   - Enable "Sign In with Apple" capability
   - Create a Service ID for web authentication
   - Generate a private key for Apple Sign-In
   - Note down your Team ID, Key ID, and Client ID

2. **In Supabase Dashboard:**
   - Go to Authentication → Providers
   - Enable Apple provider
   - Fill in:
     - **Client ID**: Your Service ID
     - **Secret**: Generate JWT using your private key (see Apple docs)
     - **Redirect URL**: `https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback`

### Google Sign-In Setup

1. **In Google Cloud Console:**
   - Create new project or use existing
   - Enable Google+ API
   - Create OAuth 2.0 credentials
   - Add authorized redirect URIs

2. **In Supabase Dashboard:**
   - Enable Google provider
   - Fill in Client ID and Client Secret
   - **Redirect URL**: `https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback`

## ⚡ **Step 4: Deploy Edge Functions**

### Set Up Environment Variables

1. In Supabase Dashboard, go to **Settings** → **Environment Variables**
2. Add these variables:

```bash
FINNHUB_API_KEY=your_finnhub_api_key_here
OPENAI_API_KEY=your_openai_api_key_here  # Optional
APPLE_CLIENT_ID=your_apple_client_id
APPLE_CLIENT_SECRET=your_apple_jwt_secret
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
```

### Deploy Functions

```bash
# Deploy all functions
supabase functions deploy fetch-stock-data
supabase functions deploy fetch-sentiment-data
supabase functions deploy ai-chat

# Or deploy all at once
supabase functions deploy
```

### Test Functions

```bash
# Test stock data function
curl -X POST 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/fetch-stock-data' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"symbol": "AAPL"}'

# Test sentiment function
curl -X POST 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/fetch-sentiment-data' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"symbol": "AAPL"}'
```

## 🔄 **Step 5: Set Up Automated Data Fetching**

### Enable pg_cron Extension

1. Go to **Database** → **Extensions**
2. Search for "pg_cron" and enable it
3. The extension allows scheduled database tasks

### Set Up Cron Jobs

Run this SQL in your SQL Editor:

```sql
-- Fetch popular stocks every minute during market hours
SELECT cron.schedule('fetch-popular-stocks', '* 9-16 * * 1-5', $$
  SELECT net.http_post(
    url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/fetch-stock-data',
    headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY", "Content-Type": "application/json"}',
    body := '{"symbols": ["AAPL", "TSLA", "GOOGL", "MSFT", "NVDA", "META", "AMZN", "NFLX"]}'
  );
$$);

-- Generate sentiment analysis every 4 hours
SELECT cron.schedule('generate-sentiment', '0 */4 * * *', $$
  SELECT net.http_post(
    url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/fetch-sentiment-data',
    headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY", "Content-Type": "application/json"}',
    body := '{"symbols": ["AAPL", "TSLA", "GOOGL", "MSFT", "NVDA"]}'
  );
$$);

-- Reset daily usage counters at midnight
SELECT cron.schedule('reset-daily-usage', '0 0 * * *', 'SELECT reset_daily_usage();');
```

**Important**: Replace `YOUR_PROJECT_REF` and `YOUR_SERVICE_ROLE_KEY` with your actual values.

## 📱 **Step 6: Configure iOS App**

### Update Config.plist

Create `ChartSense/Config.plist` (copy from Config.plist.example):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>SUPABASE_URL</key>
    <string>https://YOUR_PROJECT_REF.supabase.co</string>
    <key>SUPABASE_ANON_KEY</key>
    <string>YOUR_ANON_KEY_HERE</string>
    <key>FINNHUB_API_KEY</key>
    <string>YOUR_FINNHUB_KEY_HERE</string>
    <key>OPENAI_API_KEY</key>
    <string>YOUR_OPENAI_KEY_HERE</string>
</dict>
</plist>
```

### Get Your Keys

1. **Supabase URL & Keys**: 
   - Go to Settings → API
   - Copy Project URL and anon/public key

2. **Service Role Key** (for server functions):
   - Copy service_role key (keep this secret!)

## 🔒 **Step 7: Configure Row Level Security**

The schema already includes RLS policies, but verify they're working:

### Test RLS Policies

1. Create a test user in Authentication → Users
2. Try accessing data with different user tokens
3. Verify users can only see their own data

### Key Security Features Included:

- ✅ Users can only access their own watchlists
- ✅ Users can only see their own AI conversations
- ✅ Public read access to stock data
- ✅ Premium feature usage tracking
- ✅ Rate limiting per user

## 📊 **Step 8: Set Up Real-time Subscriptions**

### Enable Realtime

1. Go to **Database** → **Replication**
2. Enable replication for these tables:
   - `stock_prices`
   - `sentiment_analysis`
   - `news_articles`
   - `watchlists`
   - `price_alerts`

### Test Real-time

Your iOS app can now subscribe to real-time updates:

```swift
// Example: Subscribe to stock price updates
supabase
  .from("stock_prices")
  .on(.update) { result in
    // Handle real-time price updates
  }
  .subscribe()
```

## 🧪 **Step 9: Testing Your Backend**

### Manual Testing

1. **Authentication**: Try signing up/in with email and social providers
2. **Stock Data**: Verify data is being fetched and stored
3. **AI Chat**: Test the AI chat functionality
4. **Real-time**: Check that price updates appear in real-time
5. **Premium Features**: Test usage limits and premium upgrades

### Automated Testing

Create test scripts to verify:

```bash
# Test all endpoints
./test-backend.sh

# Monitor cron jobs
SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 10;
```

## 🚀 **Step 10: Production Deployment**

### Pre-Production Checklist

- [ ] All environment variables set
- [ ] RLS policies tested
- [ ] Cron jobs running
- [ ] Edge functions deployed
- [ ] Authentication providers configured
- [ ] Real-time subscriptions working
- [ ] Rate limiting configured
- [ ] Backup strategy in place

### Production Settings

1. **Database Settings**:
   - Enable Point-in-Time Recovery
   - Set up daily backups
   - Configure connection pooling

2. **Security**:
   - Rotate all API keys
   - Enable email confirmations
   - Set up monitoring and alerts

3. **Performance**:
   - Add database indexes (already included)
   - Monitor query performance
   - Set up CDN for static assets

## 🔧 **Troubleshooting**

### Common Issues

**1. Functions not deploying**
```bash
# Check function logs
supabase functions logs fetch-stock-data

# Redeploy with verbose output
supabase functions deploy fetch-stock-data --debug
```

**2. Authentication not working**
- Check redirect URLs match exactly
- Verify API keys are correct
- Check browser console for errors

**3. Cron jobs not running**
```sql
-- Check cron job status
SELECT * FROM cron.job;
SELECT * FROM cron.job_run_details WHERE job_name = 'fetch-popular-stocks';
```

**4. Real-time not working**
- Verify replication is enabled
- Check network connectivity
- Ensure proper authentication

### Getting Help

- Check Supabase documentation: [supabase.com/docs](https://supabase.com/docs)
- Join Supabase Discord: [discord.supabase.com](https://discord.supabase.com)
- Review function logs in Dashboard → Edge Functions → Logs

## 📈 **Monitoring and Maintenance**

### Key Metrics to Monitor

1. **API Usage**: Track requests per minute
2. **Database Performance**: Monitor query times
3. **Function Execution**: Check success rates
4. **User Growth**: Track new registrations
5. **Premium Conversions**: Monitor upgrade rates

### Regular Maintenance

- **Weekly**: Review error logs and performance
- **Monthly**: Update dependencies and security patches
- **Quarterly**: Review and optimize database queries
- **Yearly**: Audit security settings and access controls

## 🎉 **Congratulations!**

Your ChartSense backend is now fully configured and ready for production! You have:

✅ **Complete Database Schema** - All tables, indexes, and relationships
✅ **Authentication System** - Email, Apple, and Google sign-in
✅ **Real-time Stock Data** - Automated fetching every minute
✅ **AI-Powered Sentiment Analysis** - Updated every 4 hours
✅ **Premium Features** - Usage tracking and limits
✅ **Secure API** - Row Level Security and rate limiting
✅ **Automated Tasks** - Cron jobs for data updates
✅ **Real-time Updates** - Live price and sentiment updates

Your iOS app can now seamlessly integrate with this powerful backend to provide users with real-time financial data, AI-powered insights, and a premium experience.

## 🔗 **Next Steps**

1. **Update your iOS app** to use the new backend endpoints
2. **Test thoroughly** with real users
3. **Monitor performance** and optimize as needed
4. **Add more features** like news aggregation or advanced charts
5. **Scale up** your Supabase plan as you grow

---

**Need Help?** This backend is designed to scale with your app from MVP to millions of users. Each component can be enhanced and extended as your needs grow. 
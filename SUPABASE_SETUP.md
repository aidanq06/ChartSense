# 🚀 Supabase Setup Guide for ChartSense

This guide will help you set up Supabase as your complete backend solution for ChartSense, replacing multiple services with one unified platform.

## 📋 What Supabase Replaces

| Current Service | Supabase Solution | Cost Savings |
|----------------|------------------|--------------|
| **Authentication** | Supabase Auth | $0/month |
| **Database** | Supabase PostgreSQL | $0/month (up to 500MB) |
| **API Proxy** | Supabase Edge Functions | $0/month (up to 500K invocations) |
| **Real-time** | Supabase Realtime | $0/month |
| **File Storage** | Supabase Storage | $0/month (up to 1GB) |
| **Push Notifications** | Supabase + OneSignal | $0/month |
| **Analytics** | Supabase Analytics | $0/month |

**Total Monthly Cost: $0** (for development and small-scale production)

## 🛠️ Step-by-Step Setup

### 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Click "Start your project"
3. Sign in with GitHub
4. Click "New Project"
5. Choose your organization
6. Enter project details:
   - **Name**: `chartsense`
   - **Database Password**: Generate a strong password
   - **Region**: Choose closest to your users
7. Click "Create new project"

### 2. Get Your API Keys

1. In your Supabase dashboard, go to **Settings** → **API**
2. Copy these values:
   - **Project URL** (e.g., `https://your-project.supabase.co`)
   - **Anon public key** (starts with `eyJ...`)

### 3. Update Your iOS App

1. **Install Supabase Swift SDK**:
   ```bash
   # In your Xcode project, add this to Package.swift or use Swift Package Manager
   https://github.com/supabase-community/supabase-swift.git
   ```

2. **Update SupabaseService.swift**:
   ```swift
   // Replace these values in SupabaseService.swift
   private let supabaseURL = "YOUR_PROJECT_URL"
   private let supabaseAnonKey = "YOUR_ANON_KEY"
   ```

### 4. Set Up Database Schema

1. In Supabase dashboard, go to **SQL Editor**
2. Copy and paste the contents of `supabase/migrations/001_initial_schema.sql`
3. Click "Run" to execute the migration

### 5. Deploy Edge Functions

1. **Install Supabase CLI**:
   ```bash
   npm install -g supabase
   ```

2. **Login to Supabase**:
   ```bash
   supabase login
   ```

3. **Link your project**:
   ```bash
   supabase link --project-ref YOUR_PROJECT_REF
   ```

4. **Deploy functions**:
   ```bash
   supabase functions deploy fetch-stock-data
   supabase functions deploy fetch-sentiment-data
   supabase functions deploy fetch-news-data
   ```

### 6. Configure Environment Variables

1. In Supabase dashboard, go to **Settings** → **Edge Functions**
2. Add these environment variables:
   ```
   ALPHA_VANTAGE_API_KEY=your_alpha_vantage_key
   OPENAI_API_KEY=your_openai_key (optional)
   ```

### 7. Set Up Authentication

1. In Supabase dashboard, go to **Authentication** → **Settings**
2. Configure:
   - **Site URL**: `chartsense://` (for your app)
   - **Redirect URLs**: `chartsense://auth/callback`
   - **Enable email confirmations**: Off (for development)

## 🔧 Integration with Your App

### Update Your Services

Your existing services can now use Supabase:

```swift
// In StockService.swift
class StockService: ObservableObject {
    private let supabase = SupabaseService.shared
    
    func searchStock(symbol: String) async {
        do {
            let stock = try await supabase.fetchStockData(symbol: symbol)
            await MainActor.run {
                self.currentStock = stock
            }
        } catch {
            print("Error fetching stock: \(error)")
        }
    }
}
```

### Update WatchlistViewModel

```swift
// In WatchlistViewModel.swift
class WatchlistViewModel: ObservableObject {
    private let supabase = SupabaseService.shared
    
    func loadWatchlist() {
        Task {
            do {
                let watchlist = try await supabase.getWatchlist()
                await MainActor.run {
                    self.watchlistItems = watchlist
                }
            } catch {
                print("Error loading watchlist: \(error)")
            }
        }
    }
    
    func addToWatchlist(_ stock: Stock) {
        Task {
            do {
                try await supabase.addToWatchlist(
                    symbol: stock.symbol,
                    companyName: stock.companyName
                )
                await loadWatchlist()
            } catch {
                print("Error adding to watchlist: \(error)")
            }
        }
    }
}
```

## 🎯 What You Get

### ✅ **Authentication**
- Email/password signup/login
- Social login (Apple, Google) - easy to add
- Session management
- Password reset

### ✅ **Database**
- User profiles
- Watchlists
- Search history
- User preferences
- Price alerts
- Device tokens

### ✅ **Real-time Features**
- Live watchlist updates
- Price alert notifications
- Real-time sentiment changes

### ✅ **API Proxy**
- Cached financial data
- Rate limiting
- Error handling
- Multiple API sources

### ✅ **Security**
- Row Level Security (RLS)
- Automatic user isolation
- Secure API keys
- JWT tokens

## 📊 Performance Benefits

### **Caching Strategy**
- Stock data: 5 minutes
- Sentiment data: 1 hour
- News data: 30 minutes
- User data: Real-time

### **API Cost Reduction**
- **Before**: 100 API calls per user session
- **After**: 10-20 API calls per user session
- **Savings**: 80-90% reduction in API costs

### **Real-time Updates**
- WebSocket connections for live data
- Push notifications for alerts
- Instant UI updates

## 🔄 Migration Path

### Phase 1: Authentication (Week 1)
1. Set up Supabase project
2. Deploy database schema
3. Update AuthViewModel
4. Test signup/login

### Phase 2: Data Storage (Week 2)
1. Update WatchlistViewModel
2. Update SearchService
3. Migrate user preferences
4. Test data persistence

### Phase 3: API Integration (Week 3)
1. Deploy Edge Functions
2. Update StockService
3. Update SentimentService
4. Test API calls

### Phase 4: Real-time Features (Week 4)
1. Set up real-time subscriptions
2. Implement push notifications
3. Add live updates
4. Performance testing

## 🚨 Important Notes

### **Rate Limits**
- Supabase: 100 requests/second
- Alpha Vantage: 5 requests/minute (free tier)
- Edge Functions: 500K invocations/month (free tier)

### **Data Limits**
- Database: 500MB (free tier)
- Storage: 1GB (free tier)
- Bandwidth: 2GB (free tier)

### **Scaling**
When you exceed free limits:
- **Pro Plan**: $25/month
- **Team Plan**: $599/month
- **Enterprise**: Custom pricing

## 🎉 Benefits Summary

### **For Development**
- ✅ Single service to manage
- ✅ Built-in authentication
- ✅ Real-time capabilities
- ✅ Automatic scaling
- ✅ Zero infrastructure management

### **For Users**
- ✅ Faster app performance
- ✅ Real-time updates
- ✅ Reliable data persistence
- ✅ Cross-device sync
- ✅ Push notifications

### **For Business**
- ✅ $0/month to start
- ✅ 90% cost reduction
- ✅ Easy to scale
- ✅ Professional infrastructure
- ✅ Built-in analytics

## 🆘 Troubleshooting

### Common Issues

**1. Authentication not working**
- Check API keys in SupabaseService.swift
- Verify redirect URLs in Supabase dashboard
- Check network connectivity

**2. Database errors**
- Run the migration script again
- Check RLS policies
- Verify user permissions

**3. Edge Functions failing**
- Check environment variables
- Verify API keys
- Check function logs in Supabase dashboard

### Support Resources
- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Discord](https://discord.supabase.com)
- [Supabase GitHub](https://github.com/supabase/supabase)

---

**🎯 Result**: You now have a production-ready backend that costs $0/month and can handle thousands of users with real-time features, all managed through one simple dashboard! 
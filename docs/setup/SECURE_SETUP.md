# 🔐 Secure API Key Setup Guide

This guide ensures your API keys are **NEVER exposed** in your GitHub repository.

## ⚠️ Security Warning

**NEVER commit API keys to GitHub!** They will be:
- ❌ Visible to everyone
- ❌ Used by malicious actors
- ❌ Cost you money
- ❌ Compromise your app

## 🛡️ How This Secure Setup Works

### 1. **Config.plist** (Local Only)
- Contains your actual API keys
- **Gitignored** - never committed to GitHub
- Only exists on your local machine

### 2. **Config.swift** (Safe to Commit)
- Loads keys from Config.plist
- Contains no actual keys
- Safe to share and commit

### 3. **Environment Variables** (Production)
- For App Store builds
- Set in Xcode build settings
- Override Config.plist values

## 📝 Step-by-Step Setup

### Step 1: Add Your API Keys to Config.plist

1. **Open** `ChartSense/Config.plist` in Xcode
2. **Replace** the placeholder values with your actual keys:

```xml
<key>SUPABASE_URL</key>
<string>https://your-project-id.supabase.co</string>

<key>SUPABASE_ANON_KEY</key>
<string>eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...</string>

<key>ALPHA_VANTAGE_API_KEY</key>
<string>your_alpha_vantage_key_here</string>
```

### Step 2: Verify .gitignore

1. **Check** that `.gitignore` contains:
```gitignore
# API Keys and Configuration Files
ChartSense/Config.plist
**/Config.plist
```

2. **Test** that Config.plist is ignored:
```bash
git status
```
You should **NOT** see `Config.plist` in the output.

### Step 3: Test Configuration

1. **Build and run** your app
2. **Check Xcode console** for:
```
✅ Configuration validated successfully
📱 App: ChartSense v1.0.0 (1)
🔗 Supabase URL: https://your-project-id...
🔑 Supabase Key: eyJhbGciOiJ...
📊 Alpha Vantage: Configured
```

## 🔍 Verification Checklist

### ✅ Before Committing Code

1. **Config.plist is gitignored**
   ```bash
   git status
   # Should NOT show Config.plist
   ```

2. **Config.swift has no hardcoded keys**
   ```swift
   // ✅ GOOD - loads from file
   private let supabaseURL = Config.supabaseURL
   
   // ❌ BAD - hardcoded
   private let supabaseURL = "https://..."
   ```

3. **Keys are working**
   - App builds without errors
   - Console shows "Configuration validated successfully"
   - Authentication works

### ✅ Before Pushing to GitHub

1. **Check what you're committing**:
   ```bash
   git add .
   git status
   ```

2. **Verify no sensitive files**:
   - No `Config.plist`
   - No `.env` files
   - No API keys in any files

3. **Test on clean clone**:
   ```bash
   # In a different folder
   git clone your-repo
   cd your-repo
   # Should NOT have Config.plist
   ```

## 🚀 Production Deployment

### For App Store Builds

1. **Set environment variables** in Xcode:
   - Select your target
   - Build Settings → Environment Variables
   - Add:
     - `SUPABASE_URL`
     - `SUPABASE_ANON_KEY`
      - `ALPHA_VANTAGE_API_KEY`
      - `GOOGLE_API_KEY` (Gemini 2.5 Flash)

2. **Or use Xcode build phases**:
   ```bash
   # In Build Phases → Run Script
   export SUPABASE_URL="https://your-project.supabase.co"
   export SUPABASE_ANON_KEY="your-key"
   ```

### For CI/CD (GitHub Actions)

1. **Add secrets** in GitHub repository:
   - Settings → Secrets and variables → Actions
   - Add repository secrets:
     - `SUPABASE_URL`
     - `SUPABASE_ANON_KEY`
      - `ALPHA_VANTAGE_API_KEY`
      - `GOOGLE_API_KEY`

2. **Use in workflow**:
   ```yaml
   env:
     SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
     SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
   ```

## 🛠️ Troubleshooting

### Issue: "Configuration validation failed"

**Solution**:
1. Check `Config.plist` exists in `ChartSense/` folder
2. Verify keys are not empty strings
3. Make sure file is properly formatted XML

### Issue: "Config.plist not found"

**Solution**:
1. Add `Config.plist` to your Xcode project
2. Make sure it's in the correct target
3. Check file path in `Config.swift`

### Issue: Keys showing in git status

**Solution**:
1. Add to `.gitignore`:
   ```gitignore
   ChartSense/Config.plist
   ```
2. Remove from git tracking:
   ```bash
   git rm --cached ChartSense/Config.plist
   ```

### Issue: App crashes on startup

**Solution**:
1. Check console for configuration errors
2. Verify API keys are valid
3. Test network connectivity

## 🔄 Team Development

### Sharing with Team Members

1. **Create Config.plist.example**:
   ```xml
   <key>SUPABASE_URL</key>
   <string>YOUR_SUPABASE_URL_HERE</string>
   ```

2. **Document setup** in README:
   ```markdown
   ## Setup
   1. Copy `Config.plist.example` to `Config.plist`
   2. Add your API keys to `Config.plist`
   3. Never commit `Config.plist`
   ```

### New Developer Setup

1. **Clone repository**
2. **Copy example config**:
   ```bash
   cp ChartSense/Config.plist.example ChartSense/Config.plist
   ```
3. **Add API keys** to `Config.plist`
4. **Build and test**

## 🎯 Security Best Practices

### ✅ Do This
- Use Config.plist for local development
- Use environment variables for production
- Keep Config.plist in .gitignore
- Rotate API keys regularly
- Use least-privilege API keys

### ❌ Don't Do This
- Commit API keys to GitHub
- Share Config.plist files
- Use production keys in development
- Hardcode keys in source code
- Use admin keys in client apps

## 🔐 Additional Security

### Key Rotation
- Rotate Supabase keys monthly
- Rotate Alpha Vantage keys quarterly
- Monitor API usage for anomalies

### Monitoring
- Set up API usage alerts
- Monitor for unusual activity
- Log authentication attempts

### Backup Strategy
- Store keys in password manager
- Document key purposes
- Have recovery procedures

---

**🎯 Result**: Your API keys are now secure and will never be exposed in your GitHub repository! 
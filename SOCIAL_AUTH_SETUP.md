# Social Authentication Setup Guide

## Apple Sign In Setup

### 1. Apple Developer Account Setup
1. Go to [Apple Developer](https://developer.apple.com)
2. Sign in with your Apple ID
3. Navigate to **Certificates, Identifiers & Profiles**
4. Select **Identifiers** → **App IDs**
5. Find your app's identifier or create a new one

### 2. Enable Sign In with Apple
1. In your App ID settings, scroll to **Capabilities**
2. Enable **Sign In with Apple**
3. Save the changes

### 3. Configure Supabase
1. Go to your Supabase dashboard
2. Navigate to **Authentication** → **Configuration**
3. Click on **"Third Party Auth"** tab
4. Find **Apple** and click the arrow to configure
5. Enable Apple provider
6. Add your Apple Service ID (format: `com.yourcompany.yourapp.service`)
7. Add your Apple Team ID (found in Apple Developer account)
8. Add your Apple Key ID (create a new key in Apple Developer)
9. Add your Apple Private Key (download from Apple Developer)

### 4. Add to Xcode Project
1. In Xcode, select your project
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **Sign In with Apple**

## Google Sign In Setup

### 1. Google Cloud Console Setup
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing one
3. Enable **Google+ API** and **Google Sign-In API**

### 2. Create OAuth 2.0 Credentials
1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **OAuth 2.0 Client IDs**
3. Choose **iOS** as application type
4. Add your bundle identifier
5. Download the `GoogleService-Info.plist` file

### 3. Add GoogleSignIn Package
1. In Xcode, go to **File** → **Add Package Dependencies**
2. Add: `https://github.com/google/GoogleSignIn-iOS`
3. Select your target

### 4. Configure Supabase
1. Go to your Supabase dashboard
2. Navigate to **Authentication** → **Configuration**
3. Click on **"Third Party Auth"** tab
4. Find **Google** and click the arrow to configure
5. Enable Google provider
6. Add your Google Client ID (from GoogleService-Info.plist)
7. Add your Google Client Secret

### 5. Add URL Schemes
1. In Xcode, select your project
2. Go to **Info.plist**
3. Add URL schemes:
   - `com.googleusercontent.apps.YOUR_CLIENT_ID`
   - `YOUR_BUNDLE_ID`

## Implementation Status

### ✅ Apple Sign In
- **Code**: Implemented in `SupabaseService.swift`
- **Setup Required**: Apple Developer account configuration
- **Supabase Setup**: Enable Apple provider in dashboard

### 🔄 Google Sign In
- **Code**: Placeholder implemented (requires GoogleSignIn SDK)
- **Setup Required**: Google Cloud Console + GoogleSignIn package
- **Supabase Setup**: Enable Google provider in dashboard

## Testing

### Apple Sign In
1. Build and run the app
2. Tap "Sign in with Apple"
3. Complete Apple ID authentication
4. User should be signed in to Supabase

### Google Sign In
1. Complete Google setup above
2. Build and run the app
3. Tap "Sign in with Google"
4. Complete Google authentication
5. User should be signed in to Supabase

## Troubleshooting

### Apple Sign In Issues
- **"No valid 'aps-environment' entitlement"**: Add Sign In with Apple capability
- **"Invalid client"**: Check Apple Service ID and Team ID in Supabase
- **"Invalid key"**: Verify Apple Key ID and Private Key

### Google Sign In Issues
- **"Invalid client ID"**: Check Google Client ID in Supabase
- **"URL scheme not found"**: Add correct URL schemes to Info.plist
- **"Package not found"**: Add GoogleSignIn package to project

## Security Notes

1. **Never commit sensitive keys** to version control
2. **Use environment variables** for production keys
3. **Enable Row Level Security (RLS)** in Supabase
4. **Validate tokens** on the server side
5. **Handle user data** according to privacy policies

## Next Steps

1. **Complete Apple setup** (easier, fewer dependencies)
2. **Test Apple Sign In** functionality
3. **Add Google Sign In** when needed
4. **Implement user profile creation** after social auth
5. **Add proper error handling** for auth failures 
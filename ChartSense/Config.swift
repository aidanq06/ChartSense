//
//  Config.swift
//  ChartSense
//
//  Created by Aidan Quach on 7/22/25.
//

import Foundation

// MARK: - Configuration Manager
struct Config {
    // MARK: - Supabase Configuration
    static let supabaseURL: String = {
        // Try to load from environment variable first (for production)
        if let url = ProcessInfo.processInfo.environment["SUPABASE_URL"] {
            return url
        }
        
        // Fall back to local config file (for development)
        return loadFromConfigFile(key: "SUPABASE_URL") ?? ""
    }()
    
    static let supabaseAnonKey: String = {
        // Try to load from environment variable first (for production)
        if let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] {
            return key
        }
        
        // Fall back to local config file (for development)
        return loadFromConfigFile(key: "SUPABASE_ANON_KEY") ?? ""
    }()
    
    // MARK: - Financial API Keys
    static let finnhubAPIKey: String = {
        if let key = ProcessInfo.processInfo.environment["FINNHUB_API_KEY"] {
            return key
        }
        return loadFromConfigFile(key: "FINNHUB_API_KEY") ?? ""
    }()
    
    static let openAIAPIKey: String = {
        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return key
        }
        return loadFromConfigFile(key: "OPENAI_API_KEY") ?? ""
    }()
    
    // MARK: - App Configuration
    static let appName = "ChartSense"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // MARK: - Feature Flags
    static let enableAnalytics = true
    static let enableCrashReporting = true
    static let enablePushNotifications = true
    
    // MARK: - API Endpoints
    static let baseURL = "https://api.chartsense.app" // Your custom domain if you have one
    
    // MARK: - Cache Settings
    static let stockCacheDuration: TimeInterval = 300 // 5 minutes
    static let sentimentCacheDuration: TimeInterval = 3600 // 1 hour
    static let newsCacheDuration: TimeInterval = 1800 // 30 minutes
    
    // MARK: - Rate Limiting
    static let maxAPICallsPerMinute = 60
    static let maxConcurrentRequests = 10
    
    // MARK: - Helper Methods
    private static func loadFromConfigFile(key: String) -> String? {
        // Load from Config.plist file (which should be gitignored)
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist") else {
            print("❌ Config.plist file not found in bundle")
            return nil
        }
        
        guard let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            print("❌ Could not load Config.plist as dictionary")
            return nil
        }
        
        guard let value = dict[key] as? String else {
            print("❌ Key '\(key)' not found in Config.plist or is not a string")
            return nil
        }
        
        print("✅ Successfully loaded '\(key)' from Config.plist")
        return value
    }
    
    // MARK: - Validation
    static func validateConfiguration() -> Bool {
        print("🔍 Starting configuration validation...")
        
        // Check if Config.plist exists in bundle
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist") {
            print("✅ Config.plist found at: \(path)")
        } else {
            print("❌ Config.plist not found in app bundle")
            return false
        }
        
        let requiredKeys = [
            supabaseURL,
            supabaseAnonKey
        ]
        
        for key in requiredKeys {
            if key.isEmpty {
                print("❌ Configuration Error: Missing required API key")
                return false
            }
        }
        
        print("✅ Configuration validated successfully")
        return true
    }
    
    // MARK: - Debug Information (Safe to log)
    static func printDebugInfo() {
        print("📱 App: \(appName) v\(appVersion) (\(buildNumber))")
        print("🔗 Supabase URL: \(supabaseURL.prefix(20))...")
        print("🔑 Supabase Key: \(supabaseAnonKey.prefix(10))...")
        print("🤖 OpenAI: \(openAIAPIKey.isEmpty ? "Not configured" : "Configured")")
    }

    // MARK: - Debug Methods
    static func testSupabaseConnection() {
        print("🔧 Testing Supabase Configuration:")
        print("   URL: \(supabaseURL)")
        print("   Anon Key: \(String(supabaseAnonKey.prefix(10)))...")
        
        // Test basic connectivity
        Task {
            do {
                let url = URL(string: "\(supabaseURL)/rest/v1/")!
                var request = URLRequest(url: url)
                request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
                request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("   Connection test: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("   Response: \(responseString)")
                    }
                }
            } catch {
                print("   Connection test failed: \(error)")
            }
        }
    }
}

// MARK: - Environment Detection
extension Config {
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var isRelease: Bool {
        return !isDebug
    }
    
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
} 

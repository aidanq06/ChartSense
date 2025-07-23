//
//  SupabaseService.swift
//  ChartSense
//
//  Created by Aidan Quach on 7/22/25.
//

import Foundation
import SwiftUI
import Supabase

// MARK: - Supabase Configuration
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    // Load from secure configuration
    private let supabaseURL = Config.supabaseURL
    private let supabaseAnonKey = Config.supabaseAnonKey
    
    private var client: SupabaseClient?
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {
        print("🏗️ Initializing SupabaseService...")
        setupSupabase()
        validateConfiguration()
        
        // Test the connection
        Task {
            await testConnection()
        }
        
        checkAuthenticationStatus()
    }
    
    // MARK: - Reinitialization
    func reinitializeClient() {
        print("🔄 Reinitializing Supabase client...")
        setupSupabase()
        validateConfiguration()
        
        Task {
            await testConnection()
        }
    }
    
    private func setupSupabase() {
        print("🔧 Setting up Supabase...")
        print("📋 Config.supabaseURL: \(supabaseURL)")
        print("📋 Config.supabaseAnonKey length: \(supabaseAnonKey.count)")
        print("📋 Config.supabaseAnonKey starts with: \(supabaseAnonKey.prefix(20))")
        
        guard let url = URL(string: supabaseURL) else {
            print("❌ Invalid Supabase URL: \(supabaseURL)")
            return
        }
        
        print("🔗 Setting up Supabase with URL: \(url)")
        print("🔑 Using anon key: \(supabaseAnonKey.prefix(20))...")
        
        // Initialize Supabase client with direct constructor
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseAnonKey
        )
        
        print("✅ Supabase client initialized successfully")
        print("🔍 Client object: \(String(describing: client))")
    }
    
    private func validateConfiguration() {
        print("🔍 Validating Supabase configuration...")
        print("📋 URL: \(supabaseURL)")
        print("📋 Key length: \(supabaseAnonKey.count)")
        print("📋 Key valid format: \(supabaseAnonKey.hasPrefix("eyJ"))")
        
        if supabaseURL.isEmpty {
            print("❌ Supabase URL is empty!")
        }
        if supabaseAnonKey.isEmpty {
            print("❌ Supabase anon key is empty!")
        }
        if !supabaseAnonKey.hasPrefix("eyJ") {
            print("❌ Supabase anon key doesn't look like a valid JWT!")
        }
        
        print("✅ Configuration validation complete")
    }
    
    // MARK: - Authentication
    func signUp(email: String, password: String, name: String) async throws {
        await MainActor.run { isLoading = true; errorMessage = nil }
        
        print("🚀 Starting sign up process...")
        print("📧 Email: \(email)")
        print("👤 Name: \(name)")
        print("🔍 Client exists: \(client != nil)")
        
        do {
            guard let client = client else {
                print("❌ No Supabase client available")
                throw SupabaseError.networkError
            }
            
            print("🔑 Making sign up request to Supabase...")
            print("🔗 Request URL: \(supabaseURL)/auth/v1/signup")
            
            // Use the correct API with user metadata
            let response = try await client.auth.signUp(
                email: email,
                password: password,
                data: ["name": .string(name)]
            )
            
            print("✅ Sign up response received: \(response)")
            
            let user = response.user
            await MainActor.run {
                self.currentUser = User(
                    id: user.id.uuidString,
                    email: user.email ?? "",
                    name: name,
                    authProvider: .email,
                    createdAt: user.createdAt ?? Date()
                )
                self.isAuthenticated = true
                self.isLoading = false
            }
            print("✅ User signed up successfully: \(user.email ?? "")")
        } catch {
            print("❌ Sign up error details: \(error)")
            print("❌ Error type: \(type(of: error))")
            
            // Try to get more details about the error
            if let authError = error as? AuthError {
                print("❌ Auth error: \(authError)")
            }
            
            // If SDK fails, try manual request as fallback
            if error.localizedDescription.contains("No api key found") || error.localizedDescription.contains("No API key found") {
                print("🔄 Trying manual signup request as fallback...")
                try await manualSignUp(email: email, password: password, name: name)
                return
            }
            
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            print("❌ Sign up error: \(error)")
            throw error
        }
    }
    
    private func manualSignUp(email: String, password: String, name: String) async throws {
        print("🔧 Attempting manual signup...")
        
        guard let url = URL(string: "\(supabaseURL)/auth/v1/signup") else {
            throw SupabaseError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "data": ["name": name]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as? HTTPURLResponse
        
        print("📊 Manual signup response status: \(httpResponse?.statusCode ?? 0)")
        print("📊 Manual signup response data: \(String(data: data, encoding: .utf8) ?? "none")")
        
        if httpResponse?.statusCode == 200 || httpResponse?.statusCode == 201 {
            // Parse the response and create user
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let userData = json["user"] as? [String: Any],
               let userId = userData["id"] as? String {
                
                await MainActor.run {
                    self.currentUser = User(
                        id: userId,
                        email: email,
                        name: name,
                        authProvider: .email,
                        createdAt: Date()
                    )
                    self.isAuthenticated = true
                    self.isLoading = false
                }
                print("✅ Manual signup successful")
            }
        } else {
            throw SupabaseError.networkError
        }
    }
    
    func signIn(email: String, password: String) async throws {
        await MainActor.run { isLoading = true; errorMessage = nil }
        
        do {
            guard let client = client else {
                throw SupabaseError.networkError
            }
            
            let response = try await client.auth.signIn(
                email: email,
                password: password
            )
            
            let user = response.user
            let userMetadata = user.userMetadata
            let userName = userMetadata["name"] as? String ?? "User"
            
            await MainActor.run {
                self.currentUser = User(
                    id: user.id.uuidString,
                    email: user.email ?? "",
                    name: userName,
                    authProvider: .email,
                    createdAt: user.createdAt ?? Date()
                )
                self.isAuthenticated = true
                self.isLoading = false
            }
            print("✅ User signed in successfully: \(user.email ?? "")")
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            print("❌ Sign in error: \(error)")
            throw error
        }
    }
    
    func signOut() async {
        do {
            guard let client = client else { return }
            
            try await client.auth.signOut()
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
            }
            print("✅ User signed out successfully")
        } catch {
            print("❌ Sign out error: \(error)")
        }
    }
    
    private func checkAuthenticationStatus() {
        Task {
            do {
                guard let client = client else { return }
                
                let session = try await client.auth.session
                let user = session.user
                let userMetadata = user.userMetadata
                let userName = userMetadata["name"] as? String ?? "User"
                
                await MainActor.run {
                    self.currentUser = User(
                        id: user.id.uuidString,
                        email: user.email ?? "",
                        name: userName,
                        authProvider: .email,
                        createdAt: user.createdAt ?? Date()
                    )
                    self.isAuthenticated = true
                }
                print("✅ Found active session for user: \(user.email ?? "")")
            } catch {
                print("ℹ️ No active session: \(error)")
            }
        }
    }
    
    // MARK: - Test Connection
    func testConnection() async {
        print("🧪 Testing Supabase connection...")
        
        guard let client = client else {
            print("❌ No client available for testing")
            return
        }
        
        do {
            // Try to get the current session (this should work even without auth)
            let session = try await client.auth.session
            print("✅ Connection test successful - got session")
        } catch {
            print("❌ Connection test failed: \(error)")
            
            // Test API key directly
            await testAPIKeyDirectly()
            
            // Test auth endpoint
            await testAuthEndpoint()
            
            // Test signup endpoint
            await testSignupEndpoint()
            
            // Check project settings
            await checkSupabaseProjectSettings()
            
            // Try a simple HTTP request to see if we can reach Supabase
            await testBasicHTTPConnection()
        }
    }
    
    private func testAPIKeyDirectly() async {
        print("🔑 Testing API key directly...")
        
        guard let url = URL(string: "\(supabaseURL)/rest/v1/") else {
            print("❌ Invalid API URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("*", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            print("✅ Direct API test successful")
            print("📊 Response status: \(httpResponse?.statusCode ?? 0)")
            print("📊 Response headers: \(httpResponse?.allHeaderFields ?? [:])")
            print("📊 Response data: \(String(data: data, encoding: .utf8) ?? "none")")
        } catch {
            print("❌ Direct API test failed: \(error)")
        }
    }
    
    private func testAuthEndpoint() async {
        print("🔐 Testing auth endpoint directly...")
        
        guard let url = URL(string: "\(supabaseURL)/auth/v1/") else {
            print("❌ Invalid auth URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            print("✅ Auth endpoint test successful")
            print("📊 Response status: \(httpResponse?.statusCode ?? 0)")
            print("📊 Response data: \(String(data: data, encoding: .utf8) ?? "none")")
        } catch {
            print("❌ Auth endpoint test failed: \(error)")
        }
    }
    
    private func checkSupabaseProjectSettings() async {
        print("🔧 Checking Supabase project settings...")
        
        // Test if we can access the project settings
        guard let url = URL(string: "\(supabaseURL)/rest/v1/") else {
            print("❌ Invalid project URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            print("📊 Project settings response status: \(httpResponse?.statusCode ?? 0)")
            
            if httpResponse?.statusCode == 200 {
                print("✅ Project settings accessible")
            } else {
                print("❌ Project settings not accessible - status: \(httpResponse?.statusCode ?? 0)")
            }
        } catch {
            print("❌ Project settings check failed: \(error)")
        }
    }
    
    private func testSignupEndpoint() async {
        print("🔐 Testing signup endpoint directly...")
        
        guard let url = URL(string: "\(supabaseURL)/auth/v1/signup") else {
            print("❌ Invalid signup URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Test with a real email format
        let testBody: [String: Any] = [
            "email": "testuser123@test.com",
            "password": "TestPassword123!"
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: testBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            print("📊 Signup endpoint test response status: \(httpResponse?.statusCode ?? 0)")
            print("📊 Signup endpoint test response data: \(String(data: data, encoding: .utf8) ?? "none")")
            
            if httpResponse?.statusCode == 200 || httpResponse?.statusCode == 201 {
                print("✅ Signup endpoint is working")
            } else {
                print("❌ Signup endpoint returned error status: \(httpResponse?.statusCode ?? 0)")
            }
        } catch {
            print("❌ Signup endpoint test failed: \(error)")
        }
    }
    
    private func testBasicHTTPConnection() async {
        print("🌐 Testing basic HTTP connection to Supabase...")
        
        guard let url = URL(string: "\(supabaseURL)/auth/v1/health") else {
            print("❌ Invalid health check URL")
            return
        }
        
        var request = URLRequest(url: url)
        // Use the correct headers for Supabase API
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print("✅ HTTP test successful")
            print("📊 Response status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            print("📊 Response data: \(String(data: data, encoding: .utf8) ?? "none")")
        } catch {
            print("❌ HTTP test failed: \(error)")
        }
    }
    
    // MARK: - Social Authentication
    func signInWithApple() async throws {
        await MainActor.run { isLoading = true; errorMessage = nil }
        
        do {
            guard let client = client else {
                throw SupabaseError.networkError
            }
            
            // TODO: Implement Apple Sign In
            // This requires additional setup with Apple Developer account
            print("🍎 Apple Sign In not yet implemented")
            
            // For now, show a placeholder message
            await MainActor.run {
                self.errorMessage = "Apple Sign In coming soon!"
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            print("❌ Apple Sign In error: \(error)")
            throw error
        }
    }
    
    func signInWithGoogle() async throws {
        await MainActor.run { isLoading = true; errorMessage = nil }
        
        do {
            guard let client = client else {
                throw SupabaseError.networkError
            }
            
            // TODO: Implement Google Sign In
            // This requires additional setup with Google Cloud Console
            print("🔍 Google Sign In not yet implemented")
            
            // For now, show a placeholder message
            await MainActor.run {
                self.errorMessage = "Google Sign In coming soon!"
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            print("❌ Google Sign In error: \(error)")
            throw error
        }
    }
    
    // MARK: - Watchlist Management
    func addToWatchlist(symbol: String, companyName: String, priceTarget: Double? = nil) async throws {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        
        // TODO: Implement with correct Supabase API
        print("Adding \(symbol) to watchlist for user \(userId)")
    }
    
    func removeFromWatchlist(symbol: String) async throws {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        
        // TODO: Implement with correct Supabase API
        print("Removing \(symbol) from watchlist for user \(userId)")
    }
    
    func getWatchlist() async throws -> [WatchlistItem] {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        
        // TODO: Implement with correct Supabase API
        print("Getting watchlist for user \(userId)")
        
        // Return empty array for now
        return []
    }
    
    // MARK: - Search History
    func addSearchHistory(symbol: String, companyName: String) async throws {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        
        // TODO: Implement with correct Supabase API
        print("Adding search history for \(symbol)")
    }
    
    func getSearchHistory() async throws -> [SearchHistory] {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        
        // TODO: Implement with correct Supabase API
        print("Getting search history for user \(userId)")
        
        // Return empty array for now
        return []
    }
    
    // MARK: - User Preferences
    func saveUserPreferences(preferences: UserPreferences) async throws {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        
        // TODO: Implement with correct Supabase API
        print("Saving preferences for user \(userId)")
    }
    
    func getUserPreferences() async throws -> UserPreferences? {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        
        // TODO: Implement with correct Supabase API
        print("Getting preferences for user \(userId)")
        
        // Return nil for now
        return nil
    }
    
    // MARK: - Financial Data Proxy (Edge Function)
    func fetchStockData(symbol: String) async throws -> Stock {
        // TODO: Implement with correct Supabase API
        print("Fetching stock data for \(symbol)")
        
        // Return mock stock for now
        return Stock(
            symbol: symbol,
            companyName: "\(symbol) Corporation",
            currentPrice: 100.0,
            dailyChange: 1.0,
            dailyChangePercent: 1.0,
            marketCap: 1000000000,
            volume: 1000000,
            peRatio: 20.0
        )
    }
    
    func fetchSentimentData(symbol: String) async throws -> SentimentAnalysis {
        // TODO: Implement with correct Supabase API
        print("Fetching sentiment data for \(symbol)")
        
        // Return mock sentiment for now
        return SentimentAnalysis(
            symbol: symbol,
            overallRating: .neutral,
            score: 0.0,
            keyDrivers: [],
            confidence: 0.8,
            lastUpdated: Date(),
            breakdown: SentimentBreakdown(
                newsPositive: 0.5,
                newsNegative: 0.3,
                newsNeutral: 0.2,
                analystSentiment: 0.0,
                socialSentiment: 0.0,
                technicalIndicators: 0.0
            )
        )
    }
    
    func fetchNewsData(symbol: String) async throws -> [NewsItem] {
        // TODO: Implement with correct Supabase API
        print("Fetching news data for \(symbol)")
        
        // Return empty array for now
        return []
    }
    
    // MARK: - Push Notifications
    func registerForPushNotifications(deviceToken: String) async throws {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        
        // TODO: Implement with correct Supabase API
        print("Registering push notifications for user \(userId)")
    }
    
    func createPriceAlert(symbol: String, targetPrice: Double, isAbove: Bool) async throws {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        
        // TODO: Implement with correct Supabase API
        print("Creating price alert for \(symbol) at \(targetPrice)")
    }
    
    // MARK: - Debug Methods
    func debugConfiguration() {
        print("🔍 Debug Configuration:")
        print("📋 Supabase URL: \(supabaseURL)")
        print("📋 Supabase Key Length: \(supabaseAnonKey.count)")
        print("📋 Supabase Key Prefix: \(supabaseAnonKey.prefix(20))")
        print("📋 Client exists: \(client != nil)")
        
        if let client = client {
            print("✅ Supabase client is initialized")
        } else {
            print("❌ Supabase client is not initialized")
        }
    }
}

// MARK: - User Preferences Model
struct UserPreferences: Codable {
    let isDarkMode: Bool
    let notificationsEnabled: Bool
    let priceAlertsEnabled: Bool
    let newsAlertsEnabled: Bool
    let refreshInterval: String
    let defaultView: String
}

// MARK: - Errors
enum SupabaseError: Error, LocalizedError {
    case notAuthenticated
    case networkError
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .networkError:
            return "Network error occurred"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
} 
//
//  SupabaseService.swift
//  ChartSense
//
//  Created by Aidan Quach on 7/22/25.
//

import Foundation
import SwiftUI
import Security

// MARK: - Supabase Service
enum SupabaseError: Error, LocalizedError {
    case networkError
    case notAuthenticated
    case invalidResponse
    case rateLimitExceeded
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network error occurred"
        case .notAuthenticated:
            return "User not authenticated"
        case .invalidResponse:
            return "Invalid response from server"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .serverError(let message):
            return message
        }
    }
}

class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    private var supabaseURL: String?
    private var supabaseAnonKey: String?
    private var accessToken: String?
    private var refreshToken: String?
    private var accessTokenExpiry: Date?
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {
        setupClient()
    }
    
    private func setupClient() {
        supabaseURL = Config.supabaseURL
        supabaseAnonKey = Config.supabaseAnonKey
        
        if supabaseURL == nil || supabaseAnonKey == nil {
            print("❌ Missing Supabase configuration")
            return
        }
        
        print("✅ Supabase service initialized")
        Task { await restoreSession() }
    }
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String, name: String) async throws {
        guard let supabaseURL = supabaseURL,
              let supabaseAnonKey = supabaseAnonKey else {
            throw SupabaseError.networkError
        }
        
        do {
            let url = URL(string: "\(supabaseURL)/auth/v1/signup")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            
            let body: [String: Any] = [
                "email": email,
                "password": password,
                "data": ["name": name]
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.networkError
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let userData = json["user"] as? [String: Any],
                   let userId = userData["id"] as? String,
                   let accessToken = json["access_token"] as? String {
                    
                    self.accessToken = accessToken
                    currentUser = User(
                        id: userId,
                        email: email,
                        name: name,
                        authProvider: .email,
                        createdAt: Date()
                    )
                    isAuthenticated = true
                    print("✅ User signed up successfully with token")
                }
            } else {
                // Print the error response for debugging
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Signup error response: \(errorBody)")
                
                // Parse the error to extract user-friendly message
                let userFriendlyMessage = ErrorMessageParser.parseUserFriendlyMessage(errorBody)
                throw SupabaseError.serverError(userFriendlyMessage)
            }
        } catch {
            print("❌ Sign up error: \(error)")
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        guard let supabaseURL = supabaseURL,
              let supabaseAnonKey = supabaseAnonKey else {
            throw SupabaseError.networkError
        }
        
        do {
            let url = URL(string: "\(supabaseURL)/auth/v1/token?grant_type=password")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            
            let body: [String: Any] = [
                "email": email,
                "password": password
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let userData = json["user"] as? [String: Any],
                   let userId = userData["id"] as? String,
                   let accessToken = json["access_token"] as? String {
                    
                    let userName = userData["user_metadata"] as? [String: Any]
                    let name = userName?["name"] as? String ?? "User"
                    
                    let refresh = json["refresh_token"] as? String
                    self.accessToken = accessToken
                    self.refreshToken = refresh
                    self.accessTokenExpiry = decodeJWTExpiry(accessToken)
                    saveSession(accessToken: accessToken, refreshToken: refresh, userId: userId, email: email, name: name)
                    currentUser = User(
                        id: userId,
                        email: email,
                        name: name,
                        authProvider: .email,
                        createdAt: Date()
                    )
                    isAuthenticated = true
                    print("✅ User signed in successfully with token")
                }
            } else {
                // Print the error response for debugging
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Signin error response: \(errorBody)")
                
                // Parse the error to extract user-friendly message
                let userFriendlyMessage = ErrorMessageParser.parseUserFriendlyMessage(errorBody)
                throw SupabaseError.serverError(userFriendlyMessage)
            }
        } catch {
            print("❌ Sign in error: \(error)")
            throw error
        }
    }
    
    func signOut() async {
        currentUser = nil
        isAuthenticated = false
        accessToken = nil
        refreshToken = nil
        accessTokenExpiry = nil
        clearSession()
        print("✅ User signed out successfully")
    }
    
    func checkAuthenticationStatus() async { await restoreSession() }
    
    func signInWithApple() async throws {
        // Apple Sign In implementation would go here
        // For now, we'll throw an error indicating it's not implemented
        throw SupabaseError.serverError("Apple Sign In not implemented yet")
    }
    
    func signInWithGoogle() async throws {
        // Google Sign In implementation would go here
        // For now, we'll throw an error indicating it's not implemented
        throw SupabaseError.serverError("Google Sign In not implemented yet")
    }
    
    // MARK: - Watchlist Management
    
    func addToWatchlist(symbol: String, companyName: String, priceTarget: Double? = nil, notes: String? = nil, alertPrice: Double? = nil, alertType: String = "above") async throws {
        print("🔄 SupabaseService: Adding \(symbol) to watchlist...")
        print("🔄 SupabaseService: User authenticated: \(isAuthenticated)")
        print("🔄 SupabaseService: Current user: \(currentUser?.id ?? "nil")")
        print("🔄 SupabaseService: Access token: \(accessToken != nil ? "present" : "missing")")
        
        guard let userId = currentUser?.id else { 
            print("❌ SupabaseService: User not authenticated")
            throw SupabaseError.notAuthenticated 
        }
        guard let accessToken = accessToken else { 
            print("❌ SupabaseService: Access token missing")
            throw SupabaseError.notAuthenticated 
        }
        guard let supabaseURL = supabaseURL else {
            print("❌ SupabaseService: Supabase URL missing")
            throw SupabaseError.networkError
        }
        
        // First, ensure user profile exists
        try await ensureUserProfileExists(userId: userId)
        
        do {
            let url = URL(string: "\(supabaseURL)/rest/v1/watchlists")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            
            var body: [String: Any] = [
                "user_id": userId,
                "symbol": symbol.uppercased(),
                "company_name": companyName,
                "alerts_enabled": alertPrice != nil,
                "alert_type": alertType
            ]
            
            if let priceTarget = priceTarget {
                body["price_target"] = priceTarget
            }
            
            if let notes = notes {
                body["notes"] = notes
            }
            
            if let alertPrice = alertPrice {
                body["alert_price"] = alertPrice
            }
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.networkError
            }
            
            if httpResponse.statusCode == 201 {
                print("✅ SupabaseService: Successfully added \(symbol) to watchlist for user \(userId)")
                
                // Track usage
                try await incrementUsageTracking(featureType: "watchlist_add")
            } else {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ SupabaseService: Add to watchlist error response: \(errorBody)")
                print("❌ SupabaseService: HTTP status code: \(httpResponse.statusCode)")
                
                // Check if it's a foreign key constraint error
                if errorBody.contains("user_profiles") && errorBody.contains("foreign key constraint") {
                    print("🔧 Detected missing user profile, attempting to create one...")
                    try await createUserProfile(userId: userId)
                    
                    // Retry the watchlist addition
                    return try await addToWatchlist(symbol: symbol, companyName: companyName, priceTarget: priceTarget, notes: notes, alertPrice: alertPrice, alertType: alertType)
                }
                
                throw SupabaseError.serverError("Failed to add to watchlist: \(httpResponse.statusCode) - \(errorBody)")
            }
        } catch {
            print("❌ Error adding to watchlist: \(error)")
            throw error
        }
    }
    
    func removeFromWatchlist(symbol: String) async throws {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        guard let accessToken = accessToken else { throw SupabaseError.notAuthenticated }
        guard let supabaseURL = supabaseURL else {
            throw SupabaseError.networkError
        }
        
        do {
            let url = URL(string: "\(supabaseURL)/rest/v1/watchlists?user_id=eq.\(userId)&symbol=eq.\(symbol.uppercased())")!
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.networkError
            }
            
            if httpResponse.statusCode == 204 {
                print("✅ Removed \(symbol) from watchlist for user \(userId)")
            } else {
                throw SupabaseError.serverError("Failed to remove from watchlist: \(httpResponse.statusCode)")
            }
        } catch {
            print("❌ Error removing from watchlist: \(error)")
            throw error
        }
    }
    
    func getWatchlist() async throws -> [WatchlistItem] {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        guard let accessToken = accessToken else { throw SupabaseError.notAuthenticated }
        guard let supabaseURL = supabaseURL else {
            throw SupabaseError.networkError
        }
        
        do {
            let url = URL(string: "\(supabaseURL)/rest/v1/watchlists?user_id=eq.\(userId)&order=added_at.desc")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    let watchlistItems = jsonArray.compactMap { row -> WatchlistItem? in
                        guard let symbol = row["symbol"] as? String,
                              let companyName = row["company_name"] as? String else {
                            return nil
                        }
                        
                        let alertsEnabled = row["alerts_enabled"] as? Bool ?? false
                        let priceTarget = row["price_target"] as? Double
                        let notes = row["notes"] as? String
                        let alertPrice = row["alert_price"] as? Double
                        let alertType = row["alert_type"] as? String ?? "above"
                        let addedAtString = row["added_at"] as? String
                        
                        let addedAt: Date
                        if let addedAtString = addedAtString {
                            let formatter = ISO8601DateFormatter()
                            addedAt = formatter.date(from: addedAtString) ?? Date()
                        } else {
                            addedAt = Date()
                        }
                        
                        return WatchlistItem(
                            symbol: symbol,
                            companyName: companyName,
                            alertsEnabled: alertsEnabled,
                            priceTarget: priceTarget,
                            notes: notes,
                            alertPrice: alertPrice,
                            alertType: alertType,
                            addedDate: addedAt
                        )
                    }
                    
                    print("✅ Retrieved \(watchlistItems.count) watchlist items")
                    return watchlistItems
                }
            }
            
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Get watchlist error response: \(errorBody)")
            throw SupabaseError.serverError("Failed to get watchlist: \(httpResponse.statusCode) - \(errorBody)")
        } catch {
            print("❌ Error getting watchlist: \(error)")
            throw error
        }
    }
    
    func updateWatchlistItem(symbol: String, priceTarget: Double? = nil, notes: String? = nil, alertPrice: Double? = nil, alertType: String? = nil, alertsEnabled: Bool? = nil) async throws {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        guard let accessToken = accessToken else { throw SupabaseError.notAuthenticated }
        guard let supabaseURL = supabaseURL else {
            throw SupabaseError.networkError
        }
        
        do {
            let url = URL(string: "\(supabaseURL)/rest/v1/watchlists?user_id=eq.\(userId)&symbol=eq.\(symbol.uppercased())")!
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            
            var body: [String: Any] = [:]
            
            if let priceTarget = priceTarget {
                body["price_target"] = priceTarget
            }
            
            if let notes = notes {
                body["notes"] = notes
            }
            
            if let alertPrice = alertPrice {
                body["alert_price"] = alertPrice
            }
            
            if let alertType = alertType {
                body["alert_type"] = alertType
            }
            
            if let alertsEnabled = alertsEnabled {
                body["alerts_enabled"] = alertsEnabled
            }
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.networkError
            }
            
            if httpResponse.statusCode == 204 {
                print("✅ Updated watchlist item \(symbol)")
            } else {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Update watchlist error response: \(errorBody)")
                throw SupabaseError.serverError("Failed to update watchlist: \(httpResponse.statusCode) - \(errorBody)")
            }
        } catch {
            print("❌ Error updating watchlist item: \(error)")
            throw error
        }
    }
    
    func toggleWatchlistAlerts(symbol: String, enabled: Bool) async throws {
        try await updateWatchlistItem(symbol: symbol, alertsEnabled: enabled)
    }
    
    func setWatchlistPriceTarget(symbol: String, target: Double) async throws {
        try await updateWatchlistItem(symbol: symbol, priceTarget: target)
    }
    
    func setWatchlistAlert(symbol: String, price: Double, type: String = "above") async throws {
        try await updateWatchlistItem(symbol: symbol, alertPrice: price, alertType: type, alertsEnabled: true)
    }
    
    func getWatchlistWithStockData() async throws -> [WatchlistItemWithStock] {
        let watchlistItems = try await getWatchlist()
        var itemsWithStock: [WatchlistItemWithStock] = []
        
        for item in watchlistItems {
            do {
                let stock = try await fetchStockData(symbol: item.symbol)
                let itemWithStock = WatchlistItemWithStock(
                    watchlistItem: item,
                    stock: stock
                )
                itemsWithStock.append(itemWithStock)
            } catch {
                print("⚠️ Could not fetch stock data for \(item.symbol): \(error)")
                // Add item without stock data
                let itemWithStock = WatchlistItemWithStock(
                    watchlistItem: item,
                    stock: nil
                )
                itemsWithStock.append(itemWithStock)
            }
        }
        
        return itemsWithStock
    }
    
    // MARK: - Usage Tracking
    
    private func incrementUsageTracking(featureType: String) async throws {
        guard let userId = currentUser?.id else { return }
        guard let accessToken = accessToken else { return }
        guard let supabaseURL = supabaseURL else {
            return
        }
        
        do {
            let url = URL(string: "\(supabaseURL)/rest/v1/usage_tracking")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            
            let body: [String: Any] = [
                "user_id": userId,
                "feature_type": featureType,
                "usage_count": 1,
                "usage_date": ISO8601DateFormatter().string(from: Date())
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return
            }
            
            if httpResponse.statusCode == 201 {
                print("✅ Tracked usage for \(featureType)")
            }
        } catch {
            print("⚠️ Failed to track usage for \(featureType): \(error)")
        }
    }
    
    // MARK: - Stock Data
    
    func fetchStockData(symbol: String) async throws -> Stock {
        guard let supabaseURL = supabaseURL,
              let supabaseAnonKey = supabaseAnonKey else {
            throw SupabaseError.networkError
        }
        
        do {
            // First try to get from our database
            let url = URL(string: "\(supabaseURL)/rest/v1/stock_prices?symbol=eq.\(symbol.uppercased())&select=*,stocks(company_name)")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   let stockData = jsonArray.first {
                    
                    let currentPrice = stockData["current_price"] as? Double ?? 0.0
                    let dailyChange = stockData["daily_change"] as? Double ?? 0.0
                    let dailyChangePercent = stockData["daily_change_percent"] as? Double ?? 0.0
                    let volume = stockData["volume"] as? Int64 ?? 0
                    let marketCap = stockData["market_cap"] as? Double ?? 0.0
                    let peRatio = stockData["pe_ratio"] as? Double ?? 0.0
                    
                    let stocksData = stockData["stocks"] as? [String: Any]
                    let companyName = stocksData?["company_name"] as? String ?? "\(symbol) Corporation"
                    
                    print("✅ Found stock data in database for \(symbol): price=\(currentPrice), change=\(dailyChange)")
                    
                    return Stock(
                        symbol: symbol.uppercased(),
                        companyName: companyName,
                        currentPrice: currentPrice,
                        dailyChange: dailyChange,
                        dailyChangePercent: dailyChangePercent,
                        marketCap: marketCap,
                        volume: volume,
                        peRatio: peRatio
                    )
                }
            }
            
            // If not in database, fetch from Edge Function
            print("🔄 Fetching fresh data for \(symbol) via Edge Function")
            
            let functionURL = URL(string: "\(supabaseURL)/functions/v1/fetch-stock-data")!
            var functionRequest = URLRequest(url: functionURL)
            functionRequest.httpMethod = "POST"
            functionRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            functionRequest.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            
            let functionBody = ["symbol": symbol]
            functionRequest.httpBody = try JSONSerialization.data(withJSONObject: functionBody)
            
            let (functionData, functionResponse) = try await URLSession.shared.data(for: functionRequest)
            
            guard let functionHttpResponse = functionResponse as? HTTPURLResponse else {
                throw SupabaseError.networkError
            }
            
            if functionHttpResponse.statusCode == 200 {
                if let responseJson = try JSONSerialization.jsonObject(with: functionData) as? [String: Any],
                   let data = responseJson["data"] as? [[String: Any]],
                   let stockInfo = data.first {
                    
                    let currentPrice = stockInfo["current_price"] as? Double ?? 0.0
                    let dailyChange = stockInfo["daily_change"] as? Double ?? 0.0
                    let dailyChangePercent = stockInfo["daily_change_percent"] as? Double ?? 0.0
                    let volume = stockInfo["volume"] as? Int64 ?? 0
                    
                    print("✅ Fetched fresh stock data via Edge Function for \(symbol): price=\(currentPrice), change=\(dailyChange)")
                    
                    return Stock(
                        symbol: symbol.uppercased(),
                        companyName: "\(symbol) Corporation",
                        currentPrice: currentPrice,
                        dailyChange: dailyChange,
                        dailyChangePercent: dailyChangePercent,
                        marketCap: 0,
                        volume: volume,
                        peRatio: 0
                    )
                }
            }
            
            throw SupabaseError.invalidResponse
        } catch {
            print("❌ Error fetching stock data: \(error)")
            throw error
        }
    }
    
    func fetchSentimentData(symbol: String) async throws -> SentimentAnalysis {
        guard let supabaseURL = supabaseURL,
              let supabaseAnonKey = supabaseAnonKey else {
            throw SupabaseError.networkError
        }
        
        do {
            // First try to get from our database
            let url = URL(string: "\(supabaseURL)/rest/v1/sentiment_analysis?symbol=eq.\(symbol.uppercased())")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   let sentimentData = jsonArray.first {
                    
                    let overallRating = SentimentAnalysis.SentimentRating(rawValue: sentimentData["overall_rating"] as? String ?? "neutral") ?? .neutral
                    let score = sentimentData["score"] as? Double ?? 0.0
                    let confidence = sentimentData["confidence"] as? Double ?? 0.0
                    let keyDrivers = sentimentData["key_drivers"] as? [String] ?? []
                    
                    let breakdown = SentimentBreakdown(
                        newsPositive: sentimentData["news_positive"] as? Double ?? 0.0,
                        newsNegative: sentimentData["news_negative"] as? Double ?? 0.0,
                        newsNeutral: sentimentData["news_neutral"] as? Double ?? 0.0,
                        analystSentiment: sentimentData["analyst_sentiment"] as? Double ?? 0.0,
                        socialSentiment: sentimentData["social_sentiment"] as? Double ?? 0.0,
                        technicalIndicators: sentimentData["technical_indicators"] as? Double ?? 0.0
                    )
                    
                    return SentimentAnalysis(
                        symbol: symbol.uppercased(),
                        overallRating: overallRating,
                        score: score,
                        keyDrivers: keyDrivers,
                        confidence: confidence,
                        lastUpdated: Date(),
                        breakdown: breakdown
                    )
                }
            }
            
            // If not in database, fetch from Edge Function
            print("🔄 Fetching sentiment data for \(symbol) via Edge Function")
            
            let functionURL = URL(string: "\(supabaseURL)/functions/v1/fetch-sentiment-data")!
            var functionRequest = URLRequest(url: functionURL)
            functionRequest.httpMethod = "POST"
            functionRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            functionRequest.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            
            let functionBody = ["symbol": symbol]
            functionRequest.httpBody = try JSONSerialization.data(withJSONObject: functionBody)
            
            let (functionData, functionResponse) = try await URLSession.shared.data(for: functionRequest)
            
            guard let functionHttpResponse = functionResponse as? HTTPURLResponse else {
                throw SupabaseError.networkError
            }
            
            if functionHttpResponse.statusCode == 200 {
                if let responseJson = try JSONSerialization.jsonObject(with: functionData) as? [String: Any],
                   let data = responseJson["data"] as? [String: Any] {
                    
                    let overallRating = SentimentAnalysis.SentimentRating(rawValue: data["overall_rating"] as? String ?? "neutral") ?? .neutral
                    let score = data["score"] as? Double ?? 0.0
                    let confidence = data["confidence"] as? Double ?? 0.0
                    let keyDrivers = data["key_drivers"] as? [String] ?? []
                    
                    let breakdown = SentimentBreakdown(
                        newsPositive: data["news_positive"] as? Double ?? 0.0,
                        newsNegative: data["news_negative"] as? Double ?? 0.0,
                        newsNeutral: data["news_neutral"] as? Double ?? 0.0,
                        analystSentiment: data["analyst_sentiment"] as? Double ?? 0.0,
                        socialSentiment: data["social_sentiment"] as? Double ?? 0.0,
                        technicalIndicators: data["technical_indicators"] as? Double ?? 0.0
                    )
                    
                    return SentimentAnalysis(
                        symbol: symbol.uppercased(),
                        overallRating: overallRating,
                        score: score,
                        keyDrivers: keyDrivers,
                        confidence: confidence,
                        lastUpdated: Date(),
                        breakdown: breakdown
                    )
                }
            }
            
            throw SupabaseError.invalidResponse
        } catch {
            print("❌ Error fetching sentiment data: \(error)")
            throw error
        }
    }
    
    func fetchNewsData(symbol: String) async throws -> [NewsItem] {
        guard let supabaseURL = supabaseURL,
              let supabaseAnonKey = supabaseAnonKey else {
            throw SupabaseError.networkError
        }
        
        do {
            let url = URL(string: "\(supabaseURL)/rest/v1/news_articles?symbol=eq.\(symbol.uppercased())&order=published_at.desc&limit=10")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    let newsItems = jsonArray.compactMap { row -> NewsItem? in
                        guard let title = row["title"] as? String,
                              let content = row["content"] as? String else {
                            return nil
                        }
                        
                        let category = NewsItem.NewsCategory(rawValue: row["category"] as? String ?? "general") ?? .general
                        let sentiment = row["sentiment"] as? String ?? "neutral"
                        let imageUrl = row["image_url"] as? String
                        let relevanceScore = row["relevance_score"] as? Double ?? 0.0
                        
                        return NewsItem(
                            headline: title,
                            summary: content,
                            source: "ChartSense",
                            publishedAt: Date(),
                            url: "",
                            category: category,
                            sentiment: 0.5, // Convert string to double
                            relevanceScore: relevanceScore,
                            imageURL: imageUrl
                        )
                    }
                    
                    return newsItems
                }
            }
            
            // If not in database, return mock data for now
            print("ℹ️ No news data in database for \(symbol), returning mock data")
            return [
                NewsItem(
                    headline: "Market Update for \(symbol)",
                    summary: "Latest market analysis and trends for \(symbol) stock.",
                    source: "ChartSense",
                    publishedAt: Date(),
                    url: "",
                    category: .general,
                    sentiment: 0.5,
                    relevanceScore: 0.8,
                    imageURL: nil
                )
            ]
        } catch {
            print("❌ Error fetching news data: \(error)")
            throw error
        }
    }
    
    // MARK: - AI Chat
    
    func sendAIMessage(message: String) async throws -> ChatMessage {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        guard let supabaseURL = supabaseURL,
              let supabaseAnonKey = supabaseAnonKey else {
            throw SupabaseError.networkError
        }
        
        do {
            let functionURL = URL(string: "\(supabaseURL)/functions/v1/ai-chat")!
            var functionRequest = URLRequest(url: functionURL)
            functionRequest.httpMethod = "POST"
            functionRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            functionRequest.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            
            let functionBody = [
                "message": message,
                "userId": userId
            ]
            functionRequest.httpBody = try JSONSerialization.data(withJSONObject: functionBody)
            
            let (functionData, functionResponse) = try await URLSession.shared.data(for: functionRequest)
            
            guard let functionHttpResponse = functionResponse as? HTTPURLResponse else {
                throw SupabaseError.networkError
            }
            
            if functionHttpResponse.statusCode == 200 {
                if let responseJson = try JSONSerialization.jsonObject(with: functionData) as? [String: Any],
                   let content = responseJson["content"] as? String {
                    
                    let aiMessage = ChatMessage(
                        content: content,
                        isUser: false
                    )
                    
                    print("✅ AI message sent successfully")
                    return aiMessage
                }
            }
            
            throw SupabaseError.invalidResponse
        } catch {
            print("❌ Error sending AI message: \(error)")
            throw error
        }
    }
    
    // MARK: - Search History
    
    func addSearchHistory(symbol: String, companyName: String) async throws {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        guard let supabaseURL = supabaseURL,
              let supabaseAnonKey = supabaseAnonKey else {
            throw SupabaseError.networkError
        }
        
        do {
            let url = URL(string: "\(supabaseURL)/rest/v1/search_history")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            
            let body: [String: Any] = [
                "user_id": userId,
                "symbol": symbol.uppercased(),
                "company_name": companyName,
                "search_count": 1
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.networkError
            }
            
            if httpResponse.statusCode == 201 {
                print("✅ Added \(symbol) to search history")
            } else {
                throw SupabaseError.serverError("Failed to add search history: \(httpResponse.statusCode)")
            }
        } catch {
            print("❌ Error adding to search history: \(error)")
            throw error
        }
    }
    
    func getSearchHistory() async throws -> [SearchHistory] {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        guard let supabaseURL = supabaseURL,
              let supabaseAnonKey = supabaseAnonKey else {
            throw SupabaseError.networkError
        }
        
        do {
            let url = URL(string: "\(supabaseURL)/rest/v1/search_history?user_id=eq.\(userId)&order=last_searched_at.desc&limit=20")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    let searchHistory = jsonArray.compactMap { row -> SearchHistory? in
                        guard let symbol = row["symbol"] as? String,
                              let companyName = row["company_name"] as? String else {
                            return nil
                        }
                        
                        let searchCount = row["search_count"] as? Int ?? 1
                        
                        let searchHistory = SearchHistory(symbol: symbol, companyName: companyName)
                        // Update the search count
                        for _ in 1..<searchCount {
                            searchHistory.incrementSearchCount()
                        }
                        
                        return searchHistory
                    }
                    
                    print("✅ Retrieved \(searchHistory.count) search history items")
                    return searchHistory
                }
            }
            
            throw SupabaseError.serverError("Failed to get search history: \(httpResponse.statusCode)")
        } catch {
            print("❌ Error getting search history: \(error)")
            throw error
        }
    }
    
    // MARK: - User Profile Management
    
    private func ensureUserProfileExists(userId: String) async throws {
        guard let supabaseURL = supabaseURL,
              let accessToken = accessToken else {
            throw SupabaseError.networkError
        }
        
        do {
            // Check if user profile exists
            let url = URL(string: "\(supabaseURL)/rest/v1/user_profiles?id=eq.\(userId)")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   !jsonArray.isEmpty {
                    print("✅ User profile exists for \(userId)")
                    return
                }
            }
            
            // Profile doesn't exist, create it
            print("⚠️ User profile missing for \(userId), creating...")
            try await createUserProfile(userId: userId)
            
        } catch {
            print("❌ Error checking user profile: \(error)")
            throw error
        }
    }
    
    private func createUserProfile(userId: String) async throws {
        guard let supabaseURL = supabaseURL,
              let accessToken = accessToken,
              let currentUser = currentUser else {
            throw SupabaseError.networkError
        }
        
        do {
            let url = URL(string: "\(supabaseURL)/rest/v1/user_profiles")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            
            let body: [String: Any] = [
                "id": userId,
                "email": currentUser.email,
                "name": currentUser.name,
                "auth_provider": currentUser.authProvider.rawValue
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.networkError
            }
            
            if httpResponse.statusCode == 201 {
                print("✅ Created user profile for \(userId)")
                
                // Also create user preferences
                try await createUserPreferences(userId: userId)
                
                // Create home widgets
                try await createHomeWidgets(userId: userId)
                
            } else {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Error creating user profile: \(errorBody)")
                throw SupabaseError.serverError("Failed to create user profile: \(httpResponse.statusCode) - \(errorBody)")
            }
        } catch {
            print("❌ Error creating user profile: \(error)")
            throw error
        }
    }
    
    private func createUserPreferences(userId: String) async throws {
        guard let supabaseURL = supabaseURL,
              let accessToken = accessToken else {
            throw SupabaseError.networkError
        }
        
        do {
            let url = URL(string: "\(supabaseURL)/rest/v1/user_preferences")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            
            let body: [String: Any] = [
                "user_id": userId
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.networkError
            }
            
            if httpResponse.statusCode == 201 {
                print("✅ Created user preferences for \(userId)")
            } else {
                print("⚠️ Could not create user preferences for \(userId)")
            }
        } catch {
            print("⚠️ Error creating user preferences: \(error)")
        }
    }
    
    private func createHomeWidgets(userId: String) async throws {
        guard let supabaseURL = supabaseURL,
              let accessToken = accessToken else {
            throw SupabaseError.networkError
        }
        
        let widgets = [
            ["widget_type": "search", "widget_size": "large", "order_index": 1],
            ["widget_type": "watchlist", "widget_size": "medium", "order_index": 2],
            ["widget_type": "news", "widget_size": "medium", "order_index": 3],
            ["widget_type": "ai", "widget_size": "medium", "order_index": 4],
            ["widget_type": "market_overview", "widget_size": "small", "order_index": 5],
            ["widget_type": "trending_stocks", "widget_size": "small", "order_index": 6]
        ]
        
        for widget in widgets {
            do {
                let url = URL(string: "\(supabaseURL)/rest/v1/home_widgets")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
                
                var body = widget
                body["user_id"] = userId
                
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    continue
                }
                if httpResponse.statusCode == 201 {
                    print("✅ Created home widget \(widget["widget_type"] ?? "") for \(userId)")
                }
            } catch {
                print("⚠️ Error creating home widget: \(error)")
            }
        }
    }
    
    // MARK: - Stock Data
    
    func getAllStocks() async throws -> [Stock] {
        guard let supabaseURL = supabaseURL,
              let supabaseAnonKey = supabaseAnonKey else {
            throw SupabaseError.networkError
        }
        
        do {
            let url = URL(string: "\(supabaseURL)/rest/v1/stocks?select=*&is_active=eq.true&order=symbol.asc")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                if let stocksData = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    var stocks: [Stock] = []
                    
                    for stockData in stocksData {
                        if let symbol = stockData["symbol"] as? String,
                           let companyName = stockData["company_name"] as? String {
                            
                            // Create a basic Stock object with default values
                            // We'll fetch real-time data separately if needed
                            let stock = Stock(
                                symbol: symbol,
                                companyName: companyName,
                                currentPrice: 0.0, // Will be updated with real data
                                dailyChange: 0.0,
                                dailyChangePercent: 0.0
                            )
                            stocks.append(stock)
                        }
                    }
                    
                    print("✅ Fetched \(stocks.count) stocks from database")
                    return stocks
                } else {
                    throw SupabaseError.invalidResponse
                }
            } else {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Error fetching stocks: \(httpResponse.statusCode) - \(errorBody)")
                throw SupabaseError.serverError("Failed to fetch stocks: \(httpResponse.statusCode)")
            }
        } catch {
            print("❌ Error fetching stocks: \(error)")
            throw error
        }
    }
    
    // MARK: - Debug Configuration
    func debugConfiguration() {
        print("🔧 Supabase Configuration Debug:")
        print("   URL: \(supabaseURL)")
        if let anonKey = supabaseAnonKey {
            print("   Anon Key: \(String(anonKey.prefix(10)))...")
        } else {
            print("   Anon Key: Not configured")
        }
        print("   Current User: \(currentUser?.email ?? "None")")
        print("   Is Authenticated: \(isAuthenticated)")
    }
} 

// MARK: - Session persistence helpers
extension SupabaseService {
    private var kAccessTokenKey: String { "SupabaseAccessToken" }
    private var kRefreshTokenKey: String { "SupabaseRefreshToken" }
    private var kUserIdKey: String { "SupabaseUserId" }
    private var kUserEmailKey: String { "SupabaseUserEmail" }
    private var kUserNameKey: String { "SupabaseUserName" }

    private func saveSession(accessToken: String?, refreshToken: String?, userId: String?, email: String?, name: String?) {
        if let accessToken = accessToken { KeychainHelper.save(accessToken, for: kAccessTokenKey) }
        if let refreshToken = refreshToken { KeychainHelper.save(refreshToken, for: kRefreshTokenKey) }
        if let userId = userId { KeychainHelper.save(userId, for: kUserIdKey) }
        if let email = email { KeychainHelper.save(email, for: kUserEmailKey) }
        if let name = name { KeychainHelper.save(name, for: kUserNameKey) }
    }

    private func clearSession() {
        KeychainHelper.delete(kAccessTokenKey)
        KeychainHelper.delete(kRefreshTokenKey)
        KeychainHelper.delete(kUserIdKey)
        KeychainHelper.delete(kUserEmailKey)
        KeychainHelper.delete(kUserNameKey)
    }

    @MainActor
    private func restoreSession() async {
        if let storedAccess = KeychainHelper.read(kAccessTokenKey) {
            self.accessToken = storedAccess
            self.accessTokenExpiry = decodeJWTExpiry(storedAccess)
        }
        if let storedRefresh = KeychainHelper.read(kRefreshTokenKey) { self.refreshToken = storedRefresh }
        if let uid = KeychainHelper.read(kUserIdKey), let email = KeychainHelper.read(kUserEmailKey) {
            let name = KeychainHelper.read(kUserNameKey) ?? "User"
            self.currentUser = User(id: uid, email: email, name: name, authProvider: .email, createdAt: Date())
        }
        do {
            try await refreshAccessTokenIfNeeded()
            self.isAuthenticated = (self.accessToken != nil && self.currentUser != nil)
        } catch {
            print("❌ Failed to restore session: \(error)")
            clearSession()
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }

    private func decodeJWTExpiry(_ token: String?) -> Date? {
        guard let token = token else { return nil }
        let parts = token.split(separator: ".")
        guard parts.count > 1 else { return nil }
        var base64 = String(parts[1])
        let rem = base64.count % 4
        if rem > 0 { base64.append(String(repeating: "=", count: 4 - rem)) }
        let fixed = base64.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        guard let data = Data(base64Encoded: fixed),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = json["exp"] as? Double else { return nil }
        return Date(timeIntervalSince1970: exp)
    }

    @discardableResult
    private func refreshAccessTokenIfNeeded() async throws -> String? {
        guard let supabaseURL = supabaseURL, let anon = supabaseAnonKey else { return nil }
        let now = Date()
        let needsRefresh = accessToken == nil || (accessTokenExpiry ?? now).addingTimeInterval(-60) <= now
        guard needsRefresh, let refresh = refreshToken else { return accessToken }
        var req = URLRequest(url: URL(string: "\(supabaseURL)/auth/v1/token?grant_type=refresh_token")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(anon)", forHTTPHeaderField: "Authorization")
        req.setValue(anon, forHTTPHeaderField: "apikey")
        let body = ["refresh_token": refresh]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw SupabaseError.notAuthenticated }
        let newAccess = json["access_token"] as? String
        let newRefresh = json["refresh_token"] as? String ?? refresh
        self.accessToken = newAccess
        self.refreshToken = newRefresh
        self.accessTokenExpiry = decodeJWTExpiry(newAccess)
        saveSession(accessToken: newAccess, refreshToken: newRefresh, userId: KeychainHelper.read(kUserIdKey), email: KeychainHelper.read(kUserEmailKey), name: KeychainHelper.read(kUserNameKey))
        return newAccess
    }
}

fileprivate struct KeychainHelper {
    static func save(_ value: String, for key: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func read(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
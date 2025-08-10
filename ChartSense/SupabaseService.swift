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
        // Normalize and validate configuration
        let url = Config.supabaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = Config.supabaseAnonKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty, !key.isEmpty else {
            print("❌ Missing Supabase configuration (URL or Anon Key). Ensure `Config.plist` contains SUPABASE_URL and SUPABASE_ANON_KEY and is included in the app bundle.")
            return
        }

        supabaseURL = url
        supabaseAnonKey = key

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
    
    // MARK: - Watchlist Management (v2 schema)

    private func defaultWatchlistId() async throws -> String {
        // Ensure we have a fresh access token
        _ = try await refreshAccessTokenIfNeeded()
        guard let userId = currentUser?.id, let supabaseURL = supabaseURL, let accessToken = accessToken else { throw SupabaseError.notAuthenticated }
        // Find default
        if let url = URL(string: "\(supabaseURL)/rest/v1/watchlists?user_id=eq.\(userId)&is_default=eq.true&select=id&limit=1") {
            var req = URLRequest(url: url)
            req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            req.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            if let (data, resp) = try? await URLSession.shared.data(for: req), let http = resp as? HTTPURLResponse, http.statusCode == 200,
               let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]], let row = arr.first, let id = row["id"] as? String { return id }
        }
        // Create default (return id)
        let createURL = URL(string: "\(supabaseURL)/rest/v1/watchlists?select=id")!
        var createReq = URLRequest(url: createURL)
        createReq.httpMethod = "POST"
        createReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        createReq.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        createReq.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        createReq.setValue("return=representation", forHTTPHeaderField: "Prefer")
        let body: [String: Any] = ["user_id": userId, "name": "Watchlist", "is_default": true, "position": 0]
        createReq.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (d2, r2) = try await URLSession.shared.data(for: createReq)
        if let h2 = r2 as? HTTPURLResponse, (200...201).contains(h2.statusCode),
           let arr2 = try? JSONSerialization.jsonObject(with: d2) as? [[String: Any]], let id = arr2.first?["id"] as? String {
            return id
        }
        // Fallback: read it back
        if let url2 = URL(string: "\(supabaseURL)/rest/v1/watchlists?user_id=eq.\(userId)&is_default=eq.true&select=id&limit=1") {
            var req2 = URLRequest(url: url2)
            req2.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            req2.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            let (d3, r3) = try await URLSession.shared.data(for: req2)
            if let h3 = r3 as? HTTPURLResponse, h3.statusCode == 200,
               let arr3 = try? JSONSerialization.jsonObject(with: d3) as? [[String: Any]], let id = arr3.first?["id"] as? String {
                return id
            }
        }
        throw SupabaseError.serverError("Failed to create default watchlist")
    }

    func addToWatchlist(symbol: String, companyName: String, priceTarget: Double? = nil, notes: String? = nil, alertPrice: Double? = nil, alertType: String = "above") async throws {
        guard let supabaseURL = supabaseURL, let accessToken = accessToken else { throw SupabaseError.notAuthenticated }
        let wlId = try await defaultWatchlistId()
        // Ensure symbol exists with name
        if let url = URL(string: "\(supabaseURL)/rest/v1/symbols") {
            var up = URLRequest(url: url)
            up.httpMethod = "POST"
            up.setValue("application/json", forHTTPHeaderField: "Content-Type")
            up.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            up.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            up.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
            up.httpBody = try JSONSerialization.data(withJSONObject: [["symbol": symbol.uppercased(), "name": companyName]])
            _ = try? await URLSession.shared.data(for: up)
        }
        // Upsert item
        let url = URL(string: "\(supabaseURL)/rest/v1/watchlist_items")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        let body: [String: Any] = ["watchlist_id": wlId, "symbol": symbol.uppercased(), "position": 0]
        req.httpBody = try JSONSerialization.data(withJSONObject: [body])
        let (_, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...201).contains(http.statusCode) else {
            throw SupabaseError.serverError("Failed to add to watchlist")
        }
        try await incrementUsageTracking(featureType: "watchlist_add")
    }
    
    func removeFromWatchlist(symbol: String) async throws {
        guard let supabaseURL = supabaseURL, let accessToken = accessToken else { throw SupabaseError.notAuthenticated }
        let wlId = try await defaultWatchlistId()
        let url = URL(string: "\(supabaseURL)/rest/v1/watchlist_items?watchlist_id=eq.\(wlId)&symbol=eq.\(symbol.uppercased())")!
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        let (_, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 204 else { throw SupabaseError.serverError("Failed to remove from watchlist") }
    }
    
    func getWatchlist() async throws -> [WatchlistItem] {
        guard let supabaseURL = supabaseURL, let accessToken = accessToken else { throw SupabaseError.notAuthenticated }
        let wlId = try await defaultWatchlistId()
        // Join watchlist_items with symbols to get names
        let url = URL(string: "\(supabaseURL)/rest/v1/watchlist_items?watchlist_id=eq.\(wlId)&select=symbol,position,symbols!inner(name)&order=position.asc")!
        var req = URLRequest(url: url)
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let httpResp = resp as? HTTPURLResponse, httpResp.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            let status = (resp as? HTTPURLResponse)?.statusCode ?? -1
            print("❌ Get watchlist error response: \(body)")
            throw SupabaseError.serverError("Failed to get watchlist: \(status) - \(body)")
        }
        guard let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }
        let items: [WatchlistItem] = arr.compactMap { row in
            let symbol = (row["symbol"] as? String) ?? "?"
            let symObj = row["symbols"] as? [String: Any]
            let name = (symObj?["name"] as? String) ?? symbol
            return WatchlistItem(symbol: symbol, companyName: name)
        }
        print("✅ Retrieved \(items.count) watchlist items")
        return items
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
        let symbols = watchlistItems.map { $0.symbol }
        var itemsWithStock: [WatchlistItemWithStock] = []
        do {
            let qMap = try await fetchQuotesDisplayForSymbols(symbols)
            for item in watchlistItems {
                let key = item.symbol.uppercased()
                if let q = qMap[key] {
                    let stock = Stock(
                        symbol: item.symbol.uppercased(),
                        companyName: item.companyName,
                        currentPrice: q.price,
                        dailyChange: q.delta ?? 0,
                        dailyChangePercent: q.deltaPercent ?? 0
                    )
                    itemsWithStock.append(WatchlistItemWithStock(watchlistItem: item, stock: stock))
                } else {
                    itemsWithStock.append(WatchlistItemWithStock(watchlistItem: item, stock: nil))
                }
            }
        } catch {
            print("⚠️ Bulk quotes fetch failed, falling back per-symbol: \(error)")
            for item in watchlistItems {
                let stock = try? await fetchStockData(symbol: item.symbol)
                itemsWithStock.append(WatchlistItemWithStock(watchlistItem: item, stock: stock))
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
        // Use quotes_display for current price; fetch company name from symbols
        guard let supabaseURL = supabaseURL, let supabaseAnonKey = supabaseAnonKey else { throw SupabaseError.networkError }
        // Price
        let priceTuple = try await fetchQuoteDisplay(symbol: symbol)
        // Name
        var companyName = symbol.uppercased()
        if let url = URL(string: "\(supabaseURL)/rest/v1/symbols?symbol=eq.\(symbol.uppercased())&select=name") {
            var req = URLRequest(url: url)
            req.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            if let (data, resp) = try? await URLSession.shared.data(for: req), let http = resp as? HTTPURLResponse, http.statusCode == 200, let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]], let row = arr.first, let name = row["name"] as? String, !name.isEmpty {
                companyName = name
            }
        }
        return Stock(
            symbol: symbol.uppercased(),
            companyName: companyName,
            currentPrice: priceTuple.price,
            dailyChange: priceTuple.delta ?? 0,
            dailyChangePercent: priceTuple.deltaPercent ?? 0,
            marketCap: nil,
            volume: nil,
            peRatio: nil
        )
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
        guard currentUser?.id != nil else { throw SupabaseError.notAuthenticated }
        guard let supabaseURL = supabaseURL else {
            throw SupabaseError.networkError
        }
        
        do {
            let functionURL = URL(string: "\(supabaseURL)/functions/v1/ai-chat")!
            var functionRequest = URLRequest(url: functionURL)
            functionRequest.httpMethod = "POST"
            functionRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            // Use user access token so the function can enforce per-user limits
            if let accessToken = self.accessToken {
                functionRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            }
            
            let functionBody = [
                "message": message,
                // user inferred from auth header by function
            ]
            functionRequest.httpBody = try JSONSerialization.data(withJSONObject: functionBody)
            
            let (functionData, functionResponse) = try await URLSession.shared.data(for: functionRequest)
            
            guard let functionHttpResponse = functionResponse as? HTTPURLResponse else {
                throw SupabaseError.networkError
            }
            
            if functionHttpResponse.statusCode == 200 {
                if let responseJson = try JSONSerialization.jsonObject(with: functionData) as? [String: Any],
                   let content = (responseJson["reply"] as? String) ?? (responseJson["content"] as? String) {
                    
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

    // MARK: - Market Data (Supabase)

    func fetchQuoteDisplay(symbol: String) async throws -> (price: Double, session: String, delta: Double?, deltaPercent: Double?, ts: Date) {
        guard let supabaseURL = supabaseURL,
              let supabaseAnonKey = supabaseAnonKey else { throw SupabaseError.networkError }

        // Primary path: quotes_display view (if present)
        if let viewURL = URL(string: "\(supabaseURL)/rest/v1/quotes_display?symbol=eq.\(symbol.uppercased())") {
            var req = URLRequest(url: viewURL)
            req.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            req.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            if let (data, resp) = try? await URLSession.shared.data(for: req),
               let http = resp as? HTTPURLResponse, http.statusCode == 200,
               let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let row = arr.first {
                let price = row["display_price"] as? Double ?? row["price"] as? Double ?? 0
                let session = (row["session"] as? String) ?? "unknown"
                let tsStr = (row["display_ts"] as? String) ?? (row["ts"] as? String) ?? ISO8601DateFormatter().string(from: Date())
                let ts = ISO8601DateFormatter().date(from: tsStr) ?? Date()
                let prev = row["previous_close"] as? Double
                let deltaServer = row["display_change"] as? Double
                let deltaPctServer = row["display_change_percent"] as? Double
                let delta = deltaServer ?? ((prev != nil) ? (price - prev!) : nil)
                let deltaPct = deltaPctServer ?? ((prev != nil && prev! != 0) ? ((price - prev!) / prev! * 100.0) : nil)
                return (price, session, delta, deltaPct, ts)
            }
        }

        // Fallback: direct read from quotes_latest
        let url = URL(string: "\(supabaseURL)/rest/v1/quotes_latest?symbol=eq.\(symbol.uppercased())&select=price,ts,previous_close,extended_price,extended_ts,premarket_price,premarket_ts,session")!
        var req = URLRequest(url: url)
        // Public read: use anon apikey only
        req.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200,
              let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]], let row = arr.first else {
            throw SupabaseError.invalidResponse
        }

        let session = (row["session"] as? String) ?? "unknown"
        let priceRegular = row["price"] as? Double
        let priceExt = row["extended_price"] as? Double
        let pricePre = row["premarket_price"] as? Double
        let tsRegular = row["ts"] as? String
        let tsExt = row["extended_ts"] as? String
        let tsPre = row["premarket_ts"] as? String

        // Compute display price and timestamp following session if provided; otherwise prefer the most recent timestamp
        var displayPrice: Double? = nil
        var tsStr: String? = nil
        if session == "extended", let p = priceExt, let t = tsExt { displayPrice = p; tsStr = t }
        else if session == "premarket", let p = pricePre, let t = tsPre { displayPrice = p; tsStr = t }
        else if let p = priceRegular, let t = tsRegular { displayPrice = p; tsStr = t }

        // If no session-based selection, pick the latest by timestamp
        if displayPrice == nil {
            let candidates: [(Double?, String?)] = [ (priceRegular, tsRegular), (priceExt, tsExt), (pricePre, tsPre) ]
            let fmt = ISO8601DateFormatter()
            let best = candidates.compactMap { (p, t) -> (Double, String, Date)? in
                guard let p = p, let t = t, let d = fmt.date(from: t) else { return nil }
                return (p, t, d)
            }.sorted { $0.2 > $1.2 }.first
            if let best = best { displayPrice = best.0; tsStr = best.1 }
        }

        let price = displayPrice ?? (priceRegular ?? 0)
        let ts = ISO8601DateFormatter().date(from: tsStr ?? "") ?? Date()
        let prev = row["previous_close"] as? Double
        let delta = (prev != nil) ? (price - prev!) : nil
        let deltaPct = (prev != nil && prev! != 0) ? ((price - prev!) / prev! * 100.0) : nil
        return (price, session, delta, deltaPct, ts)
    }

    // Bulk: fetch quotes_display for many symbols at once for faster hydration
    func fetchQuotesDisplayForSymbols(_ symbols: [String]) async throws -> [String: (price: Double, delta: Double?, deltaPercent: Double?, ts: Date, session: String)] {
        guard let supabaseURL = supabaseURL,
              let supabaseAnonKey = supabaseAnonKey else { throw SupabaseError.networkError }
        let upper = Array(Set(symbols.map { $0.uppercased() })).sorted()
        guard !upper.isEmpty else { return [:] }
        let list = upper.joined(separator: ",")
        let urlString = "\(supabaseURL)/rest/v1/quotes_display?symbol=in.(\(list))"
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidResponse }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        req.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200,
              let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { throw SupabaseError.invalidResponse }
        var out: [String: (Double, Double?, Double?, Date, String)] = [:]
        let fmt = ISO8601DateFormatter()
        for row in arr {
            guard let sym = (row["symbol"] as? String)?.uppercased() else { continue }
            let price = row["display_price"] as? Double ?? row["price"] as? Double ?? 0
            let session = (row["session"] as? String) ?? "unknown"
            let tsStr = (row["display_ts"] as? String) ?? (row["ts"] as? String)
            let ts = (tsStr != nil ? fmt.date(from: tsStr!) : nil) ?? Date()
            let deltaServer = row["display_change"] as? Double
            let deltaPctServer = row["display_change_percent"] as? Double
            let prev = row["previous_close"] as? Double
            let delta = deltaServer ?? ((prev != nil) ? (price - prev!) : nil)
            let deltaPct = deltaPctServer ?? ((prev != nil && prev! != 0) ? ((price - prev!) / prev! * 100.0) : nil)
            out[sym] = (price, delta, deltaPct, ts, session)
        }
        return out
    }

    func fetchCandles5m(symbol: String, hoursBack: Int = 24) async throws -> [(Date, Double)] {
        guard let supabaseURL = supabaseURL, let supabaseAnonKey = supabaseAnonKey else { throw SupabaseError.networkError }
        let fromISO: String = ISO8601DateFormatter().string(from: Date().addingTimeInterval(Double(-hoursBack) * 3600))
        let url = URL(string: "\(supabaseURL)/rest/v1/candles_5m?symbol=eq.\(symbol.uppercased())&ts=gt.\(fromISO)&select=ts,close&order=ts.asc")!
        var req = URLRequest(url: url)
        // RLS on candles requires authenticated role; use user token when available
        if let token = self.accessToken { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        req.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200,
              let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { throw SupabaseError.invalidResponse }
        let iso = ISO8601DateFormatter()
        return arr.compactMap { row in
            guard let tsStr = row["ts"] as? String, let close = row["close"] as? Double, let d = iso.date(from: tsStr) else { return nil }
            return (d, close)
        }
    }

    func fetchCandles1d(symbol: String, daysBack: Int = 365) async throws -> [(Date, Double)] {
        guard let supabaseURL = supabaseURL, let supabaseAnonKey = supabaseAnonKey else { throw SupabaseError.networkError }
        let fromDate = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date().addingTimeInterval(-365*86400)
        let dayStr = ISO8601DateFormatter().string(from: fromDate).prefix(10)
        let url = URL(string: "\(supabaseURL)/rest/v1/candles_1d?symbol=eq.\(symbol.uppercased())&day=gt.\(dayStr)&select=day,close&order=day.asc")!
        var req = URLRequest(url: url)
        if let token = self.accessToken { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        req.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200,
              let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { throw SupabaseError.invalidResponse }
        let df = ISO8601DateFormatter()
        return arr.compactMap { row in
            guard let dayStr = row["day"] as? String, let close = row["close"] as? Double, let d = df.date(from: dayStr + "T00:00:00Z") else { return nil }
            return (d, close)
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
        guard let supabaseURL = supabaseURL, let supabaseAnonKey = supabaseAnonKey else {
            throw SupabaseError.networkError
        }
        do {
            let url = URL(string: "\(supabaseURL)/rest/v1/symbols?select=symbol,name&order=symbol.asc")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let authHeader = (self.accessToken != nil) ? "Bearer \(self.accessToken!)" : "Bearer \(supabaseAnonKey)"
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw SupabaseError.networkError }
            if httpResponse.statusCode == 200 {
                guard let rows = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { throw SupabaseError.invalidResponse }
                let stocks: [Stock] = rows.compactMap { row in
                    guard let sym = row["symbol"] as? String else { return nil }
                    let name = (row["name"] as? String) ?? sym
                    return Stock(symbol: sym, companyName: name, currentPrice: 0.0, dailyChange: 0.0, dailyChangePercent: 0.0)
                }
                print("✅ Fetched \(stocks.count) symbols")
                return stocks
            } else {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Error fetching symbols: \(httpResponse.statusCode) - \(errorBody)")
                throw SupabaseError.serverError("Failed to fetch symbols: \(httpResponse.statusCode)")
            }
        } catch {
            print("❌ Error fetching symbols: \(error)")
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

// MARK: - Premium Helpers (best-effort, optional)
extension SupabaseService {
    /// Attempts to mark current user as free on the backend. If no premium
    /// state exists server-side, this call is harmless.
    static func tryMarkUserAsFree() async {
        let service = SupabaseService.shared
        guard let userId = service.currentUser?.id else { return }
        guard let supabaseURL = service.supabaseURL, let anonKey = service.supabaseAnonKey else { return }
        guard let url = URL(string: "\(supabaseURL)/rest/v1/user_profiles?id=eq.\(userId)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(anonKey, forHTTPHeaderField: "apikey")
        let body = ["is_premium": false]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse { print("🔎 tryMarkUserAsFree status: \(http.statusCode)") }
        } catch { print("⚠️ tryMarkUserAsFree failed: \(error)") }
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
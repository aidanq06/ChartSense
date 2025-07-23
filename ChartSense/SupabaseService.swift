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
    
    // Replace with your Supabase project URL and anon key
    private let supabaseURL = "YOUR_SUPABASE_URL"
    private let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"
    
    private var client: SupabaseClient?
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {
        setupSupabase()
        checkAuthenticationStatus()
    }
    
    private func setupSupabase() {
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseAnonKey
        )
    }
    
    // MARK: - Authentication
    func signUp(email: String, password: String, name: String) async throws {
        await MainActor.run { isLoading = true; errorMessage = nil }
        
        do {
            let response = try await client?.auth.signUp(
                email: email,
                password: password,
                data: ["name": name]
            )
            
            if let user = response?.user {
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
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        await MainActor.run { isLoading = true; errorMessage = nil }
        
        do {
            let response = try await client?.auth.signIn(
                email: email,
                password: password
            )
            
            if let user = response?.user {
                await MainActor.run {
                    self.currentUser = User(
                        id: user.id.uuidString,
                        email: user.email ?? "",
                        name: user.userMetadata?["name"] as? String ?? "User",
                        authProvider: .email,
                        createdAt: user.createdAt ?? Date()
                    )
                    self.isAuthenticated = true
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            throw error
        }
    }
    
    func signOut() async {
        do {
            try await client?.auth.signOut()
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
            }
        } catch {
            print("Sign out error: \(error)")
        }
    }
    
    private func checkAuthenticationStatus() {
        Task {
            do {
                let session = try await client?.auth.session
                if let user = session?.user {
                    await MainActor.run {
                        self.currentUser = User(
                            id: user.id.uuidString,
                            email: user.email ?? "",
                            name: user.userMetadata?["name"] as? String ?? "User",
                            authProvider: .email,
                            createdAt: user.createdAt ?? Date()
                        )
                        self.isAuthenticated = true
                    }
                }
            } catch {
                print("No active session")
            }
        }
    }
    
    // MARK: - Watchlist Management
    func addToWatchlist(symbol: String, companyName: String, priceTarget: Double? = nil) async throws {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        
        let watchlistItem = WatchlistItemDB(
            userId: userId,
            symbol: symbol.uppercased(),
            companyName: companyName,
            priceTarget: priceTarget,
            addedDate: Date()
        )
        
        try await client?.database
            .from("watchlist")
            .insert(watchlistItem)
            .execute()
    }
    
    func removeFromWatchlist(symbol: String) async throws {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        
        try await client?.database
            .from("watchlist")
            .delete()
            .eq("user_id", value: userId)
            .eq("symbol", value: symbol.uppercased())
            .execute()
    }
    
    func getWatchlist() async throws -> [WatchlistItem] {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        
        let response: [WatchlistItemDB] = try await client?.database
            .from("watchlist")
            .select()
            .eq("user_id", value: userId)
            .order("added_date", ascending: false)
            .execute()
            .value ?? []
        
        return response.map { $0.toWatchlistItem() }
    }
    
    // MARK: - Search History
    func addSearchHistory(symbol: String, companyName: String) async throws {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        
        let searchHistory = SearchHistoryDB(
            userId: userId,
            symbol: symbol.uppercased(),
            companyName: companyName,
            searchDate: Date()
        )
        
        try await client?.database
            .from("search_history")
            .upsert(searchHistory)
            .execute()
    }
    
    func getSearchHistory() async throws -> [SearchHistory] {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        
        let response: [SearchHistoryDB] = try await client?.database
            .from("search_history")
            .select()
            .eq("user_id", value: userId)
            .order("search_date", ascending: false)
            .limit(50)
            .execute()
            .value ?? []
        
        return response.map { $0.toSearchHistory() }
    }
    
    // MARK: - User Preferences
    func saveUserPreferences(preferences: UserPreferences) async throws {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        
        let userPrefs = UserPreferencesDB(
            userId: userId,
            isDarkMode: preferences.isDarkMode,
            notificationsEnabled: preferences.notificationsEnabled,
            priceAlertsEnabled: preferences.priceAlertsEnabled,
            newsAlertsEnabled: preferences.newsAlertsEnabled,
            refreshInterval: preferences.refreshInterval,
            defaultView: preferences.defaultView
        )
        
        try await client?.database
            .from("user_preferences")
            .upsert(userPrefs)
            .execute()
    }
    
    func getUserPreferences() async throws -> UserPreferences? {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        
        let response: [UserPreferencesDB] = try await client?.database
            .from("user_preferences")
            .select()
            .eq("user_id", value: userId)
            .limit(1)
            .execute()
            .value ?? []
        
        return response.first?.toUserPreferences()
    }
    
    // MARK: - Real-time Subscriptions
    func subscribeToWatchlistUpdates() -> RealtimeChannel {
        guard let userId = currentUser?.id else { 
            fatalError("User must be authenticated to subscribe")
        }
        
        return client?.realtime
            .channel("watchlist_updates")
            .on("postgres_changes", filter: .init(event: .all, schema: "public", table: "watchlist")) { payload in
                // Handle watchlist updates
                print("Watchlist updated: \(payload)")
            }
            .subscribe() ?? RealtimeChannel()
    }
    
    // MARK: - Financial Data Proxy (Edge Function)
    func fetchStockData(symbol: String) async throws -> Stock {
        let response: StockResponse = try await client?.functions
            .invoke("fetch-stock-data", invokeOptions: .init(body: ["symbol": symbol]))
            .value ?? StockResponse()
        
        return response.toStock()
    }
    
    func fetchSentimentData(symbol: String) async throws -> SentimentAnalysis {
        let response: SentimentResponse = try await client?.functions
            .invoke("fetch-sentiment-data", invokeOptions: .init(body: ["symbol": symbol]))
            .value ?? SentimentResponse()
        
        return response.toSentimentAnalysis()
    }
    
    func fetchNewsData(symbol: String) async throws -> [NewsItem] {
        let response: [NewsResponse] = try await client?.functions
            .invoke("fetch-news-data", invokeOptions: .init(body: ["symbol": symbol]))
            .value ?? []
        
        return response.map { $0.toNewsItem() }
    }
    
    // MARK: - Push Notifications
    func registerForPushNotifications(deviceToken: String) async throws {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        
        let device = DeviceTokenDB(
            userId: userId,
            deviceToken: deviceToken,
            platform: "ios",
            registeredAt: Date()
        )
        
        try await client?.database
            .from("device_tokens")
            .upsert(device)
            .execute()
    }
    
    func createPriceAlert(symbol: String, targetPrice: Double, isAbove: Bool) async throws {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        
        let alert = PriceAlertDB(
            userId: userId,
            symbol: symbol.uppercased(),
            targetPrice: targetPrice,
            isAbove: isAbove,
            isActive: true,
            createdAt: Date()
        )
        
        try await client?.database
            .from("price_alerts")
            .insert(alert)
            .execute()
    }
}

// MARK: - Database Models
struct WatchlistItemDB: Codable {
    let id: UUID?
    let userId: String
    let symbol: String
    let companyName: String
    let priceTarget: Double?
    let alertsEnabled: Bool
    let addedDate: Date
    
    enum CodingKeys: String, CodingKey {
        case id, symbol, companyName, priceTarget, alertsEnabled, addedDate
        case userId = "user_id"
    }
    
    func toWatchlistItem() -> WatchlistItem {
        return WatchlistItem(
            symbol: symbol,
            companyName: companyName,
            alertsEnabled: alertsEnabled,
            priceTarget: priceTarget
        )
    }
}

struct SearchHistoryDB: Codable {
    let id: UUID?
    let userId: String
    let symbol: String
    let companyName: String
    let searchDate: Date
    let searchCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id, symbol, companyName, searchDate, searchCount
        case userId = "user_id"
    }
    
    func toSearchHistory() -> SearchHistory {
        let history = SearchHistory(symbol: symbol, companyName: companyName)
        // Note: searchCount would need to be updated in the database
        return history
    }
}

struct UserPreferencesDB: Codable {
    let id: UUID?
    let userId: String
    let isDarkMode: Bool
    let notificationsEnabled: Bool
    let priceAlertsEnabled: Bool
    let newsAlertsEnabled: Bool
    let refreshInterval: String
    let defaultView: String
    
    enum CodingKeys: String, CodingKey {
        case id, isDarkMode, notificationsEnabled, priceAlertsEnabled, newsAlertsEnabled, refreshInterval, defaultView
        case userId = "user_id"
    }
    
    func toUserPreferences() -> UserPreferences {
        return UserPreferences(
            isDarkMode: isDarkMode,
            notificationsEnabled: notificationsEnabled,
            priceAlertsEnabled: priceAlertsEnabled,
            newsAlertsEnabled: newsAlertsEnabled,
            refreshInterval: refreshInterval,
            defaultView: defaultView
        )
    }
}

struct DeviceTokenDB: Codable {
    let id: UUID?
    let userId: String
    let deviceToken: String
    let platform: String
    let registeredAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, deviceToken, platform, registeredAt
        case userId = "user_id"
    }
}

struct PriceAlertDB: Codable {
    let id: UUID?
    let userId: String
    let symbol: String
    let targetPrice: Double
    let isAbove: Bool
    let isActive: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, symbol, targetPrice, isAbove, isActive, createdAt
        case userId = "user_id"
    }
}

// MARK: - API Response Models
struct StockResponse: Codable {
    let symbol: String?
    let companyName: String?
    let currentPrice: Double?
    let dailyChange: Double?
    let dailyChangePercent: Double?
    let marketCap: Double?
    let volume: Int64?
    let peRatio: Double?
    
    func toStock() -> Stock {
        return Stock(
            symbol: symbol ?? "",
            companyName: companyName ?? "",
            currentPrice: currentPrice ?? 0.0,
            dailyChange: dailyChange ?? 0.0,
            dailyChangePercent: dailyChangePercent ?? 0.0,
            marketCap: marketCap,
            volume: volume,
            peRatio: peRatio
        )
    }
}

struct SentimentResponse: Codable {
    let symbol: String?
    let overallRating: String?
    let score: Double?
    let confidence: Double?
    
    func toSentimentAnalysis() -> SentimentAnalysis {
        let rating = SentimentAnalysis.SentimentRating(rawValue: overallRating ?? "neutral") ?? .neutral
        return SentimentAnalysis(
            symbol: symbol ?? "",
            overallRating: rating,
            score: score ?? 0.0,
            keyDrivers: [],
            confidence: confidence ?? 0.0,
            lastUpdated: Date(),
            breakdown: SentimentBreakdown(
                newsPositive: 0.0,
                newsNegative: 0.0,
                newsNeutral: 0.0,
                analystSentiment: 0.0,
                socialSentiment: 0.0,
                technicalIndicators: 0.0
            )
        )
    }
}

struct NewsResponse: Codable {
    let headline: String?
    let summary: String?
    let source: String?
    let publishedAt: Date?
    let url: String?
    let category: String?
    let sentiment: Double?
    
    func toNewsItem() -> NewsItem {
        return NewsItem(
            headline: headline ?? "",
            summary: summary ?? "",
            source: source ?? "",
            publishedAt: publishedAt ?? Date(),
            url: url ?? "",
            category: NewsItem.NewsCategory(rawValue: category ?? "general") ?? .general,
            sentiment: sentiment ?? 0.0,
            relevanceScore: 0.0,
            imageURL: nil
        )
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
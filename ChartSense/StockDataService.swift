import Foundation
import Combine

// MARK: - Stock Data Service
class StockDataService: ObservableObject {
    static let shared = StockDataService()
    
    // Supabase-backed data source; Finnhub no longer called from device
    private let supabase = SupabaseService.shared
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Enhanced cache for stock data
    private var stockCache: [String: (data: Stock, timestamp: Date)] = [:]
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes for better performance
    
    // Cache statistics
    private var cacheHits = 0
    private var cacheMisses = 0
    
    private init() {
        print("📈 Initializing StockDataService...")
        startBackgroundRefresh()
    }
    
    private func validateAPIKey() { /* no-op: using Supabase */ }
    
    // MARK: - Public Methods
    
    func fetchStockData(symbol: String) async throws -> Stock {
        // Check cache first
        if let cachedData = getCachedStockData(for: symbol) {
            print("📦 Using cached data for \(symbol)")
            return cachedData
        }
        
        print("🌐 Fetching real data for \(symbol) from Supabase...")
        let stock = try await fetchStockFromSupabase(symbol)
        
        // Cache the result
        cacheStockData(stock, for: symbol)
        
        return stock
    }
    
    func fetchMultipleStocks(symbols: [String]) async throws -> [Stock] {
        print("🌐 Fetching data for multiple stocks: \(symbols)")
        
        // Use concurrent requests for better performance
        return try await fetchStocksConcurrent(symbols: symbols)
    }
    
    private func fetchStocksConcurrent(symbols: [String]) async throws -> [Stock] {
        print("⚡ Using concurrent requests for \(symbols.count) stocks")
        
        var stocks: [Stock] = []
        
        // Use TaskGroup for concurrent requests with rate limiting
        try await withThrowingTaskGroup(of: (Int, Stock).self) { group in
            // Add tasks with staggered start times to avoid rate limits
            for (index, symbol) in symbols.enumerated() {
                group.addTask {
                    // Stagger requests by 200ms to avoid rate limits
                    if index > 0 {
                        try await Task.sleep(nanoseconds: UInt64(index) * 200_000_000) // 200ms * index
                    }
                    
                    let stock = try await self.fetchStockData(symbol: symbol)
                    print("✅ Successfully fetched \(symbol)")
                    return (index, stock)
                }
            }
            
            // Collect results
            var results: [(Int, Stock)] = []
            for try await result in group {
                results.append(result)
            }
            
            // Sort by index and extract stocks
            stocks = results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
        
        return stocks
    }
    

    
    // MARK: - Private Methods
    
    private func fetchStockFromSupabase(_ symbol: String) async throws -> Stock {
        let display = try await supabase.fetchQuoteDisplay(symbol: symbol)
        // Try to get company name from symbols table
        var companyName = "\(symbol.uppercased())"
        let supabaseURL = Config.supabaseURL
        let anon = Config.supabaseAnonKey
        if let url = URL(string: "\(supabaseURL)/rest/v1/symbols?symbol=eq.\(symbol.uppercased())&select=name") {
            var req = URLRequest(url: url)
            req.setValue("Bearer \(anon)", forHTTPHeaderField: "Authorization")
            req.setValue(anon, forHTTPHeaderField: "apikey")
            if let (data, resp) = try? await URLSession.shared.data(for: req), let http = resp as? HTTPURLResponse, http.statusCode == 200, let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]], let row = arr.first, let name = row["name"] as? String, !name.isEmpty {
                companyName = name
            }
        }
        let dailyChange = display.delta ?? 0
        let dailyChangePercent = display.deltaPercent ?? 0
        return Stock(
            symbol: symbol.uppercased(),
            companyName: companyName,
            currentPrice: display.price,
            dailyChange: dailyChange,
            dailyChangePercent: dailyChangePercent,
            marketCap: nil,
            volume: nil,
            peRatio: nil
        )
    }
    
    private func getCachedStockData(for symbol: String) -> Stock? {
        guard let cached = stockCache[symbol.uppercased()] else { 
            cacheMisses += 1
            return nil 
        }
        
        let age = Date().timeIntervalSince(cached.timestamp)
        if age < cacheValidityDuration {
            cacheHits += 1
            print("📦 Cache HIT for \(symbol) (age: \(Int(age))s)")
            return cached.data
        } else {
            // Remove expired cache
            stockCache.removeValue(forKey: symbol.uppercased())
            cacheMisses += 1
            print("📦 Cache MISS for \(symbol) (expired: \(Int(age))s)")
            return nil
        }
    }
    
    private func cacheStockData(_ stock: Stock, for symbol: String) {
        stockCache[symbol.uppercased()] = (data: stock, timestamp: Date())
        print("💾 Cached data for \(symbol)")
    }
    

    
    // MARK: - Background Refresh
    
    private func startBackgroundRefresh() {
        // Refresh popular stocks every 5 minutes in background
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task {
                await self.refreshPopularStocksInBackground()
            }
        }
    }
    
    private func refreshPopularStocksInBackground() async {
        print("🔄 Background refresh started")
        let popularSymbols = ["AAPL", "TSLA", "GOOGL", "MSFT", "NVDA"]
        
        do {
            _ = try await fetchMultipleStocks(symbols: popularSymbols)
            print("✅ Background refresh completed")
        } catch {
            print("❌ Background refresh failed: \(error)")
        }
    }
    
    // MARK: - Cache Statistics
    
    func getCacheStatistics() -> (hits: Int, misses: Int, hitRate: Double) {
        let total = cacheHits + cacheMisses
        let hitRate = total > 0 ? Double(cacheHits) / Double(total) : 0.0
        return (hits: cacheHits, misses: cacheMisses, hitRate: hitRate)
    }
    
    func clearCache() {
        stockCache.removeAll()
        cacheHits = 0
        cacheMisses = 0
        print("🗑️ Cache cleared")
    }
    
    // MARK: - Cache Warming
    
    func warmCache() async {
        print("🔥 Warming cache with popular stocks...")
        let popularSymbols = ["AAPL", "TSLA", "GOOGL", "MSFT", "NVDA"]
        
        do {
            _ = try await fetchMultipleStocks(symbols: popularSymbols)
            print("🔥 Cache warming completed")
        } catch {
            print("❌ Cache warming failed: \(error)")
        }
    }
    
    func getCacheInfo() -> String {
        let stats = getCacheStatistics()
        return "Cache: \(stockCache.count) items, \(Int(stats.hitRate * 100))% hit rate (\(stats.hits)/\(stats.hits + stats.misses))"
    }
}

// MARK: - Finnhub API Response Models
// Finnhub response structs removed; device no longer calls Finnhub directly

// MARK: - Errors
enum StockDataError: Error, LocalizedError {
    case apiKeyNotConfigured
    case invalidURL
    case invalidResponse
    case rateLimitExceeded
    case apiError(Int)
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "Finnhub API key not configured"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .rateLimitExceeded:
            return "API rate limit exceeded"
        case .apiError(let code):
            return "API error: \(code)"
        }
    }
} 
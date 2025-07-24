import Foundation
import Combine

// MARK: - Stock Data Service
class StockDataService: ObservableObject {
    static let shared = StockDataService()
    
    private let apiKey = Config.finnhubAPIKey
    private let baseURL = "https://finnhub.io/api/v1"
    
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
        validateAPIKey()
        startBackgroundRefresh()
    }
    
    private func validateAPIKey() {
        if apiKey.isEmpty || apiKey == "YOUR_FINNHUB_API_KEY_HERE" {
            print("❌ Finnhub API key not configured!")
            print("💡 Please add your Finnhub API key to Config.plist")
        } else {
            print("✅ Finnhub API key configured")
        }
    }
    
    // MARK: - Public Methods
    
    func fetchStockData(symbol: String) async throws -> Stock {
        // Check cache first
        if let cachedData = getCachedStockData(for: symbol) {
            print("📦 Using cached data for \(symbol)")
            return cachedData
        }
        
        print("🌐 Fetching real data for \(symbol) from Finnhub...")
        
        // Make API call
        let stock = try await fetchStockFromAPI(symbol)
        
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
    
    private func fetchStockFromAPI(_ symbol: String) async throws -> Stock {
        guard !apiKey.isEmpty && apiKey != "YOUR_FINNHUB_API_KEY_HERE" else {
            throw StockDataError.apiKeyNotConfigured
        }
        
        let urlString = "\(baseURL)/quote?symbol=\(symbol.uppercased())&token=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw StockDataError.invalidURL
        }
        
        print("🔗 Making API call to: \(urlString)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StockDataError.invalidResponse
        }
        
        print("📊 API Response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 429 {
            print("⚠️ Rate limit exceeded, waiting 2 seconds before retry...")
            try await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds
            throw StockDataError.rateLimitExceeded
        }
        
        if httpResponse.statusCode != 200 {
            print("❌ API Error: \(String(data: data, encoding: .utf8) ?? "unknown")")
            throw StockDataError.apiError(httpResponse.statusCode)
        }
        
        // Parse the response
        let finnhubResponse = try JSONDecoder().decode(FinnhubQuoteResponse.self, from: data)
        
        // Convert to our Stock model
        return Stock(
            symbol: symbol.uppercased(),
            companyName: "\(symbol.uppercased()) Corporation", // We'll get real company names later
            currentPrice: finnhubResponse.c,
            dailyChange: finnhubResponse.d,
            dailyChangePercent: finnhubResponse.dp,
            marketCap: 0, // Not available in basic quote
            volume: Int64(finnhubResponse.v ?? 0),
            peRatio: 0 // Not available in basic quote
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
struct FinnhubQuoteResponse: Codable {
    let c: Double      // Current price
    let d: Double      // Change
    let dp: Double     // Percent change
    let h: Double      // High price of the day
    let l: Double      // Low price of the day
    let o: Double      // Open price of the day
    let pc: Double     // Previous close price
    let v: Int?        // Volume (optional)
}

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
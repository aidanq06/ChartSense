import Foundation
import Combine

// MARK: - Async Sequence Extensions
extension Sequence {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var results = [T]()
        for element in self {
            results.append(try await transform(element))
        }
        return results
    }
}

// MARK: - Stock Data Service
class StockDataService: ObservableObject {
    static let shared = StockDataService()
    
    private let apiKey = Config.finnhubAPIKey
    private let baseURL = "https://finnhub.io/api/v1"
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Simple cache for stock data
    private var stockCache: [String: (data: Stock, timestamp: Date)] = [:]
    private let cacheValidityDuration: TimeInterval = 30 // 30 seconds
    
    private init() {
        print("📈 Initializing StockDataService...")
        validateAPIKey()
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
        try await withThrowingTaskGroup(of: Stock.self) { group in
            // Add tasks with staggered start times to avoid rate limits
            for (index, symbol) in symbols.enumerated() {
                group.addTask {
                    // Stagger requests by 200ms to avoid rate limits
                    if index > 0 {
                        try await Task.sleep(nanoseconds: UInt64(index) * 200_000_000) // 200ms * index
                    }
                    
                    let stock = try await self.fetchStockData(symbol: symbol)
                    print("✅ Successfully fetched \(symbol)")
                    return stock
                }
            }
            
            // Collect results in order
            for try await stock in group {
                stocks.append(stock)
            }
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
        guard let cached = stockCache[symbol.uppercased()] else { return nil }
        
        let age = Date().timeIntervalSince(cached.timestamp)
        if age < cacheValidityDuration {
            return cached.data
        } else {
            // Remove expired cache
            stockCache.removeValue(forKey: symbol.uppercased())
            return nil
        }
    }
    
    private func cacheStockData(_ stock: Stock, for symbol: String) {
        stockCache[symbol.uppercased()] = (data: stock, timestamp: Date())
        print("💾 Cached data for \(symbol)")
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
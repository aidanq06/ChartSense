//
//  Services.swift
//  ChartSense
//
//  Created by Aidan Quach on 7/22/25.
//

import Foundation
import SwiftUI

// MARK: - Stock Service
class StockService: ObservableObject {
    static let shared = StockService()
    
    @Published var currentStock: Stock?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // Mock stock data for popular stocks
    private let mockStocks: [String: Stock] = [
        "AAPL": Stock(symbol: "AAPL", companyName: "Apple Inc.", currentPrice: 178.85, dailyChange: 2.45, dailyChangePercent: 1.39, marketCap: 2.8e12, volume: 45_678_923, peRatio: 29.2),
        "TSLA": Stock(symbol: "TSLA", companyName: "Tesla, Inc.", currentPrice: 248.75, dailyChange: -4.20, dailyChangePercent: -1.66, marketCap: 7.9e11, volume: 89_234_567, peRatio: 45.8),
        "GOOGL": Stock(symbol: "GOOGL", companyName: "Alphabet Inc.", currentPrice: 142.65, dailyChange: 1.85, dailyChangePercent: 1.31, marketCap: 1.8e12, volume: 23_456_789, peRatio: 24.1),
        "MSFT": Stock(symbol: "MSFT", companyName: "Microsoft Corporation", currentPrice: 420.15, dailyChange: 5.60, dailyChangePercent: 1.35, marketCap: 3.1e12, volume: 34_567_890, peRatio: 32.7),
        "AMZN": Stock(symbol: "AMZN", companyName: "Amazon.com, Inc.", currentPrice: 156.92, dailyChange: -2.38, dailyChangePercent: -1.49, marketCap: 1.6e12, volume: 56_789_012, peRatio: 45.2),
        "NVDA": Stock(symbol: "NVDA", companyName: "NVIDIA Corporation", currentPrice: 875.30, dailyChange: 18.45, dailyChangePercent: 2.15, marketCap: 2.2e12, volume: 67_890_123, peRatio: 65.4),
        "META": Stock(symbol: "META", companyName: "Meta Platforms, Inc.", currentPrice: 485.20, dailyChange: -8.75, dailyChangePercent: -1.77, marketCap: 1.2e12, volume: 45_123_456, peRatio: 22.8),
        "NFLX": Stock(symbol: "NFLX", companyName: "Netflix, Inc.", currentPrice: 642.50, dailyChange: 12.30, dailyChangePercent: 1.95, marketCap: 2.8e11, volume: 12_345_678, peRatio: 35.6),
        "SPY": Stock(symbol: "SPY", companyName: "SPDR S&P 500 ETF Trust", currentPrice: 456.78, dailyChange: 1.23, dailyChangePercent: 0.27, volume: 78_901_234),
        "QQQ": Stock(symbol: "QQQ", companyName: "Invesco QQQ Trust", currentPrice: 389.45, dailyChange: 2.67, dailyChangePercent: 0.69, volume: 45_678_901)
    ]
    
    func searchStock(symbol: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        await MainActor.run {
            if let stock = mockStocks[symbol.uppercased()] {
                currentStock = stock
            } else {
                // Generate random stock data for unknown symbols
                let price = Double.random(in: 10...500)
                let change = Double.random(in: -20...20)
                let changePercent = (change / price) * 100
                
                currentStock = Stock(
                    symbol: symbol.uppercased(),
                    companyName: "\(symbol.uppercased()) Corporation",
                    currentPrice: price,
                    dailyChange: change,
                    dailyChangePercent: changePercent,
                    marketCap: Double.random(in: 1e9...1e12),
                    volume: Int64.random(in: 1_000_000...100_000_000),
                    peRatio: Double.random(in: 10...80)
                )
            }
            isLoading = false
        }
    }
    
    func getPopularStocks() -> [Stock] {
        return Array(mockStocks.values).sorted { $0.symbol < $1.symbol }
    }
    
    func updateStockPrices() {
        // Simulate real-time price updates
        for (_, stock) in mockStocks {
            let priceChange = Double.random(in: -0.5...0.5)
            stock.currentPrice += priceChange
            stock.dailyChange += priceChange
            stock.dailyChangePercent = (stock.dailyChange / (stock.currentPrice - stock.dailyChange)) * 100
            stock.lastUpdated = Date()
        }
    }
}

// MARK: - Sentiment Service
class SentimentService: ObservableObject {
    static let shared = SentimentService()
    
    @Published var currentSentiment: SentimentAnalysis?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    func getSentimentAnalysis(for symbol: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Simulate API delay
        try? await Task.sleep(nanoseconds: 800_000_000)
        
        await MainActor.run {
            currentSentiment = generateMockSentiment(for: symbol)
            isLoading = false
        }
    }
    
    private func generateMockSentiment(for _: String) -> SentimentAnalysis {
        let ratings = SentimentAnalysis.SentimentRating.allCases
        let randomRating = ratings.randomElement() ?? .neutral
        let score = generateSentimentScore(for: randomRating)
        
        let keyDrivers = generateKeyDrivers(for: randomRating)
        let breakdown = generateSentimentBreakdown()
        
        return SentimentAnalysis(
            symbol: "MOCK",
            overallRating: randomRating,
            score: score,
            keyDrivers: keyDrivers,
            confidence: Double.random(in: 0.7...0.95),
            lastUpdated: Date(),
            breakdown: breakdown
        )
    }
    
    private func generateSentimentScore(for rating: SentimentAnalysis.SentimentRating) -> Double {
        switch rating {
        case .stronglyBullish: return Double.random(in: 0.7...1.0)
        case .bullish: return Double.random(in: 0.4...0.7)
        case .cautiouslyOptimistic: return Double.random(in: 0.1...0.4)
        case .neutral: return Double.random(in: -0.1...0.1)
        case .bearishUndercurrents: return Double.random(in: -0.4...(-0.1))
        case .bearish: return Double.random(in: -0.7...(-0.4))
        case .highlyNegative: return Double.random(in: -1.0...(-0.7))
        }
    }
    
    private func generateKeyDrivers(for rating: SentimentAnalysis.SentimentRating) -> [String] {
        let positiveDrivers = [
            "Strong earnings beat with revenue up 15% YoY",
            "Positive analyst upgrades from major firms",
            "New product launches driving market excitement",
            "Expansion into emerging markets showing promise",
            "AI integration boosting operational efficiency"
        ]
        
        let negativeDrivers = [
            "Concerns about rising production costs",
            "Regulatory challenges in key markets",
            "Increased competition pressuring margins",
            "Supply chain disruptions affecting delivery",
            "Macroeconomic headwinds impacting demand"
        ]
        
        let neutralDrivers = [
            "Mixed earnings results with some bright spots",
            "Ongoing strategic transformation initiatives",
            "Market consolidation creating uncertainty",
            "Seasonal factors affecting performance",
            "Investor focus on long-term growth prospects"
        ]
        
        switch rating {
        case .stronglyBullish, .bullish, .cautiouslyOptimistic:
            return Array(positiveDrivers.shuffled().prefix(3))
        case .bearish, .highlyNegative, .bearishUndercurrents:
            return Array(negativeDrivers.shuffled().prefix(3))
        case .neutral:
            return Array(neutralDrivers.shuffled().prefix(2))
        }
    }
    
    private func generateSentimentBreakdown() -> SentimentBreakdown {
        let total = 1.0
        let positive = Double.random(in: 0.1...0.8)
        let negative = Double.random(in: 0.1...(total - positive))
        let neutral = total - positive - negative
        
        return SentimentBreakdown(
            newsPositive: positive,
            newsNegative: negative,
            newsNeutral: neutral,
            analystSentiment: Double.random(in: -1...1),
            socialSentiment: Double.random(in: -1...1),
            technicalIndicators: Double.random(in: -1...1)
        )
    }
}

// MARK: - News Service
class NewsService: ObservableObject {
    static let shared = NewsService()
    
    @Published var newsItems: [NewsItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    func fetchNews(for symbol: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 600_000_000)
        
        await MainActor.run {
            newsItems = generateMockNews(for: symbol)
            isLoading = false
        }
    }
    
    private func generateMockNews(for symbol: String) -> [NewsItem] {
        let categories = NewsItem.NewsCategory.allCases
        var news: [NewsItem] = []
        
        let headlines = generateHeadlines(for: symbol)
        let sources = ["Bloomberg", "Reuters", "CNBC", "MarketWatch", "Financial Times", "Wall Street Journal", "Yahoo Finance", "Benzinga", "TheStreet", "Barron's"]
        
        for _ in 0..<15 {
            let category = categories.randomElement() ?? .general
            let source = sources.randomElement() ?? "Financial News"
            let headline = headlines.randomElement() ?? "Market Update"
            let sentiment = Double.random(in: -0.8...0.8)
            
            let newsItem = NewsItem(
                headline: headline,
                summary: generateSummary(for: headline, category: category),
                source: source,
                publishedAt: Date().addingTimeInterval(-Double.random(in: 0...86400 * 7)), // Last 7 days
                url: "https://example.com/news/\(UUID().uuidString)",
                category: category,
                sentiment: sentiment,
                relevanceScore: Double.random(in: 0.5...1.0),
                imageURL: nil
            )
            
            news.append(newsItem)
        }
        
        return news.sorted { $0.publishedAt > $1.publishedAt }
    }
    
    private func generateHeadlines(for symbol: String) -> [String] {
        let company = symbol.uppercased()
        return [
            "\(company) Reports Strong Q4 Earnings, Beats Expectations",
            "\(company) Announces Major Product Launch for 2025",
            "Analysts Upgrade \(company) Price Target Following Recent Results",
            "\(company) CEO Discusses Future Growth Strategy",
            "\(company) Faces Regulatory Scrutiny Over Market Practices",
            "\(company) Stock Surges on Partnership Announcement",
            "\(company) Invests $2B in AI Research and Development",
            "\(company) Reports Supply Chain Improvements",
            "\(company) Expands International Operations",
            "Institutional Investors Increase \(company) Holdings",
            "\(company) Launches Sustainability Initiative",
            "\(company) Settles Legal Dispute, Shares Rise",
            "\(company) Technology Patent Approved",
            "\(company) Management Team Reshuffling Announced",
            "\(company) Dividend Increase Approved by Board"
        ]
    }
    
    private func generateSummary(for headline: String, category: NewsItem.NewsCategory) -> String {
        let summaries = [
            "The company's latest quarterly results exceeded analyst expectations, with revenue growth driven by strong demand in key market segments. Management provided optimistic guidance for the upcoming quarters.",
            "Strategic initiatives continue to show positive momentum as the company expands its market presence. Industry experts note the potential for significant long-term value creation.",
            "Recent developments indicate a shift in market dynamics that could benefit the company's competitive position. Analysts are closely monitoring the situation for further updates.",
            "The announcement addresses investor concerns about future growth prospects while demonstrating management's commitment to shareholder value creation.",
            "Market participants are evaluating the potential impact on operations and profitability. The situation remains fluid with updates expected in the coming weeks.",
            "Industry analysts highlight this as a significant development that could reshape the competitive landscape in the sector.",
            "The initiative reflects the company's focus on innovation and long-term strategic positioning in rapidly evolving markets.",
            "Financial implications of the announcement are being assessed by market participants, with initial reactions generally positive.",
            "The development comes at a critical time for the industry, with regulatory changes and market consolidation creating new opportunities.",
            "Management commentary suggests confidence in the company's ability to navigate current market challenges while maintaining growth trajectory."
        ]
        
        return summaries.randomElement() ?? "Further details are expected to be released in the coming days."
    }
}

// MARK: - Market Context Service
class MarketContextService: ObservableObject {
    static let shared = MarketContextService()
    
    @Published var marketContext: MarketContext?
    @Published var analystConsensus: AnalystConsensus?
    @Published var isLoading = false
    
    private init() {}
    
    func fetchMarketContext(for symbol: String) async {
        await MainActor.run {
            isLoading = true
        }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 400_000_000)
        
        await MainActor.run {
            marketContext = generateMockMarketContext(for: symbol)
            analystConsensus = generateMockAnalystConsensus(for: symbol)
            isLoading = false
        }
    }
    
    private func generateMockMarketContext(for symbol: String) -> MarketContext {
        let sectorData = SectorData(
            name: "Technology",
            dailyChange: Double.random(in: -2...3),
            weeklyChange: Double.random(in: -5...8),
            topPerformers: ["NVDA", "AAPL", "MSFT"],
            bottomPerformers: ["META", "NFLX", "AMZN"],
            keyThemes: ["AI Innovation", "Cloud Computing", "Mobile Technology"]
        )
        
        let macroData = MacroData(
            marketTrend: ["Bull Market", "Bear Market", "Volatile", "Consolidating"].randomElement() ?? "Mixed",
            interestRateEnvironment: "Stable with potential for cuts",
            inflationTrend: "Moderating from recent highs",
            keyEconomicIndicators: [
                EconomicIndicator(name: "GDP Growth", currentValue: "2.1%", trend: "Stable", impact: "Neutral"),
                EconomicIndicator(name: "Unemployment", currentValue: "3.7%", trend: "Declining", impact: "Positive"),
                EconomicIndicator(name: "CPI Inflation", currentValue: "3.2%", trend: "Declining", impact: "Positive")
            ],
            geopoliticalFactors: ["Trade Relations", "Regulatory Changes", "Energy Prices"]
        )
        
        let upcomingEvents = generateUpcomingEvents(for: symbol)
        
        let communityData = CommunityData(
            trendingTopics: ["AI Development", "Market Volatility", "Earnings Season"],
            discussionVolume: Int.random(in: 1000...10000),
            keyMentions: ["Innovation", "Growth", "Valuation"],
            socialSentiment: Double.random(in: -0.5...0.5),
            redditMentions: Int.random(in: 50...500),
            twitterMentions: Int.random(in: 100...1000)
        )
        
        return MarketContext(
            symbol: symbol,
            sectorPerformance: sectorData,
            macroEnvironment: macroData,
            upcomingEvents: upcomingEvents,
            communityPulse: communityData,
            lastUpdated: Date()
        )
    }
    
    private func generateUpcomingEvents(for symbol: String) -> [MarketEvent] {
        var events: [MarketEvent] = []
        let eventTypes = MarketEvent.EventType.allCases
        let importance = MarketEvent.EventImportance.allCases
        
        for _ in 0..<5 {
            let type = eventTypes.randomElement() ?? .earnings
            let imp = importance.randomElement() ?? .medium
            let futureDate = Date().addingTimeInterval(Double.random(in: 0...86400 * 30)) // Next 30 days
            
            let event = MarketEvent(
                title: "\(symbol.uppercased()) \(type.rawValue)",
                date: futureDate,
                type: type,
                description: "Important \(type.rawValue.lowercased()) event for \(symbol.uppercased())",
                importance: imp
            )
            
            events.append(event)
        }
        
        return events.sorted { $0.date < $1.date }
    }
    
    private func generateMockAnalystConsensus(for symbol: String) -> AnalystConsensus {
        let buyRating = Double.random(in: 0.3...0.7)
        let sellRating = Double.random(in: 0.1...0.3)
        let holdRating = 1.0 - buyRating - sellRating
        
        let revisions = generateAnalystRevisions(for: symbol)
        
        return AnalystConsensus(
            symbol: symbol,
            buyRating: buyRating,
            holdRating: holdRating,
            sellRating: sellRating,
            averageTargetPrice: Double.random(in: 100...600),
            numberOfAnalysts: Int.random(in: 15...45),
            recentRevisions: revisions,
            lastUpdated: Date()
        )
    }
    
    private func generateAnalystRevisions(for symbol: String) -> [AnalystRevision] {
        let firms = ["Goldman Sachs", "Morgan Stanley", "J.P. Morgan", "Bank of America", "Citigroup", "Wells Fargo", "UBS", "Credit Suisse", "Deutsche Bank", "Barclays"]
        let ratings = ["Buy", "Hold", "Sell", "Strong Buy", "Underperform", "Outperform"]
        
        var revisions: [AnalystRevision] = []
        
        for _ in 0..<5 {
            let firm = firms.randomElement() ?? "Investment Bank"
            let previousRating = ratings.randomElement() ?? "Hold"
            let newRating = ratings.randomElement() ?? "Buy"
            let previousTarget = Double.random(in: 80...400)
            let newTarget = previousTarget + Double.random(in: -50...100)
            let date = Date().addingTimeInterval(-Double.random(in: 0...86400 * 14)) // Last 2 weeks
            
            let revision = AnalystRevision(
                firm: firm,
                analyst: "Senior Analyst",
                previousRating: previousRating,
                newRating: newRating,
                previousTarget: previousTarget,
                newTarget: newTarget,
                date: date,
                reasoning: "Updated valuation model based on recent market conditions and company fundamentals."
            )
            
            revisions.append(revision)
        }
        
        return revisions.sorted { $0.date > $1.date }
    }
}

// MARK: - Search Service
class SearchService: ObservableObject {
    static let shared = SearchService()
    
    @Published var searchResults: [Stock] = []
    @Published var recentSearches: [String] = []
    @Published var isLoading = false
    
    private init() {
        loadRecentSearches()
    }
    
    func searchStocks(query: String) async {
        await MainActor.run {
            isLoading = true
        }
        
        // Simulate search delay
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        await MainActor.run {
            if query.isEmpty {
                searchResults = []
            } else {
                let allStocks = StockService.shared.getPopularStocks()
                searchResults = allStocks.filter {
                    $0.symbol.localizedCaseInsensitiveContains(query) ||
                    $0.companyName.localizedCaseInsensitiveContains(query)
                }
                
                // Add query to recent searches
                addToRecentSearches(query.uppercased())
            }
            isLoading = false
        }
    }
    
    private func addToRecentSearches(_ query: String) {
        recentSearches.removeAll { $0 == query }
        recentSearches.insert(query, at: 0)
        if recentSearches.count > 10 {
            recentSearches.removeLast()
        }
        saveRecentSearches()
    }
    
    private func loadRecentSearches() {
        if let data = UserDefaults.standard.data(forKey: "recentSearches"),
           let searches = try? JSONDecoder().decode([String].self, from: data) {
            recentSearches = searches
        }
    }
    
    private func saveRecentSearches() {
        if let data = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(data, forKey: "recentSearches")
        }
    }
} 
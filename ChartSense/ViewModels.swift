//
//  ViewModels.swift
//  ChartSense
//
//  Created by Aidan Quach on 7/22/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Main App View Model
class AppViewModel: ObservableObject {
    @Published var selectedTab = 0
    @Published var selectedStock: Stock?
    @Published var themeManager = ThemeManager.shared
    
    let stockService = StockService.shared
    let sentimentService = SentimentService.shared
    let newsService = NewsService.shared
    let marketContextService = MarketContextService.shared
    let searchService = SearchService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Listen for theme changes
        themeManager.$isDarkMode
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func selectStock(_ stock: Stock) {
        selectedStock = stock
        selectedTab = 1 // Switch to sentiment tab
        
        // Fetch related data
        Task {
            await loadStockData(for: stock.symbol)
        }
    }
    
    @MainActor
    func loadStockData(for symbol: String) async {
        await sentimentService.getSentimentAnalysis(for: symbol)
        await newsService.fetchNews(for: symbol)
        await marketContextService.fetchMarketContext(for: symbol)
    }
}

// MARK: - Search View Model
class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [Stock] = []
    @Published var recentSearches: [String] = []
    @Published var popularStocks: [Stock] = []
    @Published var isLoading = false
    @Published var hasSearched = false
    
    private let searchService = SearchService.shared
    private let stockService = StockService.shared
    private var searchCancellable: AnyCancellable?
    
    init() {
        popularStocks = stockService.getPopularStocks()
        recentSearches = searchService.recentSearches
        
        // Debounced search
        searchCancellable = $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                Task {
                    await self?.performSearch(query: searchText)
                }
            }
        
        // Listen for search service updates
        searchService.$searchResults
            .assign(to: &$searchResults)
        
        searchService.$recentSearches
            .assign(to: &$recentSearches)
        
        searchService.$isLoading
            .assign(to: &$isLoading)
    }
    
    @MainActor
    func performSearch(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            hasSearched = false
            return
        }
        
        hasSearched = true
        await searchService.searchStocks(query: query)
    }
    
    func selectRecentSearch(_ search: String) {
        searchText = search
    }
    
    func clearSearch() {
        searchText = ""
        searchResults = []
        hasSearched = false
    }
}

// MARK: - Sentiment View Model
class SentimentViewModel: ObservableObject {
    @Published var currentStock: Stock?
    @Published var sentiment: SentimentAnalysis?
    @Published var newsItems: [NewsItem] = []
    @Published var marketContext: MarketContext?
    @Published var analystConsensus: AnalystConsensus?
    
    @Published var isLoadingSentiment = false
    @Published var isLoadingNews = false
    @Published var isLoadingMarketContext = false
    
    @Published var selectedNewsCategory: NewsItem.NewsCategory?
    @Published var expandedSections: Set<String> = []
    
    private let sentimentService = SentimentService.shared
    private let newsService = NewsService.shared
    private let marketContextService = MarketContextService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Bind services to published properties
        sentimentService.$currentSentiment
            .assign(to: &$sentiment)
        
        sentimentService.$isLoading
            .assign(to: &$isLoadingSentiment)
        
        newsService.$newsItems
            .assign(to: &$newsItems)
        
        newsService.$isLoading
            .assign(to: &$isLoadingNews)
        
        marketContextService.$marketContext
            .assign(to: &$marketContext)
        
        marketContextService.$analystConsensus
            .assign(to: &$analystConsensus)
        
        marketContextService.$isLoading
            .assign(to: &$isLoadingMarketContext)
    }
    
    func loadData(for stock: Stock) {
        currentStock = stock
        
        Task {
            await loadAllData(for: stock.symbol)
        }
    }
    
    @MainActor
    private func loadAllData(for symbol: String) async {
        await sentimentService.getSentimentAnalysis(for: symbol)
        await newsService.fetchNews(for: symbol)
        await marketContextService.fetchMarketContext(for: symbol)
    }
    
    func filteredNews() -> [NewsItem] {
        if let category = selectedNewsCategory {
            return newsItems.filter { $0.category == category }
        }
        return newsItems
    }
    
    func newsCategories() -> [(category: NewsItem.NewsCategory, count: Int)] {
        let categories = NewsItem.NewsCategory.allCases
        return categories.compactMap { category in
            let count = newsItems.filter { $0.category == category }.count
            return count > 0 ? (category, count) : nil
        }
    }
    
    func toggleSection(_ section: String) {
        if expandedSections.contains(section) {
            expandedSections.remove(section)
        } else {
            expandedSections.insert(section)
        }
    }
    
    func isSectionExpanded(_ section: String) -> Bool {
        expandedSections.contains(section)
    }
    
    func openNewsArticle(_ newsItem: NewsItem) {
        // In a real app, this would open the article URL
        print("Opening article: \(newsItem.url)")
    }
    
    func refreshData() {
        guard let stock = currentStock else { return }
        loadData(for: stock)
    }
}

// MARK: - Watchlist View Model
class WatchlistViewModel: ObservableObject {
    @Published var watchlistItems: [WatchlistItem] = []
    @Published var stockDetails: [String: Stock] = [:]
    @Published var sentiments: [String: SentimentAnalysis] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingAddStock = false
    
    private let stockService = StockService.shared
    private let sentimentService = SentimentService.shared
    
    init() {
        loadWatchlist()
    }
    
    func loadWatchlist() {
        // In a real app, this would load from Core Data/SwiftData
        // For now, using mock data
        watchlistItems = [
            WatchlistItem(symbol: "AAPL", companyName: "Apple Inc.", alertsEnabled: true, priceTarget: 200.0),
            WatchlistItem(symbol: "TSLA", companyName: "Tesla, Inc.", alertsEnabled: false, priceTarget: 300.0),
            WatchlistItem(symbol: "GOOGL", companyName: "Alphabet Inc.", alertsEnabled: true)
        ]
        
        loadStockDetails()
    }
    
    func addToWatchlist(_ stock: Stock) {
        let newItem = WatchlistItem(
            symbol: stock.symbol,
            companyName: stock.companyName
        )
        
        watchlistItems.append(newItem)
        stockDetails[stock.symbol] = stock
        
        // Load sentiment for new stock
        Task {
            await loadSentiment(for: stock.symbol)
        }
    }
    
    func removeFromWatchlist(_ item: WatchlistItem) {
        watchlistItems.removeAll { $0.symbol == item.symbol }
        stockDetails.removeValue(forKey: item.symbol)
        sentiments.removeValue(forKey: item.symbol)
    }
    
    func updatePriceTarget(for symbol: String, target: Double) {
        if let index = watchlistItems.firstIndex(where: { $0.symbol == symbol }) {
            watchlistItems[index].priceTarget = target
        }
    }
    
    func toggleAlerts(for symbol: String) {
        if let index = watchlistItems.firstIndex(where: { $0.symbol == symbol }) {
            watchlistItems[index].alertsEnabled.toggle()
        }
    }
    
    private func loadStockDetails() {
        isLoading = true
        
        Task {
            await loadAllStockDetails()
        }
    }
    
    @MainActor
    private func loadAllStockDetails() async {
        let symbols = watchlistItems.map { $0.symbol }
        
        for symbol in symbols {
            await stockService.searchStock(symbol: symbol)
            if let stock = stockService.currentStock, stock.symbol == symbol {
                stockDetails[symbol] = stock
            }
            
            await loadSentiment(for: symbol)
        }
        
        isLoading = false
    }
    
    @MainActor
    private func loadSentiment(for symbol: String) async {
        await sentimentService.getSentimentAnalysis(for: symbol)
        if let sentiment = sentimentService.currentSentiment, sentiment.symbol == symbol {
            sentiments[symbol] = sentiment
        }
    }
    
    func refreshWatchlist() {
        loadStockDetails()
    }
    
    func sortedWatchlistItems() -> [WatchlistItem] {
        return watchlistItems.sorted { $0.symbol < $1.symbol }
    }
}

// MARK: - Settings View Model
class SettingsViewModel: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
            ThemeManager.shared.isDarkMode = isDarkMode
        }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }
    
    @Published var priceAlertsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(priceAlertsEnabled, forKey: "priceAlertsEnabled")
        }
    }
    
    @Published var newsAlertsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(newsAlertsEnabled, forKey: "newsAlertsEnabled")
        }
    }
    
    @Published var marketOpenAlerts: Bool {
        didSet {
            UserDefaults.standard.set(marketOpenAlerts, forKey: "marketOpenAlerts")
        }
    }
    
    @Published var refreshInterval: String {
        didSet {
            UserDefaults.standard.set(refreshInterval, forKey: "refreshInterval")
        }
    }
    
    @Published var defaultView: String {
        didSet {
            UserDefaults.standard.set(defaultView, forKey: "defaultView")
        }
    }
    
    @Published var autoRefreshEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoRefreshEnabled, forKey: "autoRefreshEnabled")
        }
    }
    
    @Published var highQualityCharts: Bool {
        didSet {
            UserDefaults.standard.set(highQualityCharts, forKey: "highQualityCharts")
        }
    }
    
    @Published var aiInsightsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(aiInsightsEnabled, forKey: "aiInsightsEnabled")
        }
    }
    
    @Published var newsSources: String {
        didSet {
            UserDefaults.standard.set(newsSources, forKey: "newsSources")
        }
    }
    
    @Published var showConfidenceScores: Bool {
        didSet {
            UserDefaults.standard.set(showConfidenceScores, forKey: "showConfidenceScores")
        }
    }
    
    init() {
        // Load settings from UserDefaults with sensible defaults
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        self.notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        self.priceAlertsEnabled = UserDefaults.standard.object(forKey: "priceAlertsEnabled") as? Bool ?? true
        self.newsAlertsEnabled = UserDefaults.standard.object(forKey: "newsAlertsEnabled") as? Bool ?? false
        self.marketOpenAlerts = UserDefaults.standard.object(forKey: "marketOpenAlerts") as? Bool ?? true
        self.refreshInterval = UserDefaults.standard.string(forKey: "refreshInterval") ?? "5 minutes"
        self.defaultView = UserDefaults.standard.string(forKey: "defaultView") ?? "Search"
        self.autoRefreshEnabled = UserDefaults.standard.object(forKey: "autoRefreshEnabled") as? Bool ?? true
        self.highQualityCharts = UserDefaults.standard.object(forKey: "highQualityCharts") as? Bool ?? true
        self.aiInsightsEnabled = UserDefaults.standard.object(forKey: "aiInsightsEnabled") as? Bool ?? true
        self.newsSources = UserDefaults.standard.string(forKey: "newsSources") ?? "All Sources"
        self.showConfidenceScores = UserDefaults.standard.object(forKey: "showConfidenceScores") as? Bool ?? true
        
        // Sync with theme manager
        ThemeManager.shared.isDarkMode = isDarkMode
    }
    
    func exportData() {
        // In a real app, this would export watchlist and settings data
        print("Exporting data...")
        
        // Simulate export process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Show success message or share sheet
            print("Data exported successfully")
        }
    }
    
    func clearCache() {
        // In a real app, this would clear cached data
        print("Clearing cache...")
        
        // Simulate cache clearing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("Cache cleared successfully")
        }
    }
    
    func resetToDefaults() {
        // Reset all settings to defaults
        isDarkMode = false
        notificationsEnabled = true
        priceAlertsEnabled = true
        newsAlertsEnabled = false
        marketOpenAlerts = true
        refreshInterval = "5 minutes"
        defaultView = "Search"
        autoRefreshEnabled = true
        highQualityCharts = true
        aiInsightsEnabled = true
        newsSources = "All Sources"
        showConfidenceScores = true
        
        print("Settings reset to defaults")
    }
    
    func rateApp() {
        // In a real app, this would open the App Store rating page
        print("Opening App Store rating page...")
        
        // Simulate opening App Store
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("App Store rating page opened")
        }
    }
}

// MARK: - Utility Extensions
extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
} 
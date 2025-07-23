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
    
    func performSearch() {
        Task {
            await performSearch(query: searchText)
        }
    }
    
    func loadInitialData() {
        popularStocks = stockService.getPopularStocks()
        recentSearches = searchService.recentSearches
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
        
        // Load stock details and sentiment in parallel for better performance
        await withTaskGroup(of: Void.self) { group in
            for symbol in symbols {
                group.addTask {
                    await self.loadStockAndSentiment(for: symbol)
                }
            }
        }
        
        isLoading = false
    }
    
    @MainActor
    private func loadStockAndSentiment(for symbol: String) async {
        // Load stock details and sentiment concurrently
        async let stockTask = loadStockDetails(for: symbol)
        async let sentimentTask = loadSentiment(for: symbol)
        
        // Wait for both to complete
        _ = await (stockTask, sentimentTask)
    }
    
    @MainActor
    private func loadStockDetails(for symbol: String) async {
        await stockService.searchStock(symbol: symbol)
        if let stock = stockService.currentStock, stock.symbol == symbol {
            stockDetails[symbol] = stock
        }
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

// MARK: - AI View Model
class AIViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isTyping: Bool = false
    @Published var suggestedMessages: [SuggestedMessage] = []
    
    private let aiService = AIService()
    
    init() {
        setupInitialMessages()
        setupSuggestedMessages()
    }
    
    private func setupInitialMessages() {
        let welcomeMessage = ChatMessage(
            content: "Hello! I'm your AI financial assistant. I can help you analyze stocks, explain market concepts, and provide insights about your portfolio. What would you like to know?",
            isUser: false
        )
        messages.append(welcomeMessage)
    }
    
    private func setupSuggestedMessages() {
        suggestedMessages = [
            SuggestedMessage(text: "Analyze AAPL's current sentiment", category: .analysis),
            SuggestedMessage(text: "What is a P/E ratio?", category: .education),
            SuggestedMessage(text: "How should I diversify my portfolio?", category: .portfolio),
            SuggestedMessage(text: "Latest market news", category: .news),
            SuggestedMessage(text: "Explain technical analysis", category: .education),
            SuggestedMessage(text: "Compare TSLA vs NIO", category: .analysis)
        ]
    }
    
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(content: inputText, isUser: true)
        messages.append(userMessage)
        
        let userInput = inputText
        inputText = ""
        
        // Show typing indicator
        isTyping = true
        
        // Simulate AI response (replace with actual OpenAI API call)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isTyping = false
            let aiResponse = self.generateAIResponse(to: userInput)
            let aiMessage = ChatMessage(content: aiResponse, isUser: false)
            self.messages.append(aiMessage)
        }
    }
    
    func sendSuggestedMessage(_ suggestion: SuggestedMessage) {
        inputText = suggestion.text
        sendMessage()
    }
    
    func resetChat() {
        messages.removeAll()
        setupInitialMessages()
    }
    
    private func generateAIResponse(to userInput: String) -> String {
        // Mock AI responses - replace with actual OpenAI API integration
        let lowercasedInput = userInput.lowercased()
        
        if lowercasedInput.contains("aapl") || lowercasedInput.contains("apple") {
            return "Apple (AAPL) is currently showing strong fundamentals with a P/E ratio of 28.5. Recent earnings beat expectations, and the iPhone 15 launch has been well-received. Technical indicators suggest a bullish trend, with support at $170 and resistance at $190. The company's services revenue growth and strong cash position make it an attractive long-term investment."
        } else if lowercasedInput.contains("p/e") || lowercasedInput.contains("price to earnings") {
            return "The Price-to-Earnings (P/E) ratio measures a company's stock price relative to its earnings per share. It's calculated by dividing the market value per share by the earnings per share. A higher P/E suggests investors expect higher earnings growth, while a lower P/E might indicate undervaluation or lower growth expectations. The average P/E for the S&P 500 is around 20."
        } else if lowercasedInput.contains("diversify") || lowercasedInput.contains("portfolio") {
            return "Diversification is key to managing investment risk. Consider spreading your investments across different sectors (tech, healthcare, finance), asset classes (stocks, bonds, ETFs), and market caps (large, mid, small). A well-diversified portfolio typically includes 10-20 different stocks across various industries. Don't forget to include some international exposure and consider your risk tolerance."
        } else if lowercasedInput.contains("technical") || lowercasedInput.contains("analysis") {
            return "Technical analysis uses historical price and volume data to predict future price movements. Key concepts include support/resistance levels, moving averages, RSI, MACD, and chart patterns. While useful for timing entries and exits, technical analysis works best when combined with fundamental analysis. Remember that past performance doesn't guarantee future results."
        } else if lowercasedInput.contains("tsla") || lowercasedInput.contains("tesla") {
            return "Tesla (TSLA) is a high-growth electric vehicle company with significant market volatility. Recent quarterly results show strong delivery numbers but margin pressure from price competition. The stock trades at a premium P/E due to growth expectations. Key factors to watch include delivery growth, margin trends, and competition from traditional automakers entering the EV space."
        } else {
            return "I understand you're asking about \(userInput). As an AI financial assistant, I can help you analyze stocks, explain market concepts, and provide portfolio insights. Could you please be more specific about what you'd like to know? I can help with stock analysis, market education, portfolio advice, or current market news."
        }
    }
}

// MARK: - AI Service
class AIService: ObservableObject {
    func sendMessage(_ message: String) async -> String {
        // TODO: Integrate with OpenAI API
        // This is where you'll add the actual API call to OpenAI
        return "AI response placeholder"
    }
}

// MARK: - Authentication View Model
class AuthViewModel: ObservableObject {
    static let shared = AuthViewModel()
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Login/Signup form fields
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var name: String = ""
    @Published var isSignupMode: Bool = false
    
    private let supabaseService = SupabaseService.shared
    
    init() {
        // Bind to Supabase service
        supabaseService.$isAuthenticated
            .assign(to: &$isAuthenticated)
        
        supabaseService.$currentUser
            .assign(to: &$currentUser)
        
        supabaseService.$isLoading
            .assign(to: &$isLoading)
        
        supabaseService.$errorMessage
            .assign(to: &$errorMessage)
    }
    
    func signInWithEmail() {
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        Task {
            do {
                try await supabaseService.signIn(email: email, password: password)
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func signUpWithEmail() {
        guard !email.isEmpty && !password.isEmpty && !name.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        Task {
            do {
                try await supabaseService.signUp(email: email, password: password, name: name)
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func signInWithApple() {
        Task {
            do {
                try await supabaseService.signInWithApple()
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func signInWithGoogle() {
        Task {
            do {
                try await supabaseService.signInWithGoogle()
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func signOut() {
        Task {
            await supabaseService.signOut()
        }
        
        // Clear form fields
        email = ""
        password = ""
        name = ""
    }
    
    func toggleMode() {
        isSignupMode.toggle()
        errorMessage = nil
    }
}

// MARK: - Home View Model
class HomeViewModel: ObservableObject {
    @Published var widgets: [HomeWidget] = []
    @Published var widgetData: WidgetData?
    @Published var isLoading: Bool = false
    @Published var showingWidgetCustomization: Bool = false
    
    private let stockService = StockService.shared
    private let newsService = NewsService.shared
    private let sentimentService = SentimentService.shared
    
    init() {
        setupDefaultWidgets()
        loadWidgetData()
    }
    
    private func setupDefaultWidgets() {
        // Load saved widgets or use defaults
        let savedWidgets = UserDefaults.standard.data(forKey: "homeWidgets")
        if let savedWidgets = savedWidgets,
           let decodedWidgets = try? JSONDecoder().decode([HomeWidget].self, from: savedWidgets) {
            self.widgets = decodedWidgets
        } else {
            // Default widget configuration
            self.widgets = [
                HomeWidget(type: .search, size: .medium, order: 0, isEnabled: true),
                HomeWidget(type: .news, size: .medium, order: 1, isEnabled: true),
                HomeWidget(type: .watchlist, size: .large, order: 2, isEnabled: true),
                HomeWidget(type: .ai, size: .medium, order: 3, isEnabled: true)
            ]
        }
    }
    
    func addWidget(_ type: HomeWidget.WidgetType) {
        let newOrder = widgets.count
        let newWidget = HomeWidget(type: type, size: .medium, order: newOrder, isEnabled: true)
        widgets.append(newWidget)
        saveWidgetConfiguration()
    }
    
    func removeWidget(_ widget: HomeWidget) {
        widgets.removeAll { $0.id == widget.id }
        // Reorder remaining widgets
        for (index, widget) in widgets.enumerated() {
            if let widgetIndex = widgets.firstIndex(where: { $0.id == widget.id }) {
                widgets[widgetIndex].order = index
            }
        }
        saveWidgetConfiguration()
    }
    
    func loadWidgetData() {
        isLoading = true
        
        // Load data for each enabled widget
        let enabledWidgets = widgets.filter { $0.isEnabled }
        
        // Simulate data loading (reduced from 500ms to 200ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.widgetData = WidgetData(
                searchData: self.createSearchData(),
                newsData: self.createNewsData(),
                watchlistData: self.createWatchlistData(),
                aiData: self.createAIData(),
                marketData: self.createMarketData(),
                trendingData: self.createTrendingData()
            )
            self.isLoading = false
        }
    }
    
    private func createSearchData() -> SearchWidgetData {
        return SearchWidgetData(
            recentSearches: ["AAPL", "TSLA", "NVDA"],
            popularStocks: stockService.getPopularStocks()
        )
    }
    
    private func createNewsData() -> NewsWidgetData {
        // Generate mock news data for the widget
        let mockNews = [
            NewsItem(
                headline: "Tech Stocks Rally on Strong Earnings Reports",
                summary: "Major technology companies exceeded analyst expectations, driving market optimism.",
                source: "Bloomberg",
                publishedAt: Date().addingTimeInterval(-3600),
                url: "https://example.com/news/1",
                category: .earnings,
                sentiment: 0.7,
                relevanceScore: 0.9,
                imageURL: nil
            ),
            NewsItem(
                headline: "Federal Reserve Signals Potential Rate Cuts",
                summary: "Central bank officials hint at possible monetary policy adjustments.",
                source: "Reuters",
                publishedAt: Date().addingTimeInterval(-7200),
                url: "https://example.com/news/2",
                category: .economic,
                sentiment: 0.5,
                relevanceScore: 0.8,
                imageURL: nil
            ),
            NewsItem(
                headline: "AI Sector Continues Strong Growth Momentum",
                summary: "Artificial intelligence companies report record-breaking quarterly results.",
                source: "CNBC",
                publishedAt: Date().addingTimeInterval(-10800),
                url: "https://example.com/news/3",
                category: .technology,
                sentiment: 0.8,
                relevanceScore: 0.9,
                imageURL: nil
            )
        ]
        
        return NewsWidgetData(
            headlines: mockNews,
            watchlistNews: Array(mockNews.prefix(2))
        )
    }
    
    private func createWatchlistData() -> WatchlistWidgetData {
        // Use popular stocks from service for watchlist
        let watchlistStocks = stockService.getPopularStocks().prefix(3).map { $0 }
        
        var sentiments: [String: SentimentAnalysis] = [:]
        for stock in watchlistStocks {
            sentiments[stock.symbol] = sentimentService.getSentiment(for: stock.symbol)
        }
        
        return WatchlistWidgetData(stocks: watchlistStocks, sentiments: sentiments)
    }
    
    private func createAIData() -> AIWidgetData {
        return AIWidgetData(
            insights: [
                "Market sentiment is bullish today with tech stocks leading gains.",
                "Consider watching AI and semiconductor stocks for momentum."
            ],
            suggestedQuestions: [
                "What's driving today's market rally?",
                "Which sectors look most promising?"
            ]
        )
    }
    
    private func createMarketData() -> MarketWidgetData {
        return MarketWidgetData(
            indices: [
                MarketIndex(name: "S&P 500", symbol: "^GSPC", price: 4850.25, change: 45.30, changePercent: 0.94),
                MarketIndex(name: "NASDAQ", symbol: "^IXIC", price: 15250.75, change: 125.50, changePercent: 0.83),
                MarketIndex(name: "DOW", symbol: "^DJI", price: 38250.40, change: 180.20, changePercent: 0.47)
            ],
            sentiment: 0.75
        )
    }
    
    private func createTrendingData() -> TrendingWidgetData {
        return TrendingWidgetData(
            stocks: stockService.getPopularStocks(),
            trends: ["AI", "Semiconductors", "EV", "Biotech"]
        )
    }
    
    func saveWidgetConfiguration() {
        if let encoded = try? JSONEncoder().encode(widgets) {
            UserDefaults.standard.set(encoded, forKey: "homeWidgets")
        }
    }
    
    func toggleWidget(_ widget: HomeWidget) {
        if let index = widgets.firstIndex(where: { $0.id == widget.id }) {
            widgets[index].isEnabled.toggle()
            saveWidgetConfiguration()
        }
    }
    

    
    func updateWidgetOrder(from source: IndexSet, to destination: Int) {
        widgets.move(fromOffsets: source, toOffset: destination)
        
        // Update order numbers
        for (index, widget) in widgets.enumerated() {
            if let widgetIndex = widgets.firstIndex(where: { $0.id == widget.id }) {
                widgets[widgetIndex].order = index
            }
        }
        
        saveWidgetConfiguration()
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
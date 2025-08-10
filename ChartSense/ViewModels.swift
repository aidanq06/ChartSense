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
    @Published var allStocks: [Stock] = []
    @Published var recentSearches: [String] = []
    @Published var popularStocks: [Stock] = []
    @Published var isLoading = false
    @Published var hasSearched = false
    @Published var isLoadingAllStocks = false
    
    private let searchService = SearchService.shared
    private let stockService = StockService.shared
    private let stockDataService = StockDataService.shared
    private let supabaseService = SupabaseService.shared
    private var searchCancellable: AnyCancellable?
    
    init() {
        Task {
            await loadInitialData()
        }
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
            // When search is empty, show all stocks
            searchResults = allStocks
            hasSearched = false
            return
        }
        
        hasSearched = true
        
        // Filter all stocks based on search query
        searchResults = allStocks.filter { stock in
            stock.symbol.localizedCaseInsensitiveContains(query) ||
            stock.companyName.localizedCaseInsensitiveContains(query)
        }

        // Hydrate prices for visible results (increase batch to reduce zeros)
        await hydrateSearchResults(limit: 200)
    }
    
    func selectRecentSearch(_ search: String) {
        searchText = search
    }
    
    func clearSearch() {
        searchText = ""
        searchResults = allStocks
        hasSearched = false
    }
    
    func performSearch() {
        Task {
            await performSearch(query: searchText)
        }
    }
    
    @MainActor
    func loadInitialData() async {
        // Load all stocks from database
        await loadAllStocks()
        
        do {
            popularStocks = try await stockService.getPopularStocks()
        } catch {
            print("❌ Error loading popular stocks: \(error)")
            popularStocks = []
        }
        recentSearches = searchService.recentSearches
    }
    
    @MainActor
    func loadAllStocks() async {
        isLoadingAllStocks = true
        
        do {
            let stocks = try await supabaseService.getAllStocks()
            allStocks = stocks
            searchResults = stocks // Show all stocks by default
            print("✅ Loaded \(stocks.count) stocks from database")
            // Hydrate initial list with prices (increase batch for better coverage)
            await hydrateSearchResults(limit: 200)
        } catch {
            print("❌ Error loading all stocks: \(error)")
            allStocks = []
            searchResults = []
        }
        
        isLoadingAllStocks = false
    }

    // MARK: - Hydration
    @MainActor
    private func hydrateSearchResults(limit: Int = 50) async {
        let symbols = Array(searchResults.prefix(limit)).map { $0.symbol }
        guard !symbols.isEmpty else { return }
        do {
            let quotes = try await supabaseService.fetchQuotesDisplayForSymbols(symbols)
            let updated: [Stock] = searchResults.map { stock in
                let key = stock.symbol.uppercased()
                if let q = quotes[key] {
                    let newPrice = q.price
                    let newDelta = q.delta ?? 0
                    let newDeltaPct = q.deltaPercent ?? 0
                    return Stock(symbol: stock.symbol, companyName: stock.companyName, currentPrice: newPrice, dailyChange: newDelta, dailyChangePercent: newDeltaPct)
                }
                return stock
            }
            searchResults = updated
            if !hasSearched {
                let bySymbol = Dictionary(uniqueKeysWithValues: updated.map { ($0.symbol.uppercased(), $0) })
                allStocks = allStocks.map { bySymbol[$0.symbol.uppercased()] ?? $0 }
            }
        } catch {
            print("⚠️ Hydration failed: \(error)")
        }
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
    static let shared = WatchlistViewModel()
    
    @Published var watchlistItems: [WatchlistItem] = []
    @Published var watchlistItemsWithStock: [WatchlistItemWithStock] = []
    @Published var stockDetails: [String: Stock] = [:]
    @Published var sentiments: [String: SentimentAnalysis] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingAddStock = false
    
    private let supabaseService = SupabaseService.shared
    private let stockService = StockService.shared
    private let sentimentService = SentimentService.shared
    
    private init() {
        Task { @MainActor in
            loadWatchlist()
        }
    }
    
    @MainActor
    func loadWatchlist() {
        // Require auth before hitting RLS-protected tables
        guard supabaseService.isAuthenticated else { 
            print("⏸️ Skipping loadWatchlist: not authenticated yet")
            return 
        }
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let items = try await supabaseService.getWatchlist()
                await MainActor.run {
                    self.watchlistItems = items
                    self.isLoading = false
                }
                
                // Load stock data for all items
                await loadWatchlistWithStockData()
                
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
                print("❌ Error loading watchlist: \(error)")
            }
        }
    }
    
    // Check if stock is already in watchlist
    func isStockInWatchlist(_ symbol: String) -> Bool {
        return watchlistItems.contains { $0.symbol.uppercased() == symbol.uppercased() }
    }
    
    @MainActor
    func addToWatchlist(_ stock: Stock, priceTarget: Double? = nil, notes: String? = nil, alertPrice: Double? = nil, alertType: String = "above") {
        print("🔄 WatchlistViewModel: Adding \(stock.symbol) to watchlist...")
        
        // Check if stock is already in watchlist
        if isStockInWatchlist(stock.symbol) {
            print("❌ WatchlistViewModel: \(stock.symbol) is already in watchlist")
            self.errorMessage = "\(stock.symbol) is already in your watchlist"
            return
        }
        
        // Check watchlist limit for free users
        let premiumManager = PremiumManager.shared
        if !premiumManager.isPremium && watchlistItems.count >= 1 {
            print("❌ WatchlistViewModel: Free user limit reached (1 stock)")
            self.errorMessage = "Free users can only track 1 stock. Upgrade to Premium for unlimited watchlist!"
            premiumManager.showingPremiumUpgrade = true
            return
        }
        
        Task {
            do {
                print("🔄 WatchlistViewModel: Calling Supabase service...")
                try await supabaseService.addToWatchlist(
                    symbol: stock.symbol,
                    companyName: stock.companyName,
                    priceTarget: priceTarget,
                    notes: notes,
                    alertPrice: alertPrice,
                    alertType: alertType
                )
                
                print("✅ WatchlistViewModel: Successfully added to Supabase, reloading watchlist...")
                // Reload watchlist to get updated data
                await loadWatchlist()
                
                print("✅ WatchlistViewModel: Sending notification to home screen...")
                // Notify home screen to refresh
                NotificationCenter.default.post(name: NSNotification.Name("WatchlistChanged"), object: nil)
                
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
                print("❌ Error adding to watchlist: \(error)")
            }
        }
    }
    
    @MainActor
    func removeFromWatchlist(_ item: WatchlistItem) {
        Task {
            do {
                try await supabaseService.removeFromWatchlist(symbol: item.symbol)
                
                // Reload watchlist to get updated data
                await loadWatchlist()
                
                // Notify home screen to refresh
                NotificationCenter.default.post(name: NSNotification.Name("WatchlistChanged"), object: nil)
                
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
                print("❌ Error removing from watchlist: \(error)")
            }
        }
    }
    
    @MainActor
    func updatePriceTarget(for symbol: String, target: Double) {
        Task {
            do {
                try await supabaseService.setWatchlistPriceTarget(symbol: symbol, target: target)
                
                // Update local state
                if let index = watchlistItems.firstIndex(where: { $0.symbol == symbol }) {
                    watchlistItems[index].priceTarget = target
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
                print("❌ Error updating price target: \(error)")
            }
        }
    }
    
    @MainActor
    func toggleAlerts(for symbol: String) {
        // Update UI immediately for better UX
        if let index = watchlistItems.firstIndex(where: { $0.symbol == symbol }) {
            let newEnabled = !watchlistItems[index].alertsEnabled
            watchlistItems[index].alertsEnabled = newEnabled
            
            // Also update the combined data structure
            if let combinedIndex = watchlistItemsWithStock.firstIndex(where: { $0.watchlistItem.symbol == symbol }) {
                watchlistItemsWithStock[combinedIndex].watchlistItem.alertsEnabled = newEnabled
            }
        }
        
        // Update in background
        Task {
            do {
                let currentItem = watchlistItems.first { $0.symbol == symbol }
                let newEnabled = currentItem?.alertsEnabled ?? false
                
                try await supabaseService.toggleWatchlistAlerts(symbol: symbol, enabled: newEnabled)
                
            } catch {
                // Revert the UI change if the API call fails
                await MainActor.run {
                    if let index = watchlistItems.firstIndex(where: { $0.symbol == symbol }) {
                        watchlistItems[index].alertsEnabled = !(watchlistItems[index].alertsEnabled)
                    }
                    if let combinedIndex = watchlistItemsWithStock.firstIndex(where: { $0.watchlistItem.symbol == symbol }) {
                        watchlistItemsWithStock[combinedIndex].watchlistItem.alertsEnabled = !(watchlistItemsWithStock[combinedIndex].watchlistItem.alertsEnabled)
                    }
                    self.errorMessage = error.localizedDescription
                }
                print("❌ Error toggling alerts: \(error)")
            }
        }
    }
    
    @MainActor
    func setAlert(for symbol: String, price: Double, type: String = "above") {
        Task {
            do {
                try await supabaseService.setWatchlistAlert(symbol: symbol, price: price, type: type)
                
                // Update local state
                if let index = watchlistItems.firstIndex(where: { $0.symbol == symbol }) {
                    watchlistItems[index].alertPrice = price
                    watchlistItems[index].alertType = type
                    watchlistItems[index].alertsEnabled = true
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
                print("❌ Error setting alert: \(error)")
            }
        }
    }
    
    @MainActor
    func updateWatchlistItem(symbol: String, priceTarget: Double? = nil, notes: String? = nil, alertPrice: Double? = nil, alertType: String? = nil, alertsEnabled: Bool? = nil) {
        Task {
            do {
                try await supabaseService.updateWatchlistItem(
                    symbol: symbol,
                    priceTarget: priceTarget,
                    notes: notes,
                    alertPrice: alertPrice,
                    alertType: alertType,
                    alertsEnabled: alertsEnabled
                )
                
                // Reload watchlist to get updated data
                await loadWatchlist()
                
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
                print("❌ Error updating watchlist item: \(error)")
            }
        }
    }
    
    @MainActor
    private func loadWatchlistWithStockData() async {
        do {
            let itemsWithStock = try await supabaseService.getWatchlistWithStockData()
            await MainActor.run {
                self.watchlistItemsWithStock = itemsWithStock
                
                // Update stock details and sentiments
                for itemWithStock in itemsWithStock {
                    if let stock = itemWithStock.stock {
                        self.stockDetails[stock.symbol] = stock
                    }
                }
            }
        } catch {
            print("❌ Error loading watchlist with stock data: \(error)")
        }
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
        do {
            let stock = try await supabaseService.fetchStockData(symbol: symbol)
            stockDetails[symbol] = stock
        } catch {
            print("❌ Error loading stock details for \(symbol): \(error)")
        }
    }
    
    @MainActor
    private func loadSentiment(for symbol: String) async {
        await sentimentService.getSentimentAnalysis(for: symbol)
        if let sentiment = sentimentService.currentSentiment, sentiment.symbol == symbol {
            sentiments[symbol] = sentiment
        }
    }
    
    @MainActor
    func refreshWatchlist() {
        loadWatchlist()
    }
    
    func sortedWatchlistItems() -> [WatchlistItem] {
        return watchlistItems.sorted { $0.symbol < $1.symbol }
    }
    
    func sortedWatchlistItemsWithStock() -> [WatchlistItemWithStock] {
        return watchlistItemsWithStock.sorted { $0.watchlistItem.symbol < $1.watchlistItem.symbol }
    }
    
    func getStockForSymbol(_ symbol: String) -> Stock? {
        return stockDetails[symbol]
    }
    
    func getSentimentForSymbol(_ symbol: String) -> SentimentAnalysis? {
        return sentiments[symbol]
    }
}

// MARK: - Settings View Model (Replaced by ModernSettingsViewModel)
// The modern settings implementation is now in ModernSettingsViewModel.swift

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
        
        Task {
            await loadWidgetDataAsync()
        }
    }
    
    @MainActor
    private func loadWidgetDataAsync() async {
        // Load data for each enabled widget
        let enabledWidgets = widgets.filter { $0.isEnabled }
        
        do {
            let searchData = await createSearchData()
            let newsData = createNewsData()
            let watchlistData = await createWatchlistData()
            let aiData = createAIData()
            let marketData = createMarketData()
            let trendingData = await createTrendingData()
            
            self.widgetData = WidgetData(
                searchData: searchData,
                newsData: newsData,
                watchlistData: watchlistData,
                aiData: aiData,
                marketData: marketData,
                trendingData: trendingData
            )
        } catch {
            print("❌ Error loading widget data: \(error)")
        }
        
        self.isLoading = false
    }
    
    private func createSearchData() async -> SearchWidgetData {
        do {
            let popularStocks = try await stockService.getPopularStocks()
            return SearchWidgetData(
                recentSearches: ["AAPL", "TSLA", "NVDA"],
                popularStocks: popularStocks
            )
        } catch {
            print("❌ Error creating search data: \(error)")
            return SearchWidgetData(
                recentSearches: ["AAPL", "TSLA", "NVDA"],
                popularStocks: []
            )
        }
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
    
    private func createWatchlistData() async -> WatchlistWidgetData {
        // Use popular stocks from service for watchlist
        do {
            let allStocks = try await stockService.getPopularStocks()
            let watchlistStocks = allStocks.prefix(3).map { $0 }
        
        var sentiments: [String: SentimentAnalysis] = [:]
        for stock in watchlistStocks {
            sentiments[stock.symbol] = sentimentService.getSentiment(for: stock.symbol)
        }
        
            return WatchlistWidgetData(stocks: watchlistStocks, sentiments: sentiments)
        } catch {
            print("❌ Error creating watchlist data: \(error)")
            return WatchlistWidgetData(stocks: [], sentiments: [:])
        }
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
    
    private func createTrendingData() async -> TrendingWidgetData {
        do {
            let stocks = try await stockService.getPopularStocks()
            return TrendingWidgetData(
                stocks: stocks,
                trends: ["AI", "Semiconductors", "EV", "Biotech"]
            )
        } catch {
            print("❌ Error creating trending data: \(error)")
            return TrendingWidgetData(
                stocks: [],
                trends: ["AI", "Semiconductors", "EV", "Biotech"]
            )
        }
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

// MARK: - New Home View Data Models
struct SentimentTile: Identifiable {
    let id = UUID()
    let ticker: String
    let companyName: String
    let sentimentScore: Double
    let sentimentLabel: String
    let currentPrice: Double
    let priceChange: Double
    let intradayData: [Double]
    
    init(ticker: String, companyName: String, sentimentScore: Double, currentPrice: Double, priceChange: Double) {
        self.ticker = ticker
        self.companyName = companyName
        self.sentimentScore = sentimentScore
        self.currentPrice = currentPrice
        self.priceChange = priceChange
        
        // Generate sentiment label based on score
        switch sentimentScore {
        case 0.7...:
            self.sentimentLabel = "Bullish"
        case 0.5..<0.7:
            self.sentimentLabel = "Neutral"
        default:
            self.sentimentLabel = "Bearish"
        }
        
        // Generate mock intraday data
        self.intradayData = (0..<20).map { _ in
            Double.random(in: 0.8...1.2)
        }
    }
}

struct AINudgeCard: Identifiable {
    let id = UUID()
    let insight: String
    let tag: String
    
    init(insight: String, tag: String) {
        self.insight = insight
        self.tag = tag
    }
}

// MARK: - Sentiment Feed View Model
class SentimentFeedViewModel: ObservableObject {
    @Published var sentimentTiles: [SentimentTile] = []
    @Published var isLoading = false
    
    init() {
        loadMockData()
    }
    
    func refreshData() {
        isLoading = true
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.loadMockData()
            self.isLoading = false
        }
    }
    
    private func loadMockData() {
        sentimentTiles = [
            SentimentTile(
                ticker: "TSLA",
                companyName: "Tesla Inc",
                sentimentScore: 0.85,
                currentPrice: 245.67,
                priceChange: 12.34
            ),
            SentimentTile(
                ticker: "AAPL",
                companyName: "Apple Inc",
                sentimentScore: 0.72,
                currentPrice: 178.45,
                priceChange: -2.15
            ),
            SentimentTile(
                ticker: "NVDA",
                companyName: "NVIDIA Corp",
                sentimentScore: 0.91,
                currentPrice: 485.23,
                priceChange: 23.67
            ),
            SentimentTile(
                ticker: "MSFT",
                companyName: "Microsoft Corp",
                sentimentScore: 0.68,
                currentPrice: 342.89,
                priceChange: 8.92
            ),
            SentimentTile(
                ticker: "GOOGL",
                companyName: "Alphabet Inc",
                sentimentScore: 0.55,
                currentPrice: 156.78,
                priceChange: -5.43
            ),
            SentimentTile(
                ticker: "AMZN",
                companyName: "Amazon.com Inc",
                sentimentScore: 0.78,
                currentPrice: 134.56,
                priceChange: 15.23
            ),
            SentimentTile(
                ticker: "META",
                companyName: "Meta Platforms",
                sentimentScore: 0.82,
                currentPrice: 298.34,
                priceChange: 18.76
            ),
            SentimentTile(
                ticker: "NFLX",
                companyName: "Netflix Inc",
                sentimentScore: 0.63,
                currentPrice: 445.12,
                priceChange: -3.21
            )
        ]
    }
}

// MARK: - AI Nudge Cards View Model
class AINudgeCardsViewModel: ObservableObject {
    @Published var aiCards: [AINudgeCard] = []
    @Published var selectedCardIndex = 0
    @Published var isLoading = false
    
    private var autoScrollTimer: Timer?
    
    init() {
        loadMockData()
        startAutoScroll()
    }
    
    deinit {
        autoScrollTimer?.invalidate()
    }
    
    func refreshCards() {
        isLoading = true
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.loadMockData()
            self.isLoading = false
        }
    }
    
    private func loadMockData() {
        aiCards = [
            AINudgeCard(
                insight: "Tech stocks are showing strong momentum with AI and semiconductor sectors leading gains. Consider monitoring NVDA and AMD for continued strength.",
                tag: "Trending"
            ),
            AINudgeCard(
                insight: "Earnings season approaches with major banks reporting next week. Financial sector sentiment is cautiously optimistic ahead of results.",
                tag: "Earnings Watch"
            ),
            AINudgeCard(
                insight: "Market volatility has increased 15% this week. Consider defensive positions in consumer staples and utilities for portfolio stability.",
                tag: "Volatility Spike"
            ),
            AINudgeCard(
                insight: "Federal Reserve meeting minutes suggest potential rate cuts in Q2. Bond yields are declining, which could benefit growth stocks.",
                tag: "Trending"
            ),
            AINudgeCard(
                insight: "Oil prices are surging due to supply concerns. Energy sector stocks like XOM and CVX are showing strong technical momentum.",
                tag: "Volatility Spike"
            ),
            AINudgeCard(
                insight: "Retail sales data exceeded expectations, indicating strong consumer spending. Consumer discretionary stocks may benefit from this trend.",
                tag: "Trending"
            )
        ]
    }
    
    private func startAutoScroll() {
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                self.selectedCardIndex = (self.selectedCardIndex + 1) % self.aiCards.count
            }
        }
    }
}

// MARK: - Market Status Enum
enum MarketStatus: String, CaseIterable {
    case open = "Market Open"
    case closed = "Market Closed"
    case preMarket = "Pre-Market"
    case afterHours = "After Hours"
}

// MARK: - Market Pulse View Model
class MarketPulseViewModel: ObservableObject {
    @Published var marketStatus: MarketStatus = .open
    @Published var bullishPercentage: Int = 68
    @Published var bullishTrend: Double = 2.3
    @Published var volatilityIndex: String = "VIX: 18.5"
    @Published var volatilityTrend: Double = -1.2
    @Published var aiConfidence: Int = 87
    @Published var aiConfidenceTrend: Double = 3.1
    @Published var newsSentiment: String = "Positive"
    @Published var newsSentimentTrend: Double = 1.8
    
    init() {
        startMarketStatusUpdates()
    }
    
    private func startMarketStatusUpdates() {
        // Simulate market status changes
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            // Randomly change market status for demo
            if Bool.random() {
                self.marketStatus = MarketStatus.allCases.randomElement() ?? .open
            }
        }
    }
}

// MARK: - AI Market Insight Data Models
struct AIMarketInsight: Identifiable {
    let id = UUID()
    let category: String
    let insight: String
    let confidence: Int
    let actionItems: [String]
    
    init(category: String, insight: String, confidence: Int, actionItems: [String] = []) {
        self.category = category
        self.insight = insight
        self.confidence = confidence
        self.actionItems = actionItems
    }
}

// MARK: - AI Market Insights View Model
class AIMarketInsightsViewModel: ObservableObject {
    @Published var insights: [AIMarketInsight] = []
    @Published var selectedInsightIndex = 0
    @Published var isLoading = false
    
    private var autoScrollTimer: Timer?
    
    init() {
        loadMockData()
        startAutoScroll()
    }
    
    deinit {
        autoScrollTimer?.invalidate()
    }
    
    func refreshInsights() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.loadMockData()
            self.isLoading = false
        }
    }
    
    private func loadMockData() {
        insights = [
            AIMarketInsight(
                category: "Trend Analysis",
                insight: "AI detects a 73% probability of continued tech sector momentum based on institutional flow patterns and earnings revisions.",
                confidence: 87,
                actionItems: ["Monitor NVDA, AMD, TSLA", "Consider tech ETF exposure", "Watch for earnings catalysts"]
            ),
            AIMarketInsight(
                category: "Risk Alert",
                insight: "Unusual options activity detected in financial sector. AI predicts 15% volatility increase in next 48 hours.",
                confidence: 92,
                actionItems: ["Review financial positions", "Consider hedging strategies", "Monitor JPM, BAC, WFC"]
            ),
            AIMarketInsight(
                category: "Opportunity",
                insight: "AI identifies undervalued healthcare stocks with strong fundamentals. 68% confidence in 12-month outperformance.",
                confidence: 68,
                actionItems: ["Research JNJ, PFE, UNH", "Consider healthcare ETFs", "Monitor FDA approvals"]
            ),
            AIMarketInsight(
                category: "Market Shift",
                insight: "Institutional money flow analysis shows rotation from growth to value. AI predicts 3-6 month trend change.",
                confidence: 78,
                actionItems: ["Review portfolio allocation", "Consider value ETFs", "Monitor sector rotation"]
            ),
            AIMarketInsight(
                category: "Risk Alert",
                insight: "AI detects potential market correction signals. Volatility expected to increase 25% in next 2 weeks.",
                confidence: 85,
                actionItems: ["Review risk exposure", "Consider defensive positions", "Monitor market breadth"]
            )
        ]
    }
    
    private func startAutoScroll() {
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                self.selectedInsightIndex = (self.selectedInsightIndex + 1) % self.insights.count
            }
        }
    }
}

// MARK: - Unusual Activity Alert Data Models
enum UnusualActivityType {
    case volumeSpike
    case priceMovement
    case newsImpact
    case insiderActivity
}

struct UnusualActivityAlert: Identifiable {
    let id = UUID()
    let type: UnusualActivityType
    let title: String
    let description: String
    let timeAgo: String
    let icon: String
    
    init(type: UnusualActivityType, title: String, description: String, timeAgo: String, icon: String) {
        self.type = type
        self.title = title
        self.description = description
        self.timeAgo = timeAgo
        self.icon = icon
    }
}

// MARK: - Unusual Activity View Model
class UnusualActivityViewModel: ObservableObject {
    @Published var alerts: [UnusualActivityAlert] = []
    
    init() {
        loadMockData()
    }
    
    func dismissAll() {
        withAnimation(.easeInOut(duration: 0.3)) {
            alerts.removeAll()
        }
    }
    
    private func loadMockData() {
        alerts = [
            UnusualActivityAlert(
                type: .volumeSpike,
                title: "Unusual Volume Spike",
                description: "TSLA volume 3x normal levels with 15% price movement",
                timeAgo: "2 min ago",
                icon: "chart.bar.fill"
            ),
            UnusualActivityAlert(
                type: .priceMovement,
                title: "Sharp Price Movement",
                description: "NVDA up 8% in 15 minutes on heavy institutional buying",
                timeAgo: "5 min ago",
                icon: "arrow.up.right.circle.fill"
            ),
            UnusualActivityAlert(
                type: .newsImpact,
                title: "News Impact Detected",
                description: "AAPL sentiment shifted negative on supply chain news",
                timeAgo: "8 min ago",
                icon: "newspaper.fill"
            ),
            UnusualActivityAlert(
                type: .insiderActivity,
                title: "Insider Trading Alert",
                description: "Unusual options activity detected in META ahead of earnings",
                timeAgo: "12 min ago",
                icon: "person.2.fill"
            )
        ]
    }
}

// MARK: - Market Sector Data Models
struct MarketSector: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let sentimentScore: Double
    
    init(name: String, icon: String, sentimentScore: Double) {
        self.name = name
        self.icon = icon
        self.sentimentScore = sentimentScore
    }
}

// MARK: - Market Sentiment Heatmap View Model
class MarketSentimentHeatmapViewModel: ObservableObject {
    @Published var sectors: [MarketSector] = []
    @Published var isLoading = false
    
    init() {
        loadMockData()
    }
    
    func refreshData() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.loadMockData()
            self.isLoading = false
        }
    }
    
    private func loadMockData() {
        sectors = [
            MarketSector(name: "Technology", icon: "laptopcomputer", sentimentScore: 85),
            MarketSector(name: "Healthcare", icon: "cross.case", sentimentScore: 72),
            MarketSector(name: "Finance", icon: "building.2", sentimentScore: 45),
            MarketSector(name: "Energy", icon: "bolt.fill", sentimentScore: 68),
            MarketSector(name: "Consumer", icon: "cart.fill", sentimentScore: 58),
            MarketSector(name: "Industrial", icon: "gearshape.fill", sentimentScore: 62),
            MarketSector(name: "Materials", icon: "cube.fill", sentimentScore: 41),
            MarketSector(name: "Real Estate", icon: "house.fill", sentimentScore: 35),
            MarketSector(name: "Utilities", icon: "bolt.circle", sentimentScore: 78)
        ]
    }
} 
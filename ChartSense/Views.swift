//
//  Views.swift
//  ChartSense
//
//  Created by Aidan Quach on 7/22/25.
//

import SwiftUI

// MARK: - Discover View (Combined Search + Sentiment)
struct DiscoverView: View {
    @StateObject private var searchViewModel = SearchViewModel()
    @StateObject private var sentimentViewModel = SentimentViewModel()
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingStockDetail = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                DiscoverHeader()
                
                // Search Content (Always visible)
                SearchContent(viewModel: searchViewModel)
            }
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingStockDetail) {
            if let selectedStock = appViewModel.selectedStock {
                ModernStockDetailView(stock: selectedStock)
                    .onDisappear {
                        appViewModel.selectedStock = nil
                        showingStockDetail = false
                    }
            }
        }
        .onReceive(appViewModel.$selectedStock) { stock in
            if stock != nil {
                showingStockDetail = true
            }
        }
        .onAppear {
            // Load initial data
            Task {
                await searchViewModel.loadInitialData()
            }
        }
    }
}

// MARK: - Stock Detail Sheet
struct StockDetailSheet: View {
    let stock: Stock
    @ObservedObject var sentimentViewModel: SentimentViewModel
    let onDismiss: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                StockDetailHeader(stock: stock, onDismiss: onDismiss)
                
                // Content
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Stock Overview Card
                        StockOverviewCard(stock: stock)
                        
                        // Sentiment Analysis
                        if let sentiment = sentimentViewModel.sentiment {
                            SentimentOverviewCard(sentiment: sentiment)
                        }
                        
                        // News Section
                        if !sentimentViewModel.newsItems.isEmpty {
                            NewsOverviewSection(newsItems: sentimentViewModel.newsItems)
                        }
                        
                        // Market Context
                        if let marketContext = sentimentViewModel.marketContext {
                            MarketContextCard(marketContext: marketContext)
                        }
                        
                        // Analyst Consensus
                        if let consensus = sentimentViewModel.analystConsensus {
                            AnalystConsensusDetailCard(consensus: consensus)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
            .navigationBarHidden(true)
        }
        .onAppear {
            sentimentViewModel.loadData(for: stock)
        }
    }
}

struct StockDetailHeader: View {
    let stock: Stock
    let onDismiss: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    .frame(width: 32, height: 32)
                    .background(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryBackground : AppTheme.light.colors.secondaryBackground)
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}

struct DiscoverHeader: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Discover")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

struct SearchContent: View {
    @ObservedObject var viewModel: SearchViewModel
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            SearchBar(
                text: $viewModel.searchText,
                placeholder: "Search stocks, ETFs...",
                onCommit: {
                    viewModel.performSearch()
                }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
            
            // Content
            ScrollView {
                LazyVStack(spacing: 20) {
                    if viewModel.isLoading {
                        LoadingCard()
                    } else if viewModel.hasSearched && viewModel.searchResults.isEmpty {
                        EmptySearchCard()
                    } else if !viewModel.searchResults.isEmpty {
                        SearchResultsSection(
                            results: viewModel.searchResults,
                            onSelect: { stock in
                                appViewModel.selectStock(stock)
                            }
                        )
                    } else {
                        // Default content when not searching
                        if !viewModel.recentSearches.isEmpty {
                            RecentSearchesSection(
                                searches: viewModel.recentSearches,
                                onSelect: viewModel.selectRecentSearch
                            )
                        }
                        
                        PopularStocksSection(
                            stocks: viewModel.popularStocks,
                            onSelect: { stock in
                                appViewModel.selectStock(stock)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 70) // Tab bar spacing
            }
        }
    }
}

// MARK: - Search View
struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Header
                VStack(spacing: 16) {
                    HStack {
                        Text("ChartSense")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        
                        Spacer()
                    }
                    
                    SearchBar(
                        text: $viewModel.searchText,
                        placeholder: "Search stocks, ETFs...",
                        onCommit: { }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                // Content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if viewModel.isLoading {
                            LoadingCard()
                        } else if viewModel.hasSearched && viewModel.searchResults.isEmpty {
                            EmptySearchCard()
                        } else if !viewModel.searchResults.isEmpty {
                            SearchResultsSection(
                                results: viewModel.searchResults,
                                onSelect: { stock in
                                    appViewModel.selectStock(stock)
                                }
                            )
                        } else {
                            // Default content when not searching
                            if !viewModel.recentSearches.isEmpty {
                                RecentSearchesSection(
                                    searches: viewModel.recentSearches,
                                    onSelect: viewModel.selectRecentSearch
                                )
                            }
                            
                            PopularStocksSection(
                                stocks: viewModel.popularStocks,
                                isLoading: viewModel.isLoading,
                                onSelect: { stock in
                                    appViewModel.selectStock(stock)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 70) // Tab bar spacing
                }
            }
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
            .navigationBarHidden(true)
        }
    }
}

struct SearchResultsSection: View {
    let results: [Stock]
    let onSelect: (Stock) -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Search Results", count: results.count)
            
            ForEach(results, id: \.symbol) { stock in
                Button(action: { onSelect(stock) }) {
                    StockListRow(stock: stock)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct RecentSearchesSection: View {
    let searches: [String]
    let onSelect: (String) -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Recent Searches", count: nil)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(searches, id: \.self) { search in
                        Button(action: { onSelect(search) }) {
                            Text(search)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background((themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary).opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.horizontal, -16)
        }
    }
}

struct PopularStocksSection: View {
    let stocks: [Stock]
    let isLoading: Bool
    let onSelect: (Stock) -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    init(stocks: [Stock], isLoading: Bool = false, onSelect: @escaping (Stock) -> Void) {
        self.stocks = stocks
        self.isLoading = isLoading
        self.onSelect = onSelect
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Popular Stocks", count: nil)
            
            if isLoading {
                ForEach(0..<5, id: \.self) { _ in
                    StockListRowSkeleton()
                }
            } else if stocks.isEmpty {
                EmptyStateView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "No Popular Stocks",
                    message: "Popular stocks will appear here once loaded.",
                    actionTitle: "Refresh",
                    action: {
                        // This would trigger a refresh
                    }
                )
            } else {
                ForEach(stocks, id: \.symbol) { stock in
                    Button(action: { onSelect(stock) }) {
                        StockListRow(stock: stock)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

struct EmptySearchCard: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NotionCard {
            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 50))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                
                Text("No results found")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Text("Try a different search term or stock symbol")
                    .font(.body)
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(32)
        }
    }
}

// MARK: - Sentiment View
struct SentimentView: View {
    @StateObject private var viewModel = SentimentViewModel()
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                if let stock = viewModel.currentStock {
                    SentimentHeader(stock: stock, onRefresh: viewModel.refreshData, onBack: {
                        appViewModel.selectedTab = 0 // Go back to search
                    })
                } else {
                    EmptyStateHeader()
                }
                
                // Content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if let stock = viewModel.currentStock {
                            SentimentContent(viewModel: viewModel)
                        } else {
                            EmptyStateContent()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 70) // Tab bar spacing
                }
            }
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
            .navigationBarHidden(true)
        }
        .onReceive(appViewModel.$selectedStock) { stock in
            if let stock = stock {
                viewModel.loadData(for: stock)
            }
        }
    }
}

struct SentimentHeader: View {
    let stock: Stock
    let onRefresh: () -> Void
    let onBack: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                // Back Button
                Button(action: onBack) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("Back")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                }
                
                Spacer()
                
                // Stock Info
                VStack(alignment: .trailing, spacing: 4) {
                    Text(stock.symbol)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Text(stock.companyName)
                        .font(.body)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                }
                
                Spacer()
                
                // Refresh Button
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

struct EmptyStateHeader: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Sentiment")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

struct SentimentContent: View {
    @ObservedObject var viewModel: SentimentViewModel
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Stock Quote Card
            if let stock = viewModel.currentStock {
                StockQuoteCard(stock: stock)
            }
            
            // Sentiment Analysis Card
            if viewModel.isLoadingSentiment {
                LoadingCard()
            } else if let sentiment = viewModel.sentiment {
                SentimentCard(sentiment: sentiment)
            }
            
            // News Categories Filter
            if !viewModel.newsItems.isEmpty {
                NewsCategoriesFilter(
                    categories: viewModel.newsCategories(),
                    selectedCategory: viewModel.selectedNewsCategory,
                    onCategorySelected: { category in
                        viewModel.selectedNewsCategory = category
                    }
                )
            }
            
            // News Section
            if viewModel.isLoadingNews {
                LoadingCard()
            } else if !viewModel.newsItems.isEmpty {
                NewsSection(
                    newsItems: viewModel.filteredNews(),
                    onNewsItemTapped: viewModel.openNewsArticle
                )
            }
            
            // Analyst Consensus
            if let consensus = viewModel.analystConsensus {
                AnalystConsensusCard(consensus: consensus)
            }
            
            // Market Context & Events
            if let marketContext = viewModel.marketContext {
                MarketContextSection(marketContext: marketContext)
            }
        }
    }
}

struct EmptyStateContent: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NotionCard {
            VStack(spacing: 24) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 60))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                
                VStack(spacing: 8) {
                    Text("Select a Stock")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Text("Choose a stock from the search tab to view its sentiment analysis and market insights")
                        .font(.body)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(32)
        }
    }
}

// MARK: - Watchlist View
struct WatchlistView: View {
    @StateObject private var viewModel = WatchlistViewModel()
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                WatchlistHeader(
                    onAddStock: { viewModel.showingAddStock = true },
                    onRefresh: viewModel.refreshWatchlist
                )
                
                // Content
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading watchlist...")
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    Spacer()
                } else if viewModel.watchlistItems.isEmpty {
                    EmptyWatchlistView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.sortedWatchlistItems(), id: \.symbol) { item in
                                WatchlistItemCard(
                                    item: item,
                                    stock: viewModel.stockDetails[item.symbol],
                                    sentiment: viewModel.sentiments[item.symbol],
                                    onSelect: { stock in
                                        appViewModel.selectStock(stock)
                                    },
                                    onRemove: {
                                        viewModel.removeFromWatchlist(item)
                                    },
                                    onToggleAlerts: {
                                        viewModel.toggleAlerts(for: item.symbol)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 70) // Tab bar spacing
                    }
                }
            }
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $viewModel.showingAddStock) {
            AddStockSheet { stock in
                viewModel.addToWatchlist(stock)
            }
        }
    }
}

struct WatchlistHeader: View {
    let onAddStock: () -> Void
    let onRefresh: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Watchlist")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                    }
                    
                    Button(action: onAddStock) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

struct EmptyWatchlistView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            NotionCard {
                VStack(spacing: 24) {
                    Image(systemName: "heart")
                        .font(.system(size: 60))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                    
                    VStack(spacing: 8) {
                        Text("Your Watchlist is Empty")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        
                        Text("Add stocks you want to track for quick access to their sentiment and market data")
                            .font(.body)
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(32)
            }
            .padding(.horizontal, 16)
            
            Spacer()
        }
    }
}

// MARK: - Home View
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HomeHeader(
                    onCustomize: { viewModel.showingWidgetCustomization = true }
                )
                
                // Widgets
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading your dashboard...")
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.widgets.filter { $0.isEnabled }.sorted { $0.order < $1.order }, id: \.id) { widget in
                                widgetView(for: widget)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 70) // Tab bar spacing
                    }
                }
            }
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $viewModel.showingWidgetCustomization) {
            WidgetCustomizationView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.loadWidgetData()
        }
    }
    
    @ViewBuilder
    private func widgetView(for widget: HomeWidget) -> some View {
        switch widget.type {
        case .search:
            if let data = viewModel.widgetData?.searchData {
                HomeWidgetCard(widget: widget, onTap: {
                    appViewModel.selectedTab = 1 // Switch to Discover tab
                }) {
                    SearchWidget(
                        data: data,
                        onStockSelected: { stock in
                            appViewModel.selectStock(stock)
                            appViewModel.selectedTab = 1 // Switch to Discover tab
                        },
                        onSearchTapped: {
                            appViewModel.selectedTab = 1 // Switch to Discover tab
                        }
                    )
                }
            }
            
        case .news:
            if let data = viewModel.widgetData?.newsData {
                HomeWidgetCard(widget: widget, onTap: {
                    // TODO: Navigate to full news view
                }) {
                    NewsWidget(
                        data: data,
                        onNewsTapped: { news in
                            // TODO: Open news article
                        }
                    )
                }
            }
            
        case .watchlist:
            if let data = viewModel.widgetData?.watchlistData {
                HomeWidgetCard(widget: widget, onTap: {
                    appViewModel.selectedTab = 3 // Switch to Watchlist tab
                }) {
                    WatchlistWidget(
                        data: data,
                        onStockTapped: { stock in
                            appViewModel.selectStock(stock)
                            appViewModel.selectedTab = 1 // Switch to Discover tab
                        }
                    )
                }
            }
            
        case .ai:
            if let data = viewModel.widgetData?.aiData {
                HomeWidgetCard(widget: widget, onTap: {
                    appViewModel.selectedTab = 2 // Switch to AI tab
                }) {
                    AIWidget(
                        data: data,
                        onAITapped: {
                            appViewModel.selectedTab = 2 // Switch to AI tab
                        }
                    )
                }
            }
            
        case .marketOverview:
            if let data = viewModel.widgetData?.marketData {
                HomeWidgetCard(widget: widget) {
                    MarketOverviewWidget(data: data)
                }
            }
            
        case .trendingStocks:
            if let data = viewModel.widgetData?.trendingData {
                HomeWidgetCard(widget: widget) {
                    TrendingStocksWidget(data: data)
                }
            }
        }
    }
}

struct HomeHeader: View {
    let onCustomize: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Home")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Text("Your personalized dashboard")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                }
                
                Spacer()
                
                Button(action: onCustomize) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                        .padding(8)
                        .background((themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary).opacity(0.1))
                        .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

struct WidgetCustomizationView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                    
                    Spacer()
                    
                    Text("Customize Home")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Spacer()
                    
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                Divider()
                    .background(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border)
                
                // Widget List
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(HomeWidget.WidgetType.allCases, id: \.self) { widgetType in
                            WidgetCustomizationRow(
                                widgetType: widgetType,
                                isEnabled: viewModel.widgets.contains { $0.type == widgetType && $0.isEnabled },
                                onToggle: {
                                    if let widget = viewModel.widgets.first(where: { $0.type == widgetType }) {
                                        viewModel.toggleWidget(widget)
                                    } else {
                                        // Widget doesn't exist, add it
                                        viewModel.addWidget(widgetType)
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
            .navigationBarHidden(true)
        }
    }
}

struct WidgetCustomizationRow: View {
    let widgetType: HomeWidget.WidgetType
    let isEnabled: Bool
    let onToggle: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill((themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary).opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: widgetType.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(widgetType.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Text(widgetType.description)
                        .font(.caption)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                }
                
                Spacer()
                
                // Toggle
                Toggle("", isOn: Binding(
                    get: { isEnabled },
                    set: { _ in onToggle() }
                ))
                .toggleStyle(SwitchToggleStyle(tint: themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
        
        Divider()
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border)
            .padding(.leading, 76)
    }
}

// MARK: - AI View
struct AIView: View {
    var body: some View {
        ModernAIChatView()
    }
}

struct AIHeader: View {
    let onReset: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Assistant")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Text("Your financial intelligence companion")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                }
                
                Spacer()
                
                Button(action: onReset) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                        Text("New Chat")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background((themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary).opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

// MARK: - Authentication View
struct AuthView: View {
    @ObservedObject private var viewModel = AuthViewModel.shared
    @State private var logoScale: CGFloat = 0.8
    @State private var formOffset: CGFloat = 50
    @State private var formOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Clean white background
            Color.white
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Logo Section
                    VStack(spacing: 24) {
                        // App Logo
                        ZStack {
                            Image("AppIconImage")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                                .scaleEffect(logoScale)
                                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: logoScale)
                        }
                        
                        VStack(spacing: 8) {
                            Text("ChartSense")
                                .font(.system(size: 32, weight: .bold, design: .default))
                                .foregroundColor(.black)
                            
                            Text("AI-Powered Stock Sentiment Analysis")
                                .font(.system(size: 16, weight: .medium, design: .default))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                    
                    // Form Section
                    VStack(spacing: 24) {
                        // Social Login Buttons
                        VStack(spacing: 12) {
                            AuthButton(
                                title: "Continue with Apple",
                                icon: "applelogo",
                                backgroundColor: .black,
                                isLoading: viewModel.isLoading
                            ) {
                                viewModel.signInWithApple()
                            }
                            
                            AuthButton(
                                title: "Continue with Google",
                                icon: "globe",
                                backgroundColor: .white,
                                textColor: .black,
                                isLoading: viewModel.isLoading
                            ) {
                                viewModel.signInWithGoogle()
                            }
                        }
                        
                        DividerWithText(text: "or")
                        
                        // Email Form
                        VStack(spacing: 16) {
                            if viewModel.isSignupMode {
                                AuthTextField(
                                    placeholder: "Full Name",
                                    text: $viewModel.name
                                )
                            }
                            
                            AuthTextField(
                                placeholder: "Email",
                                text: $viewModel.email
                            )
                            
                            AuthTextField(
                                placeholder: "Password",
                                text: $viewModel.password,
                                isSecure: true
                            )
                            
                            // Error Message
                            if let errorMessage = viewModel.errorMessage {
                                ErrorNotification(
                                    message: errorMessage,
                                    onDismiss: {
                                        viewModel.errorMessage = nil
                                    }
                                )
                                .padding(.top, 8)
                            }
                            
                            // Primary Action Button
                            AuthButton(
                                title: viewModel.isSignupMode ? "Sign Up for Free" : "Sign In",
                                icon: "envelope.fill",
                                backgroundColor: .blue,
                                isLoading: viewModel.isLoading
                            ) {
                                if viewModel.isSignupMode {
                                    viewModel.signUpWithEmail()
                                } else {
                                    viewModel.signInWithEmail()
                                }
                            }
                            
                            // Toggle Mode Button
                            Button(action: viewModel.toggleMode) {
                                HStack(spacing: 4) {
                                    Text(viewModel.isSignupMode ? "Already have an account?" : "Don't have an account?")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    Text(viewModel.isSignupMode ? "Sign In" : "Sign Up")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.blue)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .offset(y: formOffset)
                    .opacity(formOpacity)
                    .animation(.easeOut(duration: 0.8).delay(0.3), value: formOffset)
                    .animation(.easeOut(duration: 0.8).delay(0.3), value: formOpacity)
                    
                    Spacer(minLength: 40)
                    
                    // Terms and Conditions
                    VStack(spacing: 8) {
                        Text("By continuing, you agree to our")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 4) {
                            Button("Terms of Service") {
                                // TODO: Show Terms of Service
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.blue)
                            
                            Text("and")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Button("Privacy Policy") {
                                // TODO: Show Privacy Policy
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            // Animate logo
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                logoScale = 1.0
            }
            
            // Animate form
            formOffset = 0
            formOpacity = 1.0
        }
        .preferredColorScheme(.light) // Force light mode for login
    }
}

// MARK: - Settings View
struct SettingsView: View {
    var body: some View {
        ModernSettingsView()
    }
}

// MARK: - Settings Components (Replaced by ModernSettingsView.swift)

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    @StateObject private var themeManager = ThemeManager.shared
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                .padding(.horizontal, 4)
            
            content
        }
    }
}

struct SettingToggleCard: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NotionCard {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill((themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary).opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                }
                
                Spacer()
                
                // Toggle
                Toggle("", isOn: $isOn)
                    .toggleStyle(SwitchToggleStyle(tint: themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary))
            }
        }
    }
}

struct SettingPickerCard: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var selection: String
    let options: [(String, String)]
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingPicker = false
    
    var body: some View {
        NotionCard {
            Button(action: { showingPicker = true }) {
                HStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill((themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary).opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Current Value
                    Text(selection)
                        .font(.body)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showingPicker) {
            SettingsPickerSheet(
                title: title,
                selection: $selection,
                options: options
            )
        }
    }
}

struct SettingActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    let destructive: Bool
    @StateObject private var themeManager = ThemeManager.shared
    
    init(title: String, subtitle: String, icon: String, action: @escaping () -> Void, destructive: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.action = action
        self.destructive = destructive
    }
    
    var body: some View {
        NotionCard {
            Button(action: action) {
                HStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill((destructive ? (themeManager.isDarkMode ? AppTheme.dark.colors.error : AppTheme.light.colors.error) : (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)).opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(destructive ? (themeManager.isDarkMode ? AppTheme.dark.colors.error : AppTheme.light.colors.error) : (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary))
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(destructive ? (themeManager.isDarkMode ? AppTheme.dark.colors.error : AppTheme.light.colors.error) : (themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText))
                        
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct SettingNavigationCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let destination: AnyView
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationLink(destination: destination) {
            NotionCard {
                HStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill((themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary).opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Settings Picker Sheet
struct SettingsPickerSheet: View {
    let title: String
    @Binding var selection: String
    let options: [(String, String)]
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                    
                    Spacer()
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Spacer()
                    
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                Divider()
                    .background(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border)
                
                // Options List
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(options, id: \.0) { option in
                            Button(action: {
                                selection = option.0
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(option.0)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                                        
                                        Text(option.1)
                                            .font(.caption)
                                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                                    }
                                    
                                    Spacer()
                                    
                                    if selection == option.0 {
                                        Image(systemName: "checkmark")
                                            .font(.body)
                                            .fontWeight(.semibold)
                                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if option.0 != options.last?.0 {
                                Divider()
                                    .padding(.leading, 56)
                                    .background(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border)
                            }
                        }
                    }
                }
            }
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Supporting Views and Components
struct SectionHeader: View {
    let title: String
    let count: Int?
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            
            if let count = count {
                Text("\(count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryBackground : AppTheme.light.colors.secondaryBackground)
                    .cornerRadius(6)
            }
            
            Spacer()
        }
        .padding(.bottom, 8)
    }
}

struct StockListRow: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Stock Info
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Text(stock.companyName)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Price Info
            VStack(alignment: .trailing, spacing: 4) {
                if stock.currentPrice > 0 {
                    HStack(spacing: 4) {
                        Text(stock.formattedRealTimePrice)
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundColor(stock.hasRealTimeUpdate ? .green : (themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText))
                        
                        if stock.hasRealTimeUpdate {
                            Image(systemName: "livephoto")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.green)
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: stock.dailyChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(stock.dailyChange >= 0 ? Color.bullish : Color.bearish)
                        
                        Text(stock.formattedChange)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(stock.dailyChange >= 0 ? Color.bullish : Color.bearish)
                        
                        Text("(\(String(format: "%.2f%%", stock.dailyChangePercent)))")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(stock.dailyChange >= 0 ? Color.bullish : Color.bearish)
                    }
                } else {
                    HStack(spacing: 4) {
                        Text("N/A")
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    }
                    
                    HStack(spacing: 4) {
                        Text("N/A")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    }
                }
            }
        }
        .padding(16)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border, lineWidth: 0.5)
        )
        .shadow(
            color: themeManager.isDarkMode ? AppTheme.dark.shadows.card.color : AppTheme.light.shadows.card.color,
            radius: themeManager.isDarkMode ? AppTheme.dark.shadows.card.radius : AppTheme.light.shadows.card.radius,
            x: themeManager.isDarkMode ? AppTheme.dark.shadows.card.x : AppTheme.light.shadows.card.x,
            y: themeManager.isDarkMode ? AppTheme.dark.shadows.card.y : AppTheme.light.shadows.card.y
        )
    }
}

struct StockListRowSkeleton: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Stock Info skeleton
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryBackground : AppTheme.light.colors.tertiaryBackground)
                    .frame(width: 60, height: 16)
                    .shimmer()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryBackground : AppTheme.light.colors.tertiaryBackground)
                    .frame(width: 120, height: 14)
                    .shimmer()
            }
            
            Spacer()
            
            // Price Info skeleton
            VStack(alignment: .trailing, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryBackground : AppTheme.light.colors.tertiaryBackground)
                    .frame(width: 80, height: 16)
                    .shimmer()
                
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryBackground : AppTheme.light.colors.tertiaryBackground)
                        .frame(width: 60, height: 13)
                        .shimmer()
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryBackground : AppTheme.light.colors.tertiaryBackground)
                        .frame(width: 70, height: 12)
                        .shimmer()
                }
            }
        }
        .padding(16)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border, lineWidth: 0.5)
        )
    }
}

// Placeholder views for complex components that would be implemented
struct NewsCategoriesFilter: View {
    let categories: [(category: NewsItem.NewsCategory, count: Int)]
    let selectedCategory: NewsItem.NewsCategory?
    let onCategorySelected: (NewsItem.NewsCategory?) -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button("All") {
                    onCategorySelected(nil)
                }
                .foregroundColor(selectedCategory == nil ? .white : (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedCategory == nil ? (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary) : (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary).opacity(0.1))
                .cornerRadius(12)
                
                ForEach(categories, id: \.category) { categoryInfo in
                    Button("\(categoryInfo.category.rawValue) (\(categoryInfo.count))") {
                        onCategorySelected(categoryInfo.category)
                    }
                    .foregroundColor(selectedCategory == categoryInfo.category ? .white : (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(selectedCategory == categoryInfo.category ? (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary) : (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary).opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.horizontal, -16)
    }
}

struct NewsSection: View {
    let newsItems: [NewsItem]
    let onNewsItemTapped: (NewsItem) -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Latest News", count: newsItems.count)
            
            ForEach(newsItems) { newsItem in
                NewsCard(newsItem: newsItem) {
                    onNewsItemTapped(newsItem)
                }
            }
        }
    }
}

struct MarketContextSection: View {
    let marketContext: MarketContext
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Market Context", count: nil)
            
            // Upcoming Events
            if !marketContext.upcomingEvents.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Upcoming Events")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    ForEach(marketContext.upcomingEvents.prefix(3)) { event in
                        EventCard(event: event)
                    }
                }
            }
        }
    }
}

struct WatchlistItemCard: View {
    let item: WatchlistItem
    let stock: Stock?
    let sentiment: SentimentAnalysis?
    let onSelect: (Stock) -> Void
    let onRemove: () -> Void
    let onToggleAlerts: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NotionCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.symbol)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        
                        Text(item.companyName)
                            .font(.body)
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    if let stock = stock {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(stock.formattedPrice)
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                            
                            Text(stock.formattedChange)
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundColor(stock.isPositiveChange ? (themeManager.isDarkMode ? AppTheme.dark.colors.success : AppTheme.light.colors.success) : (themeManager.isDarkMode ? AppTheme.dark.colors.error : AppTheme.light.colors.error))
                        }
                    }
                }
                
                if let sentiment = sentiment {
                    HStack {
                        Image(systemName: sentiment.overallRating.icon)
                            .foregroundColor(sentimentColor(sentiment))
                            .font(.caption)
                        
                        Text(sentiment.overallRating.rawValue)
                            .font(.caption)
                            .foregroundColor(sentimentColor(sentiment))
                        
                        Spacer()
                    }
                }
                
                HStack {
                    if let stock = stock {
                        Button("View Details") {
                            onSelect(stock)
                        }
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button(action: onToggleAlerts) {
                            Image(systemName: item.alertsEnabled ? "bell.fill" : "bell")
                                .foregroundColor(item.alertsEnabled ? (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary) : (themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText))
                        }
                        
                        Button(action: onRemove) {
                            Image(systemName: "trash")
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.error : AppTheme.light.colors.error)
                        }
                    }
                }
            }
        }
    }
    
    private func sentimentColor(_ sentiment: SentimentAnalysis) -> Color {
        switch sentiment.overallRating {
        case .stronglyBullish, .bullish:
            return themeManager.isDarkMode ? AppTheme.dark.colors.success : AppTheme.light.colors.success
        case .cautiouslyOptimistic:
            return themeManager.isDarkMode ? AppTheme.dark.colors.accent : AppTheme.light.colors.accent
        case .neutral:
            return themeManager.isDarkMode ? AppTheme.dark.colors.neutral : AppTheme.light.colors.neutral
        case .bearishUndercurrents:
            return themeManager.isDarkMode ? AppTheme.dark.colors.warning : AppTheme.light.colors.warning
        case .bearish, .highlyNegative:
            return themeManager.isDarkMode ? AppTheme.dark.colors.error : AppTheme.light.colors.error
        }
    }
}

// MARK: - Setting Row Components
struct SettingToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
        }
    }
}

struct SettingPickerRow<T: Hashable & CaseIterable & RawRepresentable>: View where T.RawValue == String {
    let title: String
    let icon: String
    @Binding var selection: T
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            
            Spacer()
            
            Picker("", selection: $selection) {
                ForEach(Array(T.allCases), id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
}

struct SettingActionRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    let destructive: Bool
    @StateObject private var themeManager = ThemeManager.shared
    
    init(title: String, icon: String, action: @escaping () -> Void, destructive: Bool = false) {
        self.title = title
        self.icon = icon
        self.action = action
        self.destructive = destructive
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(destructive ? (themeManager.isDarkMode ? AppTheme.dark.colors.error : AppTheme.light.colors.error) : (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary))
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(destructive ? (themeManager.isDarkMode ? AppTheme.dark.colors.error : AppTheme.light.colors.error) : (themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText))
                
                Spacer()
            }
        }
    }
}

struct SettingNavigationRow: View {
    let title: String
    let icon: String
    let destination: AnyView
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Spacer()
            }
        }
    }
}

// MARK: - Enhanced Sheet Views with Navigation
struct AddStockSheet: View {
    let onAddStock: (Stock) -> Void
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var searchViewModel = SearchViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                    
                    Spacer()
                    
                    Text("Add Stock")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Spacer()
                    
                    // Invisible spacer for balance
                    Text("Cancel")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                Divider()
                    .background(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border)
                
                // Content
                VStack(spacing: 16) {
                    SearchBar(
                        text: $searchViewModel.searchText,
                        placeholder: "Search for stocks to add...",
                        onCommit: { }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    if searchViewModel.isLoadingAllStocks {
                        Spacer()
                        ProgressView("Loading stocks...")
                        Spacer()
                    } else if !searchViewModel.searchResults.isEmpty {
                        List(searchViewModel.searchResults, id: \.symbol) { stock in
                            StockListRow(stock: stock)
                                .onTapGesture {
                                    onAddStock(stock)
                                    presentationMode.wrappedValue.dismiss()
                                }
                        }
                        .listStyle(PlainListStyle())
                    } else {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 50))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                            
                            Text("All Available Stocks")
                                .font(.body)
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 32)
                        Spacer()
                    }
                }
            }
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Enhanced About Views with Navigation
struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            HStack {
                Button("Back") {
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                
                Spacer()
                
                Text("About")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Spacer()
                
                // Invisible spacer for balance
                Text("Back")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
                .background(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border)
            
            // Content
            ScrollView {
                VStack(spacing: 32) {
                    // App Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary,
                                        themeManager.isDarkMode ? AppTheme.dark.colors.secondary : AppTheme.light.colors.secondary
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        if themeManager.isDarkMode {
                            // For dark mode, use a styled version
                            Image("AppIconImage")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary, lineWidth: 2)
                                )
                        } else {
                            // For light mode, use the original icon
                            Image("AppIconImage")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                    // App Info
                    VStack(spacing: 16) {
                        Text("ChartSense")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        
                        Text("AI-Powered Stock Sentiment Analysis")
                            .font(.body)
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                            .multilineTextAlignment(.center)
                        
                        Text("Version 1.0.0 • Build 1")
                            .font(.caption)
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                    }
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            FeatureRow(icon: "brain.head.profile", title: "AI-Powered Sentiment Analysis", description: "Advanced machine learning for market insights")
                            FeatureRow(icon: "newspaper", title: "Real-time News Integration", description: "Latest financial news and market updates")
                            FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Comprehensive Market Data", description: "Detailed stock information and analytics")
                            FeatureRow(icon: "heart", title: "Personalized Watchlists", description: "Track your favorite stocks and ETFs")
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 32)
            }
        }
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
        .navigationBarHidden(true)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill((themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary).opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            }
            
            Spacer()
        }
    }
}

struct PrivacyView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            HStack {
                Button("Back") {
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                
                Spacer()
                
                Text("Privacy Policy")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Spacer()
                
                // Invisible spacer for balance
                Text("Back")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
                .background(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Your privacy is important to us. This policy describes how ChartSense collects, uses, and protects your information.")
                        .font(.body)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        PolicySection(title: "Information We Collect", content: "We collect watchlist data, search history, and app preferences to provide personalized experiences.")
                        PolicySection(title: "How We Use Information", content: "Your data helps us deliver relevant stock insights, news, and market analysis tailored to your interests.")
                        PolicySection(title: "Data Protection", content: "We implement industry-standard security measures to protect your personal information.")
                        PolicySection(title: "Third-Party Services", content: "We may use third-party services for data analysis and market information, all with appropriate privacy safeguards.")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
            }
        }
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
        .navigationBarHidden(true)
    }
}

struct PolicySection: View {
    let title: String
    let content: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            
            Text(content)
                .font(.body)
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
        }
    }
}

struct TermsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            HStack {
                Button("Back") {
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                
                Spacer()
                
                Text("Terms of Service")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Spacer()
                
                // Invisible spacer for balance
                Text("Back")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
                .background(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("By using ChartSense, you agree to these terms of service. Please read them carefully.")
                        .font(.body)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        PolicySection(title: "Acceptance of Terms", content: "Using ChartSense constitutes acceptance of these terms and any future modifications.")
                        PolicySection(title: "Use of Service", content: "ChartSense is for informational purposes only. We do not provide financial advice.")
                        PolicySection(title: "Data Usage", content: "You grant us permission to use your data to provide and improve our services.")
                        PolicySection(title: "Limitation of Liability", content: "ChartSense is not liable for any investment decisions made based on our data or analysis.")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
            }
        }
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
        .navigationBarHidden(true)
    }
} 
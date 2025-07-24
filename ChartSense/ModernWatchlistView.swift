//
//  ModernWatchlistView.swift
//  ChartSense
//
//  Created by Aidan Quach on 7/22/25.
//

import SwiftUI

// MARK: - Modern Watchlist View
struct ModernWatchlistView: View {
    @StateObject private var viewModel = WatchlistViewModel()
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingAddStock = false
    @State private var searchText = ""
    @State private var selectedSortOption = SortOption.symbol
    @State private var showingSortMenu = false
    @State private var showingFilterMenu = false
    @State private var selectedFilter = FilterOption.all
    
    enum SortOption: String, CaseIterable {
        case symbol = "Symbol"
        case name = "Name"
        case price = "Price"
        case change = "Change"
        case sentiment = "Sentiment"
        case added = "Added"
        
        var icon: String {
            switch self {
            case .symbol: return "textformat.abc"
            case .name: return "building.2"
            case .price: return "dollarsign.circle"
            case .change: return "chart.line.uptrend.xyaxis"
            case .sentiment: return "brain.head.profile"
            case .added: return "calendar"
            }
        }
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case bullish = "Bullish"
        case bearish = "Bearish"
        case alerts = "Alerts"
        case targets = "Price Targets"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .bullish: return "arrow.up.circle"
            case .bearish: return "arrow.down.circle"
            case .alerts: return "bell"
            case .targets: return "target"
            }
        }
    }
    
    var filteredAndSortedItems: [WatchlistItem] {
        let filtered = viewModel.watchlistItems.filter { item in
            let matchesSearch = searchText.isEmpty || 
                item.symbol.localizedCaseInsensitiveContains(searchText) ||
                item.companyName.localizedCaseInsensitiveContains(searchText)
            
            let matchesFilter: Bool
            switch selectedFilter {
            case .all:
                matchesFilter = true
            case .bullish:
                if let sentiment = viewModel.sentiments[item.symbol] {
                    matchesFilter = sentiment.overallRating == .bullish || sentiment.overallRating == .stronglyBullish
                } else {
                    matchesFilter = false
                }
            case .bearish:
                if let sentiment = viewModel.sentiments[item.symbol] {
                    matchesFilter = sentiment.overallRating == .bearish || sentiment.overallRating == .highlyNegative
                } else {
                    matchesFilter = false
                }
            case .alerts:
                matchesFilter = item.alertsEnabled
            case .targets:
                matchesFilter = item.priceTarget != nil
            }
            
            return matchesSearch && matchesFilter
        }
        
        return filtered.sorted { first, second in
            switch selectedSortOption {
            case .symbol:
                return first.symbol < second.symbol
            case .name:
                return first.companyName < second.companyName
            case .price:
                let firstPrice = viewModel.stockDetails[first.symbol]?.currentPrice ?? 0
                let secondPrice = viewModel.stockDetails[second.symbol]?.currentPrice ?? 0
                return firstPrice > secondPrice
            case .change:
                let firstChange = viewModel.stockDetails[first.symbol]?.dailyChangePercent ?? 0
                let secondChange = viewModel.stockDetails[second.symbol]?.dailyChangePercent ?? 0
                return firstChange > secondChange
            case .sentiment:
                let firstSentiment = viewModel.sentiments[first.symbol]?.overallRating.rawValue ?? ""
                let secondSentiment = viewModel.sentiments[second.symbol]?.overallRating.rawValue ?? ""
                return firstSentiment < secondSentiment
            case .added:
                return first.addedDate > second.addedDate
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Modern Header
                ModernWatchlistHeader(
                    searchText: $searchText,
                    selectedSortOption: $selectedSortOption,
                    selectedFilter: $selectedFilter,
                    showingSortMenu: $showingSortMenu,
                    showingFilterMenu: $showingFilterMenu,
                    onAddStock: { showingAddStock = true },
                    onRefresh: viewModel.refreshWatchlist
                )
                
                // Content
                if viewModel.isLoading {
                    ModernLoadingView()
                } else if filteredAndSortedItems.isEmpty {
                    ModernEmptyWatchlistView(
                        hasSearchText: !searchText.isEmpty,
                        hasFilters: selectedFilter != .all,
                        onClearSearch: { searchText = "" },
                        onClearFilters: { selectedFilter = .all }
                    )
                } else {
                    ModernWatchlistContent(
                        items: filteredAndSortedItems,
                        stockDetails: viewModel.stockDetails,
                        sentiments: viewModel.sentiments,
                        onSelect: { stock in
                            appViewModel.selectStock(stock)
                        },
                        onRemove: { item in
                            viewModel.removeFromWatchlist(item)
                        },
                        onToggleAlerts: { symbol in
                            viewModel.toggleAlerts(for: symbol)
                        }
                    )
                }
            }
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddStock) {
            ModernAddStockSheet { stock in
                viewModel.addToWatchlist(stock)
            }
        }
    }
}

// MARK: - Modern Watchlist Header
struct ModernWatchlistHeader: View {
    @Binding var searchText: String
    @Binding var selectedSortOption: ModernWatchlistView.SortOption
    @Binding var selectedFilter: ModernWatchlistView.FilterOption
    @Binding var showingSortMenu: Bool
    @Binding var showingFilterMenu: Bool
    let onAddStock: () -> Void
    let onRefresh: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Main Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Watchlist")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Text("Track your favorite stocks")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                            .frame(width: 40, height: 40)
                            .background(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryBackground : AppTheme.light.colors.secondaryBackground)
                            .cornerRadius(10)
                    }
                    
                    Button(action: onAddStock) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                    }
                }
            }
            
            // Search Bar
            ModernSearchBar(text: $searchText, placeholder: "Search watchlist...")
            
            // Filter and Sort Controls
            HStack(spacing: 12) {
                // Sort Button
                Button(action: { showingSortMenu = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: selectedSortOption.icon)
                            .font(.system(size: 14, weight: .medium))
                        
                        Text(selectedSortOption.rawValue)
                            .font(.system(size: 14, weight: .medium))
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryBackground : AppTheme.light.colors.secondaryBackground)
                    .cornerRadius(8)
                }
                .actionSheet(isPresented: $showingSortMenu) {
                    ActionSheet(
                        title: Text("Sort by"),
                        buttons: ModernWatchlistView.SortOption.allCases.map { option in
                            .default(Text(option.rawValue)) {
                                selectedSortOption = option
                            }
                        } + [.cancel()]
                    )
                }
                
                // Filter Button
                Button(action: { showingFilterMenu = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: selectedFilter.icon)
                            .font(.system(size: 14, weight: .medium))
                        
                        Text(selectedFilter.rawValue)
                            .font(.system(size: 14, weight: .medium))
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryBackground : AppTheme.light.colors.secondaryBackground)
                    .cornerRadius(8)
                }
                .actionSheet(isPresented: $showingFilterMenu) {
                    ActionSheet(
                        title: Text("Filter by"),
                        buttons: ModernWatchlistView.FilterOption.allCases.map { option in
                            .default(Text(option.rawValue)) {
                                selectedFilter = option
                            }
                        } + [.cancel()]
                    )
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }
}

// MARK: - Modern Search Bar
struct ModernSearchBar: View {
    @Binding var text: String
    let placeholder: String
    @StateObject private var themeManager = ThemeManager.shared
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                .focused($isFocused)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryBackground : AppTheme.light.colors.secondaryBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused ? (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary) : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Modern Loading View
struct ModernLoadingView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary))
                
                Text("Loading your watchlist...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            }
            
            Spacer()
        }
    }
}

// MARK: - Modern Empty Watchlist View
struct ModernEmptyWatchlistView: View {
    let hasSearchText: Bool
    let hasFilters: Bool
    let onClearSearch: () -> Void
    let onClearFilters: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: hasSearchText || hasFilters ? "magnifyingglass" : "heart")
                    .font(.system(size: 60))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                
                VStack(spacing: 8) {
                    Text(hasSearchText || hasFilters ? "No matching stocks" : "Your Watchlist is Empty")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Text(hasSearchText || hasFilters ? "Try adjusting your search or filters" : "Add stocks you want to track for quick access to their sentiment and market data")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                if hasSearchText || hasFilters {
                    HStack(spacing: 12) {
                        if hasSearchText {
                            Button("Clear Search", action: onClearSearch)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        
                        if hasFilters {
                            Button("Clear Filters", action: onClearFilters)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.purple)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Modern Watchlist Content
struct ModernWatchlistContent: View {
    let items: [WatchlistItem]
    let stockDetails: [String: Stock]
    let sentiments: [String: SentimentAnalysis]
    let onSelect: (Stock) -> Void
    let onRemove: (WatchlistItem) -> Void
    let onToggleAlerts: (String) -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(items, id: \.symbol) { item in
                    ModernWatchlistCard(
                        item: item,
                        stock: stockDetails[item.symbol],
                        sentiment: sentiments[item.symbol],
                        onSelect: onSelect,
                        onRemove: { onRemove(item) },
                        onToggleAlerts: { onToggleAlerts(item.symbol) }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Tab bar + extra spacing
        }
    }
}

// MARK: - Modern Watchlist Card
struct ModernWatchlistCard: View {
    let item: WatchlistItem
    let stock: Stock?
    let sentiment: SentimentAnalysis?
    let onSelect: (Stock) -> Void
    let onRemove: () -> Void
    let onToggleAlerts: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingOptions = false
    
    var body: some View {
        Button(action: {
            if let stock = stock {
                onSelect(stock)
            }
        }) {
            VStack(spacing: 0) {
                // Main Content
                HStack(spacing: 16) {
                    // Stock Info
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(item.symbol)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                            
                            if item.alertsEnabled {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                            }
                        }
                        
                        Text(item.companyName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Price Info
                    if let stock = stock {
                        VStack(alignment: .trailing, spacing: 6) {
                            Text(stock.formattedPrice)
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                            
                            HStack(spacing: 4) {
                                Image(systemName: stock.isPositiveChange ? "arrow.up.right" : "arrow.down.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(stock.isPositiveChange ? Color.bullish : Color.bearish)
                                
                                Text(stock.formattedChangePercent)
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .foregroundColor(stock.isPositiveChange ? Color.bullish : Color.bearish)
                            }
                        }
                    } else {
                        VStack(alignment: .trailing, spacing: 6) {
                            Text("--")
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                            
                            Text("Loading...")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                        }
                    }
                    
                    // Options Button
                    Button(action: { showingOptions = true }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                            .frame(width: 32, height: 32)
                            .background(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryBackground : AppTheme.light.colors.tertiaryBackground)
                            .cornerRadius(8)
                    }
                    .actionSheet(isPresented: $showingOptions) {
                        ActionSheet(
                            title: Text(item.symbol),
                            message: Text(item.companyName),
                            buttons: [
                                .default(Text(item.alertsEnabled ? "Disable Alerts" : "Enable Alerts")) {
                                    onToggleAlerts()
                                },
                                .destructive(Text("Remove from Watchlist")) {
                                    onRemove()
                                },
                                .cancel()
                            ]
                        )
                    }
                }
                .padding(16)
                
                // Sentiment Bar (if available)
                if let sentiment = sentiment {
                    HStack(spacing: 8) {
                        Image(systemName: sentiment.overallRating.icon)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(sentimentColor(sentiment))
                        
                        Text(sentiment.overallRating.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(sentimentColor(sentiment))
                        
                        Spacer()
                        
                        if let stock = stock, let target = item.priceTarget {
                            HStack(spacing: 4) {
                                Text("Target:")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                                
                                Text(String(format: "$%.2f", target))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func sentimentColor(_ sentiment: SentimentAnalysis) -> Color {
        switch sentiment.overallRating {
        case .stronglyBullish, .bullish:
            return Color.bullish
        case .cautiouslyOptimistic:
            return .orange
        case .neutral:
            return .gray
        case .bearishUndercurrents:
            return .orange
        case .bearish, .highlyNegative:
            return Color.bearish
        }
    }
}

// MARK: - Modern Add Stock Sheet
struct ModernAddStockSheet: View {
    let onAdd: (Stock) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var searchViewModel = SearchViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                    
                    Spacer()
                    
                    Text("Add to Watchlist")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Spacer()
                    
                    // Invisible spacer for balance
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                Divider()
                    .background(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border)
                
                // Search Bar
                ModernSearchBar(
                    text: $searchViewModel.searchText,
                    placeholder: "Search for stocks to add..."
                )
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Results
                if searchViewModel.isLoading {
                    Spacer()
                    ProgressView("Searching...")
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    Spacer()
                } else if !searchViewModel.searchResults.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(searchViewModel.searchResults, id: \.symbol) { stock in
                                ModernAddStockRow(
                                    stock: stock,
                                    onAdd: { stock in
                                        onAdd(stock)
                                        dismiss()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                } else if searchViewModel.hasSearched {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                        
                        Text("No stocks found")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        
                        Text("Try searching with a different term")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    }
                    Spacer()
                } else {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 40))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                        
                        Text("Search for stocks")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        
                        Text("Enter a stock symbol or company name")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    }
                    Spacer()
                }
            }
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Modern Add Stock Row
struct ModernAddStockRow: View {
    let stock: Stock
    let onAdd: (Stock) -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: { onAdd(stock) }) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(stock.symbol)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Text(stock.companyName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(stock.formattedPrice)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Text(stock.formattedChangePercent)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(stock.isPositiveChange ? Color.bullish : Color.bearish)
                }
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
            }
            .padding(16)
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 
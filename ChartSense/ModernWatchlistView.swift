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
    

    

    
    var filteredItems: [WatchlistItemWithStock] {
        return viewModel.watchlistItemsWithStock.filter { itemWithStock in
            let item = itemWithStock.watchlistItem
            let stock = itemWithStock.stock
            
            let matchesSearch = searchText.isEmpty || 
                item.symbol.localizedCaseInsensitiveContains(searchText) ||
                item.companyName.localizedCaseInsensitiveContains(searchText)
            
            return matchesSearch
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Modern Header
                ModernWatchlistHeader(
                    searchText: $searchText,
                    onAddStock: { showingAddStock = true },
                    onRefresh: viewModel.refreshWatchlist
                )
                
                // Content
                if viewModel.isLoading && viewModel.watchlistItemsWithStock.isEmpty {
                    ModernLoadingView()
                } else if filteredItems.isEmpty {
                    ModernEmptyWatchlistView(
                        hasSearchText: !searchText.isEmpty,
                        onClearSearch: { searchText = "" }
                    )
                } else {
                    ModernWatchlistContent(
                        items: filteredItems,
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
    @State private var animateSearch = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Enhanced search icon with animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isFocused ? 
                                [Color.blue.opacity(0.2), Color.purple.opacity(0.2)] :
                                [Color.clear, Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .scaleEffect(animateSearch ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateSearch)
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isFocused ? 
                        (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary) :
                        (themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText))
            }
            
            // Enhanced text field
            TextField(placeholder, text: $text)
                .font(.system(size: 16, weight: .medium, design: .default))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                .focused($isFocused)
                .onAppear {
                    animateSearch = true
                }
            
            // Enhanced clear button
            if !text.isEmpty {
                Button(action: { 
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        text = "" 
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.red)
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.isDarkMode ? 
                    Color(hex: "1A1A1A") : 
                    Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: isFocused ? 
                                    [Color.blue.opacity(0.6), Color.purple.opacity(0.6)] :
                                    [Color.clear, Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isFocused ? 2 : 0
                        )
                )
        )
        .shadow(
            color: themeManager.isDarkMode ? 
                Color.black.opacity(0.3) : 
                Color.black.opacity(0.08),
            radius: isFocused ? 12 : 8,
            x: 0,
            y: isFocused ? 6 : 4
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: isFocused)
    }
}

// MARK: - Modern Loading View
struct ModernLoadingView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.3)
                    .progressViewStyle(CircularProgressViewStyle(tint: themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary))
                
                VStack(spacing: 8) {
                    Text("Loading Watchlist")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Text("Fetching your stocks...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Modern Empty Watchlist View
struct ModernEmptyWatchlistView: View {
    let hasSearchText: Bool
    let onClearSearch: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: hasSearchText ? "magnifyingglass" : "heart")
                    .font(.system(size: 60))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                
                VStack(spacing: 8) {
                    Text(hasSearchText ? "No matching stocks" : "Your Watchlist is Empty")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Text(hasSearchText ? "Try adjusting your search" : "Add stocks you want to track for quick access to their sentiment and market data")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                if hasSearchText {
                    Button("Clear Search", action: onClearSearch)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Modern Watchlist Content
struct ModernWatchlistContent: View {
    let items: [WatchlistItemWithStock]
    let sentiments: [String: SentimentAnalysis]
    let onSelect: (Stock) -> Void
    let onRemove: (WatchlistItem) -> Void
    let onToggleAlerts: (String) -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(items, id: \.id) { itemWithStock in
                    ModernWatchlistCard(
                        item: itemWithStock.watchlistItem,
                        stock: itemWithStock.stock,
                        sentiment: sentiments[itemWithStock.watchlistItem.symbol],
                        onSelect: onSelect,
                        onRemove: { onRemove(itemWithStock.watchlistItem) },
                        onToggleAlerts: { onToggleAlerts(itemWithStock.watchlistItem.symbol) }
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
    @State private var isPressed = false
    @State private var animateCard = false
    
    var body: some View {
        Button(action: {
            if let stock = stock {
                onSelect(stock)
            }
        }) {
            VStack(spacing: 0) {
                // Enhanced Main Content
                HStack(spacing: 20) {
                    // Enhanced Stock Info with Visual Accent
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            // Stock symbol with accent
                            Text(item.symbol)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                            
                            // Sentiment indicator badge
                            if let sentiment = sentiment {
                                ZStack {
                                    Circle()
                                        .fill(sentimentColor(sentiment).opacity(0.15))
                                        .frame(width: 24, height: 24)
                                    
                                    Image(systemName: sentiment.overallRating.icon)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(sentimentColor(sentiment))
                                }
                            }
                        }
                        
                        Text(item.companyName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Enhanced Price Info with Visual Impact
                    if let stock = stock {
                        VStack(alignment: .trailing, spacing: 8) {
                            Text(stock.formattedPrice)
                                .font(.system(size: 22, weight: .bold, design: .monospaced))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                            
                            HStack(spacing: 6) {
                                // Enhanced change indicator
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(stock.isPositiveChange ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                                        .frame(width: 60, height: 24)
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: stock.isPositiveChange ? "arrow.up.right" : "arrow.down.right")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(stock.isPositiveChange ? Color.green : Color.red)
                                        
                                        Text(stock.formattedChangePercent)
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundColor(stock.isPositiveChange ? Color.green : Color.red)
                                    }
                                }
                            }
                        }
                    } else {
                        VStack(alignment: .trailing, spacing: 8) {
                            Text("--")
                                .font(.system(size: 22, weight: .bold, design: .monospaced))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                            
                            Text("Loading...")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                        }
                    }
                    
                    // Enhanced Action Buttons
                    VStack(spacing: 8) {
                        // Enhanced Alert Toggle Button
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            onToggleAlerts()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(item.alertsEnabled ? 
                                        (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary).opacity(0.2) :
                                        (themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryBackground : AppTheme.light.colors.tertiaryBackground))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: item.alertsEnabled ? "bell.fill" : "bell")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(item.alertsEnabled ? 
                                        (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary) :
                                        (themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText))
                            }
                            .scaleEffect(item.alertsEnabled ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: item.alertsEnabled)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Enhanced Options Button
                        Button(action: { showingOptions = true }) {
                            ZStack {
                                Circle()
                                    .fill(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryBackground : AppTheme.light.colors.tertiaryBackground)
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                            }
                        }
                        .actionSheet(isPresented: $showingOptions) {
                            ActionSheet(
                                title: Text(item.symbol),
                                message: Text(item.companyName),
                                buttons: [
                                    .destructive(Text("Remove from Watchlist")) {
                                        onRemove()
                                    },
                                    .cancel()
                                ]
                            )
                        }
                    }
                }
                .padding(20)
                
                // Enhanced Sentiment Section
                if let sentiment = sentiment {
                    VStack(spacing: 12) {
                        Divider()
                            .background(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border)
                        
                        HStack(spacing: 16) {
                            // Sentiment overview
                            VStack(alignment: .leading, spacing: 6) {
                                Text("SENTIMENT")
                                    .font(.system(size: 10, weight: .bold, design: .default))
                                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                                    .tracking(1.0)
                                
                                HStack(spacing: 8) {
                                    Image(systemName: sentiment.overallRating.icon)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(sentimentColor(sentiment))
                                    
                                    Text(sentiment.overallRating.rawValue)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(sentimentColor(sentiment))
                                }
                            }
                            
                            Spacer()
                            
                            // Price target if available
                            if let stock = stock, let target = item.priceTarget {
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text("TARGET")
                                        .font(.system(size: 10, weight: .bold, design: .default))
                                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                                        .tracking(1.0)
                                    
                                    Text(String(format: "$%.2f", target))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeManager.isDarkMode ? 
                        Color(hex: "1A1A1A") : 
                        Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: themeManager.isDarkMode ? 
                    Color.black.opacity(0.2) : 
                    Color.black.opacity(0.05),
                radius: isPressed ? 12 : 8,
                x: 0,
                y: isPressed ? 6 : 4
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                animateCard = true
            }
        }
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
                if searchViewModel.isLoadingAllStocks {
                    Spacer()
                    ProgressView("Loading stocks...")
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
                        Image(systemName: "list.bullet")
                            .font(.system(size: 40))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                        
                        Text("All Available Stocks")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        
                        Text("Search to filter the list")
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
    @State private var isPressed = false
    
    var body: some View {
        Button(action: { onAdd(stock) }) {
            HStack(spacing: 20) {
                // Enhanced Stock Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(stock.symbol)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Text(stock.companyName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Enhanced Price Info
                VStack(alignment: .trailing, spacing: 8) {
                    if stock.currentPrice > 0 {
                        Text(stock.formattedPrice)
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        
                        // Enhanced change indicator
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(stock.isPositiveChange ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                                .frame(width: 50, height: 20)
                            
                            HStack(spacing: 3) {
                                Image(systemName: stock.isPositiveChange ? "arrow.up.right" : "arrow.down.right")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(stock.isPositiveChange ? Color.green : Color.red)
                                
                                Text(stock.formattedChangePercent)
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(stock.isPositiveChange ? Color.green : Color.red)
                            }
                        }
                    } else {
                        Text("N/A")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                        
                        Text("N/A")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    }
                }
                
                // Enhanced Add Button
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.isDarkMode ? 
                        Color(hex: "1A1A1A") : 
                        Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: themeManager.isDarkMode ? 
                    Color.black.opacity(0.2) : 
                    Color.black.opacity(0.05),
                radius: isPressed ? 12 : 8,
                x: 0,
                y: isPressed ? 6 : 4
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
        }
        .buttonStyle(PlainButtonStyle())
    }
} 
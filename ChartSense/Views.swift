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
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                (themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Modern Header
                    ModernDiscoverHeader()
                    
                    // Premium Search Bar
                    ModernDiscoverSearchBar(
                        text: $searchText,
                        onSearch: { query in
                            searchViewModel.searchText = query
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    
                    // Dynamic Content
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 24) {
                                // Invisible anchor at top for programmatic scrolling
                                Color.clear.frame(height: 0).id("discoverTopAnchor")
                                if searchViewModel.isLoading && searchViewModel.searchResults.isEmpty {
                                    ModernDiscoverLoadingView()
                                } else if searchViewModel.searchResults.isEmpty && !searchText.isEmpty {
                                    ModernEmptySearchView()
                                } else if !searchViewModel.searchResults.isEmpty {
                                    ModernSearchResultsSection(results: searchViewModel.searchResults)
                                }
                                // When searchText is empty, show nothing - clean slate
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100) // Tab bar spacing
                        }
                        .onChange(of: searchText) { _ in
                            withAnimation { proxy.scrollTo("discoverTopAnchor", anchor: .top) }
                        }
                    }
                }
            }
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
            Task {
                await searchViewModel.loadInitialData()
            }
        }
        .onChange(of: searchText) { newValue in
            searchViewModel.searchText = newValue
        }
    }
}

// MARK: - Modern Discover Header
struct ModernDiscoverHeader: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Discover")
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                }
                
                Spacer()
                
                // Market Status Badge
                ModernMarketStatusBadge()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }
}

// MARK: - Modern Market Status Badge
struct ModernMarketStatusBadge: View {
    @State private var isMarketOpen = true
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isMarketOpen ? Color.green : Color.red)
                .frame(width: 6, height: 6)
                .scaleEffect(isMarketOpen ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isMarketOpen)
            
            Text(isMarketOpen ? "Market Open" : "Market Closed")
                .font(.system(size: 12, weight: .semibold, design: .default))
                .foregroundColor(isMarketOpen ? .green : .red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isMarketOpen ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
    }
}

// MARK: - Modern Discover Search Bar
struct ModernDiscoverSearchBar: View {
    @Binding var text: String
    let onSearch: (String) -> Void
    
    @StateObject private var themeManager = ThemeManager.shared
    @State private var searchDebounce: Timer?
    @FocusState private var isFocused: Bool
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        ZStack {
            // Animated background with gradient
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: isFocused ? 
                            [
                                themeManager.isDarkMode ? Color(hex: "1A1A1A") : Color.white,
                                themeManager.isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F8F9FA")
                            ] :
                            [
                                themeManager.isDarkMode ? Color(hex: "1A1A1A") : Color.white,
                                themeManager.isDarkMode ? Color(hex: "1A1A1A") : Color.white
                            ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // Animated border
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: isFocused ? 
                                    [Color.blue.opacity(0.8), Color.purple.opacity(0.6), Color.cyan.opacity(0.4)] :
                                    [Color.clear, Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isFocused ? 2 : 0
                        )
                )
                .shadow(
                    color: themeManager.isDarkMode ? 
                        Color.black.opacity(0.3) : 
                        Color.black.opacity(0.08),
                    radius: isFocused ? 12 : 6,
                    x: 0,
                    y: isFocused ? 6 : 3
                )
                .frame(height: 44) // Fixed height for proper sizing
            
            // Shimmer effect when focused
            if isFocused {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 44) // Match the main container height
                    .offset(x: shimmerOffset)
                    .clipped()
            }
            
            HStack(spacing: 6) {
                // Enhanced search icon with multiple animations
                ZStack {
                    // Pulsing background circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isFocused ? 
                                    [Color.blue.opacity(0.3), Color.purple.opacity(0.2)] :
                                    [Color.clear, Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 20, height: 20)
                    
                    // Main icon background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isFocused ? 
                                    [Color.blue.opacity(0.2), Color.purple.opacity(0.1)] :
                                    [Color.clear, Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 16, height: 16)
                    
                    // Search icon
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(isFocused ? 
                            (themeManager.isDarkMode ? Color.blue : Color.blue) :
                            (themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText))
                }
                
                // Enhanced text field with placeholder animation
                TextField("Search stocks, companies, or symbols...", text: $text)
                    .font(.system(size: 15, weight: .medium, design: .default))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    .focused($isFocused)
                    .onChange(of: text) { newValue in
                        // Debounce search
                        searchDebounce?.invalidate()
                        searchDebounce = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                            onSearch(newValue)
                        }
                    }
                
                Spacer()
                
                // Enhanced clear button with animations
                if !text.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            text = ""
                            onSearch("")
                        }
                    }) {
                        ZStack {
                            // Pulsing background
                            Circle()
                                .fill(Color.red.opacity(0.15))
                                .frame(width: 16, height: 16)
                            
                            // Main button background
                            Circle()
                                .fill(Color.red.opacity(0.1))
                                .frame(width: 14, height: 14)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(Color.red)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .onAppear {
            // Search bar ready
        }
        .onChange(of: isFocused) { focused in
            if focused {
                withAnimation(.easeInOut(duration: 0.3)) {
                    shimmerOffset = 200
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    shimmerOffset = -200
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
    }
}

// MARK: - Modern Search Results Section
struct ModernSearchResultsSection: View {
    let results: [Stock]
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var themeManager = ThemeManager.shared
    @State private var animateResults = false
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        VStack(spacing: 16) {
            // Enhanced header with animations
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Search Results")
                        .font(.system(size: 24, weight: .bold, design: .default))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Text("\(results.count) stocks found")
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                }
                
                Spacer()
                
                // Animated results count badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .scaleEffect(animateResults ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateResults)
                    
                    Text("\(results.count)")
                        .font(.system(size: 16, weight: .bold, design: .default))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                themeManager.isDarkMode ? Color(hex: "1A1A1A") : Color.white,
                                themeManager.isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F8F9FA")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: themeManager.isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.05),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
            
            // Enhanced results list with staggered animations
            LazyVStack(spacing: 12) {
                ForEach(Array(results.enumerated()), id: \.element.id) { index, stock in
                    EnhancedStockCard(stock: stock, index: index)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity).combined(with: .slide),
                            removal: .scale.combined(with: .opacity)
                        ))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: results.count)
                }
            }
        }
        .onAppear {
            animateResults = true
            withAnimation(.easeInOut(duration: 0.5)) {
                shimmerOffset = 200
            }
        }
    }
}

// MARK: - Enhanced Stock Card
struct EnhancedStockCard: View {
    let stock: Stock
    let index: Int
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isPressed = false
    @State private var animateCard = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var shimmerOffset: CGFloat = -200
    
    private var sparklinePrices: [Double] {
        return stock.sparklineData
    }
    
    private var isPositiveChange: Bool {
        return stock.dailyChangePercent >= 0
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                appViewModel.selectStock(stock)
            }
        }) {
            ZStack {
                // Animated background with gradient
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: isPressed ? 
                                [
                                    themeManager.isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F0F0F0"),
                                    themeManager.isDarkMode ? Color(hex: "3A3A3A") : Color(hex: "E8E8E8")
                                ] :
                                [
                                    themeManager.isDarkMode ? Color(hex: "1A1A1A") : Color.white,
                                    themeManager.isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F8F9FA")
                                ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: isPositiveChange ? 
                                        [Color.green.opacity(0.3), Color.blue.opacity(0.2)] :
                                        [Color.red.opacity(0.3), Color.orange.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isPressed ? 2 : 1
                            )
                    )
                    .shadow(
                        color: themeManager.isDarkMode ? Color.black.opacity(0.3) : Color.black.opacity(0.08),
                        radius: isPressed ? 12 : 8,
                        x: 0,
                        y: isPressed ? 6 : 4
                    )
                    .scaleEffect(isPressed ? 0.98 : 1.0)
                
                // Shimmer effect on press
                if isPressed {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerOffset)
                        .clipped()
                }
                
                HStack(spacing: 16) {
                    // Enhanced stock info section
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(stock.symbol)
                                .font(.system(size: 18, weight: .bold, design: .default))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                            
                            // Animated change indicator
                            ZStack {
                                Circle()
                                    .fill(isPositiveChange ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                                    .frame(width: 24, height: 24)
                                    .scaleEffect(pulseScale)
                                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseScale)
                                
                                Image(systemName: isPositiveChange ? "arrow.up" : "arrow.down")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(isPositiveChange ? Color.green : Color.red)
                            }
                        }
                        
                        Text(stock.companyName)
                            .font(.system(size: 14, weight: .medium, design: .default))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Enhanced price and change section
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(stock.formattedPrice)
                            .font(.system(size: 18, weight: .bold, design: .default))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        
                        HStack(spacing: 4) {
                            Text(isPositiveChange ? "+" : "")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(isPositiveChange ? Color.green : Color.red)
                            
                            Text(String(format: "%.2f%%", abs(stock.dailyChangePercent)))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(isPositiveChange ? Color.green : Color.red)
                        }
                    }
                    
                    // Enhanced sparkline with animation
                    VStack {
                        MiniSparklineView(prices: sparklinePrices, isPositive: isPositiveChange)
                            .frame(width: 60, height: 30)
                            .scaleEffect(animateCard ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateCard)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            animateCard = true
            pulseScale = 1.0
        }
        .onLongPressGesture(minimumDuration: 0) { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
            if pressing {
                withAnimation(.easeInOut(duration: 0.3)) {
                    shimmerOffset = 200
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    shimmerOffset = -200
                }
            }
        } perform: {
            // Handle long press if needed
        }
    }
}

// MARK: - Mini Sparkline View
struct MiniSparklineView: View {
    let prices: [Double]
    let isPositive: Bool
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard prices.count > 1 else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                
                // Find min and max for scaling
                let minPrice = prices.min() ?? 0
                let maxPrice = prices.max() ?? 1
                let priceRange = maxPrice - minPrice
                
                // Calculate points
                let points = prices.enumerated().map { index, price in
                    let x = (CGFloat(index) / CGFloat(prices.count - 1)) * width
                    let normalizedPrice = priceRange > 0 ? (price - minPrice) / priceRange : 0.5
                    let y = height - (normalizedPrice * height)
                    return CGPoint(x: x, y: y)
                }
                
                // Draw the line
                path.move(to: points[0])
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
            .stroke(
                isPositive ? Color.green : Color.red,
                style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round)
            )
        }
    }
}

// MARK: - Modern Stock Card
struct ModernStockCard: View {
    let stock: Stock
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isPressed = false
    
    // Use actual price history from stock model
    private var sparklinePrices: [Double] {
        return stock.sparklineData
    }
    
    private var isPositiveChange: Bool {
        return stock.dailyChangePercent >= 0
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left: Stock Symbol and Company Name (Clickable for stock selection)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appViewModel.selectStock(stock)
                }
            }) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(stock.symbol)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    
                    Text(stock.companyName)
                        .font(.system(size: 13, weight: .regular, design: .default))
                        .foregroundColor(themeManager.isDarkMode ? .gray : .secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Right: Price and Add Button
            HStack(spacing: 8) {
                // Price
                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(stock.currentPrice, specifier: "%.2f")")
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    
                    Text("\(stock.dailyChangePercent, specifier: "%.1f")%")
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(isPositiveChange ? .green : .red)
                }
                
                // Add to Watchlist Button - Clean and Simple
                Button(action: {
                    print("🎯 BUTTON TAPPED! Adding \(stock.symbol) to watchlist...")
                    
                    // Simple haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    // Add to watchlist
                    WatchlistViewModel.shared.addToWatchlist(stock)
                    
                    print("✅ addToWatchlist call completed")
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                        .frame(width: 44, height: 44)
                        .background(Color.clear)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.isDarkMode ? Color(.systemGray5) : Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeManager.isDarkMode ? Color(.systemGray4) : Color(.systemGray5), lineWidth: 0.5)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

// MARK: - Modern Default Content
struct ModernDefaultContent: View {
    let popularStocks: [Stock]
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 32) {
            // Popular Stocks
            if !popularStocks.isEmpty {
                ModernPopularStocksSection(stocks: popularStocks)
            }
        }
    }
}

// MARK: - Modern Recent Searches Section
struct ModernRecentSearchesSection: View {
    let searches: [String]
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Searches")
                .font(.system(size: 20, weight: .bold, design: .default))
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            LazyVStack(spacing: 8) {
                ForEach(searches.prefix(5), id: \.self) { search in
                    ModernRecentSearchItem(search: search)
                }
            }
        }
    }
}

// MARK: - Modern Recent Search Item
struct ModernRecentSearchItem: View {
    let search: String
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Handle recent search tap
        }) {
            HStack(spacing: 12) {
                Image(systemName: "clock")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? .gray : .secondary)
                
                Text(search)
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Spacer()
                
                Image(systemName: "arrow.up.left")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? .gray : .secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.isDarkMode ? Color(.systemGray5) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager.isDarkMode ? Color(.systemGray4) : Color(.systemGray5), lineWidth: 0.5)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Modern Popular Stocks Section
struct ModernPopularStocksSection: View {
    let stocks: [Stock]
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Popular Stocks")
                .font(.system(size: 20, weight: .bold, design: .default))
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            LazyVStack(spacing: 8) {
                ForEach(Array(stocks.prefix(10).enumerated()), id: \.element.id) { index, stock in
                    ModernStockCard(stock: stock)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                        .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.05), value: stocks.count)
                }
            }
        }
    }
}

// MARK: - Modern Market Insights Card
struct ModernMarketInsightsCard: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Market Insights")
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Spacer()
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? .blue : .blue)
            }
            
            // Market Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ModernInsightCard(
                    title: "Bullish Sentiment",
                    value: "68%",
                    trend: "+5.2%",
                    color: .green,
                    icon: "arrow.up.right"
                )
                
                ModernInsightCard(
                    title: "Market Volatility",
                    value: "Medium",
                    trend: "-2.1%",
                    color: .orange,
                    icon: "waveform.path.ecg"
                )
                
                ModernInsightCard(
                    title: "AI Confidence",
                    value: "85%",
                    trend: "+3.4%",
                    color: .blue,
                    icon: "brain.head.profile"
                )
                
                ModernInsightCard(
                    title: "News Sentiment",
                    value: "Positive",
                    trend: "+1.8%",
                    color: .purple,
                    icon: "newspaper"
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.isDarkMode ? Color(.systemGray6) : .white)
                .shadow(color: themeManager.isDarkMode ? .clear : Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
        )
        .scaleEffect(isAnimating ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Modern Insight Card
struct ModernInsightCard: View {
    let title: String
    let value: String
    let trend: String
    let color: Color
    let icon: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
                
                Text(trend)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(trend.hasPrefix("+") ? .green : .red)
            }
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .default))
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .default))
                .foregroundColor(themeManager.isDarkMode ? .gray : .secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.isDarkMode ? Color(.systemGray5) : Color(.systemGray6))
        )
    }
}

// MARK: - Modern Discover Loading View
struct ModernDiscoverLoadingView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var shimmerOffset: CGFloat = -200
    @State private var rotateAngle: Double = 0
    @State private var loadingDots = ""
    
    var body: some View {
        VStack(spacing: 32) {
            // Enhanced animated loading icon with multiple effects
            ZStack {
                // Outer pulsing ring with gradient
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.4), Color.purple.opacity(0.3), Color.cyan.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(pulseScale)
                    .rotationEffect(.degrees(rotateAngle))
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: pulseScale)
                    .animation(.linear(duration: 6.0).repeatForever(autoreverses: false), value: rotateAngle)
                
                // Middle ring with different rotation
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
                    .frame(width: 75, height: 75)
                    .scaleEffect(pulseScale * 0.9)
                    .rotationEffect(.degrees(-rotateAngle * 0.7))
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseScale)
                    .animation(.linear(duration: 4.0).repeatForever(autoreverses: false), value: rotateAngle)
                
                // Inner animated progress circle
                Circle()
                    .trim(from: 0, to: 0.8)
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue, Color.purple, Color.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: isAnimating)
                
                // Center search icon
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(
                        themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText
                    )
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
            }
            
            // Enhanced content section with animated background
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                themeManager.isDarkMode ? Color(hex: "1A1A1A") : Color.white,
                                themeManager.isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F8F9FA")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(
                        color: themeManager.isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.05),
                        radius: 10,
                        x: 0,
                        y: 5
                    )
                
                VStack(spacing: 16) {
                    // Animated title with gradient
                    Text("Searching stocks")
                        .font(.system(size: 24, weight: .bold, design: .default))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText,
                                    themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .scaleEffect(isAnimating ? 1.02 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                    
                    // Animated subtitle with dots
                    HStack(spacing: 2) {
                        Text("Finding the best matches for you")
                            .font(.system(size: 16, weight: .medium, design: .default))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                        
                        Text(loadingDots)
                            .font(.system(size: 16, weight: .medium, design: .default))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    }
                    
                    // Animated progress indicators
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 8, height: 8)
                                .scaleEffect(isAnimating ? 1.2 : 0.8)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true).delay(Double(index) * 0.2), value: isAnimating)
                        }
                    }
                }
                .padding(.vertical, 24)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .onAppear {
            isAnimating = true
            pulseScale = 1.0
            rotateAngle = 0
            
            // Animate loading dots
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                if loadingDots.count >= 3 {
                    loadingDots = ""
                } else {
                    loadingDots += "."
                }
            }
        }
    }
}

// MARK: - Modern Empty Search View
struct ModernEmptySearchView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var shimmerOffset: CGFloat = -200
    @State private var rotateAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 32) {
            // Enhanced animated search icon with multiple effects
            ZStack {
                // Outer pulsing ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2), Color.cyan.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseScale)
                    .rotationEffect(.degrees(rotateAngle))
                    .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: pulseScale)
                    .animation(.linear(duration: 8.0).repeatForever(autoreverses: false), value: rotateAngle)
                
                // Middle ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 90, height: 90)
                    .scaleEffect(pulseScale * 0.8)
                    .rotationEffect(.degrees(-rotateAngle * 0.5))
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: pulseScale)
                    .animation(.linear(duration: 6.0).repeatForever(autoreverses: false), value: rotateAngle)
                
                // Inner search icon with enhanced styling
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    themeManager.isDarkMode ? Color(hex: "2A2A2A") : Color.white,
                                    themeManager.isDarkMode ? Color(hex: "3A3A3A") : Color(hex: "F8F9FA")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .shadow(
                            color: themeManager.isDarkMode ? Color.black.opacity(0.3) : Color.black.opacity(0.1),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(
                            themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText
                        )
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                }
            }
            
            // Enhanced content section
            VStack(spacing: 16) {
                // Animated title with gradient
                Text("No Results Found")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText,
                                themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .scaleEffect(isAnimating ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: isAnimating)
                
                // Enhanced description with animated background
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    themeManager.isDarkMode ? Color(hex: "1A1A1A") : Color.white,
                                    themeManager.isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F8F9FA")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: themeManager.isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.05),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    
                    VStack(spacing: 12) {
                        Text("Try searching for a different stock symbol or company name")
                            .font(.system(size: 16, weight: .medium, design: .default))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        
                        // Animated suggestions
                        HStack(spacing: 12) {
                            ForEach(["AAPL", "TSLA", "MSFT", "GOOGL"], id: \.self) { symbol in
                                Text(symbol)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(themeManager.isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F0F0F0"))
                                    )
                                    .scaleEffect(isAnimating ? 1.05 : 1.0)
                                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(Double(symbol.hashValue % 4) * 0.2), value: isAnimating)
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .onAppear {
            isAnimating = true
            pulseScale = 1.0
            rotateAngle = 0
            withAnimation(.easeInOut(duration: 0.5)) {
                shimmerOffset = 200
            }
        }
    }
}



// MARK: - Home View (Clean, Sentiment-Focused Design)
struct HomeView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var homeViewModel = EnhancedHomeViewModel()
    @State private var showingStockDetail = false
    @State private var animateHeader = false
    @State private var animateCards = false
    @State private var selectedCardIndex: Int?
    @State private var hoveredStockIndex: Int?
    @State private var showingAI = false
    @State private var showingWatchlist = false
    
    var body: some View {
                        ZStack {
                    // Clean solid background
                    (themeManager.isDarkMode ? Color(hex: "1A1A1A") : Color.white)
                        .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {

                    
                    // Clean Header
                    CleanHeader()
                        .offset(y: animateHeader ? 0 : -8)
                        .opacity(animateHeader ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.7), value: animateHeader)
                    
                    // Market Status Bar
                    MarketStatusBar()
                        .offset(y: animateHeader ? 0 : -4)
                        .opacity(animateHeader ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.5).delay(0.1), value: animateHeader)
                    
                    // Sentiment-Focused Watchlist Section
                    SentimentFocusedWatchlistSection(
                        stocks: homeViewModel.watchlistStocks,
                        sentiments: homeViewModel.stockSentiments,
                        onSelectStock: { stock in
                            appViewModel.selectedStock = stock
                            showingStockDetail = true
                        },
                        onEditWatchlist: {
                            showingWatchlist = true
                        }
                    )
                    .offset(y: animateCards ? 0 : 15)
                    .opacity(animateCards ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.3).delay(0.05), value: animateCards)
                    
                    // Sentiment Alerts with Enhanced Visuals
                    EnhancedSentimentAlertsSection(alerts: homeViewModel.sentimentAlerts)
                        .offset(y: animateCards ? 0 : 10)
                        .opacity(animateCards ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.3).delay(0.2), value: animateCards)
                    
                    // News Feed with Premium Design
                    PremiumNewsFeedSection(news: homeViewModel.newsItems)
                        .offset(y: animateCards ? 0 : 8)
                        .opacity(animateCards ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.3).delay(0.35), value: animateCards)
                    
                    // AI Summary with Unique Visuals
                    UniqueAISummarySection(
                        summary: homeViewModel.marketSummary,
                        onAskAI: { showingAI = true }
                    )
                    .offset(y: animateCards ? 0 : 6)
                    .opacity(animateCards ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.3).delay(0.5), value: animateCards)
                    
                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 20)
            }
        }
            .navigationBarHidden(true)
        .sheet(isPresented: $showingStockDetail) {
            if let selectedStock = appViewModel.selectedStock {
                ModernStockDetailView(stock: selectedStock)
                    .onDisappear {
                        appViewModel.selectedStock = nil
                        showingStockDetail = false
                    }
            }
        }
        .sheet(isPresented: $showingAI) {
            AIView()
        }
        .sheet(isPresented: $showingWatchlist) {
            ModernWatchlistView()
        }
        .onAppear {
            // Load data first, then animate
            homeViewModel.loadData()
            
            // Smooth header animation
            withAnimation(.easeOut(duration: 0.4)) {
                animateHeader = true
            }
            
            // Delayed card animation with better timing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.6)) {
                    animateCards = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WatchlistChanged"))) { _ in
            // Refresh home screen when watchlist changes
            print("🔄 HomeView: Received watchlist change notification, refreshing...")
            Task {
                await homeViewModel.refreshWatchlist()
            }
        }
        .refreshable {
            await homeViewModel.refreshData()
        }
    }
}

// MARK: - Clean Header
struct CleanHeader: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var animateAccent = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Custom accent line with unique animation
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 4, height: 40)
                    .scaleEffect(animateAccent ? 1.0 : 0.8)
                    .opacity(animateAccent ? 1.0 : 0.6)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateAccent)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("ChartSense")
                        .font(.system(size: 36, weight: .bold, design: .default))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                }
                
                Spacer()
            }
        }
        .padding(.top, 32)
        .padding(.bottom, 12)
        .onAppear {
            animateAccent = true
        }
    }
}

// MARK: - Sentiment-Focused Watchlist Section
struct SentimentFocusedWatchlistSection: View {
    let stocks: [Stock]
    let sentiments: [String: SentimentData]
    let onSelectStock: (Stock) -> Void
    let onEditWatchlist: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    @State private var animateCards = false
    @State private var hoveredIndex: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Section Header with Unique Design
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WATCHLIST")
                        .font(.system(size: 12, weight: .bold, design: .default))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                        .tracking(1.5)
                    
                    Text("Your Market Focus")
                        .font(.system(size: 20, weight: .semibold, design: .default))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                }
                
                Spacer()
                
                // Clean Edit Button
                Button(action: onEditWatchlist) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                        
                        Text("Edit")
                            .font(.system(size: 12, weight: .medium, design: .default))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(themeManager.isDarkMode ? AppTheme.dark.colors.primary.opacity(0.1) : AppTheme.light.colors.primary.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(themeManager.isDarkMode ? AppTheme.dark.colors.primary.opacity(0.3) : AppTheme.light.colors.primary.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            
            // Content based on watchlist state
            if stocks.isEmpty {
                // Empty Watchlist State
                VStack(spacing: 16) {
                    Image(systemName: "heart")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                        .opacity(animateCards ? 1.0 : 0.0)
                        .scaleEffect(animateCards ? 1.0 : 0.8)
                        .animation(.easeOut(duration: 0.3).delay(0.1), value: animateCards)
                    
                    VStack(spacing: 8) {
                        Text("Your Watchlist is Empty")
                            .font(.system(size: 20, weight: .semibold, design: .default))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                            .opacity(animateCards ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.3).delay(0.15), value: animateCards)
                        
                        Text("Add stocks to your watchlist to track their sentiment and market data")
                            .font(.system(size: 14, weight: .medium, design: .default))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .opacity(animateCards ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.3).delay(0.2), value: animateCards)
                    }
                    
                    Button(action: onEditWatchlist) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .medium))
                            
                            Text("Add Stocks")
                                .font(.system(size: 14, weight: .semibold, design: .default))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                        )
                    }
                    .opacity(animateCards ? 1.0 : 0.0)
                    .scaleEffect(animateCards ? 1.0 : 0.9)
                    .animation(.easeOut(duration: 0.3).delay(0.25), value: animateCards)
                }
                .padding(.vertical, 28)
            } else {
                // Sentiment-Focused Stock Cards with Beautiful Staggered Animation
                VStack(spacing: 12) {
                    ForEach(Array(stocks.enumerated()), id: \.element.id) { index, stock in
                        SentimentFocusedStockCard(
                            stock: stock,
                            sentiment: sentiments[stock.symbol],
                            isHovered: hoveredIndex == index,
                            onTap: {
                                onSelectStock(stock)
                            },
                            onHover: { isHovered in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    hoveredIndex = isHovered ? index : nil
                                }
                            }
                        )
                        .offset(y: animateCards ? 0 : 100)
                        .opacity(animateCards ? 1.0 : 0.0)
                        .scaleEffect(animateCards ? 1.0 : 0.7)
                        .blur(radius: animateCards ? 0 : 15)
                        .rotation3DEffect(
                            .degrees(animateCards ? 0 : 15),
                            axis: (x: 1.0, y: 0.0, z: 0.0)
                        )
                        .animation(
                            .spring(
                                response: 0.15,
                                dampingFraction: 0.9,
                                blendDuration: 0.05
                            ).delay(0.02 + Double(index) * 0.02),
                            value: animateCards
                        )
                    }
                }
            }
        }
        .padding(.top, 20)
        .onAppear {
            // Start card animations immediately when section appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.9)) {
                    animateCards = true
                }
            }
        }
    }
}

// MARK: - Sentiment-Focused Stock Card
struct SentimentFocusedStockCard: View {
    let stock: Stock
    let sentiment: SentimentData?
    let isHovered: Bool
    let onTap: () -> Void
    let onHover: (Bool) -> Void
    @StateObject private var themeManager = ThemeManager.shared
    @State private var animateCard = false
    @State private var animateSparkline = false
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            onTap()
        }) {
            ZStack {
                // Clean background with subtle design
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
                    .overlay(
                        Group {
                            if !themeManager.isDarkMode {
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.blue.opacity(isHovered ? 0.3 : 0.1),
                                                Color.purple.opacity(isHovered ? 0.3 : 0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: isHovered ? 2 : 1
                                    )
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(
                        color: themeManager.isDarkMode ? Color.black.opacity(0.3) : Color.black.opacity(0.05),
                        radius: isHovered ? 15 : 8,
                        x: 0,
                        y: isHovered ? 8 : 4
                    )
                    .scaleEffect(isHovered ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isHovered)
                
                // Beautiful shimmer effect when card appears
                if animateCard {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerOffset)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                
                VStack(spacing: 0) {
                    // Header with ticker and price
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(stock.symbol)
                                .font(.system(size: 24, weight: .bold, design: .default))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                                .opacity(animateCard ? 1.0 : 0.0)
                                .offset(y: animateCard ? 0 : 10)
                                .animation(.easeOut(duration: 0.15).delay(0.02), value: animateCard)
                            
                            Text(stock.companyName)
                                .font(.system(size: 14, weight: .medium, design: .default))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                                .lineLimit(1)
                                .opacity(animateCard ? 1.0 : 0.0)
                                .offset(y: animateCard ? 0 : 8)
                                .animation(.easeOut(duration: 0.15).delay(0.03), value: animateCard)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("$\(stock.currentPrice, specifier: "%.2f")")
                                .font(.system(size: 22, weight: .bold, design: .default))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                                .opacity(animateCard ? 1.0 : 0.0)
                                .offset(y: animateCard ? 0 : 10)
                                .animation(.easeOut(duration: 0.15).delay(0.04), value: animateCard)
                            
                            HStack(spacing: 4) {
                                Image(systemName: stock.dailyChangePercent >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(stock.dailyChangePercent >= 0 ? Color.green : Color.red)
                                
                                Text("\(stock.dailyChangePercent, specifier: "%.2f")%")
                                    .font(.system(size: 16, weight: .semibold, design: .default))
                                    .foregroundColor(stock.dailyChangePercent >= 0 ? Color.green : Color.red)
                            }
                            .opacity(animateCard ? 1.0 : 0.0)
                            .offset(y: animateCard ? 0 : 8)
                            .animation(.easeOut(duration: 0.15).delay(0.05), value: animateCard)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    // Sentiment Analysis Section (Emphasized)
                    VStack(spacing: 16) {
                        // Main sentiment indicator
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("SENTIMENT ANALYSIS")
                                    .font(.system(size: 10, weight: .bold, design: .default))
                                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                                    .tracking(1.0)
                                    .opacity(animateCard ? 1.0 : 0.0)
                                    .offset(y: animateCard ? 0 : 5)
                                    .animation(.easeOut(duration: 0.6).delay(0.7), value: animateCard)
                                
        HStack(spacing: 12) {
                                    // Sentiment score
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(getSentimentScore())")
                                            .font(.system(size: 28, weight: .bold, design: .default))
                                            .foregroundColor(sentimentColor)
                                        
                                        Text(getSentimentLabel())
                                            .font(.system(size: 14, weight: .semibold, design: .default))
                                            .foregroundColor(sentimentColor)
                                    }
                                    
                                    // Sentiment confidence
            VStack(alignment: .leading, spacing: 4) {
                                        Text("\(getConfidenceScore())%")
                                            .font(.system(size: 16, weight: .bold, design: .default))
                                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                                        
                                        Text("Confidence")
                                            .font(.system(size: 12, weight: .medium, design: .default))
                                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            }
            
            Spacer()
            
                                    // Sentiment trend
                                    VStack(alignment: .trailing, spacing: 4) {
                                        HStack(spacing: 4) {
                                            Image(systemName: getSentimentTrendIcon())
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(getSentimentTrendColor())
                                            
                                            Text(getSentimentTrendText())
                                                .font(.system(size: 14, weight: .semibold, design: .default))
                                                .foregroundColor(getSentimentTrendColor())
                                        }
                                        
                                        Text("vs Yesterday")
                                            .font(.system(size: 12, weight: .medium, design: .default))
                                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                                    }
                                }
                }
                
                Spacer()
                        }
                        
                        // Sentiment breakdown
                        HStack(spacing: 16) {
                            SentimentBreakdownItem(
                                title: "Social",
                                score: getSocialScore(),
                                color: Color.blue
                            )
                            .opacity(animateCard ? 1.0 : 0.0)
                            .offset(y: animateCard ? 0 : 10)
                            .animation(.easeOut(duration: 0.6).delay(0.8), value: animateCard)
                            
                            SentimentBreakdownItem(
                                title: "News",
                                score: getNewsScore(),
                                color: Color.purple
                            )
                            .opacity(animateCard ? 1.0 : 0.0)
                            .offset(y: animateCard ? 0 : 10)
                            .animation(.easeOut(duration: 0.6).delay(0.9), value: animateCard)
                            
                            SentimentBreakdownItem(
                                title: "Technical",
                                score: getTechnicalScore(),
                                color: Color.orange
                            )
                            .opacity(animateCard ? 1.0 : 0.0)
                            .offset(y: animateCard ? 0 : 10)
                            .animation(.easeOut(duration: 0.6).delay(1.0), value: animateCard)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .opacity(animateCard ? 1.0 : 0.0)
                    .offset(y: animateCard ? 0 : 15)
                    .animation(.easeOut(duration: 0.6).delay(0.6), value: animateCard)
                    
                    // Mini sparkline (smaller, less emphasized)
                    CustomSparklineView(data: stock.priceHistory)
                        .frame(height: 40)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                        .opacity(animateSparkline ? 1.0 : 0.0)
                        .scaleEffect(animateSparkline ? 1.0 : 0.8)
                        .animation(.easeOut(duration: 0.6).delay(0.8), value: animateSparkline)
                    
                    // AI insight preview
            HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.purple)
                        
                        Text("AI: \(getInsightPreview())")
                            .font(.system(size: 12, weight: .medium, design: .default))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // Trigger shimmer effect after card appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                animateCard = true
                
                // Animate shimmer
                withAnimation(.easeInOut(duration: 0.3)) {
                    shimmerOffset = 200
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    shimmerOffset = -200
                }
                
                // Animate sparkline
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        animateSparkline = true
                    }
                }
            }
        }
    }
    
    // Sentiment helper functions
    private func getSentimentScore() -> String {
        guard let sentiment = sentiment else { return "N/A" }
        let score = sentiment.overallScore
        return score > 0 ? "+\(Int(score * 100))" : "\(Int(score * 100))"
    }
    
    private func getSentimentLabel() -> String {
        guard let sentiment = sentiment else { return "Neutral" }
        let score = sentiment.overallScore
        if score > 0.1 { return "Bullish" }
        else if score < -0.1 { return "Bearish" }
        else { return "Neutral" }
    }
    
    private func getConfidenceScore() -> Int {
        guard let sentiment = sentiment else { return 50 }
        return Int(sentiment.confidence * 100)
    }
    
    private func getSentimentTrendIcon() -> String {
        let trend = Int.random(in: -1...1)
        return trend > 0 ? "arrow.up" : trend < 0 ? "arrow.down" : "minus"
    }
    
    private func getSentimentTrendText() -> String {
        let trend = Int.random(in: -1...1)
        return trend > 0 ? "+12%" : trend < 0 ? "-8%" : "0%"
    }
    
    private func getSentimentTrendColor() -> Color {
        let trend = Int.random(in: -1...1)
        return trend > 0 ? Color.green : trend < 0 ? Color.red : Color.gray
    }
    
    private func getSocialScore() -> Int {
        return Int.random(in: 60...95)
    }
    
    private func getNewsScore() -> Int {
        return Int.random(in: 40...90)
    }
    
    private func getTechnicalScore() -> Int {
        return Int.random(in: 50...85)
    }
    
    private var sentimentColor: Color {
        guard let sentiment = sentiment else { return Color.gray }
        
        if sentiment.overallScore > 0.1 {
            return Color.green
        } else if sentiment.overallScore < -0.1 {
            return Color.red
                    } else {
            return Color.orange
        }
    }
    
    private func getInsightPreview() -> String {
        let insights = [
            "Strong momentum with positive sentiment",
            "Technical indicators show bullish signals",
            "Market sentiment remains neutral",
            "Volume spike indicates increased interest",
            "Support level holding strong"
        ]
        return insights.randomElement() ?? "Market analysis available"
    }
}

// MARK: - Sentiment Breakdown Item
struct SentimentBreakdownItem: View {
    let title: String
    let score: Int
    let color: Color
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .default))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            
            Text("\(score)%")
                .font(.system(size: 16, weight: .bold, design: .default))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Market Status Bar
struct MarketStatusBar: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var animateStatus = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Live indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animateStatus ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateStatus)
                
                Text("LIVE")
                    .font(.system(size: 12, weight: .bold, design: .default))
                    .foregroundColor(Color.green)
            }
            
            Text("Market Open")
                .font(.system(size: 14, weight: .medium, design: .default))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            
            Spacer()
            
            // Market time
            Text("9:30 AM - 4:00 PM ET")
                .font(.system(size: 12, weight: .medium, design: .default))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.isDarkMode ? Color(hex: "1A1A1A") : Color(hex: "F8F9FA"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
            animateStatus = true
        }
    }
}

// MARK: - AI View
struct AIView: View {
    var body: some View {
        ModernAIChatView()
    }
}

// MARK: - Settings View
struct SettingsView: View {
    var body: some View {
        ModernSettingsView()
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

// MARK: - Premium Loading View
struct PremiumLoadingView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var animateGradient = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Animated Logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary,
                                themeManager.isDarkMode ? AppTheme.dark.colors.secondary : AppTheme.light.colors.secondary
                            ],
                            startPoint: UnitPoint(x: animateGradient ? 0 : 1, y: 0),
                            endPoint: UnitPoint(x: animateGradient ? 1 : 0, y: 1)
                        )
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(animateGradient ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateGradient)
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 16) {
                Text("ChartSense")
                    .font(.system(size: 24, weight: .bold, design: .default))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Text("Loading your market insights...")
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            }
            
            Spacer()
        }
        .onAppear {
            animateGradient = true
        }
    }
}

// MARK: - Preview
#Preview {
    HomeView()
        .environmentObject(AppViewModel())
} 

// MARK: - Custom Data Models for Home View
struct SentimentAlert {
    let id = UUID()
    let symbol: String
    let message: String
    let change: Double
    let severity: String
    let timeAgo: String
}

// MARK: - Enhanced Home View Model
class EnhancedHomeViewModel: ObservableObject {
    @Published var watchlistStocks: [Stock] = []
    @Published var stockSentiments: [String: SentimentData] = [:]
    @Published var sentimentAlerts: [SentimentAlert] = []
    @Published var newsItems: [NewsItem] = []
    @Published var marketSummary: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabaseService = SupabaseService.shared
    private let stockService = StockService.shared
    private let sentimentService = SentimentService.shared
    
    func loadData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            await loadRealData()
        }
    }
    
    func refreshData() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        await loadRealData()
    }
    
    // Method to refresh watchlist data specifically
    func refreshWatchlist() async {
        print("🔄 EnhancedHomeViewModel: Refreshing watchlist data...")
        await loadRealData()
        print("✅ EnhancedHomeViewModel: Watchlist data refreshed")
    }
    
    @MainActor
    private func loadRealData() async {
        do {
            // Load real watchlist data from Supabase
            let watchlistItems = try await supabaseService.getWatchlistWithStockData()
            
            // Convert to Stock objects
            let stocks = watchlistItems.compactMap { item -> Stock? in
                guard let stock = item.stock else { return nil }
                return stock
            }
            
            // Update watchlist stocks
            self.watchlistStocks = stocks
            
            // Load sentiment data for each stock
            var sentiments: [String: SentimentData] = [:]
            for stock in stocks {
                // Use the getSentiment method which returns SentimentAnalysis
                let sentimentAnalysis = sentimentService.getSentiment(for: stock.symbol)
                sentiments[stock.symbol] = SentimentData(
                    overallScore: sentimentAnalysis.score,
                    confidence: sentimentAnalysis.confidence,
                    sources: []
                )
            }
            
            self.stockSentiments = sentiments
            
            // Load sample alerts and news for now
            self.sentimentAlerts = [
                SentimentAlert(symbol: "TSLA", message: "TSLA sentiment dropped 22% in 6h", change: -22, severity: "high", timeAgo: "2h ago"),
                SentimentAlert(symbol: "AAPL", message: "AAPL sentiment improved 15% in 4h", change: 15, severity: "medium", timeAgo: "4h ago")
            ]
            
            self.newsItems = [
                NewsItem(headline: "Apple Reports Strong Q4 Earnings, Beats Expectations", summary: "Apple Inc. reported strong fourth-quarter earnings that exceeded analyst expectations.", source: "Reuters", publishedAt: Date().addingTimeInterval(-3600), url: "https://example.com", category: .earnings, sentiment: 0.8, relevanceScore: 0.9, imageURL: nil),
                NewsItem(headline: "Tesla Faces Regulatory Scrutiny Over Safety Concerns", summary: "Tesla faces new regulatory scrutiny over safety concerns.", source: "Bloomberg", publishedAt: Date().addingTimeInterval(-10800), url: "https://example.com", category: .regulatory, sentiment: -0.6, relevanceScore: 0.8, imageURL: nil),
                NewsItem(headline: "Microsoft Cloud Services See Record Growth", summary: "Microsoft's cloud services division reports record growth.", source: "CNBC", publishedAt: Date().addingTimeInterval(-18000), url: "https://example.com", category: .product, sentiment: 0.7, relevanceScore: 0.85, imageURL: nil)
            ]
            
            self.marketSummary = "Markets are showing mixed signals today with tech stocks leading gains while energy sectors face pressure. Apple and Microsoft continue to benefit from strong earnings reports, while Tesla faces regulatory headwinds. Overall sentiment remains cautiously optimistic as investors await key economic data releases this week."
            
        } catch {
            print("❌ Error loading real data: \(error)")
            self.errorMessage = "Failed to load watchlist data"
            
            // Fallback to empty state
            self.watchlistStocks = []
            self.stockSentiments = [:]
        }
        
        self.isLoading = false
    }
} 

// MARK: - Custom Sparkline View
struct CustomSparklineView: View {
    let data: [Double]
    @State private var animatePath = false
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard data.count > 1 else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let stepX = width / CGFloat(data.count - 1)
                
                let minValue = data.min() ?? 0
                let maxValue = data.max() ?? 1
                let range = maxValue - minValue
                
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let normalizedValue = range > 0 ? (value - minValue) / range : 0.5
                    let y = height - (normalizedValue * height)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .trim(from: 0, to: animatePath ? 1.0 : 0.0)
            .stroke(
                LinearGradient(
                    colors: [Color.blue, Color.purple],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            )
            .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5)) {
                animatePath = true
            }
        }
    }
}

// MARK: - Enhanced Sentiment Alerts Section
struct EnhancedSentimentAlertsSection: View {
    let alerts: [SentimentAlert]
    @StateObject private var themeManager = ThemeManager.shared
    @State private var animateAlerts = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("SENTIMENT ALERTS")
                    .font(.system(size: 12, weight: .bold, design: .default))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    .tracking(1.5)
                
                Spacer()
                
                // Custom indicator
                HStack(spacing: 3) {
                    ForEach(0..<min(alerts.count, 3)) { index in
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: 3, height: 12)
                            .cornerRadius(1.5)
                            .scaleEffect(animateAlerts ? 1.0 : 0.8)
                            .animation(.easeInOut(duration: 0.6).delay(Double(index) * 0.1), value: animateAlerts)
                    }
                }
            }
            
            LazyVStack(spacing: 8) {
                ForEach(Array(alerts.prefix(3).enumerated()), id: \.element.id) { index, alert in
                    EnhancedSentimentAlertCard(alert: alert)
                        .offset(x: animateAlerts ? 0 : -20)
                        .opacity(animateAlerts ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.5).delay(Double(index) * 0.1), value: animateAlerts)
                }
            }
        }
        .padding(.top, 12)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                animateAlerts = true
            }
        }
    }
}

// MARK: - Enhanced Sentiment Alert Card
struct EnhancedSentimentAlertCard: View {
    let alert: SentimentAlert
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            HStack(spacing: 16) {
                // Custom icon with unique design
                ZStack {
                    Circle()
                        .fill(alertColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: alertIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(alertColor)
                        .rotationEffect(.degrees(isPressed ? 15 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isPressed)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.message)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        .lineLimit(2)
                    
                    Text("\(alert.timeAgo) • \(alert.severity)")
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                }
                
                Spacer()
                
                // Custom change indicator
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(alert.change, specifier: "%.1f")%")
                        .font(.system(size: 14, weight: .bold, design: .default))
                        .foregroundColor(alertColor)
                    
                    Image(systemName: alert.change >= 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(alertColor)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.isDarkMode ? Color(hex: "1A1A1A") : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(alertColor.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(
                color: themeManager.isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.05),
                radius: 8,
                x: 0,
                y: 4
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    private var alertColor: Color {
        switch alert.severity {
        case "high":
            return Color.red
        case "medium":
            return Color.orange
        default:
            return Color.yellow
        }
    }
    
    private var alertIcon: String {
        switch alert.severity {
        case "high":
            return "exclamationmark.triangle.fill"
        case "medium":
            return "exclamationmark.circle.fill"
        default:
            return "info.circle.fill"
        }
    }
}

// MARK: - Premium News Feed Section
struct PremiumNewsFeedSection: View {
    let news: [NewsItem]
    @StateObject private var themeManager = ThemeManager.shared
    @State private var animateNews = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("MARKET NEWS")
                    .font(.system(size: 12, weight: .bold, design: .default))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    .tracking(1.5)
                
                Spacer()
                
                // Custom news indicator
                HStack(spacing: 3) {
                    ForEach(0..<min(news.count, 3)) { index in
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 3, height: 8)
                            .cornerRadius(1.5)
                            .scaleEffect(animateNews ? 1.0 : 0.8)
                            .animation(.easeInOut(duration: 0.6).delay(Double(index) * 0.1), value: animateNews)
                    }
                }
            }
            
            LazyVStack(spacing: 8) {
                ForEach(Array(news.prefix(3).enumerated()), id: \.element.id) { index, newsItem in
                    PremiumNewsCard(newsItem: newsItem)
                        .offset(x: animateNews ? 0 : 20)
                        .opacity(animateNews ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.5).delay(Double(index) * 0.1), value: animateNews)
                }
            }
        }
        .padding(.top, 12)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                animateNews = true
            }
        }
    }
}

// MARK: - Premium News Card
struct PremiumNewsCard: View {
    let newsItem: NewsItem
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(newsItem.headline)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    // Custom sentiment indicator
                    Circle()
                        .fill(sentimentColor)
                        .frame(width: 8, height: 8)
                }
                
                HStack {
                    Text(newsItem.source)
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    
                    Text("•")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    
                    Text(newsItem.timeAgo)
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.isDarkMode ? Color(hex: "1A1A1A") : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: themeManager.isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.05),
                radius: 8,
                x: 0,
                y: 4
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    private var sentimentColor: Color {
        if newsItem.sentiment > 0.1 {
            return Color.green
        } else if newsItem.sentiment < -0.1 {
            return Color.red
        } else {
            return Color.orange
        }
    }
}

// MARK: - Unique AI Summary Section
struct UniqueAISummarySection: View {
    let summary: String
    let onAskAI: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    @State private var animateSummary = false
    @State private var animateButton = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AI INSIGHTS")
                    .font(.system(size: 12, weight: .bold, design: .default))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    .tracking(1.5)
                
                Spacer()
                
                // Custom AI indicator
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 4, height: 4)
                            .scaleEffect(animateSummary ? 1.0 : 0.8)
                            .animation(.easeInOut(duration: 0.8).delay(Double(index) * 0.2), value: animateSummary)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(summary.isEmpty ? "Market sentiment analysis shows mixed signals across major indices. Tech stocks continue to lead with strong momentum, while traditional sectors show cautious optimism." : summary)
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
                
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    onAskAI()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Ask AI Anything")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(
                        color: Color.purple.opacity(0.3),
                        radius: animateButton ? 12 : 8,
                        x: 0,
                        y: animateButton ? 6 : 4
                    )
                    .scaleEffect(animateButton ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animateButton)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeManager.isDarkMode ? Color(hex: "1A1A1A") : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: themeManager.isDarkMode ? Color.black.opacity(0.2) : Color.black.opacity(0.05),
                radius: 12,
                x: 0,
                y: 6
            )
        }
        .padding(.top, 20)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                animateSummary = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                animateButton = true
            }
        }
    }
} 
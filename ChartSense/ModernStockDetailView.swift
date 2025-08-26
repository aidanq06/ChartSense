//
//  ModernStockDetailView.swift
//  ChartSense
//
//  Created by Aidan Quach on 7/22/25.
//

import SwiftUI
import Charts

// MARK: - TimeFrame Enum
enum TimeFrame: String, CaseIterable {
    case oneDay = "1D"
    case oneWeek = "1W"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case oneYear = "1Y"
    
    var displayName: String {
        return self.rawValue
    }
}







// MARK: - Modern Toggle Style
struct ModernToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Rectangle()
                .fill(configuration.isOn ? Color.blue : Color.gray.opacity(0.3))
                .frame(width: 50, height: 30)
                .cornerRadius(15)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}

// MARK: - Redesigned Stock Detail View
struct ModernStockDetailView: View {
    let stock: Stock
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var watchlistViewModel = WatchlistViewModel.shared
    @StateObject private var premiumManager = PremiumManager.shared
    @State private var selectedTab = 0
    @State private var showingAddToWatchlist = false
    @State private var currentStock: Stock
    @State private var chartRange: ChartRange = .oneDay
    // Scrub-driven overrides for price and change
    @State private var isScrubbing: Bool = false
    @State private var overridePrice: Double? = nil
    @State private var overrideChange: Double? = nil
    @State private var overridePercent: Double? = nil
    
    private let tabs = ["Chart", "Sentiment", "Insights"]
    
    init(stock: Stock) {
        self.stock = stock
        self._currentStock = State(initialValue: stock)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Ultra-Minimal Header
            ModernStockDetailHeader(
                stock: currentStock,
                onBack: { dismiss() },
                onAddToWatchlist: { showingAddToWatchlist = true },
                overridePrice: overridePrice,
                overrideChange: overrideChange,
                overridePercent: overridePercent,
                isScrubbing: isScrubbing
            )
            
            // Ultra-Minimal Tab Navigation
            ModernTabBar(
                tabs: tabs,
                selectedTab: $selectedTab
            )
            
            // Tab Content with Clean Spacing
            TabView(selection: $selectedTab) {
                // Chart Tab
                UltraCleanChartTab(
                    stock: currentStock,
                    range: $chartRange,
                    onScrubChanged: { price, delta, percent in
                        overridePrice = price
                        overrideChange = delta
                        overridePercent = percent
                    },
                    onScrubbingStateChanged: { scrubbing in
                        isScrubbing = scrubbing
                        if !scrubbing {
                            // First drive back to live values, then clear overrides next run loop
                            overridePrice = currentStock.currentPrice
                            overrideChange = currentStock.dailyChange
                            overridePercent = currentStock.dailyChangePercent
                            DispatchQueue.main.async {
                                overridePrice = nil
                                overrideChange = nil
                                overridePercent = nil
                            }
                        }
                    }
                )
                    .tag(0)

                // Sentiment Tab
                SentimentAnalysisTab(stock: currentStock)
                    .tag(1)

                // Insights Tab - Combined Analysis & Community
                ComprehensiveInsightsTab(stock: currentStock)
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
            // Reserve space so the bottom overlay doesn't overlap the chart
            .padding(.bottom, selectedTab == 0 ? 68 : 0)
        }
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
        .navigationBarHidden(true)
        // Timeframe control pinned to the device bottom, visible only on Chart tab
        .overlay(alignment: .bottom) {
            if selectedTab == 0 {
                RangeSelector(range: $chartRange)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 0)
                    .ignoresSafeArea(.all, edges: .bottom)
                    .offset(y: -12)
            }
        }
        .sheet(isPresented: $showingAddToWatchlist) {
            AddToWatchlistSheet(stock: currentStock)
        }
        .sheet(isPresented: $premiumManager.showingPremiumUpgrade) {
            PremiumUpgradeView()
        }
        .onAppear {
            // Default to Chart tab on entry
            selectedTab = 0
            // Debug: Print stock data
            print("💰 Stock detail view for \(currentStock.symbol): price=\(currentStock.currentPrice), change=\(currentStock.dailyChange), dailyChangePercent=\(currentStock.dailyChangePercent)")
            
            // If stock price is 0, try to fetch fresh data
            if currentStock.currentPrice == 0 {
                print("⚠️ Stock price is 0, attempting to fetch fresh data...")
                Task {
                    do {
                        let freshStock = try await SupabaseService.shared.fetchStockData(symbol: stock.symbol)
                        print("✅ Fetched fresh stock data: \(freshStock.currentPrice)")
                        await MainActor.run {
                            currentStock = freshStock
                        }
                    } catch {
                        print("❌ Failed to fetch fresh stock data: \(error)")
                    }
                }
            }
        }
    }
}

// MARK: - Simple Smooth Price Transition
struct SmoothPriceTransition: View {
    let price: Double
    let isAnimating: Bool
    @State private var displayPrice: Double
    
    init(price: Double, isAnimating: Bool) {
        self.price = price
        self.isAnimating = isAnimating
        self._displayPrice = State(initialValue: price)
    }
    
    var body: some View {
        Text(String(format: "%.2f", displayPrice))
            .font(.system(size: 42, weight: .bold, design: .default))
            .monospacedDigit()
            .kerning(-0.5)
            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            .contentTransition(.numericText(value: displayPrice))
            .compositingGroup() // avoid offscreen blur during fast transitions
            .drawingGroup(opaque: false, colorMode: .linear) // render at higher fidelity
            .transaction { t in
                // Very tight, high-fidelity spring to reduce blur/stretch
                t.animation = isAnimating ? .interactiveSpring(response: 0.12, dampingFraction: 1.0, blendDuration: 0.0) : .default
                t.disablesAnimations = false
            }
            .animation(isAnimating ? .interactiveSpring(response: 0.12, dampingFraction: 1.0, blendDuration: 0.0) : .default, value: displayPrice)
            .onChange(of: price) { newPrice in
                if isAnimating {
                    displayPrice = newPrice
                } else {
                    displayPrice = newPrice
                }
            }
            .onChange(of: isAnimating) { animating in
                if !animating {
                    displayPrice = price
                }
            }
    }
    
    private var themeManager: ThemeManager {
        return ThemeManager.shared
    }
}

// MARK: - Simple Smooth Change Text
struct SmoothChangeText: View {
    let change: Double
    let percent: Double
    let isPositive: Bool
    let isAnimating: Bool
    @State private var displayChange: Double
    @State private var displayPercent: Double
    
    init(change: Double, percent: Double, isPositive: Bool, isAnimating: Bool) {
        self.change = change
        self.percent = percent
        self.isPositive = isPositive
        self.isAnimating = isAnimating
        self._displayChange = State(initialValue: change)
        self._displayPercent = State(initialValue: percent)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Text(isPositive ? "+" : "")
                .font(.system(size: 16, weight: .semibold, design: .default))
                .monospacedDigit()
                .foregroundColor(isPositive ? Color.bullish : Color.bearish)
            
            Text(String(format: "%.2f", displayChange))
                .font(.system(size: 16, weight: .semibold, design: .default))
                .monospacedDigit()
                .foregroundColor(isPositive ? Color.bullish : Color.bearish)
                .contentTransition(.numericText(value: displayChange))
                .compositingGroup()
                .drawingGroup(opaque: false, colorMode: .linear)
                .animation(isAnimating ? .interactiveSpring(response: 0.12, dampingFraction: 1.0, blendDuration: 0.0) : .default, value: displayChange)
            
            Text(" (")
                .font(.system(size: 16, weight: .semibold, design: .default))
                .monospacedDigit()
                .foregroundColor(isPositive ? Color.bullish : Color.bearish)
            
            Text(isPositive ? "+" : "")
                .font(.system(size: 16, weight: .semibold, design: .default))
                .monospacedDigit()
                .foregroundColor(isPositive ? Color.bullish : Color.bearish)
            
            Text(String(format: "%.2f", displayPercent))
                .font(.system(size: 16, weight: .semibold, design: .default))
                .monospacedDigit()
                .foregroundColor(isPositive ? Color.bullish : Color.bearish)
                .contentTransition(.numericText(value: displayPercent))
                .compositingGroup()
                .drawingGroup(opaque: false, colorMode: .linear)
                .animation(isAnimating ? .interactiveSpring(response: 0.12, dampingFraction: 1.0, blendDuration: 0.0) : .default, value: displayPercent)
            
            Text("%)")
                .font(.system(size: 16, weight: .semibold, design: .default))
                .monospacedDigit()
                .foregroundColor(isPositive ? Color.bullish : Color.bearish)
        }
        .onChange(of: change) { newChange in
            if isAnimating {
                displayChange = newChange
            } else {
                displayChange = newChange
            }
        }
        .onChange(of: percent) { newPercent in
            if isAnimating {
                displayPercent = newPercent
            } else {
                displayPercent = newPercent
            }
        }
        .onChange(of: isAnimating) { animating in
            if !animating {
                displayChange = change
                displayPercent = percent
            }
        }
    }
}

// MARK: - Animated Price Text Component (Legacy - keeping for compatibility)
struct AnimatedPriceText: View {
    let price: Double
    let isAnimating: Bool
    
    init(price: Double, isAnimating: Bool) {
        self.price = price
        self.isAnimating = isAnimating
    }
    
    var body: some View {
        SmoothPriceTransition(price: price, isAnimating: isAnimating)
    }
}

// MARK: - Animated Change Text Component (Legacy - keeping for compatibility)
struct AnimatedChangeText: View {
    let change: Double
    let percent: Double
    let isPositive: Bool
    let isAnimating: Bool
    
    init(change: Double, percent: Double, isPositive: Bool, isAnimating: Bool) {
        self.change = change
        self.percent = percent
        self.isPositive = isPositive
        self.isAnimating = isAnimating
    }
    
    var body: some View {
        SmoothChangeText(change: change, percent: percent, isPositive: isPositive, isAnimating: isAnimating)
    }
}

// MARK: - Ultra-Minimal Stock Header
struct ModernStockDetailHeader: View {
    let stock: Stock
    let onBack: () -> Void
    let onAddToWatchlist: () -> Void
    // Overrides during scrubbing
    var overridePrice: Double? = nil
    var overrideChange: Double? = nil
    var overridePercent: Double? = nil
    var isScrubbing: Bool = false
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var watchlistViewModel = WatchlistViewModel.shared
    @StateObject private var premiumManager = PremiumManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Minimal Navigation Bar
            HStack(spacing: 0) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(themeManager.isDarkMode ? Color.black.opacity(0.1) : Color.black.opacity(0.05))
                        )
                }
                
                Spacer()
                
                Button(action: {
                    if watchlistViewModel.isStockInWatchlist(stock.symbol) {
                        if let item = watchlistViewModel.watchlistItems.first(where: { $0.symbol.uppercased() == stock.symbol.uppercased() }) {
                            watchlistViewModel.removeFromWatchlist(item)
                        }
                    } else {
                        watchlistViewModel.addToWatchlist(stock)
                    }
                }) {
                    Image(systemName: watchlistViewModel.isStockInWatchlist(stock.symbol) ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(watchlistViewModel.isStockInWatchlist(stock.symbol) ? .red : (themeManager.isDarkMode ? .white : .black))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(themeManager.isDarkMode ? Color.black.opacity(0.1) : Color.black.opacity(0.05))
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Clean Stock Information Layout
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    // Ticker
                    Text(stock.symbol)
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        .tracking(-0.5)
                    
                    // Company Name
                    Text(stock.companyName)
                        .font(.system(size: 15, weight: .regular, design: .default))
                        .foregroundColor(themeManager.isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    // Price and Change
                    VStack(alignment: .leading, spacing: 6) {
                        let usingOverride = isScrubbing || overridePrice != nil || overrideChange != nil || overridePercent != nil
                        let livePrice = overridePrice ?? stock.currentPrice
                        let baseline = stock.currentPrice - stock.dailyChange
                        let changeValue: Double = usingOverride ? (overrideChange ?? (livePrice - baseline)) : stock.dailyChange
                        let percentValue: Double = usingOverride
                            ? (overridePercent ?? (baseline == 0 ? 0 : (changeValue / baseline * 100.0)))
                            : stock.dailyChangePercent
                        let isPositive = changeValue >= 0
                        
                        SmoothPriceTransition(
                            price: livePrice,
                            isAnimating: usingOverride
                        )
                        
                        HStack(spacing: 8) {
                            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(isPositive ? Color.green : Color.red)
                            
                            SmoothChangeText(
                                change: changeValue,
                                percent: percentValue,
                                isPositive: isPositive,
                                isAnimating: usingOverride
                            )
                        }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
    }
}

// MARK: - Ultra-Minimal Tab Bar
struct ModernTabBar: View {
    let tabs: [String]
    @Binding var selectedTab: Int
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 0) {
                        Text(tabs[index])
                            .font(.system(size: 15, weight: selectedTab == index ? .semibold : .regular, design: .default))
                            .foregroundColor(
                                selectedTab == index 
                                ? (themeManager.isDarkMode ? .white : .black)
                                : (themeManager.isDarkMode ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                            )
                            .padding(.vertical, 16)
                            .padding(.horizontal, 8)
                        
                        // Minimal active indicator
                        Rectangle()
                            .fill(selectedTab == index ? Color.black : Color.clear)
                            .frame(height: 1)
                            .opacity(themeManager.isDarkMode ? 0.3 : 0.2)
                    }
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
    }
}

// MARK: - Sentiment Analysis Tab
struct SentimentAnalysisTab: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isLoading = false
    @State private var sentimentData: SentimentData?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                if isLoading {
                    SentimentLoadingView()
                } else {
                    // Overall Sentiment Card
                    OverallSentimentCard(stock: stock)
                    
                    // News Sources Analysis
                    NewsSourcesAnalysisCard(stock: stock)
                    
                    // Sentiment Breakdown
                    SentimentBreakdownCard(stock: stock)
                    
                    // Key Insights
                    KeyInsightsCard(stock: stock)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .refreshable {
            await loadSentimentData()
        }
        .onAppear {
            Task {
                await loadSentimentData()
            }
        }
    }
    
    private func loadSentimentData() async {
        isLoading = true
        // Simulate loading
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isLoading = false
    }
}

// MARK: - Overall Sentiment Card
struct OverallSentimentCard: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    @State private var animateProgress = false
    
    // Mock sentiment score (replace with real data)
    private let sentimentScore: Double = 0.78
    private var sentimentColor: Color {
        if sentimentScore >= 0.7 { return .green }
        if sentimentScore >= 0.4 { return .orange }
        return .red
    }
    
    private var sentimentText: String {
        if sentimentScore >= 0.7 { return "Bullish" }
        if sentimentScore >= 0.4 { return "Neutral" }
        return "Bearish"
    }
    
    var body: some View {
        NotionCard {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Market Sentiment")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        
                        Text("Based on 1,247 sources analyzed")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(sentimentText)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(sentimentColor)
                        
                        Text("\(Int(sentimentScore * 100))%")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(sentimentColor)
                    }
                }
                
                // Sentiment Visualization
                VStack(spacing: 16) {
                    // Progress Ring
                    ZStack {
                        Circle()
                            .stroke(sentimentColor.opacity(0.2), lineWidth: 12)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: animateProgress ? sentimentScore : 0)
                            .stroke(
                                LinearGradient(
                                    colors: [sentimentColor.opacity(0.8), sentimentColor],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.5), value: animateProgress)
                        
                        VStack(spacing: 4) {
                            Text("\(Int(sentimentScore * 100))")
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .foregroundColor(sentimentColor)
                            
                            Text("SCORE")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                                .tracking(1.2)
                        }
                    }
                    
                    // Confidence Indicator
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Text("95% Confidence")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        
                        Spacer()
                        
                        Text("Updated 2 min ago")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).delay(0.3)) {
                animateProgress = true
            }
        }
    }
}

// MARK: - News Sources Analysis Card
struct NewsSourcesAnalysisCard: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    private let newsSources = [
        NewsSourceData(name: "Reuters", sentiment: 0.85, articles: 23, reliability: 0.95),
        NewsSourceData(name: "Bloomberg", sentiment: 0.72, articles: 18, reliability: 0.92),
        NewsSourceData(name: "CNBC", sentiment: 0.68, articles: 15, reliability: 0.88),
        NewsSourceData(name: "MarketWatch", sentiment: 0.81, articles: 12, reliability: 0.85),
        NewsSourceData(name: "Financial Times", sentiment: 0.76, articles: 9, reliability: 0.94)
    ]
    
    var body: some View {
        NotionCard {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "newspaper.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Text("News Sources Analysis")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Spacer()
                }
                
                // Sources List
                VStack(spacing: 16) {
                    ForEach(newsSources, id: \.name) { source in
                        NewsSourceRow(source: source)
                    }
                }
                
                // Summary
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Why this sentiment?")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        
                        Text("Strong earnings report, positive analyst upgrades, and solid market position drive bullish sentiment across major financial outlets.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                            .lineLimit(nil)
                    }
                    
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - News Source Data Model
struct NewsSourceData {
    let name: String
    let sentiment: Double
    let articles: Int
    let reliability: Double
}

// MARK: - News Source Row
struct NewsSourceRow: View {
    let source: NewsSourceData
    @StateObject private var themeManager = ThemeManager.shared
    
    private var sentimentColor: Color {
        if source.sentiment >= 0.7 { return .green }
        if source.sentiment >= 0.4 { return .orange }
        return .red
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Source Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(source.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    // Reliability Badge
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Text("\(Int(source.reliability * 100))%")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                }
                
                Text("\(source.articles) articles")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            }
            
            Spacer()
            
            // Sentiment Score
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(source.sentiment * 100))%")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(sentimentColor)
                
                Circle()
                    .fill(sentimentColor)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Sentiment Breakdown Card
struct SentimentBreakdownCard: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NotionCard {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Text("Sentiment Breakdown")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Spacer()
                }
                
                // Sentiment Chart
                VStack(alignment: .leading, spacing: 12) {
                    SentimentChart(stock: stock)
                }
                
                // Summary
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sentiment Trends")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        
                        Text("Overall market sentiment is bullish, with a strong focus on positive news and analyst upgrades.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                            .lineLimit(nil)
                    }
                    
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - Sentiment Chart
struct SentimentChart: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Placeholder for actual chart data
            Text("Sentiment Score over Time (Placeholder)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            
            // Example data for chart
            let data = [
                SentimentPoint(date: Date().addingTimeInterval(-86400), score: 0.65), // Yesterday
                SentimentPoint(date: Date().addingTimeInterval(-3600), score: 0.72), // 1 hour ago
                SentimentPoint(date: Date(), score: 0.78) // Now
            ]
            
            Chart(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Score", point.score)
                )
                .foregroundStyle(LinearGradient(colors: [.blue.opacity(0.5), .blue], startPoint: .leading, endPoint: .trailing))
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Score", point.score)
                )
                .foregroundStyle(Color.blue)
                .symbolSize(10)
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel()
                }
            }
            .frame(height: 200)
        }
    }
}

// MARK: - Sentiment Point
struct SentimentPoint: Identifiable {
    let id = UUID()
    let date: Date
    let score: Double
}

// MARK: - Key Insights Card
struct KeyInsightsCard: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NotionCard {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "lightbulb.max")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Text("Key Insights")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Spacer()
                }
                
                // Insights List
                VStack(alignment: .leading, spacing: 12) {
                    InsightItem(title: "Earnings Beat", description: "Strong earnings report, exceeding expectations by 15%.", isPositive: true)
                    InsightItem(title: "Analyst Upgrade", description: "Multiple analysts upgraded their price targets, driving bullish sentiment.", isPositive: true)
                    InsightItem(title: "Market Dominance", description: "Company maintains strong market position, outperforming peers.", isPositive: true)
                    InsightItem(title: "Positive News Flow", description: "Consistent positive news coverage across major financial outlets.", isPositive: true)
                }
                
                // Summary
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("What drives this stock?")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        
                        Text("The stock's strong performance and positive market sentiment are primarily driven by robust earnings, analyst upgrades, and market dominance.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                            .lineLimit(nil)
                    }
                    
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - Insight Item
struct InsightItem: View {
    let title: String
    let description: String
    let isPositive: Bool
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isPositive ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isPositive ? .green : .red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    .lineLimit(2)
            }
        }
    }
}

// MARK: - Add to Watchlist Sheet
struct AddToWatchlistSheet: View {
    let stock: Stock
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @State private var priceTarget: String = ""
    @State private var notes: String = ""
    @State private var alertsEnabled = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Add to Watchlist")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Text("Track \(stock.symbol) with custom alerts and notes")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Form
                VStack(spacing: 16) {
                    // Price Target
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Price Target")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        
                        TextField("Enter target price", text: $priceTarget)
                            .textFieldStyle(ModernTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        
                        TextField("Add notes about this stock", text: $notes, axis: .vertical)
                            .textFieldStyle(ModernTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    
                    // Alerts
                    Toggle("Enable Price Alerts", isOn: $alertsEnabled)
                        .toggleStyle(ModernToggleStyle())
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        // Add to watchlist logic
                        dismiss()
                    }) {
                        Text("Add to Watchlist")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Modern Text Field Style
struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
    }
}

// MARK: - Sentiment Loading View
struct SentimentLoadingView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary))
            
            Text("Analyzing market sentiment...")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
        }
        .frame(height: 300)
    }
}

// (removed: ProfessionalChartTab)

// (removed: ChartPoint)







// MARK: - Comprehensive Insights Tab
struct ComprehensiveInsightsTab: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Market Insights Summary
                MarketInsightsSummaryCard(stock: stock)
                
                // Technical Indicators
                TechnicalIndicatorsCard(stock: stock)
                
                // Social Sentiment Overview
                SocialSentimentOverviewCard(stock: stock)
                
                // AI Recommendations
                AIRecommendationsCard(stock: stock)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }
}

// MARK: - Market Insights Summary Card
struct MarketInsightsSummaryCard: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.yellow)
                
                Text("Market Insights")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                InsightRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Trend Analysis",
                    description: "Strong upward momentum with support at $195",
                    color: .green
                )
                
                InsightRow(
                    icon: "person.3.fill",
                    title: "Social Sentiment",
                    description: "Positive community sentiment (78% bullish)",
                    color: .blue
                )
                
                InsightRow(
                    icon: "newspaper.fill",
                    title: "News Impact",
                    description: "Recent earnings beat driving positive momentum",
                    color: .purple
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.isDarkMode ? Color.black.opacity(0.1) : Color.white.opacity(0.9))
        )
    }
}

// MARK: - Insight Row
struct InsightRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Text(description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(themeManager.isDarkMode ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Technical Indicators Card
struct TechnicalIndicatorsCard: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.blue)
                
                Text("Technical Indicators")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                IndicatorChip(title: "RSI", value: "68", color: .orange)
                IndicatorChip(title: "MACD", value: "Bullish", color: .green)
                IndicatorChip(title: "MA20", value: "Above", color: .blue)
                IndicatorChip(title: "Volume", value: "High", color: .purple)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.isDarkMode ? Color.black.opacity(0.1) : Color.white.opacity(0.9))
        )
    }
}

// MARK: - Indicator Chip
struct IndicatorChip: View {
    let title: String
    let value: String
    let color: Color
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(themeManager.isDarkMode ? Color.black.opacity(0.05) : Color.white.opacity(0.5))
        )
    }
}

// MARK: - Social Sentiment Overview Card
struct SocialSentimentOverviewCard: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.blue)
                
                Text("Social Sentiment")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                SentimentMetric(title: "Reddit", value: "78%", color: .orange)
                SentimentMetric(title: "Twitter", value: "82%", color: .blue)
                SentimentMetric(title: "Overall", value: "80%", color: .green)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.isDarkMode ? Color.black.opacity(0.1) : Color.white.opacity(0.9))
        )
    }
}

// MARK: - Sentiment Metric
struct SentimentMetric: View {
    let title: String
    let value: String
    let color: Color
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - AI Recommendations Card
struct AIRecommendationsCard: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.purple)
                
                Text("AI Recommendations")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                RecommendationRow(
                    icon: "arrow.up.circle.fill",
                    text: "Strong buy signal based on technical momentum",
                    color: .green
                )
                
                RecommendationRow(
                    icon: "eye.fill",
                    text: "Watch for resistance at $210 level",
                    color: .orange
                )
                
                RecommendationRow(
                    icon: "chart.bar.fill",
                    text: "Volume supports current trend continuation",
                    color: .blue
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.isDarkMode ? Color.black.opacity(0.1) : Color.white.opacity(0.9))
        )
    }
}

// MARK: - Recommendation Row
struct RecommendationRow: View {
    let icon: String
    let text: String
    let color: Color
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
                .frame(width: 20, height: 20)
            
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(themeManager.isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
                .lineLimit(2)
            
            Spacer()
        }
    }
}

// MARK: - Community Insights Tab
struct CommunityInsightsTab: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Social Sentiment
                SocialSentimentCard(stock: stock)
                
                // Reddit Discussions
                RedditDiscussionsCard(stock: stock)
                
                // Twitter Mentions
                TwitterMentionsCard(stock: stock)
                
                // Community Predictions
                CommunityPredictionsCard(stock: stock)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }
}

// MARK: - Social Sentiment Card
struct SocialSentimentCard: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NotionCard {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Text("Social Sentiment")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Spacer()
                }
                
                // Social Metrics
                HStack(spacing: 20) {
                    SocialMetric(title: "Reddit", mentions: "1.2K", sentiment: 0.72, color: .orange)
                    SocialMetric(title: "Twitter", mentions: "3.4K", sentiment: 0.68, color: .blue)
                    SocialMetric(title: "StockTwits", mentions: "856", sentiment: 0.81, color: .green)
                }
                
                // Trending Topics
                VStack(alignment: .leading, spacing: 12) {
                    Text("Trending Topics")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        TrendingTopicChip(text: "Earnings Beat")
                        TrendingTopicChip(text: "AI Innovation")
                        TrendingTopicChip(text: "Market Leader")
                        TrendingTopicChip(text: "Strong Growth")
                    }
                }
            }
        }
    }
}

// MARK: - Social Metric
struct SocialMetric: View {
    let title: String
    let mentions: String
    let sentiment: Double
    let color: Color
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            
            Text(mentions)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            
            Text("\(Int(sentiment * 100))% positive")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Trending Topic Chip
struct TrendingTopicChip: View {
    let text: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary).opacity(0.1)
            )
            .cornerRadius(16)
    }
}

// MARK: - Placeholder Cards (to be implemented)
struct FundamentalAnalysisCard: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NotionCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "building.2")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Text("Fundamental Analysis")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Spacer()
                }
                
                Text("Comprehensive fundamental analysis coming soon...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            }
        }
    }
}

struct AnalystRatingsCard: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NotionCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Text("Analyst Ratings")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Spacer()
                }
                
                Text("Professional analyst ratings and recommendations coming soon...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            }
        }
    }
}

struct PriceTargetsCard: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NotionCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "target")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Text("Price Targets")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Spacer()
                }
                
                Text("Analyst price targets and projections coming soon...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            }
        }
    }
}

struct RedditDiscussionsCard: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NotionCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Text("Reddit Discussions")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Spacer()
                }
                
                Text("Popular Reddit discussions and sentiment analysis coming soon...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            }
        }
    }
}

struct TwitterMentionsCard: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NotionCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "at")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Text("Twitter Mentions")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Spacer()
                }
                
                Text("Twitter mentions and social media sentiment coming soon...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            }
        }
    }
}

struct CommunityPredictionsCard: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NotionCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "crystal.ball")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Text("Community Predictions")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Spacer()
                }
                
                Text("Community-driven price predictions and sentiment coming soon...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            }
        }
    }
}

// MARK: - Sentiment Data Model (placeholder)
struct SentimentData {
    let overallScore: Double
    let confidence: Double
    let sources: [NewsSourceData]
} 
//
//  ModernStockDetailView.swift
//  ChartSense
//
//  Created by Aidan Quach on 7/22/25.
//

import SwiftUI
import Charts

// MARK: - Redesigned Stock Detail View
struct ModernStockDetailView: View {
    let stock: Stock
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedTab = 0
    @State private var showingAddToWatchlist = false
    @State private var selectedPoint: ChartPoint?
    
    private let tabs = ["Sentiment", "Chart", "Analysis", "Community"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Professional Header
            ModernStockDetailHeader(
                stock: stock,
                selectedPoint: selectedPoint,
                onBack: { dismiss() },
                onAddToWatchlist: { showingAddToWatchlist = true }
            )
            
            // Modern Tab Navigation
            ModernTabBar(
                tabs: tabs,
                selectedTab: $selectedTab
            )
            
            // Tab Content
            TabView(selection: $selectedTab) {
                // Sentiment Tab (Default)
                SentimentAnalysisTab(stock: stock)
                    .tag(0)
                
                // Chart Tab
                RobinhoodStyleChartTab(stock: stock, selectedPoint: $selectedPoint)
                    .tag(1)
                
                // Analysis Tab
                ComprehensiveAnalysisTab(stock: stock)
                    .tag(2)
                
                // Community Tab
                CommunityInsightsTab(stock: stock)
                    .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: selectedTab)
        }
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddToWatchlist) {
            AddToWatchlistSheet(stock: stock)
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
            .font(.system(size: 32, weight: .semibold, design: .monospaced))
            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            .onChange(of: price) { newPrice in
                if isAnimating {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        displayPrice = newPrice
                    }
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
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(isPositive ? Color.bullish : Color.bearish)
            
            Text(String(format: "%.2f", displayChange))
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(isPositive ? Color.bullish : Color.bearish)
            
            Text(" (")
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(isPositive ? Color.bullish : Color.bearish)
            
            Text(isPositive ? "+" : "")
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(isPositive ? Color.bullish : Color.bearish)
            
            Text(String(format: "%.2f", displayPercent))
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(isPositive ? Color.bullish : Color.bearish)
            
            Text("%)")
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(isPositive ? Color.bullish : Color.bearish)
        }
        .onChange(of: change) { newChange in
            if isAnimating {
                withAnimation(.easeInOut(duration: 0.3)) {
                    displayChange = newChange
                }
            } else {
                displayChange = newChange
            }
        }
        .onChange(of: percent) { newPercent in
            if isAnimating {
                withAnimation(.easeInOut(duration: 0.3)) {
                    displayPercent = newPercent
                }
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

// MARK: - Professional Stock Header
struct ModernStockDetailHeader: View {
    let stock: Stock
    let selectedPoint: ChartPoint?
    let onBack: () -> Void
    let onAddToWatchlist: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isInWatchlist = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            HStack(spacing: 16) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                }
                
                Spacer()
                
                Button(action: onAddToWatchlist) {
                    Image(systemName: isInWatchlist ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isInWatchlist ? .red : (themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Professional Stock Information
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    // Ticker and Company
                    VStack(alignment: .leading, spacing: 4) {
                        Text(stock.symbol)
                            .font(.system(size: 28, weight: .bold, design: .default))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        
                        Text(stock.companyName)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                            .lineLimit(1)
                    }
                    
                    // Price and Change
                    VStack(alignment: .leading, spacing: 6) {
                        SmoothPriceTransition(
                            price: selectedPoint?.price ?? stock.currentPrice,
                            isAnimating: selectedPoint != nil
                        )
                        
                        HStack(spacing: 8) {
                            let changeFromCurrent = selectedPoint?.price ?? stock.currentPrice - stock.currentPrice
                            let changePercent = (changeFromCurrent / stock.currentPrice) * 100
                            let isPositive = changeFromCurrent >= 0
                            
                            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(isPositive ? Color.bullish : Color.bearish)
                            
                            SmoothChangeText(
                                change: changeFromCurrent,
                                percent: changePercent,
                                isPositive: isPositive,
                                isAnimating: selectedPoint != nil
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

// MARK: - Modern Tab Bar
struct ModernTabBar: View {
    let tabs: [String]
    @Binding var selectedTab: Int
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 12) {
                        Text(tabs[index])
                            .font(.system(size: 16, weight: selectedTab == index ? .semibold : .medium))
                            .foregroundColor(
                                selectedTab == index 
                                ? (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                                : (themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                            )
                        
                        Rectangle()
                            .fill(
                                selectedTab == index 
                                ? (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                                : Color.clear
                            )
                            .frame(height: 3)
                            .cornerRadius(1.5)
                    }
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border),
            alignment: .bottom
        )
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

// MARK: - Robinhood Style Chart Tab
struct RobinhoodStyleChartTab: View {
    let stock: Stock
    @Binding var selectedPoint: ChartPoint?
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedTimeframe: TimeFrame = .oneDay
    @State private var chartData: [ChartPoint] = []
    @State private var isLoading = false
    @State private var showingPopup = false
    @State private var dragLocation: CGPoint = .zero
    @State private var popupOffset: CGSize = .zero
    @State private var showCursor = false

    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed spacing for consistency (always present)
            Rectangle()
                .fill(Color.clear)
                .frame(height: 1)
                .padding(.vertical, 16)
            
            // Full-Width Chart Area with Fixed Height
            GeometryReader { geometry in
                ZStack {
                    // Background frame to maintain consistent height
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 350)
                    
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            
                            Text("Loading chart data...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                        }
                    } else {
                        RobinhoodChart(
                            data: chartData,
                            selectedPoint: $selectedPoint,
                            stock: stock,
                            showingPopup: $showingPopup,
                            dragLocation: $dragLocation
                        )
                    }
                    
                                    // Robinhood-style Crosshair
                if showCursor, let selectedPoint = selectedPoint {
                    let cursorY = (1 - CGFloat((selectedPoint.price - minPrice) / (maxPrice - minPrice))) * 350
                    
                    // Vertical Line
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1)
                        .position(x: dragLocation.x, y: 175)
                    
                    // Blue Dot on Graph Line
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .position(x: dragLocation.x, y: cursorY)
                }
                }
                .frame(height: 350) // Fixed height for entire chart area
                .clipped() // Ensure content doesn't overflow
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            dragLocation = value.location
                            showCursor = true
                            updateSelectedPoint(at: value.location, in: geometry)
                        }
                        .onEnded { _ in
                            showCursor = false
                            selectedPoint = nil
                        }
                )
            }
            .frame(height: 350)
            
            Spacer()
            
            // Fixed Timeframe Buttons at Bottom
            HStack(spacing: 0) {
                ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                    TimeframeButton(
                        timeframe: timeframe,
                        isSelected: selectedTimeframe == timeframe,
                        action: {
                            selectedTimeframe = timeframe
                            loadChartData()
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .onAppear {
            loadChartData()
        }
    }
    
    private func getCursorY(for point: ChartPoint, in chartHeight: CGFloat) -> CGFloat {
        guard !chartData.isEmpty else { return chartHeight / 2 }
        
        let minPrice = chartData.map(\.price).min() ?? point.price
        let maxPrice = chartData.map(\.price).max() ?? point.price
        
        guard maxPrice != minPrice else { return chartHeight / 2 }
        
        return (1 - CGFloat((point.price - minPrice) / (maxPrice - minPrice))) * chartHeight
    }
    
    private func updateSelectedPoint(at location: CGPoint, in geometry: GeometryProxy) {
        guard !chartData.isEmpty else { return }
        
        let normalizedX = max(0, min(1, location.x / geometry.size.width))
        let index = Int(normalizedX * CGFloat(chartData.count - 1))
        let clampedIndex = max(0, min(chartData.count - 1, index))
        
        selectedPoint = chartData[clampedIndex]
    }
    
    private var minPrice: Double {
        chartData.map(\.price).min() ?? stock.currentPrice
    }
    
    private var maxPrice: Double {
        chartData.map(\.price).max() ?? stock.currentPrice
    }
    
    private func loadChartData() {
        isLoading = true
        selectedPoint = nil
        
        // Simulate loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            chartData = generateMockChartData(for: selectedTimeframe)
            isLoading = false
        }
    }
    
    private func generateMockChartData(for timeframe: TimeFrame) -> [ChartPoint] {
        let basePrice = stock.currentPrice
        let count = timeframe == .oneDay ? 100 : (timeframe == .oneWeek ? 50 : 30)
        var data: [ChartPoint] = []
        var currentPrice = basePrice * 0.95
        
        for i in 0..<count {
            let interval: TimeInterval
            switch timeframe {
            case .oneDay: interval = 240 // 4 minutes
            case .oneWeek: interval = 7200 // 2 hours
            default: interval = 86400 // 1 day
            }
            
            let date = Date().addingTimeInterval(-interval * Double(count - i))
            let trend = Double(i) / Double(count) * 0.08
            let volatility = 0.005
            let randomChange = Double.random(in: -volatility...volatility)
            
            currentPrice = currentPrice * (1 + trend/Double(count) + randomChange)
            
            if i == count - 1 {
                currentPrice = basePrice
            }
            
            data.append(ChartPoint(date: date, price: max(currentPrice, basePrice * 0.8)))
        }
        
        return data
    }
}

// MARK: - Chart Point Model
struct ChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let price: Double
    
    var formattedPrice: String {
        return String(format: "$%.2f", price)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var formattedDateOnly: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}



// MARK: - Robinhood Chart
struct RobinhoodChart: View {
    let data: [ChartPoint]
    @Binding var selectedPoint: ChartPoint?
    let stock: Stock
    @Binding var showingPopup: Bool
    @Binding var dragLocation: CGPoint
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showCursor = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Chart Background
                Rectangle()
                    .fill(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
                
                // Chart Line and Fill
                if !data.isEmpty {
                    // Fill Area with Blue Gradient
                    Path { path in
                        let points = data.enumerated().map { index, point in
                            CGPoint(
                                x: CGFloat(index) / CGFloat(data.count - 1) * geometry.size.width,
                                y: (1 - CGFloat((point.price - minPrice) / (maxPrice - minPrice))) * geometry.size.height
                            )
                        }
                        
                        path.move(to: CGPoint(x: points[0].x, y: geometry.size.height))
                        path.addLine(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                        path.addLine(to: CGPoint(x: points.last!.x, y: geometry.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.25),
                                Color.blue.opacity(0.05),
                                Color.blue.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Chart Line (Blue)
                    Path { path in
                        let points = data.enumerated().map { index, point in
                            CGPoint(
                                x: CGFloat(index) / CGFloat(data.count - 1) * geometry.size.width,
                                y: (1 - CGFloat((point.price - minPrice) / (maxPrice - minPrice))) * geometry.size.height
                            )
                        }
                        
                        path.move(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(
                        Color.blue,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                    )
                }
                
                // Interactive Cursor (highly optimized)
                if showCursor, let selectedPoint = selectedPoint {
                    let cursorX = dragLocation.x
                    let cursorY = (1 - CGFloat((selectedPoint.price - minPrice) / (maxPrice - minPrice))) * geometry.size.height
                    
                    // Vertical Line
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1)
                        .position(x: cursorX, y: geometry.size.height / 2)
                        .allowsHitTesting(false)
                    
                    // Blue Dot on Graph Line
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .position(x: cursorX, y: cursorY)
                        .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
        }
    }
    
    private var minPrice: Double {
        data.map(\.price).min() ?? 0
    }
    
    private var maxPrice: Double {
        data.map(\.price).max() ?? 1
    }
    

    
    private func updateSelectedPoint(at location: CGPoint, in geometry: GeometryProxy) {
        let index = Int(location.x / geometry.size.width * CGFloat(data.count))
        let clampedIndex = max(0, min(data.count - 1, index))
        selectedPoint = data[clampedIndex]
    }
}

// MARK: - Timeframe Button
struct TimeframeButton: View {
    let timeframe: TimeFrame
    let isSelected: Bool
    let action: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            Text(timeframe.displayName)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(
                    isSelected 
                    ? .white
                    : (themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isSelected 
                            ? Color.blue
                            : Color.clear
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Comprehensive Analysis Tab
struct ComprehensiveAnalysisTab: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Technical Analysis
                TechnicalAnalysisCard(stock: stock)
                
                // Fundamental Analysis
                FundamentalAnalysisCard(stock: stock)
                
                // Analyst Ratings
                AnalystRatingsCard(stock: stock)
                
                // Price Targets
                PriceTargetsCard(stock: stock)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }
}

// MARK: - Technical Analysis Card
struct TechnicalAnalysisCard: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NotionCard {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Text("Technical Analysis")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Spacer()
                }
                
                // Technical Indicators
                VStack(spacing: 16) {
                    TechnicalIndicatorRow(name: "RSI (14)", value: "65.4", status: .neutral, description: "Approaching overbought territory")
                    TechnicalIndicatorRow(name: "MACD", value: "0.23", status: .bullish, description: "Bullish crossover signal")
                    TechnicalIndicatorRow(name: "MA (20)", value: stock.formattedPrice, status: .bullish, description: "Price above moving average")
                    TechnicalIndicatorRow(name: "Bollinger Bands", value: "Mid", status: .neutral, description: "Trading within bands")
                }
                
                // Summary
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Technical Outlook")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        
                        Text("Mixed signals with bullish momentum but approaching resistance levels. Watch for breakout confirmation.")
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

// MARK: - Technical Indicator Row
struct TechnicalIndicatorRow: View {
    let name: String
    let value: String
    let status: IndicatorStatus
    let description: String
    @StateObject private var themeManager = ThemeManager.shared
    
    enum IndicatorStatus {
        case bullish, bearish, neutral
        
        var color: Color {
            switch self {
            case .bullish: return Color.bullish
            case .bearish: return Color.bearish
            case .neutral: return .orange
            }
        }
        
        var icon: String {
            switch self {
            case .bullish: return "arrow.up.circle.fill"
            case .bearish: return "arrow.down.circle.fill"
            case .neutral: return "minus.circle.fill"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text(value)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(status.color)
                    
                    Image(systemName: status.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(status.color)
                }
            }
            
            Text(description)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
        }
        .padding(.vertical, 4)
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
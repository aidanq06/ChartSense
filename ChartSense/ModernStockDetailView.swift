//
//  ModernStockDetailView.swift
//  ChartSense
//
//  Created by Aidan Quach on 7/22/25.
//

import SwiftUI

// MARK: - Modern Stock Detail View
struct ModernStockDetailView: View {
    let stock: Stock
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedTab = 0
    @State private var showingAddToWatchlist = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                ModernStockDetailHeader(
                    stock: stock,
                    onBack: { dismiss() },
                    onAddToWatchlist: { showingAddToWatchlist = true }
                )
                
                // Tab Selector
                ModernTabSelector(selectedTab: $selectedTab)
                
                // Content
                TabView(selection: $selectedTab) {
                    // Chart Tab
                    InteractiveChartView(stock: stock)
                        .tag(0)
                    
                    // Overview Tab
                    StockOverviewTab(stock: stock)
                        .tag(1)
                    
                    // News Tab
                    StockNewsTab(stock: stock)
                        .tag(2)
                    
                    // Analysis Tab
                    StockAnalysisTab(stock: stock)
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddToWatchlist) {
            AddToWatchlistSheet(stock: stock)
        }
    }
}

// MARK: - Modern Stock Detail Header
struct ModernStockDetailHeader: View {
    let stock: Stock
    let onBack: () -> Void
    let onAddToWatchlist: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isInWatchlist = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Navigation Bar
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        .frame(width: 40, height: 40)
                        .background(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryBackground : AppTheme.light.colors.secondaryBackground)
                        .cornerRadius(10)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(stock.symbol)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Text(stock.companyName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button(action: onAddToWatchlist) {
                    Image(systemName: isInWatchlist ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isInWatchlist ? .red : (themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText))
                        .frame(width: 40, height: 40)
                        .background(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryBackground : AppTheme.light.colors.secondaryBackground)
                        .cornerRadius(10)
                }
            }
            
            // Price Info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(stock.formattedPrice)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: stock.isPositiveChange ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(stock.isPositiveChange ? Color.bullish : Color.bearish)
                            
                            Text(stock.formattedChange)
                                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                .foregroundColor(stock.isPositiveChange ? Color.bullish : Color.bearish)
                        }
                        
                        Text("(\(stock.formattedChangePercent))")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(stock.isPositiveChange ? Color.bullish : Color.bearish)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Market Cap")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    
                    Text(stock.formattedMarketCap)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

// MARK: - Modern Tab Selector
struct ModernTabSelector: View {
    @Binding var selectedTab: Int
    @StateObject private var themeManager = ThemeManager.shared
    
    private let tabs = ["Chart", "Overview", "News", "Analysis"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: { selectedTab = index }) {
                    VStack(spacing: 8) {
                        Text(tabs[index])
                            .font(.system(size: 16, weight: selectedTab == index ? .semibold : .medium))
                            .foregroundColor(selectedTab == index ? (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary) : (themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText))
                        
                        Rectangle()
                            .fill(selectedTab == index ? (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary) : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

// MARK: - Stock Overview Tab
struct StockOverviewTab: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Key Statistics
                KeyStatisticsCard(stock: stock)
                
                // Company Info
                CompanyInfoCard(stock: stock)
                
                // Technical Indicators
                TechnicalIndicatorsCard(stock: stock)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Key Statistics Card
struct KeyStatisticsCard: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                
                Text("Key Statistics")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatItem(title: "Volume", value: stock.formattedVolume, icon: "chart.bar")
                StatItem(title: "P/E Ratio", value: stock.peRatio.map { String(format: "%.2f", $0) } ?? "N/A", icon: "chart.pie")
                StatItem(title: "52W High", value: stock.formatted52WeekHigh, icon: "arrow.up.circle")
                StatItem(title: "Market Cap", value: stock.formattedMarketCap, icon: "building.2")
            }
        }
        .padding(20)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            }
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryBackground : AppTheme.light.colors.secondaryBackground)
        .cornerRadius(12)
    }
}

// MARK: - Company Info Card
struct CompanyInfoCard: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                
                Text("Company Information")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(title: "Company", value: stock.companyName)
                InfoRow(title: "Symbol", value: stock.symbol)
                InfoRow(title: "Last Updated", value: stock.lastUpdated.formatted(date: .abbreviated, time: .shortened))
            }
        }
        .padding(20)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let title: String
    let value: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            
            Spacer()
        }
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
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                
                Text("Technical Indicators")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                IndicatorRow(name: "RSI", value: "65.4", status: .neutral)
                IndicatorRow(name: "MACD", value: "0.23", status: .bullish)
                IndicatorRow(name: "MA20", value: stock.formattedPrice, status: .neutral)
                IndicatorRow(name: "MA50", value: stock.formattedPrice, status: .neutral)
            }
        }
        .padding(20)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Indicator Row
struct IndicatorRow: View {
    let name: String
    let value: String
    let status: IndicatorStatus
    @StateObject private var themeManager = ThemeManager.shared
    
    enum IndicatorStatus {
        case bullish, bearish, neutral
        
        var color: Color {
            switch self {
            case .bullish: return Color.bullish
            case .bearish: return Color.bearish
            case .neutral: return .gray
            }
        }
    }
    
    var body: some View {
        HStack {
            Text(name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(status.color)
            
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Stock News Tab
struct StockNewsTab: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(0..<10, id: \.self) { index in
                    StockNewsCard(
                        title: "Sample News Article \(index + 1)",
                        summary: "This is a sample news article about \(stock.symbol) and its recent performance in the market.",
                        source: "Financial Times",
                        timeAgo: "2 hours ago"
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Stock News Card
struct StockNewsCard: View {
    let title: String
    let summary: String
    let source: String
    let timeAgo: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                .lineLimit(2)
            
            Text(summary)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                .lineLimit(3)
            
            HStack {
                Text(source)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                
                Spacer()
                
                Text(timeAgo)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            }
        }
        .padding(16)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Stock Analysis Tab
struct StockAnalysisTab: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Sentiment Analysis
                SentimentAnalysisCard(stock: stock)
                
                // Analyst Ratings
                AnalystRatingsCard(stock: stock)
                
                // Market Outlook
                MarketOutlookCard(stock: stock)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Sentiment Analysis Card
struct SentimentAnalysisCard: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                
                Text("AI Sentiment Analysis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                SentimentRow(label: "Overall", score: 0.75, color: .green)
                SentimentRow(label: "News", score: 0.68, color: .blue)
                SentimentRow(label: "Social", score: 0.82, color: .purple)
                SentimentRow(label: "Technical", score: 0.71, color: .orange)
            }
        }
        .padding(20)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Sentiment Row
struct SentimentRow: View {
    let label: String
    let score: Double
    let color: Color
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                .frame(width: 80, alignment: .leading)
            
            ProgressView(value: score)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
            
            Text("\(Int(score * 100))%")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

// MARK: - Analyst Ratings Card
struct AnalystRatingsCard: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                
                Text("Analyst Ratings")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                RatingRow(rating: "Buy", count: 15, percentage: 60, color: .green)
                RatingRow(rating: "Hold", count: 8, percentage: 32, color: .orange)
                RatingRow(rating: "Sell", count: 2, percentage: 8, color: .red)
            }
        }
        .padding(20)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Rating Row
struct RatingRow: View {
    let rating: String
    let count: Int
    let percentage: Int
    let color: Color
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            Text(rating)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                .frame(width: 60, alignment: .leading)
            
            ProgressView(value: Double(percentage) / 100)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
            
            Text("\(count)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

// MARK: - Market Outlook Card
struct MarketOutlookCard: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                
                Text("Market Outlook")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                OutlookItem(title: "Price Target", value: "$185.00", change: "+12.5%", isPositive: true)
                OutlookItem(title: "Earnings Date", value: "Oct 25, 2024", change: "Next Week", isPositive: nil)
                OutlookItem(title: "Dividend Yield", value: "0.5%", change: "Quarterly", isPositive: nil)
            }
        }
        .padding(20)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Outlook Item
struct OutlookItem: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool?
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            }
            
            Spacer()
            
            if let isPositive = isPositive {
                Text(change)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isPositive ? Color.bullish : Color.bearish)
            } else {
                Text(change)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
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
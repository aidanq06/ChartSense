//
//  Components.swift
//  ChartSense
//
//  Created by Aidan Quach on 7/22/25.
//

import SwiftUI

// MARK: - Card Components
struct NotionCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let backgroundColor: Color?
    
    @Environment(\.theme) private var theme
    
    init(
        padding: CGFloat = 16,
        backgroundColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor ?? theme.colors.cardBackground)
            .cornerRadius(theme.cornerRadius.card)
            .shadow(
                color: theme.shadows.card.color,
                radius: theme.shadows.card.radius,
                x: theme.shadows.card.x,
                y: theme.shadows.card.y
            )
    }
}

struct SentimentCard: View {
    let sentiment: SentimentAnalysis
    @Environment(\.theme) private var theme
    
    var body: some View {
        NotionCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                // Header with rating and timestamp
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        HStack {
                            Image(systemName: sentiment.overallRating.icon)
                                .foregroundColor(sentimentColor)
                                .font(.title2)
                            
                            Text("Sentiment")
                                .font(theme.typography.title3)
                                .primaryText(theme: theme)
                        }
                        
                        Text(sentiment.overallRating.rawValue)
                            .font(theme.typography.title2)
                            .foregroundColor(sentimentColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: theme.spacing.xs) {
                        Text("Updated \(sentiment.lastUpdated, formatter: RelativeDateTimeFormatter())")
                            .font(theme.typography.caption)
                            .tertiaryText(theme: theme)
                        
                        ConfidenceMeter(confidence: sentiment.confidence)
                    }
                }
                
                // Sentiment score bar
                SentimentScoreBar(score: sentiment.score, theme: theme)
                
                // Key drivers
                if !sentiment.keyDrivers.isEmpty {
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        Text("Key Drivers")
                            .font(theme.typography.subheadline)
                            .primaryText(theme: theme)
                        
                        ForEach(sentiment.keyDrivers, id: \.self) { driver in
                            HStack(alignment: .top, spacing: theme.spacing.sm) {
                                Circle()
                                    .fill(theme.colors.primary)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 6)
                                
                                Text(driver)
                                    .font(theme.typography.body)
                                    .secondaryText(theme: theme)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var sentimentColor: Color {
        switch sentiment.overallRating {
        case .stronglyBullish, .bullish:
            return theme.colors.success
        case .cautiouslyOptimistic:
            return theme.colors.accent
        case .neutral:
            return theme.colors.neutral
        case .bearishUndercurrents:
            return theme.colors.warning
        case .bearish, .highlyNegative:
            return theme.colors.error
        }
    }
}

struct NewsCard: View {
    let newsItem: NewsItem
    let onTap: () -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: onTap) {
            NotionCard {
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    // Category and source header
                    HStack {
                        HStack(spacing: theme.spacing.sm) {
                            Image(systemName: newsItem.category.icon)
                                .foregroundColor(categoryColor)
                                .font(.caption)
                            
                            Text(newsItem.category.rawValue)
                                .font(theme.typography.caption)
                                .foregroundColor(categoryColor)
                        }
                        .padding(.horizontal, theme.spacing.sm)
                        .padding(.vertical, theme.spacing.xs)
                        .background(categoryColor.opacity(0.1))
                        .cornerRadius(theme.cornerRadius.small)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(newsItem.source)
                                .font(theme.typography.caption)
                                .tertiaryText(theme: theme)
                            
                            Text(newsItem.timeAgo)
                                .font(theme.typography.caption2)
                                .tertiaryText(theme: theme)
                        }
                    }
                    
                    // Headline
                    Text(newsItem.headline)
                        .font(theme.typography.bodySemibold)
                        .primaryText(theme: theme)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                    
                    // Summary
                    Text(newsItem.summary)
                        .font(theme.typography.body)
                        .secondaryText(theme: theme)
                        .lineLimit(4)
                    
                    // Sentiment indicator
                    HStack {
                        HStack(spacing: theme.spacing.xs) {
                            Circle()
                                .fill(sentimentColor)
                                .frame(width: 8, height: 8)
                            
                            Text(sentimentLabel)
                                .font(theme.typography.caption)
                                .secondaryText(theme: theme)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .tertiaryText(theme: theme)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var categoryColor: Color {
        switch newsItem.category {
        case .earnings: return theme.colors.primary
        case .product: return Color.purple
        case .analyst: return theme.colors.warning
        case .regulatory: return theme.colors.error
        case .macro: return theme.colors.success
        case .competitor: return Color.indigo
        case .general: return theme.colors.neutral
        case .economic: return Color.brown
        case .technology: return Color.cyan
        }
    }
    
    private var sentimentColor: Color {
        if newsItem.sentiment > 0.1 { return theme.colors.success }
        else if newsItem.sentiment < -0.1 { return theme.colors.error }
        else { return theme.colors.neutral }
    }
    
    private var sentimentLabel: String {
        if newsItem.sentiment > 0.1 { return "Positive" }
        else if newsItem.sentiment < -0.1 { return "Negative" }
        else { return "Neutral" }
    }
}

struct StockQuoteCard: View {
    let stock: Stock
    @Environment(\.theme) private var theme
    
    var body: some View {
        NotionCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text(stock.symbol)
                            .font(theme.typography.title2)
                            .primaryText(theme: theme)
                        
                        Text(stock.companyName)
                            .font(theme.typography.body)
                            .secondaryText(theme: theme)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: theme.spacing.xs) {
                        Text(stock.formattedPrice)
                            .font(theme.typography.numberLarge)
                            .primaryText(theme: theme)
                        
                        Text(stock.formattedChange)
                            .font(theme.typography.numberSmall)
                            .foregroundColor(stock.isPositiveChange ? theme.colors.success : theme.colors.error)
                    }
                }
                
                if let marketCap = stock.marketCap,
                   let volume = stock.volume,
                   let peRatio = stock.peRatio {
                    
                    Divider()
                        .background(theme.colors.divider)
                    
                    HStack(spacing: theme.spacing.lg) {
                        MetricView(
                            title: "Market Cap",
                            value: formatLargeNumber(marketCap),
                            theme: theme
                        )
                        
                        MetricView(
                            title: "Volume",
                            value: formatLargeNumber(Double(volume)),
                            theme: theme
                        )
                        
                        MetricView(
                            title: "P/E",
                            value: String(format: "%.1f", peRatio),
                            theme: theme
                        )
                    }
                }
            }
        }
    }
    
    private func formatLargeNumber(_ number: Double) -> String {
        if number >= 1e12 {
            return String(format: "%.1fT", number / 1e12)
        } else if number >= 1e9 {
            return String(format: "%.1fB", number / 1e9)
        } else if number >= 1e6 {
            return String(format: "%.1fM", number / 1e6)
        } else if number >= 1e3 {
            return String(format: "%.1fK", number / 1e3)
        } else {
            return String(format: "%.0f", number)
        }
    }
}

struct StockQuoteCardSkeleton: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        NotionCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.colors.tertiaryBackground)
                            .frame(width: 80, height: 24)
                            .shimmer()
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.colors.tertiaryBackground)
                            .frame(width: 120, height: 16)
                            .shimmer()
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: theme.spacing.xs) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.colors.tertiaryBackground)
                            .frame(width: 100, height: 32)
                            .shimmer()
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.colors.tertiaryBackground)
                            .frame(width: 80, height: 16)
                            .shimmer()
                    }
                }
                
                Divider()
                    .background(theme.colors.divider)
                
                HStack(spacing: theme.spacing.lg) {
                    ForEach(0..<3, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.colors.tertiaryBackground)
                                .frame(width: 60, height: 12)
                                .shimmer()
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.colors.tertiaryBackground)
                                .frame(width: 80, height: 16)
                                .shimmer()
                        }
                    }
                }
            }
        }
    }
}

struct AnalystConsensusCard: View {
    let consensus: AnalystConsensus
    @Environment(\.theme) private var theme
    
    var body: some View {
        NotionCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text("Analyst Consensus")
                            .font(theme.typography.title3)
                            .primaryText(theme: theme)
                        
                        Text("\(consensus.numberOfAnalysts) analysts")
                            .font(theme.typography.caption)
                            .secondaryText(theme: theme)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: theme.spacing.xs) {
                        Text("Avg Target")
                            .font(theme.typography.caption)
                            .secondaryText(theme: theme)
                        
                        Text(String(format: "$%.2f", consensus.averageTargetPrice))
                            .font(theme.typography.numberMedium)
                            .primaryText(theme: theme)
                    }
                }
                
                // Rating distribution
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    HStack {
                        Text("Buy")
                            .font(theme.typography.caption)
                            .frame(width: 40, alignment: .leading)
                        
                        ProgressView(value: consensus.buyRating)
                            .progressViewStyle(LinearProgressViewStyle(tint: theme.colors.success))
                        
                        Text("\(consensus.strongBuyPercentage)%")
                            .font(theme.typography.caption)
                            .frame(width: 30, alignment: .trailing)
                    }
                    
                    HStack {
                        Text("Hold")
                            .font(theme.typography.caption)
                            .frame(width: 40, alignment: .leading)
                        
                        ProgressView(value: consensus.holdRating)
                            .progressViewStyle(LinearProgressViewStyle(tint: theme.colors.neutral))
                        
                        Text("\(consensus.holdPercentage)%")
                            .font(theme.typography.caption)
                            .frame(width: 30, alignment: .trailing)
                    }
                    
                    HStack {
                        Text("Sell")
                            .font(theme.typography.caption)
                            .frame(width: 40, alignment: .leading)
                        
                        ProgressView(value: consensus.sellRating)
                            .progressViewStyle(LinearProgressViewStyle(tint: theme.colors.error))
                        
                        Text("\(consensus.sellPercentage)%")
                            .font(theme.typography.caption)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
                .secondaryText(theme: theme)
            }
        }
    }
}

struct EventCard: View {
    let event: MarketEvent
    @Environment(\.theme) private var theme
    
    var body: some View {
        NotionCard {
            HStack(spacing: theme.spacing.md) {
                VStack {
                    Image(systemName: event.type.icon)
                        .font(.title2)
                        .foregroundColor(importanceColor)
                    
                    if event.isToday {
                        Text("TODAY")
                            .font(theme.typography.caption2)
                            .foregroundColor(theme.colors.error)
                            .fontWeight(.bold)
                    } else {
                        Text(formatEventDate(event.date))
                            .font(theme.typography.caption2)
                            .tertiaryText(theme: theme)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(width: 60)
                
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(event.title)
                        .font(theme.typography.bodySemibold)
                        .primaryText(theme: theme)
                    
                    Text(event.description)
                        .font(theme.typography.body)
                        .secondaryText(theme: theme)
                        .lineLimit(2)
                    
                    HStack {
                        HStack(spacing: theme.spacing.xs) {
                            Circle()
                                .fill(importanceColor)
                                .frame(width: 6, height: 6)
                            
                            Text(event.importance.rawValue)
                                .font(theme.typography.caption)
                                .foregroundColor(importanceColor)
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private var importanceColor: Color {
        switch event.importance {
        case .high: return theme.colors.error
        case .medium: return theme.colors.warning
        case .low: return theme.colors.success
        }
    }
    
    private func formatEventDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDate(date, inSameDayAs: now) {
            return "Today"
        } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
                  calendar.isDate(date, inSameDayAs: tomorrow) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Utility Components
struct SentimentScoreBar: View {
    let score: Double // -1.0 to 1.0
    let theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Sentiment Score")
                    .font(theme.typography.caption)
                    .secondaryText(theme: theme)
                
                Spacer()
                
                Text(String(format: "%.1f", score))
                    .font(theme.typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(scoreColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.colors.tertiaryBackground)
                        .frame(height: 4)
                    
                    // Score indicator
                    RoundedRectangle(cornerRadius: 2)
                        .fill(scoreColor)
                        .frame(width: max(4, geometry.size.width * CGFloat((score + 1) / 2)), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
    
    private var scoreColor: Color {
        if score > 0.1 { return theme.colors.success }
        else if score < -0.1 { return theme.colors.error }
        else { return theme.colors.neutral }
    }
}

struct ConfidenceMeter: View {
    let confidence: Double
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 4) {
            Text("Confidence")
                .font(theme.typography.caption2)
                .tertiaryText(theme: theme)
            
            Text("\(Int((confidence * 100).rounded()))%")
                .font(theme.typography.caption2)
                .fontWeight(.medium)
                .foregroundColor(confidenceColor)
        }
    }
    
    private var confidenceColor: Color {
        if confidence > 0.8 { return theme.colors.success }
        else if confidence > 0.6 { return theme.colors.warning }
        else { return theme.colors.error }
    }
}

struct MetricView: View {
    let title: String
    let value: String
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(theme.typography.caption)
                .tertiaryText(theme: theme)
            
            Text(value)
                .font(theme.typography.numberSmall)
                .primaryText(theme: theme)
        }
    }
}

// MARK: - Legacy Search Bar (Deprecated - Use ModernDiscoverSearchBar instead)
// This component has been replaced by the enhanced ModernDiscoverSearchBar in Views.swift
// to eliminate overlapping search implementations and provide a unified, visually comprehensive experience.

struct LoadingCard: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        NotionCard {
            VStack(spacing: theme.spacing.md) {
                ProgressView()
                    .scaleEffect(0.8)
                
                Text("Loading...")
                    .font(theme.typography.body)
                    .secondaryText(theme: theme)
            }
            .frame(maxWidth: .infinity)
            .padding(theme.spacing.lg)
        }
    }
}

struct ErrorCard: View {
    let message: String
    let onRetry: (() -> Void)?
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        NotionCard {
            VStack(spacing: theme.spacing.md) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(theme.colors.warning)
                
                Text("Something went wrong")
                    .font(theme.typography.bodySemibold)
                    .primaryText(theme: theme)
                
                Text(message)
                    .font(theme.typography.body)
                    .secondaryText(theme: theme)
                    .multilineTextAlignment(.center)
                
                if let onRetry = onRetry {
                    Button("Try Again", action: onRetry)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.primary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(theme.spacing.lg)
        }
    }
}

// MARK: - AI Chat Components
struct ChatBubble: View {
    let message: ChatMessage
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                        .cornerRadius(18)
                        .cornerRadius(4, corners: [.topLeft, .topRight, .bottomLeft])
                    
                    Text(message.timestamp.timeAgoDisplay())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                        .padding(.trailing, 4)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        // AI Avatar
                        ZStack {
                            Circle()
                                .fill((themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary).opacity(0.1))
                                .frame(width: 28, height: 28)
                            
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                        }
                        
                        Text(message.content)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
                            .cornerRadius(18)
                            .cornerRadius(4, corners: [.topLeft, .topRight, .bottomRight])
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border, lineWidth: 0.5)
                            )
                    }
                    
                    Text(message.timestamp.timeAgoDisplay())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                        .padding(.leading, 36)
                }
                
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

struct TypingIndicator: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 8) {
                    // AI Avatar
                    ZStack {
                        Circle()
                            .fill((themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary).opacity(0.1))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                    }
                    
                    // Typing dots
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                                .frame(width: 6, height: 6)
                                .scaleEffect(1.0)
                                .animation(
                                    Animation.easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(Double(index) * 0.2),
                                    value: animationOffset
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
                    .cornerRadius(18)
                    .cornerRadius(4, corners: [.topLeft, .topRight, .bottomRight])
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border, lineWidth: 0.5)
                    )
                }
            }
            
            Spacer(minLength: 60)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .onAppear {
            animationOffset = 1
        }
    }
}

struct SuggestedMessageButton: View {
    let suggestion: SuggestedMessage
    let onTap: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: suggestion.category.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                
                Text(suggestion.text)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border, lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ChatInputField: View {
    @Binding var text: String
    let onSend: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Input field
            TextField("Ask me anything about stocks, markets, or investing...", text: $text, axis: .vertical)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isFocused ? (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary) : (themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border),
                            lineWidth: isFocused ? 1.5 : 0.5
                        )
                )
                .focused($isFocused)
                .onSubmit {
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSend()
                    }
                }
            
            // Send button
            Button(action: onSend) {
                ZStack {
                    Circle()
                        .fill(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText) : (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .animation(.easeInOut(duration: 0.2), value: text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
    }
}

// MARK: - Extensions
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - App Icon Wrapper
struct AppRoundedIcon: View {
    let size: CGFloat
    @Environment(\.theme) private var theme
    
    init(size: CGFloat = 32) { self.size = size }
    
    var body: some View {
        ZStack {
            // Subtle container with continuous corner
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(theme.colors.secondaryBackground)
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                        .stroke(theme.colors.divider, lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
            
            // App icon from asset catalog, scaled to fit with gentle inset
            Image("AppIconImage")
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.76, height: size * 0.76)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        }
    }
}

// MARK: - Reusable Upgrade Pill Button (used across app)
struct UpgradePillButton: View {
    let title: String
    let action: () -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 11, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    colors: [theme.colors.primary, theme.colors.secondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(10)
            .frame(minWidth: 84, minHeight: 28)
            .fixedSize(horizontal: true, vertical: true)
            .shadow(color: theme.colors.primary.opacity(0.25), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Authentication Components
struct AuthButton: View {
    let title: String
    let icon: String
    let backgroundColor: Color
    let textColor: Color
    let action: () -> Void
    let isLoading: Bool
    
    init(title: String, icon: String, backgroundColor: Color, textColor: Color = .white, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
            )
        }
        .disabled(isLoading)
        .buttonStyle(PlainButtonStyle())
    }
}

struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    @FocusState private var isFocused: Bool
    
    init(placeholder: String, text: Binding<String>, isSecure: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
    }
    
    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .font(.system(size: 16, weight: .regular))
        .foregroundColor(.black)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: isFocused ? 2 : 1)
        )
        .focused($isFocused)
    }
}

struct DividerWithText: View {
    let text: String
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.gray)
                .padding(.horizontal, 16)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
        }
    }
}

// MARK: - Home Widget Components
struct HomeWidgetCard<Content: View>: View {
    let widget: HomeWidget
    let content: Content
    let onTap: (() -> Void)?
    @StateObject private var themeManager = ThemeManager.shared
    
    init(widget: HomeWidget, onTap: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.widget = widget
        self.onTap = onTap
        self.content = content()
    }
    
    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 8) {
                // Widget Header
                HStack {
                    Image(systemName: widget.type.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                    
                    Text(widget.type.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Spacer()
                    
                    if onTap != nil {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                    }
                }
                
                // Widget Content
                content
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border, lineWidth: 0.5)
            )
            .shadow(
                color: themeManager.isDarkMode ? AppTheme.dark.shadows.card.color : AppTheme.light.shadows.card.color,
                radius: themeManager.isDarkMode ? AppTheme.dark.shadows.card.radius : AppTheme.light.shadows.card.radius,
                x: themeManager.isDarkMode ? AppTheme.dark.shadows.card.x : AppTheme.light.shadows.card.x,
                y: themeManager.isDarkMode ? AppTheme.dark.shadows.card.y : AppTheme.light.shadows.card.y
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Legacy Search Widget (Deprecated - Use ModernDiscoverSearchBar instead)
// This component has been replaced by the enhanced ModernDiscoverSearchBar in Views.swift
// to eliminate overlapping search implementations and provide a unified, visually comprehensive experience.

struct NewsWidget: View {
    let data: NewsWidgetData
    let onNewsTapped: (NewsItem) -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(data.headlines.prefix(2), id: \.id) { news in
                Button(action: { onNewsTapped(news) }) {
                    HStack(alignment: .top, spacing: 8) {
                        // News content
                        VStack(alignment: .leading, spacing: 2) {
                            Text(news.headline)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            
                            HStack {
                                Text(news.source)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                                
                                Spacer()
                                
                                Text(news.timeAgo)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                            }
                        }
                        
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                if news.id != data.headlines.prefix(2).last?.id {
                    Divider()
                        .background(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border)
                }
            }
        }
    }
}

struct WatchlistWidget: View {
    let data: WatchlistWidgetData
    let onStockTapped: (Stock) -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(data.stocks.prefix(3), id: \.symbol) { stock in
                WatchlistTickerItemView(
                    stock: stock,
                    sentiment: data.sentiments[stock.symbol]
                ) { onStockTapped(stock) }
                
                if stock.symbol != data.stocks.prefix(3).last?.symbol {
                    Divider()
                        .background(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border)
                }
            }
        }
    }
}

// MARK: - Premium Watchlist Ticker Item
struct WatchlistTickerItemView: View {
    let stock: Stock
    let sentiment: SentimentAnalysis?
    let onTap: () -> Void
    
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isPressed = false
    
    private var changeIsPositive: Bool { stock.dailyChangePercent >= 0 }
    
    private var sentimentScore: Double { sentiment?.score ?? 0 }
    private var sentimentScoreInt: Int { Int(round(sentimentScore * 100)) }
    private var confidence: Double { sentiment?.confidence ?? 0 }
    
    private var shortClassification: String {
        guard let rating = sentiment?.overallRating else { return "Neutral" }
        switch rating {
        case .stronglyBullish, .bullish, .cautiouslyOptimistic: return "Bullish"
        case .neutral: return "Neutral"
        case .bearishUndercurrents, .bearish, .highlyNegative: return "Bearish"
        }
    }
    
    // Factor percents normalized to 0–100 (from -1..1 inputs)
    private var socialPercent: Int {
        let v = sentiment?.breakdown.socialSentiment ?? 0
        return Int(max(0, min(100, ((v + 1) / 2) * 100)).rounded())
    }
    private var newsPercent: Int {
        let pos = sentiment?.breakdown.newsPositive ?? 0
        let neg = sentiment?.breakdown.newsNegative ?? 0
        // Net bias −1..1, normalize
        let net = max(-1, min(1, pos - neg))
        return Int(max(0, min(100, ((net + 1) / 2) * 100)).rounded())
    }
    private var technicalPercent: Int {
        let v = sentiment?.breakdown.technicalIndicators ?? 0
        return Int(max(0, min(100, ((v + 1) / 2) * 100)).rounded())
    }
    
    private var aiSummaryText: String {
        guard let sentiment = sentiment else { return "AI analysis unavailable" }
        
        let score = sentiment.score
        let social = socialPercent
        let news = newsPercent
        let technical = technicalPercent
        
        if score > 0.3 {
            return "Strong positive sentiment across all factors with high confidence"
        } else if score > 0.1 {
            return "Moderate positive outlook with balanced factor analysis"
        } else if score > -0.1 {
            return "Neutral sentiment with mixed factor performance"
        } else if score > -0.3 {
            return "Slight negative bias with cautious factor outlook"
        } else {
            return "Strong negative sentiment across multiple factors"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                            Text(stock.symbol)
                            .font(.system(size: 16, weight: .semibold, design: .default))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                            .tracking(-0.2)
                            Text(stock.companyName)
                            .font(.system(size: 12, weight: .medium, design: .default))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                                .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .truncationMode(.tail)
                    }
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 5) {
                        Text(stock.formattedPrice)
                            .font(.system(size: 17, weight: .semibold, design: .monospaced))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        themeManager.isDarkMode ? Color(red: 0.5, green: 0.7, blue: 0.95) : Color(red: 0.2, green: 0.5, blue: 0.9),
                                        themeManager.isDarkMode ? Color(red: 0.7, green: 0.5, blue: 0.95) : Color(red: 0.4, green: 0.3, blue: 0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        ChangeChip(changePercentText: stock.formattedChangePercent, isPositive: changeIsPositive)
                    }
                }
                .padding(.bottom, 4)
                
                // Sentiment indicator
                if sentiment != nil {
                    HStack(spacing: 8) {
                        // Sentiment label
                        Text("\(shortClassification)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                        
                        // Sentiment score
                        Text("\(sentimentScoreInt >= 0 ? "+" : "")\(sentimentScoreInt)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(sentimentScoreInt >= 0 ? 
                                (themeManager.isDarkMode ? Color(red: 0.3, green: 0.8, blue: 0.5) : Color(red: 0.2, green: 0.7, blue: 0.4)) :
                                (themeManager.isDarkMode ? Color(red: 0.9, green: 0.4, blue: 0.5) : Color(red: 0.8, green: 0.3, blue: 0.4))
                            )
                        
                        Spacer()
                        
                        // Subtle sentiment indicator
                        Circle()
                            .fill(sentimentScoreInt >= 0 ? 
                                (themeManager.isDarkMode ? Color(red: 0.3, green: 0.8, blue: 0.5) : Color(red: 0.2, green: 0.7, blue: 0.4)) :
                                (themeManager.isDarkMode ? Color(red: 0.9, green: 0.4, blue: 0.5) : Color(red: 0.8, green: 0.3, blue: 0.4))
                            )
                            .frame(width: 6, height: 6)
                    }
                    .padding(.vertical, 3)
                }
                
                // Factors
                if sentiment != nil {
                    VStack(spacing: 4) {
                        // Social
                        HStack(spacing: 8) {
                            Text("Social")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                                .frame(width: 60, alignment: .leading)
                            
                            // Progress bar
                            Rectangle()
                                .fill(themeManager.isDarkMode ? Color(red: 0.2, green: 0.2, blue: 0.25) : Color(red: 0.9, green: 0.9, blue: 0.92))
                                .frame(height: 3)
                                .overlay(
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    themeManager.isDarkMode ? Color(red: 0.5, green: 0.7, blue: 0.95) : Color(red: 0.2, green: 0.5, blue: 0.9),
                                                    themeManager.isDarkMode ? Color(red: 0.7, green: 0.5, blue: 0.95) : Color(red: 0.4, green: 0.3, blue: 0.8)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: max(0, min(100, CGFloat(socialPercent))) * 0.01 * (UIScreen.main.bounds.width - 150), height: 3)
                                        .clipped()
                                    , alignment: .leading
                                )
                                .cornerRadius(1.5)
                            
                            Text("\(socialPercent)%")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                                .frame(width: 35, alignment: .trailing)
                        }
                        
                        // News
                        HStack(spacing: 8) {
                            Text("News")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                                .frame(width: 60, alignment: .leading)
                            
                            // Progress bar
                            Rectangle()
                                .fill(themeManager.isDarkMode ? Color(red: 0.2, green: 0.2, blue: 0.25) : Color(red: 0.9, green: 0.9, blue: 0.92))
                                .frame(height: 3)
                                .overlay(
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    themeManager.isDarkMode ? Color(red: 0.5, green: 0.7, blue: 0.95) : Color(red: 0.2, green: 0.5, blue: 0.9),
                                                    themeManager.isDarkMode ? Color(red: 0.7, green: 0.5, blue: 0.95) : Color(red: 0.4, green: 0.3, blue: 0.8)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: max(0, min(100, CGFloat(newsPercent))) * 0.01 * (UIScreen.main.bounds.width - 150), height: 3)
                                        .clipped()
                                    , alignment: .leading
                                )
                                .cornerRadius(1.5)
                            
                            Text("\(newsPercent)%")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                                .frame(width: 35, alignment: .trailing)
                        }
                        
                        // Technical
                        HStack(spacing: 8) {
                            Text("Technical")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                                .frame(width: 60, alignment: .leading)
                            
                            // Progress bar
                            Rectangle()
                                .fill(themeManager.isDarkMode ? Color(red: 0.2, green: 0.2, blue: 0.25) : Color(red: 0.9, green: 0.9, blue: 0.92))
                                .frame(height: 3)
                                .overlay(
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    themeManager.isDarkMode ? Color(red: 0.5, green: 0.7, blue: 0.95) : Color(red: 0.2, green: 0.5, blue: 0.9),
                                                    themeManager.isDarkMode ? Color(red: 0.7, green: 0.5, blue: 0.95) : Color(red: 0.4, green: 0.3, blue: 0.8)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: max(0, min(100, CGFloat(technicalPercent))) * 0.01 * (UIScreen.main.bounds.width - 150), height: 3)
                                        .clipped()
                                    , alignment: .leading
                                )
                                .cornerRadius(1.5)
                            
                            Text("\(technicalPercent)%")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                                .frame(width: 35, alignment: .trailing)
                        }
                    }
                    .padding(.top, 2)
                }
                
                // AI Summary
                if sentiment != nil {
                    HStack(spacing: 6) {
                        // AI Star icon
                        Image(systemName: "sparkles")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        themeManager.isDarkMode ? Color(red: 0.5, green: 0.7, blue: 0.95) : Color(red: 0.2, green: 0.5, blue: 0.9),
                                        themeManager.isDarkMode ? Color(red: 0.7, green: 0.5, blue: 0.95) : Color(red: 0.4, green: 0.3, blue: 0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // AI Summary text
                        Text(aiSummaryText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.08), value: isPressed)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        themeManager.isDarkMode ? 
                            Color(red: 0.12, green: 0.12, blue: 0.15) : 
                            Color(red: 0.98, green: 0.98, blue: 0.99)
                    )
            )
            // Inner highlight for glass effect
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        LinearGradient(
                            colors: [
                                themeManager.isDarkMode ? Color.white.opacity(0.15) : Color.white.opacity(0.4),
                                themeManager.isDarkMode ? Color.white.opacity(0.05) : Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            // Outer gradient border
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        LinearGradient(
                            colors: [
                                themeManager.isDarkMode ? Color(red: 0.5, green: 0.7, blue: 0.95) : Color(red: 0.2, green: 0.5, blue: 0.9),
                                themeManager.isDarkMode ? Color(red: 0.7, green: 0.5, blue: 0.95) : Color(red: 0.4, green: 0.3, blue: 0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            )
            .shadow(color: (themeManager.isDarkMode ? Color(red: 0.5, green: 0.7, blue: 0.95) : Color(red: 0.2, green: 0.5, blue: 0.9)).opacity(0.12), radius: 4, x: 0, y: 1)
            .shadow(
                color: (themeManager.isDarkMode ? AppTheme.dark.shadows.card.color : AppTheme.light.shadows.card.color).opacity(0.6),
                radius: themeManager.isDarkMode ? AppTheme.dark.shadows.card.radius : AppTheme.light.shadows.card.radius,
                x: themeManager.isDarkMode ? AppTheme.dark.shadows.card.x : AppTheme.light.shadows.card.x,
                y: themeManager.isDarkMode ? AppTheme.dark.shadows.card.y : AppTheme.light.shadows.card.y
            )
                }
                .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Change Chip
private struct ChangeChip: View {
    let changePercentText: String
    let isPositive: Bool
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 10, weight: .semibold))
            Text(changePercentText)
                .font(.system(size: 11.5, weight: .semibold))
        }
        .foregroundColor(isPositive ? (themeManager.isDarkMode ? Color(red: 0.3, green: 0.8, blue: 0.5) : Color(red: 0.2, green: 0.7, blue: 0.4)) : (themeManager.isDarkMode ? Color(red: 0.9, green: 0.4, blue: 0.5) : Color(red: 0.8, green: 0.3, blue: 0.4)))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            LinearGradient(
                colors: [
                    isPositive ? (themeManager.isDarkMode ? Color(red: 0.3, green: 0.8, blue: 0.5) : Color(red: 0.2, green: 0.7, blue: 0.4)).opacity(0.12) : (themeManager.isDarkMode ? Color(red: 0.9, green: 0.4, blue: 0.5) : Color(red: 0.8, green: 0.3, blue: 0.4)).opacity(0.12),
                    isPositive ? (themeManager.isDarkMode ? Color(red: 0.3, green: 0.8, blue: 0.5) : Color(red: 0.2, green: 0.7, blue: 0.4)).opacity(0.04) : (themeManager.isDarkMode ? Color(red: 0.9, green: 0.4, blue: 0.5) : Color(red: 0.8, green: 0.3, blue: 0.4)).opacity(0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isPositive ? (themeManager.isDarkMode ? Color(red: 0.3, green: 0.8, blue: 0.5) : Color(red: 0.2, green: 0.7, blue: 0.4)).opacity(0.25) : (themeManager.isDarkMode ? Color(red: 0.9, green: 0.4, blue: 0.5) : Color(red: 0.8, green: 0.3, blue: 0.4)).opacity(0.25), lineWidth: 0.6)
        )
        .cornerRadius(7)
    }
}

// MARK: - Sentiment Strip
private struct SentimentStrip: View {
    let score: Double // -1..1
    let label: String
    @StateObject private var themeManager = ThemeManager.shared
    
    private var progress: CGFloat { CGFloat(max(0, min(1, (score + 1) / 2))) }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryBackground : AppTheme.light.colors.tertiaryBackground)
                    .frame(height: 7)
                
                LinearGradient(
                    colors: [
                        (themeManager.isDarkMode ? AppTheme.dark.colors.error : AppTheme.light.colors.error).opacity(0.55),
                        (themeManager.isDarkMode ? AppTheme.dark.colors.neutral : AppTheme.light.colors.neutral).opacity(0.35),
                        (themeManager.isDarkMode ? AppTheme.dark.colors.success : AppTheme.light.colors.success).opacity(0.55)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .mask(RoundedRectangle(cornerRadius: 4).frame(height: 7))
                
                // Marker
                Circle()
                    .fill(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border, lineWidth: 1)
                    )
                    .offset(x: max(0, min(geo.size.width - 10, progress * geo.size.width - 5)))
                
                // Label near marker
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    .offset(x: max(0, min(geo.size.width - 70, progress * geo.size.width - 35)), y: -16)
            }
        }
        .frame(height: 14)
    }
}

// MARK: - Confidence Capsule
private struct ConfidenceCapsule: View {
    let confidence: Double // 0..1
    @StateObject private var themeManager = ThemeManager.shared
    
    private var clamped: CGFloat { CGFloat(max(0, min(1, confidence))) }
    private var percentText: String { "\(Int((clamped * 100).rounded()))%" }
    
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryBackground : AppTheme.light.colors.secondaryBackground)
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary,
                            themeManager.isDarkMode ? AppTheme.dark.colors.secondary : AppTheme.light.colors.secondary
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ).opacity(0.55)
                )
                .frame(width: 72 * clamped)
            Text(percentText)
                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                .frame(maxWidth: .infinity)
        }
        .frame(width: 72, height: 16)
        .overlay(
            Capsule().stroke((themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary).opacity(0.35), lineWidth: 0.5)
        )
    }
}

// MARK: - Factor Pill
private struct FactorPill: View {
    let icon: String
    let title: String
    let percent: Int
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            themeManager.isDarkMode ? Color(red: 0.5, green: 0.7, blue: 0.95) : Color(red: 0.2, green: 0.5, blue: 0.9),
                            themeManager.isDarkMode ? Color(red: 0.7, green: 0.5, blue: 0.95) : Color(red: 0.4, green: 0.3, blue: 0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text("\(title) \(percent)%")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .allowsTightening(true)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [
                            themeManager.isDarkMode ? Color(red: 0.5, green: 0.7, blue: 0.95).opacity(0.08) : Color(red: 0.2, green: 0.5, blue: 0.9).opacity(0.08),
                            themeManager.isDarkMode ? Color(red: 0.7, green: 0.5, blue: 0.95).opacity(0.04) : Color(red: 0.4, green: 0.3, blue: 0.8).opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(themeManager.isDarkMode ? Color(red: 0.5, green: 0.7, blue: 0.95).opacity(0.2) : Color(red: 0.2, green: 0.5, blue: 0.9).opacity(0.2), lineWidth: 0.5)
        )
        .cornerRadius(10)
        .frame(height: 30)
    }
}

// MARK: - SparklineMini
private struct SparklineMini: View {
    let data: [Double]
    let isPositive: Bool
    @StateObject private var themeManager = ThemeManager.shared
    
    private var sparklineFillColors: [Color] {
        let color1 = themeManager.isDarkMode ? Color(red: 0.5, green: 0.7, blue: 0.95) : Color(red: 0.2, green: 0.5, blue: 0.9)
        let color2 = themeManager.isDarkMode ? Color(red: 0.7, green: 0.5, blue: 0.95) : Color(red: 0.4, green: 0.3, blue: 0.8)
        return [color1.opacity(0.2), color2.opacity(0.08), Color.clear]
    }
    
    private var sparklineStrokeColors: [Color] {
        let color1 = themeManager.isDarkMode ? Color(red: 0.5, green: 0.7, blue: 0.95) : Color(red: 0.2, green: 0.5, blue: 0.9)
        let color2 = themeManager.isDarkMode ? Color(red: 0.7, green: 0.5, blue: 0.95) : Color(red: 0.4, green: 0.3, blue: 0.8)
        return [color1, color2]
    }
    
    var body: some View {
        GeometryReader { geo in
            let values = data
            if values.count > 1, let minV = values.min(), let maxV = values.max(), maxV - minV > 0 {
                let points: [CGPoint] = values.enumerated().map { idx, val in
                    let x = geo.size.width * CGFloat(idx) / CGFloat(values.count - 1)
                    let y = geo.size.height * CGFloat(1 - (val - minV) / (maxV - minV))
                    return CGPoint(x: x, y: y)
                }
                ZStack {
                    // Gradient fill
                    Path { path in
                        path.move(to: points.first ?? .zero)
                        for p in points.dropFirst() { path.addLine(to: p) }
                        path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                        path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: sparklineFillColors,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Line
                    Path { path in
                        path.move(to: points.first ?? .zero)
                        for p in points.dropFirst() { path.addLine(to: p) }
                    }
                    .stroke(
                        LinearGradient(
                            colors: sparklineStrokeColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round)
                    )
                }
            } else {
                Rectangle().fill(Color.clear)
            }
        }
    }
}

struct AIWidget: View {
    let data: AIWidgetData
    let onAITapped: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // AI Insight
            if let insight = data.insights.first {
                Text(insight)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            // Quick action button
            Button(action: onAITapped) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 12, weight: .medium))
                    
                    Text("Ask AI anything...")
                        .font(.system(size: 12, weight: .medium))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background((themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary).opacity(0.1))
                .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct MarketOverviewWidget: View {
    let data: MarketWidgetData
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(data.indices.prefix(3), id: \.symbol) { index in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(index.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        
                        Text(index.symbol)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.2f", index.price))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        
                        HStack(spacing: 4) {
                            Text(String(format: "%.2f", index.change))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(index.change >= 0 ? Color.bullish : Color.bearish)
                            
                            Text(String(format: "(%.2f%%)", index.changePercent))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(index.change >= 0 ? Color.bullish : Color.bearish)
                        }
                    }
                }
                
                if index.symbol != data.indices.prefix(3).last?.symbol {
                    Divider()
                        .background(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border)
                }
            }
        }
    }
}

struct TrendingStocksWidget: View {
    let data: TrendingWidgetData
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Trending topics
            if !data.trends.isEmpty {
                HStack(spacing: 6) {
                    ForEach(data.trends.prefix(4), id: \.self) { trend in
                        Text(trend)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background((themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary).opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
            
            // Trending stocks
            if !data.stocks.isEmpty {
                HStack(spacing: 8) {
                    ForEach(data.stocks.prefix(4), id: \.symbol) { stock in
                        VStack(alignment: .center, spacing: 2) {
                            Text(stock.symbol)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                            
                            Text(stock.formattedPrice)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(stock.dailyChange >= 0 ? Color.bullish : Color.bearish)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

// MARK: - Loading and State Components

struct LoadingSkeleton: View {
    let lines: Int
    let lineHeight: CGFloat
    let spacing: CGFloat
    @StateObject private var themeManager = ThemeManager.shared
    
    init(lines: Int = 3, lineHeight: CGFloat = 12, spacing: CGFloat = 8) {
        self.lines = lines
        self.lineHeight = lineHeight
        self.spacing = spacing
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(0..<lines, id: \.self) { index in
                RoundedRectangle(cornerRadius: 6)
                    .fill(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryBackground : AppTheme.light.colors.tertiaryBackground)
                    .frame(height: lineHeight)
                    .frame(maxWidth: index == lines - 1 ? 0.6 : 1.0, alignment: .leading)
                    .shimmer()
            }
        }
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.3),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: -200 + 400 * phase)
                .animation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: phase
                )
            )
            .onAppear {
                phase = 1
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

struct StockErrorView: View {
    let error: String
    let retryAction: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.warning : AppTheme.light.colors.warning)
            
            Text("Oops! Something went wrong")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            
            Text(error)
                .font(.body)
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: retryAction) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                    Text("Try Again")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                .cornerRadius(8)
            }
        }
        .padding(32)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    @StateObject private var themeManager = ThemeManager.shared
    
    init(icon: String, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            
            Text(message)
                .font(.body)
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                        .cornerRadius(8)
                }
            }
        }
        .padding(32)
    }
}

// MARK: - Real-time Price Components

struct RealTimePriceView: View {
    let stock: Stock
    @StateObject private var webSocketService = WebSocketService.shared
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            Text(stock.formattedRealTimePrice)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(stock.hasRealTimeUpdate ? .green : .primary)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isAnimating)
            
            if stock.hasRealTimeUpdate {
                Image(systemName: "livephoto")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
                    .opacity(isAnimating ? 1.0 : 0.7)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isAnimating)
            }
        }
        .onAppear {
            isAnimating = true
        }
        .onChange(of: stock.realTimePrice) { _ in
            // Trigger animation when price updates
            isAnimating = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isAnimating = true
            }
        }
    }
}

struct ConnectionStatusView: View {
    @StateObject private var webSocketService = WebSocketService.shared
    @State private var showingErrorDetails = false
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(connectionColor)
                .frame(width: 6, height: 6)
            
            Text(shortLabel)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.12))
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            if case .error = webSocketService.connectionStatus {
                showingErrorDetails = true
            }
        }
        .alert("Connection issue", isPresented: $showingErrorDetails) {
            Button("Dismiss", role: .cancel) {}
            Button("Reconnect") { webSocketService.connect() }
        } message: {
            Text(errorDetails)
        }
    }
    
    private var connectionColor: Color {
        switch webSocketService.connectionStatus {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .disconnected, .error:
            return .red
        }
    }
    
    private var shortLabel: String {
        switch webSocketService.connectionStatus {
        case .connected:
            return "Live"
        case .connecting:
            return "Connecting"
        case .disconnected:
            return "Offline"
        case .error:
            return "Error"
        }
    }
    
    private var errorDetails: String {
        if case .error(let message) = webSocketService.connectionStatus {
            return ErrorMessageParser.parseUserFriendlyMessage(message)
        }
        return ""
    }
}

// MARK: - Stock Detail Sheet Components
struct StockOverviewCard: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(stock.symbol)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Text(stock.companyName)
                        .font(.body)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(stock.formattedPrice)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    HStack(spacing: 4) {
                        Image(systemName: stock.dailyChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                            .foregroundColor(stock.dailyChange >= 0 ? Color.bullish : Color.bearish)
                        
                        Text(stock.formattedChange)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(stock.dailyChange >= 0 ? Color.bullish : Color.bearish)
                        
                        Text("(\(stock.formattedChangePercent))")
                            .font(.caption)
                            .foregroundColor(stock.dailyChange >= 0 ? Color.bullish : Color.bearish)
                    }
                }
            }
            
            // Key Metrics
            HStack(spacing: 20) {
                MetricItem(title: "Market Cap", value: stock.formattedMarketCap)
                MetricItem(title: "Volume", value: stock.formattedVolume)
                MetricItem(title: "52W High", value: stock.formatted52WeekHigh)
            }
        }
        .padding(20)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border, lineWidth: 0.5)
        )
        .shadow(
            color: shadowColor,
            radius: shadowRadius,
            x: shadowX,
            y: shadowY
        )
    }
    
    private var shadowColor: Color {
        themeManager.isDarkMode ? AppTheme.dark.shadows.card.color : AppTheme.light.shadows.card.color
    }
    
    private var shadowRadius: CGFloat {
        themeManager.isDarkMode ? AppTheme.dark.shadows.card.radius : AppTheme.light.shadows.card.radius
    }
    
    private var shadowX: CGFloat {
        themeManager.isDarkMode ? AppTheme.dark.shadows.card.x : AppTheme.light.shadows.card.x
    }
    
    private var shadowY: CGFloat {
        themeManager.isDarkMode ? AppTheme.dark.shadows.card.y : AppTheme.light.shadows.card.y
    }
}

struct MetricItem: View {
    let title: String
    let value: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
        }
    }
}

struct SentimentOverviewCard: View {
    let sentiment: SentimentAnalysis
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                
                Text("Sentiment Analysis")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Spacer()
                
                Text(sentiment.overallRating.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color(sentiment.overallRating.color))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(sentiment.overallRating.color).opacity(0.1))
                    .cornerRadius(6)
            }
            
            // Sentiment Score
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Overall Score")
                        .font(.body)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    
                    Spacer()
                    
                    Text("\(Int(sentiment.score * 100))%")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                }
                
                SentimentScoreBar(score: sentiment.score, theme: themeManager.isDarkMode ? AppTheme.dark : AppTheme.light)
            }
            
            // Key Drivers
            if !sentiment.keyDrivers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Drivers")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    ForEach(sentiment.keyDrivers.prefix(3), id: \.self) { driver in
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 4))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                            
                            Text(driver)
                                .font(.body)
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border, lineWidth: 0.5)
        )
        .shadow(
            color: shadowColor,
            radius: shadowRadius,
            x: shadowX,
            y: shadowY
        )
    }
    
    private var shadowColor: Color {
        themeManager.isDarkMode ? AppTheme.dark.shadows.card.color : AppTheme.light.shadows.card.color
    }
    
    private var shadowRadius: CGFloat {
        themeManager.isDarkMode ? AppTheme.dark.shadows.card.radius : AppTheme.light.shadows.card.radius
    }
    
    private var shadowX: CGFloat {
        themeManager.isDarkMode ? AppTheme.dark.shadows.card.x : AppTheme.light.shadows.card.x
    }
    
    private var shadowY: CGFloat {
        themeManager.isDarkMode ? AppTheme.dark.shadows.card.y : AppTheme.light.shadows.card.y
    }
}

struct NewsOverviewSection: View {
    let newsItems: [NewsItem]
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "newspaper")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                
                Text("Latest News")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Spacer()
            }
            
            // News Items
            VStack(spacing: 12) {
                ForEach(newsItems.prefix(3), id: \.id) { news in
                    NewsOverviewItem(news: news)
                }
            }
        }
        .padding(20)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border, lineWidth: 0.5)
        )
        .shadow(
            color: shadowColor,
            radius: shadowRadius,
            x: shadowX,
            y: shadowY
        )
    }
    
    private var shadowColor: Color {
        themeManager.isDarkMode ? AppTheme.dark.shadows.card.color : AppTheme.light.shadows.card.color
    }
    
    private var shadowRadius: CGFloat {
        themeManager.isDarkMode ? AppTheme.dark.shadows.card.radius : AppTheme.light.shadows.card.radius
    }
    
    private var shadowX: CGFloat {
        themeManager.isDarkMode ? AppTheme.dark.shadows.card.x : AppTheme.light.shadows.card.x
    }
    
    private var shadowY: CGFloat {
        themeManager.isDarkMode ? AppTheme.dark.shadows.card.y : AppTheme.light.shadows.card.y
    }
}

struct NewsOverviewItem: View {
    let news: NewsItem
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(news.headline)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            HStack {
                Text(news.source)
                    .font(.caption)
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                
                Spacer()
                
                Text(news.timeAgo)
                    .font(.caption)
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
            }
        }
        .padding(12)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryBackground : AppTheme.light.colors.secondaryBackground)
        .cornerRadius(8)
    }
}

struct MarketContextCard: View {
    let marketContext: MarketContext
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                
                Text("Market Context")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Spacer()
            }
            
            // Content
            Text(marketContext.summary)
                .font(.body)
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
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

// MARK: - Error Notification Component
struct ErrorNotification: View {
    let message: String
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    @State private var offset: CGFloat = -100
    @State private var iconScale: CGFloat = 0.5
    
    var body: some View {
        HStack(spacing: 12) {
            // Error Icon with animation
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .scaleEffect(iconScale)
                .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.1), value: iconScale)
            
            // Error Message
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
            
            Spacer()
            
            // Dismiss Button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .scaleEffect(isVisible ? 1 : 0.8)
                    .animation(.easeInOut(duration: 0.2), value: isVisible)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.red.opacity(0.9), Color.red.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .offset(y: offset)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.8)
        .onAppear {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isVisible = true
                offset = 0
            }
            
            // Animate icon with slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    iconScale = 1.0
                }
            }
        }
    }
}

// MARK: - Error Message Parser
struct ErrorMessageParser {
    static func parseUserFriendlyMessage(_ errorMessage: String) -> String {
        // Try to parse JSON error response first
        if let data = errorMessage.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            // Check for specific error codes
            if let errorCode = json["error_code"] as? String {
                switch errorCode {
                case "user_already_exists":
                    return "An account with this email already exists. Please try signing in instead."
                case "invalid_email":
                    return "Please enter a valid email address."
                case "weak_password":
                    return "Password must be at least 6 characters long."
                case "invalid_credentials":
                    return "Invalid email or password. Please try again."
                case "email_not_confirmed":
                    return "Please check your email and confirm your account."
                default:
                    break
                }
            }
            
            // Check for error message
            if let msg = json["msg"] as? String {
                if msg.contains("already registered") || msg.contains("already exists") {
                    return "An account with this email already exists. Please try signing in instead."
                }
                if msg.contains("Invalid email") {
                    return "Please enter a valid email address."
                }
                if msg.contains("Password") && msg.contains("at least") {
                    return "Password must be at least 6 characters long."
                }
                return msg
            }
        }
        
        // Fallback to string matching for non-JSON errors
        if errorMessage.contains("user_already_exists") || errorMessage.contains("User already registered") || errorMessage.contains("already exists") {
            return "An account with this email already exists. Please try signing in instead."
        }
        
        if errorMessage.contains("Invalid email") || errorMessage.contains("invalid_email") {
            return "Please enter a valid email address."
        }
        
        if errorMessage.contains("Password should be at least") || errorMessage.contains("weak_password") {
            return "Password must be at least 6 characters long."
        }
        
        if errorMessage.contains("Invalid credentials") || errorMessage.contains("invalid_credentials") {
            return "Invalid email or password. Please try again."
        }
        
        if errorMessage.contains("Network error") || errorMessage.contains("network") {
            return "Network connection error. Please check your internet connection and try again."
        }
        
        if errorMessage.contains("Server error") || errorMessage.contains("500") {
            return "Server error. Please try again in a moment."
        }
        
        if errorMessage.contains("rate limit") || errorMessage.contains("too many requests") {
            return "Too many attempts. Please wait a moment before trying again."
        }
        
        // Default fallback
        return "Something went wrong. Please try again."
    }
}


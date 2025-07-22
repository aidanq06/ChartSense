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

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onCommit: () -> Void
    
    @Environment(\.theme) private var theme
    @State private var isEditing = false
    
    var body: some View {
        HStack(spacing: theme.spacing.sm) {
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(theme.colors.tertiaryText)
                    .font(.body)
                
                TextField(placeholder, text: $text, onCommit: onCommit)
                    .font(theme.typography.body)
                    .primaryText(theme: theme)
                    .onTapGesture {
                        isEditing = true
                    }
                
                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(theme.colors.tertiaryText)
                            .font(.body)
                    }
                }
            }
            .padding(theme.spacing.md)
            .background(theme.colors.secondaryBackground)
            .cornerRadius(theme.cornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                    .stroke(
                        isEditing ? theme.colors.primary : theme.colors.border,
                        lineWidth: isEditing ? 2 : 1
                    )
            )
            
            if isEditing {
                Button("Cancel") {
                    text = ""
                    isEditing = false
                    hideKeyboard()
                }
                .font(theme.typography.body)
                .foregroundColor(theme.colors.primary)
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isEditing)
    }
}

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

// MARK: - Extensions
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
} 
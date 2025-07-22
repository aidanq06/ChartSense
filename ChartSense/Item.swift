//
//  Models.swift
//  ChartSense
//
//  Created by Aidan Quach on 7/22/25.
//

import Foundation
import SwiftData

// MARK: - Stock Model
@Model
final class Stock {
    var symbol: String
    var companyName: String
    var currentPrice: Double
    var dailyChange: Double
    var dailyChangePercent: Double
    var marketCap: Double?
    var volume: Int64?
    var peRatio: Double?
    var lastUpdated: Date
    var isInWatchlist: Bool
    
    init(symbol: String, companyName: String, currentPrice: Double, dailyChange: Double, dailyChangePercent: Double, marketCap: Double? = nil, volume: Int64? = nil, peRatio: Double? = nil) {
        self.symbol = symbol.uppercased()
        self.companyName = companyName
        self.currentPrice = currentPrice
        self.dailyChange = dailyChange
        self.dailyChangePercent = dailyChangePercent
        self.marketCap = marketCap
        self.volume = volume
        self.peRatio = peRatio
        self.lastUpdated = Date()
        self.isInWatchlist = false
    }
    
    var formattedPrice: String {
        return String(format: "$%.2f", currentPrice)
    }
    
    var formattedChange: String {
        let sign = dailyChange >= 0 ? "+" : ""
        return String(format: "%@%.2f (%.2f%%)", sign, dailyChange, dailyChangePercent)
    }
    
    var isPositiveChange: Bool {
        return dailyChange >= 0
    }
}

// MARK: - Sentiment Model
struct SentimentAnalysis: Codable, Identifiable {
    let id = UUID()
    let symbol: String
    let overallRating: SentimentRating
    let score: Double // -1.0 to 1.0
    let keyDrivers: [String]
    let confidence: Double
    let lastUpdated: Date
    let breakdown: SentimentBreakdown
    
    enum SentimentRating: String, CaseIterable, Codable {
        case stronglyBullish = "Strongly Bullish"
        case bullish = "Bullish"
        case cautiouslyOptimistic = "Cautiously Optimistic"
        case neutral = "Neutral/Mixed"
        case bearishUndercurrents = "Bearish Undercurrents"
        case bearish = "Bearish"
        case highlyNegative = "Highly Negative"
        
        var color: String {
            switch self {
            case .stronglyBullish, .bullish: return "green"
            case .cautiouslyOptimistic: return "lightGreen"
            case .neutral: return "gray"
            case .bearishUndercurrents: return "orange"
            case .bearish, .highlyNegative: return "red"
            }
        }
        
        var icon: String {
            switch self {
            case .stronglyBullish: return "arrow.up.circle.fill"
            case .bullish: return "arrow.up.circle"
            case .cautiouslyOptimistic: return "arrow.up.right.circle"
            case .neutral: return "minus.circle"
            case .bearishUndercurrents: return "arrow.down.right.circle"
            case .bearish: return "arrow.down.circle"
            case .highlyNegative: return "arrow.down.circle.fill"
            }
        }
    }
}

struct SentimentBreakdown: Codable {
    let newsPositive: Double
    let newsNegative: Double
    let newsNeutral: Double
    let analystSentiment: Double
    let socialSentiment: Double
    let technicalIndicators: Double
}

// MARK: - News Model
struct NewsItem: Codable, Identifiable {
    let id = UUID()
    let headline: String
    let summary: String
    let source: String
    let publishedAt: Date
    let url: String
    let category: NewsCategory
    let sentiment: Double // -1.0 to 1.0
    let relevanceScore: Double
    let imageURL: String?
    
    enum NewsCategory: String, CaseIterable, Codable {
        case earnings = "Earnings & Financials"
        case product = "Product & Innovation"
        case analyst = "Analyst Revisions"
        case regulatory = "Regulatory & Legal"
        case macro = "Macro Impact"
        case competitor = "Competitor Landscape"
        case general = "General News"
        
        var icon: String {
            switch self {
            case .earnings: return "chart.line.uptrend.xyaxis"
            case .product: return "lightbulb.fill"
            case .analyst: return "person.2.fill"
            case .regulatory: return "scale.3d"
            case .macro: return "globe"
            case .competitor: return "building.2.fill"
            case .general: return "newspaper.fill"
            }
        }
        
        var color: String {
            switch self {
            case .earnings: return "blue"
            case .product: return "purple"
            case .analyst: return "orange"
            case .regulatory: return "red"
            case .macro: return "green"
            case .competitor: return "indigo"
            case .general: return "gray"
            }
        }
    }
    
    var sentimentColor: String {
        if sentiment > 0.1 { return "green" }
        else if sentiment < -0.1 { return "red" }
        else { return "gray" }
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: publishedAt, relativeTo: Date())
    }
}

// MARK: - Analyst Model
struct AnalystConsensus: Codable, Identifiable {
    let id = UUID()
    let symbol: String
    let buyRating: Double
    let holdRating: Double
    let sellRating: Double
    let averageTargetPrice: Double
    let numberOfAnalysts: Int
    let recentRevisions: [AnalystRevision]
    let lastUpdated: Date
    
    var strongBuyPercentage: Int {
        Int((buyRating * 100).rounded())
    }
    
    var holdPercentage: Int {
        Int((holdRating * 100).rounded())
    }
    
    var sellPercentage: Int {
        Int((sellRating * 100).rounded())
    }
}

struct AnalystRevision: Codable, Identifiable {
    let id = UUID()
    let firm: String
    let analyst: String?
    let previousRating: String
    let newRating: String
    let previousTarget: Double?
    let newTarget: Double
    let date: Date
    let reasoning: String
    
    var isUpgrade: Bool {
        // Simple logic - in real app would have proper rating comparison
        return newTarget > (previousTarget ?? 0)
    }
}

// MARK: - Market Context Model
struct MarketContext: Codable, Identifiable {
    let id = UUID()
    let symbol: String
    let sectorPerformance: SectorData
    let macroEnvironment: MacroData
    let upcomingEvents: [MarketEvent]
    let communityPulse: CommunityData
    let lastUpdated: Date
}

struct SectorData: Codable {
    let name: String
    let dailyChange: Double
    let weeklyChange: Double
    let topPerformers: [String]
    let bottomPerformers: [String]
    let keyThemes: [String]
}

struct MacroData: Codable {
    let marketTrend: String
    let interestRateEnvironment: String
    let inflationTrend: String
    let keyEconomicIndicators: [EconomicIndicator]
    let geopoliticalFactors: [String]
}

struct EconomicIndicator: Codable, Identifiable {
    let id = UUID()
    let name: String
    let currentValue: String
    let trend: String
    let impact: String
}

struct MarketEvent: Codable, Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    let type: EventType
    let description: String
    let importance: EventImportance
    
    enum EventType: String, CaseIterable, Codable {
        case earnings = "Earnings Call"
        case productLaunch = "Product Launch"
        case conference = "Conference"
        case regulatory = "Regulatory Announcement"
        case dividend = "Dividend"
        case split = "Stock Split"
        
        var icon: String {
            switch self {
            case .earnings: return "chart.bar.fill"
            case .productLaunch: return "sparkles"
            case .conference: return "person.3.fill"
            case .regulatory: return "doc.text.fill"
            case .dividend: return "dollarsign.circle.fill"
            case .split: return "arrow.triangle.branch"
            }
        }
    }
    
    enum EventImportance: String, CaseIterable, Codable {
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        
        var color: String {
            switch self {
            case .high: return "red"
            case .medium: return "orange"
            case .low: return "green"
            }
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var isUpcoming: Bool {
        date > Date()
    }
}

struct CommunityData: Codable {
    let trendingTopics: [String]
    let discussionVolume: Int
    let keyMentions: [String]
    let socialSentiment: Double
    let redditMentions: Int
    let twitterMentions: Int
}

// MARK: - Search History Model
@Model
final class SearchHistory {
    var symbol: String
    var companyName: String
    var searchDate: Date
    var searchCount: Int
    
    init(symbol: String, companyName: String) {
        self.symbol = symbol.uppercased()
        self.companyName = companyName
        self.searchDate = Date()
        self.searchCount = 1
    }
    
    func incrementSearchCount() {
        self.searchCount += 1
        self.searchDate = Date()
    }
}

// MARK: - Watchlist Model
@Model
final class WatchlistItem {
    var symbol: String
    var companyName: String
    var addedDate: Date
    var alertsEnabled: Bool
    var priceTarget: Double?
    var notes: String?
    
    init(symbol: String, companyName: String, alertsEnabled: Bool = false, priceTarget: Double? = nil, notes: String? = nil) {
        self.symbol = symbol.uppercased()
        self.companyName = companyName
        self.addedDate = Date()
        self.alertsEnabled = alertsEnabled
        self.priceTarget = priceTarget
        self.notes = notes
    }
}

// MARK: - AI Chat Models
struct ChatMessage: Identifiable, Codable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    let messageType: MessageType
    
    enum MessageType: String, Codable {
        case text = "text"
        case suggestion = "suggestion"
        case error = "error"
        case loading = "loading"
    }
    
    init(content: String, isUser: Bool, messageType: MessageType = .text) {
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
        self.messageType = messageType
    }
}

struct SuggestedMessage: Identifiable {
    let id = UUID()
    let text: String
    let category: SuggestionCategory
    
    enum SuggestionCategory: String, CaseIterable {
        case analysis = "Analysis"
        case education = "Education"
        case portfolio = "Portfolio"
        case news = "News"
        
        var icon: String {
            switch self {
            case .analysis: return "chart.line.uptrend.xyaxis"
            case .education: return "book.fill"
            case .portfolio: return "briefcase.fill"
            case .news: return "newspaper.fill"
            }
        }
    }
}

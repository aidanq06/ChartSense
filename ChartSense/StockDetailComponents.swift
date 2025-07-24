//
//  StockDetailComponents.swift
//  ChartSense
//
//  Created by Aidan Quach on 7/22/25.
//

import SwiftUI

struct AnalystConsensusDetailCard: View {
    let consensus: AnalystConsensus
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "person.2")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                
                Text("Analyst Consensus")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Spacer()
            }
            
            // Ratings
            HStack(spacing: 20) {
                ConsensusDetailItem(title: "Buy", percentage: Double(consensus.strongBuyPercentage), color: Color.bullish)
                ConsensusDetailItem(title: "Hold", percentage: Double(consensus.holdPercentage), color: .orange)
                ConsensusDetailItem(title: "Sell", percentage: Double(consensus.sellPercentage), color: .red)
            }
            
            // Price Target
            if consensus.averageTargetPrice > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Average Price Target")
                        .font(.caption)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    
                    Text("$\(String(format: "%.2f", consensus.averageTargetPrice))")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
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
            color: themeManager.isDarkMode ? AppTheme.dark.shadows.card.color : AppTheme.light.shadows.card.color,
            radius: themeManager.isDarkMode ? AppTheme.dark.shadows.card.radius : AppTheme.light.shadows.card.radius,
            x: themeManager.isDarkMode ? AppTheme.dark.shadows.card.x : AppTheme.light.shadows.card.x,
            y: themeManager.isDarkMode ? AppTheme.dark.shadows.card.y : AppTheme.light.shadows.card.y
        )
    }
}

struct ConsensusDetailItem: View {
    let title: String
    let percentage: Double
    let color: Color
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Int(percentage))%")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
} 
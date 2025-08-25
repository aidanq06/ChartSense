import SwiftUI

// MARK: - Alerts Sheet (Comprehensive, modern, premium UI)
struct AlertsSheet: View {
    let item: WatchlistItem
    let stock: Stock
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var premiumManager = PremiumManager.shared
    @StateObject private var watchlistVM = WatchlistViewModel.shared

    // Local form state
    @State private var priceAlertsEnabled = true
    @State private var targetAbove: String = ""
    @State private var targetBelow: String = ""
    @State private var sentimentAlertsEnabled = true
    @State private var sentimentThreshold: Double = 0.2
    @State private var newsAlertsEnabled = true
    @State private var includeEarnings = true
    @State private var includeDowngrades = true
    @State private var includeMAndA = true
    @State private var deliveryPush = true
    @State private var deliveryEmail = false
    @State private var deliveryInApp = true
    @State private var isSaving = false
    @State private var showSavedToast = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    priceSection
                    sentimentSection
                    newsSection
                    deliverySection
                    footerNote
                }
                .padding(20)
            }
            .background(backgroundDecor)
            .navigationBarHidden(true)
            .overlay(navBar, alignment: .top)
        }
        .safeAreaInset(edge: .bottom) { actionBar }
        .overlay(savedToast, alignment: .bottom)
        .onAppear {
            targetAbove = String(format: "%.2f", max(stock.currentPrice * 1.02, stock.currentPrice + 0.01))
            targetBelow = String(format: "%.2f", max(stock.currentPrice * 0.98, 0))
            priceAlertsEnabled = item.alertsEnabled
            // Restore local prefs
            let key = item.symbol
            sentimentAlertsEnabled = UserDefaults.standard.object(forKey: "alerts.sentiment.enabled.\(key)") as? Bool ?? true
            sentimentThreshold = UserDefaults.standard.object(forKey: "alerts.sentiment.threshold.\(key)") as? Double ?? 0.2
            newsAlertsEnabled = UserDefaults.standard.object(forKey: "alerts.news.enabled.\(key)") as? Bool ?? true
            includeEarnings = UserDefaults.standard.object(forKey: "alerts.news.earnings.\(key)") as? Bool ?? true
            includeDowngrades = UserDefaults.standard.object(forKey: "alerts.news.downgrades.\(key)") as? Bool ?? true
            includeMAndA = UserDefaults.standard.object(forKey: "alerts.news.mna.\(key)") as? Bool ?? true
            deliveryPush = UserDefaults.standard.object(forKey: "alerts.delivery.push.\(key)") as? Bool ?? true
            deliveryInApp = UserDefaults.standard.object(forKey: "alerts.delivery.inapp.\(key)") as? Bool ?? true
            deliveryEmail = UserDefaults.standard.object(forKey: "alerts.delivery.email.\(key)") as? Bool ?? false
        }
    }

    // MARK: - Sections
    private var navBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeTextSecondary)
                    .frame(width: 32, height: 32)
                    .background(themeCard)
                    .cornerRadius(8)
            }
            Spacer()
            Text("Alerts")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeTextPrimary)
            Spacer()
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(themeBackground)
    }

    // Removed hero header per design: no ticker name or current price in Alerts sheet

    private var priceSection: some View {
        SectionCard(title: "Price Alerts", subtitle: "Notify me when price crosses targets", icon: "dollarsign.circle") {
            ToggleRow(isOn: $priceAlertsEnabled)
            if priceAlertsEnabled {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                    GridRow {
                        LabeledField(label: "Above", text: $targetAbove, prefix: "$", step: 0.1)
                        LabeledField(label: "Below", text: $targetBelow, prefix: "$", step: 0.1)
                    }
                }
            }
        }
    }

    private var sentimentSection: some View {
        SectionCard(title: "Sentiment Alerts", subtitle: "Ping me when AI sentiment shifts", icon: "face.smiling") {
            ToggleRow(isOn: $sentimentAlertsEnabled)
            if sentimentAlertsEnabled {
                VStack(spacing: 10) {
                    HStack {
                        Text("Threshold")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(themeTextSecondary)
                        Spacer()
                        Text(String(format: "%.0f%%", sentimentThreshold * 100))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(themeTextPrimary)
                    }
                    Slider(value: $sentimentThreshold, in: 0...1)
                        .tint(themeAccent)
                }
            }
        }
    }

    private var newsSection: some View {
        SectionCard(title: "News Alerts", subtitle: "Only what matters, no noise", icon: "newspaper") {
            ToggleRow(isOn: $newsAlertsEnabled)
            if newsAlertsEnabled {
                VStack(spacing: 10) {
                    FilterPillRow(
                        items: [
                            ("Earnings", $includeEarnings),
                            ("Analyst downgrades", $includeDowngrades),
                            ("M&A / filings", $includeMAndA)
                        ]
                    )
                }
            }
        }
    }

    private var deliverySection: some View {
        SectionCard(title: "Delivery", subtitle: "Where to send alerts", icon: "paperplane") {
            VStack(spacing: 12) {
                DeliveryRow(title: "Push Notifications", isOn: $deliveryPush)
                DeliveryRow(title: "In‑app Banner", isOn: $deliveryInApp)
                DeliveryRow(title: "Email", isOn: $deliveryEmail)
            }
        }
    }

    private var footerNote: some View {
        Text("You can adjust these later from Watchlist → Alerts.")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(themeTextSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 6)
    }

    // MARK: - Bottom Action Bar
    private var actionBar: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Text("Cancel")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(themeTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(themeCard)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(themeBorder, lineWidth: 0.6))
            }
            Button(action: saveSettings) {
                HStack(spacing: 8) {
                    Image(systemName: isSaving ? "hourglass" : "checkmark")
                    Text(isSaving ? "Saving…" : "Save")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(12)
                .shadow(color: .blue.opacity(0.18), radius: 12, x: 0, y: 6)
            }
            .disabled(isSaving)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - Toast
    private var savedToast: some View {
        Group {
            if showSavedToast {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.white)
                    Text("Saved")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.8))
                .cornerRadius(12)
                .padding(.bottom, 80)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showSavedToast)
    }

    // MARK: - Save
    private func saveSettings() {
        guard !isSaving else { return }
        let symbol = item.symbol
        isSaving = true

        // Persist price alert to backend
        if priceAlertsEnabled {
            if let above = Double(targetAbove) {
                watchlistVM.setAlert(for: symbol, price: above, type: "above")
            } else if let below = Double(targetBelow) {
                watchlistVM.setAlert(for: symbol, price: below, type: "below")
            } else {
                // If enabled but no value, just enable alerts flag
                watchlistVM.updateWatchlistItem(symbol: symbol, alertsEnabled: true)
            }
        } else {
            watchlistVM.updateWatchlistItem(symbol: symbol, alertsEnabled: false)
        }

        // Save local-only preferences
        UserDefaults.standard.set(sentimentAlertsEnabled, forKey: "alerts.sentiment.enabled.\(symbol)")
        UserDefaults.standard.set(sentimentThreshold, forKey: "alerts.sentiment.threshold.\(symbol)")
        UserDefaults.standard.set(newsAlertsEnabled, forKey: "alerts.news.enabled.\(symbol)")
        UserDefaults.standard.set(includeEarnings, forKey: "alerts.news.earnings.\(symbol)")
        UserDefaults.standard.set(includeDowngrades, forKey: "alerts.news.downgrades.\(symbol)")
        UserDefaults.standard.set(includeMAndA, forKey: "alerts.news.mna.\(symbol)")
        UserDefaults.standard.set(deliveryPush, forKey: "alerts.delivery.push.\(symbol)")
        UserDefaults.standard.set(deliveryInApp, forKey: "alerts.delivery.inapp.\(symbol)")
        UserDefaults.standard.set(deliveryEmail, forKey: "alerts.delivery.email.\(symbol)")

        // UX feedback
        let h = UINotificationFeedbackGenerator()
        h.notificationOccurred(.success)
        showSavedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { showSavedToast = false }
            isSaving = false
            dismiss()
        }
    }

    // MARK: - Background

    private var backgroundDecor: some View {
        ZStack {
            themeBackground
            RadialGradient(colors: [themeAccent.opacity(0.10), .clear], center: .topTrailing, startRadius: 10, endRadius: 400)
            RadialGradient(colors: [.purple.opacity(0.10), .clear], center: .bottomLeading, startRadius: 10, endRadius: 420)
        }
    }

    // MARK: - Subviews
    private var themeBackground: Color { themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background }
    private var themeCard: Color { themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground }
    private var themeBorder: Color { themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border }
    private var themeTextPrimary: Color { themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText }
    private var themeTextSecondary: Color { themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText }
    private var themeAccent: Color { themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary }
}

// MARK: - SectionCard
private struct SectionCard<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let content: Content
    @StateObject private var themeManager = ThemeManager.shared
    init(title: String, subtitle: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title; self.subtitle = subtitle; self.icon = icon; self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeAccent)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.system(size: 16, weight: .semibold)).foregroundColor(themeTextPrimary)
                    Text(subtitle).font(.system(size: 13, weight: .medium)).foregroundColor(themeTextSecondary)
                }
                Spacer()
            }
            content
        }
        .padding(16)
        .background(themeCard)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(themeBorder, lineWidth: 0.5))
    }
    private var themeCard: Color { themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground }
    private var themeBorder: Color { themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border }
    private var themeTextPrimary: Color { themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText }
    private var themeTextSecondary: Color { themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText }
    private var themeAccent: Color { themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary }
}

private struct ToggleRow: View {
    @Binding var isOn: Bool
    var body: some View {
        HStack {
            Text(isOn ? "Enabled" : "Disabled")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden()
        }
    }
}

private struct LabeledField: View {
    let label: String
    @Binding var text: String
    var prefix: String? = nil
    var step: Double? = nil
    @StateObject private var themeManager = ThemeManager.shared
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 12, weight: .medium)).foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            HStack(spacing: 8) {
                if let prefix = prefix { Text(prefix).font(.system(size: 14, weight: .semibold)).foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText) }
                TextField("0.00", text: $text)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 14, weight: .semibold))
                if let step = step {
                    Stepper("") {
                        let value = (Double(text) ?? 0) + step
                        text = String(format: "%.2f", value)
                    } onDecrement: {
                        let value = (Double(text) ?? 0) - step
                        text = String(format: "%.2f", max(0, value))
                    }
                    .labelsHidden()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryBackground : AppTheme.light.colors.secondaryBackground)
            .cornerRadius(10)
        }
    }
}

private struct FilterPillRow: View {
    let items: [(String, Binding<Bool>)]
    @StateObject private var themeManager = ThemeManager.shared
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, pair in
                let (label, binding) = pair
                Button(action: { binding.wrappedValue.toggle() }) {
                    Text(label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(binding.wrappedValue ? .white : themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(binding.wrappedValue ? (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary) : (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary).opacity(0.12))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// Tabs removed per design simplification

private struct DeliveryRow: View {
    let title: String
    @Binding var isOn: Bool
    @StateObject private var themeManager = ThemeManager.shared
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden()
        }
    }
}

//
//  ModernWatchlistView.swift
//  ChartSense
//
//  Created by Aidan Quach on 7/22/25.
//

import SwiftUI

// MARK: - Modern Watchlist View
struct ModernWatchlistView: View {
    @StateObject private var viewModel = WatchlistViewModel.shared
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingAddStock = false
    @State private var searchText = ""
    @State private var presentingAlerts: AlertsPair? = nil
    

    

    
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
                            if let pair = viewModel.watchlistItemsWithStock.first(where: { $0.watchlistItem.symbol == symbol }),
                               let stock = pair.stock {
                                presentingAlerts = AlertsPair(item: pair.watchlistItem, stock: stock)
                            }
                        }
                    )
                }
            }
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddStock) {
            ModernAddStockSheet { stock in
                print("🎯 WATCHLIST SHEET: Adding \(stock.symbol) to watchlist...")
                viewModel.addToWatchlist(stock)
                print("✅ WATCHLIST SHEET: addToWatchlist call completed")
            }
        }
        .sheet(item: $presentingAlerts, content: { pair in
            AlertsSheet(item: pair.item, stock: pair.stock)
        })
    }
}

// Helper Identifiable pair for sheet
fileprivate struct AlertsPair: Identifiable {
    let id = UUID()
    let item: WatchlistItem
    let stock: Stock
}

// MARK: - Alerts Sheet Launcher
enum AlertsSheetLauncher {
    static func present(item: WatchlistItem, stock: Stock) {
        NotificationCenter.default.post(
            name: Notification.Name("PresentAlertsSheet"),
            object: nil,
            userInfo: ["item": item.symbol]
        )
    }
}

// MARK: - Premium Upsell Banner
struct PremiumUpsellBanner: View {
    @StateObject private var themeManager = ThemeManager.shared
    let onUpgrade: () -> Void
    
    var body: some View {
        ZStack {
            // Background glass card
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            (themeManager.isDarkMode ? Color.white.opacity(0.06) : Color.white.opacity(0.9)),
                            (themeManager.isDarkMode ? Color.white.opacity(0.03) : Color.white.opacity(0.8))
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border, lineWidth: 0.6)
                )
                .shadow(color: .black.opacity(themeManager.isDarkMode ? 0.35 : 0.08), radius: 14, x: 0, y: 10)
            
            HStack(alignment: .center, spacing: 14) {
                // Icon badge
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 28, height: 28)
                        .shadow(color: .blue.opacity(0.2), radius: 6, x: 0, y: 3)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Text stack
                VStack(alignment: .leading, spacing: 6) {
                    Text("Premium")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    Text("Add unlimited stocks to your watchlist.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                        .lineLimit(2)
                        .minimumScaleFactor(0.98)
                }
                
                Spacer()
                
                // CTA button
                Button(action: onUpgrade) {
                    Text("Upgrade")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                        )
                        .shadow(color: .blue.opacity(0.18), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .frame(height: 82)
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
            ModernDiscoverSearchBar(
                text: $searchText,
                onSearch: { query in
                    // Handle search in watchlist context
                    searchText = query
                }
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }
}

// MARK: - Legacy Modern Search Bar (Deprecated - Use ModernDiscoverSearchBar instead)
// This component has been replaced by the enhanced ModernDiscoverSearchBar in Views.swift
// to eliminate overlapping search implementations and provide a unified, visually comprehensive experience.

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
            LazyVStack(spacing: 16) {
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

// MARK: - Modern Watchlist Card (Updated with Home Screen Design)
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
    @State private var showDeleteConfirm = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content using the modern home screen design with integrated actions
            if let stock = stock {
                VStack(spacing: 0) {
                    // Stock information with integrated action buttons
                    HStack(spacing: 0) {
                        // Left: Stock info (clickable for selection)
                        Button(action: { onSelect(stock) }) {
                            WatchlistTickerItemView(
                                stock: stock,
                                sentiment: sentiment,
                                onTap: { onSelect(stock) }
                            )
                            .padding(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Right: Integrated action buttons
                        VStack(spacing: 8) {
                            // Alerts button
                            Button(action: onToggleAlerts) {
                                Image(systemName: "bell")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(themeManager.isDarkMode ? AppTheme.dark.colors.primary.opacity(0.15) : AppTheme.light.colors.primary.opacity(0.15))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Remove button
                            Button(action: onRemove) {
                                Image(systemName: "trash")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color.red)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(Color.red.opacity(0.15))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.trailing, 12)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border, lineWidth: 0.5)
                        )
                )
                .cornerRadius(16)
                .shadow(
                    color: themeManager.isDarkMode ? AppTheme.dark.shadows.card.color : AppTheme.light.shadows.card.color,
                    radius: themeManager.isDarkMode ? AppTheme.dark.shadows.card.radius : AppTheme.light.shadows.card.radius,
                    x: themeManager.isDarkMode ? AppTheme.dark.shadows.card.x : AppTheme.light.shadows.card.x,
                    y: themeManager.isDarkMode ? AppTheme.dark.shadows.card.y : AppTheme.light.shadows.card.y
                )
            } else {
                // Fallback for when stock data is not available
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.symbol)
                                    .font(.system(size: 18, weight: .bold, design: .default))
                                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                                
                                Text(item.companyName)
                                    .font(.system(size: 14, weight: .medium, design: .default))
                                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Text("N/A")
                                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    
                    // Integrated action buttons for fallback
                    VStack(spacing: 8) {
                        Button(action: onToggleAlerts) {
                            Image(systemName: "bell")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(themeManager.isDarkMode ? AppTheme.dark.colors.primary.opacity(0.15) : AppTheme.light.colors.primary.opacity(0.15))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: onRemove) {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.red)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(Color.red.opacity(0.15))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.trailing, 12)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border, lineWidth: 0.5)
                        )
                )
                .cornerRadius(16)
            }
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.12), value: isPressed)
        .onTapGesture {
            if let stock = stock { onSelect(stock) }
        }
    }
}


// MARK: - Modern Add Stock Sheet
struct ModernAddStockSheet: View {
    let onAdd: (Stock) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var searchViewModel = SearchViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var watchlistViewModel = WatchlistViewModel.shared
    @StateObject private var premiumManager = PremiumManager.shared
    @State private var showLimitAlert = false
    
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
                ModernDiscoverSearchBar(
                    text: $searchViewModel.searchText,
                    onSearch: { query in
                        searchViewModel.searchText = query
                    }
                )
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Watchlist Limit Indicator (Premium Upsell)
                if !premiumManager.isPremium {
                    PremiumUpsellBanner {
                        premiumManager.showingPremiumUpgrade = true
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                
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
                                    },
                                    onLimitReached: { showLimitAlert = true }
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
        .sheet(isPresented: $premiumManager.showingPremiumUpgrade) {
            PremiumUpgradeView()
        }
        .alert("Upgrade to add more stocks", isPresented: $showLimitAlert) {
            Button("Not now", role: .cancel) {}
            Button("Upgrade") { premiumManager.showingPremiumUpgrade = true }
        } message: {
            Text("Free users can track 1 stock. Upgrade to Premium for unlimited watchlist.")
        }
    }
}

// MARK: - Modern Add Stock Row
struct ModernAddStockRow: View {
    let stock: Stock
    let onAdd: (Stock) -> Void
    var onLimitReached: (() -> Void)? = nil
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var watchlistViewModel = WatchlistViewModel.shared
    @StateObject private var premiumManager = PremiumManager.shared
    @State private var isPressed = false
    
    // Computed properties for button state
    private var isStockInWatchlist: Bool {
        watchlistViewModel.isStockInWatchlist(stock.symbol)
    }
    
    private var isLimitReached: Bool {
        !premiumManager.isPremium && watchlistViewModel.watchlistItems.count >= 1
    }
    
    private var buttonColor: Color {
        if isStockInWatchlist {
            return Color.gray
        } else if isLimitReached {
            return Color.orange
        } else {
            return Color.blue
        }
    }
    
    private var buttonIcon: String {
        if isStockInWatchlist {
            return "checkmark"
        } else if isLimitReached {
            return "crown"
        } else {
            return "plus"
        }
    }
    
    private var isButtonDisabled: Bool {
        isStockInWatchlist || isLimitReached
    }
    
    var body: some View {
        Button(action: {
            print("🎯 WATCHLIST ADD BUTTON TAPPED for \(stock.symbol)!")
            
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            if isLimitReached {
                onLimitReached?()
                return
            }
            if isStockInWatchlist { return }
            
            print("🔄 Calling onAdd callback...")
            onAdd(stock)
            print("✅ onAdd callback completed")
        }) {
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
                Button(action: {
                    print("🎯 ADD BUTTON TAPPED for \(stock.symbol)!")
                    
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    if isLimitReached {
                        onLimitReached?()
                    } else if !isStockInWatchlist {
                        onAdd(stock)
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(buttonColor)
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: buttonIcon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isButtonDisabled)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.isDarkMode ?
                        Color(hex: "1A1A1A") :
                        Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

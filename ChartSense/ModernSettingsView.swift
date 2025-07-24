import SwiftUI
import Combine

// MARK: - Modern Settings View
struct ModernSettingsView: View {
    @StateObject private var viewModel = ModernSettingsViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var premiumManager = PremiumManager.shared
    @ObservedObject private var authViewModel = AuthViewModel.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Modern Header
                    ModernSettingsHeader()
                    
                    // Quick Actions
                    QuickActionsSection()
                    
                    // Main Settings
                    SettingsSections()
                    
                                // Account & Support
            AccountSupportSection()
            
            // TEMPORARY: Premium Reset Button (Remove this section later)
            TemporaryPremiumResetSection()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showingProfileEditor) {
                ProfileEditorView()
            }
            .sheet(isPresented: $viewModel.showingDataExport) {
                DataExportView()
            }
            .sheet(isPresented: $premiumManager.showingPremiumUpgrade) {
                PremiumUpgradeView()
            }
            .alert("Sign Out", isPresented: $viewModel.showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out? You'll need to sign in again to access your data.")
            }
        }
    }
}

// MARK: - Modern Settings Header
struct ModernSettingsHeader: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var premiumManager = PremiumManager.shared
    @ObservedObject private var authViewModel = AuthViewModel.shared
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile Section
            HStack(spacing: 16) {
                // Profile Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                    
                    if let user = authViewModel.currentUser {
                        Text(String(user.name.prefix(1)).uppercased())
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(authViewModel.currentUser?.name ?? "Guest User")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Text(authViewModel.currentUser?.email ?? "Not signed in")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(premiumManager.isPremium ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        
                        Text(premiumManager.isPremium ? "Premium Member" : "Free User")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(premiumManager.isPremium ? .green : .orange)
                    }
                    
                    // Premium Upgrade Button (for free users)
                    if !premiumManager.isPremium {
                        Button(action: {
                            premiumManager.showPremiumUpgrade()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 14, weight: .medium))
                                
                                Text("Upgrade to Premium")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                            .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 8)
                    }
                }
                
                Spacer()
                
                // Settings Icon
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
            }
            .padding(20)
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            
            // Stats Cards
            HStack(spacing: 12) {
                StatCard(
                    title: "Watchlist",
                    value: "12",
                    icon: "list.bullet",
                    color: .blue
                )
                
                StatCard(
                    title: "Alerts",
                    value: "5",
                    icon: "bell.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Searches",
                    value: "47",
                    icon: "magnifyingglass",
                    color: .green
                )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionCard(
                    title: "Edit Profile",
                    icon: "person.circle.fill",
                    color: .blue
                ) {
                    // Action
                }
                
                QuickActionCard(
                    title: "Export Data",
                    icon: "square.and.arrow.up.fill",
                    color: .green
                ) {
                    // Action
                }
                
                QuickActionCard(
                    title: "Clear Cache",
                    icon: "trash.fill",
                    color: .red
                ) {
                    // Action
                }
                
                QuickActionCard(
                    title: "Rate App",
                    icon: "star.fill",
                    color: .yellow
                ) {
                    // Action
                }
            }
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            action()
        }) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Settings Sections
struct SettingsSections: View {
    @StateObject private var viewModel = ModernSettingsViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Appearance Section
            ModernSettingsSection(title: "Appearance", icon: "paintbrush.fill") {
                VStack(spacing: 12) {
                    ModernToggleCard(
                        title: "Dark Mode",
                        subtitle: "Switch between light and dark themes",
                        icon: "moon.fill",
                        isOn: $viewModel.isDarkMode
                    )
                    

                    
                    ModernPickerCard(
                        title: "Chart Style",
                        subtitle: "Choose your preferred chart appearance",
                        icon: "chart.line.uptrend.xyaxis",
                        selection: $viewModel.chartStyle,
                        options: [
                            ("Candlestick", "Traditional candlestick charts"),
                            ("Line", "Simple line charts"),
                            ("Area", "Filled area charts"),
                            ("Bar", "Bar chart style")
                        ]
                    )
                }
            }
            
            // Notifications Section
            ModernSettingsSection(title: "Notifications", icon: "bell.fill") {
                VStack(spacing: 12) {
                    ModernToggleCard(
                        title: "Push Notifications",
                        subtitle: "Receive alerts for important updates",
                        icon: "bell.fill",
                        isOn: $viewModel.notificationsEnabled
                    )
                    
                    if viewModel.notificationsEnabled {
                        ModernToggleCard(
                            title: "Price Alerts",
                            subtitle: "Get notified when stocks hit your targets",
                            icon: "dollarsign.circle.fill",
                            isOn: $viewModel.priceAlertsEnabled
                        )
                        
                        ModernToggleCard(
                            title: "News Alerts",
                            subtitle: "Breaking news for your watchlist stocks",
                            icon: "newspaper.fill",
                            isOn: $viewModel.newsAlertsEnabled
                        )
                        
                        ModernToggleCard(
                            title: "Market Open Alerts",
                            subtitle: "Daily market opening notifications",
                            icon: "clock.fill",
                            isOn: $viewModel.marketOpenAlerts
                        )
                        
                        ModernToggleCard(
                            title: "AI Insights",
                            subtitle: "Get AI-powered market insights",
                            icon: "brain.head.profile",
                            isOn: $viewModel.aiInsightsEnabled
                        )
                    }
                }
            }
            
            // Data & Performance Section
            ModernSettingsSection(title: "Data & Performance", icon: "speedometer") {
                VStack(spacing: 12) {
                    ModernPickerCard(
                        title: "Refresh Interval",
                        subtitle: "How often to update stock data",
                        icon: "arrow.clockwise",
                        selection: $viewModel.refreshInterval,
                        options: [
                            ("1 minute", "Real-time updates"),
                            ("5 minutes", "Frequent updates"),
                            ("15 minutes", "Standard updates"),
                            ("30 minutes", "Battery optimized")
                        ]
                    )
                    
                    ModernToggleCard(
                        title: "Auto-Refresh",
                        subtitle: "Automatically update data in background",
                        icon: "wifi",
                        isOn: $viewModel.autoRefreshEnabled
                    )
                    
                    ModernToggleCard(
                        title: "High-Quality Charts",
                        subtitle: "Use detailed charts (uses more data)",
                        icon: "chart.line.uptrend.xyaxis",
                        isOn: $viewModel.highQualityCharts
                    )
                    
                    ModernToggleCard(
                        title: "Offline Mode",
                        subtitle: "Cache data for offline viewing",
                        icon: "icloud.fill",
                        isOn: $viewModel.offlineModeEnabled
                    )
                }
            }
            
            // AI & Analysis Section
            ModernSettingsSection(title: "AI & Analysis", icon: "brain.head.profile") {
                VStack(spacing: 12) {
                    ModernToggleCard(
                        title: "AI-Powered Insights",
                        subtitle: "Use advanced AI for sentiment analysis",
                        icon: "brain.head.profile",
                        isOn: $viewModel.aiInsightsEnabled
                    )
                    
                    ModernPickerCard(
                        title: "News Sources",
                        subtitle: "Select preferred news sources",
                        icon: "newspaper",
                        selection: $viewModel.newsSources,
                        options: [
                            ("All Sources", "Include all available sources"),
                            ("Major Outlets", "Bloomberg, Reuters, CNBC"),
                            ("Financial Focus", "Financial Times, WSJ, Barron's"),
                            ("Tech Focus", "TechCrunch, The Verge, Ars Technica")
                        ]
                    )
                    
                    ModernToggleCard(
                        title: "Show Sentiment Confidence",
                        subtitle: "Display confidence scores for analysis",
                        icon: "chart.bar.fill",
                        isOn: $viewModel.showConfidenceScores
                    )
                    
                    ModernToggleCard(
                        title: "Auto-Analyze Watchlist",
                        subtitle: "Automatically analyze your watchlist stocks",
                        icon: "chart.pie.fill",
                        isOn: $viewModel.autoAnalyzeWatchlist
                    )
                }
            }
        }
    }
}

// MARK: - Modern Settings Section
struct ModernSettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    @StateObject private var themeManager = ThemeManager.shared
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            }
            
            VStack(spacing: 8) {
                content
            }
        }
    }
}

// MARK: - Modern Toggle Card
struct ModernToggleCard: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary))
        }
        .padding(16)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }
    }
}

// MARK: - Modern Picker Card
struct ModernPickerCard: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var selection: String
    let options: [(String, String)]
    
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isPressed = false
    @State private var showingPicker = false
    
    var body: some View {
        Button(action: {
            showingPicker = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                }
                
                Spacer()
                
                Text(selection)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            }
            .padding(16)
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .sheet(isPresented: $showingPicker) {
            ModernPickerSheet(
                title: title,
                selection: $selection,
                options: options
            )
        }
    }
}

// MARK: - Modern Picker Sheet
struct ModernPickerSheet: View {
    let title: String
    @Binding var selection: String
    let options: [(String, String)]
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                    
                    Spacer()
                    
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Spacer()
                    
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                }
                .padding()
                .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
                
                // Options
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(options, id: \.0) { option in
                            Button(action: {
                                selection = option.0
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(option.0)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                                        
                                        Text(option.1)
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                                    }
                                    
                                    Spacer()
                                    
                                    if selection == option.0 {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                                    }
                                }
                                .padding()
                                .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .padding(.leading)
                        }
                    }
                }
            }
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
        }
    }
}

// MARK: - Account & Support Section
struct AccountSupportSection: View {
    @StateObject private var viewModel = ModernSettingsViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    @ObservedObject private var authViewModel = AuthViewModel.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Account Section
            ModernSettingsSection(title: "Account", icon: "person.circle.fill") {
                VStack(spacing: 12) {
                    ModernActionCard(
                        title: "Edit Profile",
                        subtitle: "Update your personal information",
                        icon: "person.circle.fill",
                        color: .blue
                    ) {
                        viewModel.showingProfileEditor = true
                    }
                    
                    ModernActionCard(
                        title: "Export Data",
                        subtitle: "Download your data and settings",
                        icon: "square.and.arrow.up.fill",
                        color: .green
                    ) {
                        viewModel.showingDataExport = true
                    }
                    
                    ModernActionCard(
                        title: "Sign Out",
                        subtitle: "Sign out of your account",
                        icon: "rectangle.portrait.and.arrow.right",
                        color: .red,
                        destructive: true
                    ) {
                        viewModel.showingSignOutAlert = true
                    }
                }
            }
            
            // Support Section
            ModernSettingsSection(title: "Support", icon: "questionmark.circle.fill") {
                VStack(spacing: 12) {
                    ModernActionCard(
                        title: "Help Center",
                        subtitle: "Get help and find answers",
                        icon: "questionmark.circle.fill",
                        color: .blue
                    ) {
                        // Action
                    }
                    
                    ModernActionCard(
                        title: "Contact Support",
                        subtitle: "Reach out to our team",
                        icon: "envelope.fill",
                        color: .green
                    ) {
                        // Action
                    }
                    
                    ModernActionCard(
                        title: "Rate ChartSense",
                        subtitle: "Share your feedback",
                        icon: "star.fill",
                        color: .yellow
                    ) {
                        // Action
                    }
                }
            }
            
            // About Section
            ModernSettingsSection(title: "About", icon: "info.circle.fill") {
                VStack(spacing: 12) {
                    ModernActionCard(
                        title: "About ChartSense",
                        subtitle: "Version 1.0.0 • Build 1",
                        icon: "info.circle.fill",
                        color: .blue
                    ) {
                        // Action
                    }
                    
                    ModernActionCard(
                        title: "Privacy Policy",
                        subtitle: "How we protect your data",
                        icon: "hand.raised.fill",
                        color: .green
                    ) {
                        // Action
                    }
                    
                    ModernActionCard(
                        title: "Terms of Service",
                        subtitle: "Usage terms and conditions",
                        icon: "doc.text.fill",
                        color: .orange
                    ) {
                        // Action
                    }
                }
            }
        }
    }
}

// MARK: - Modern Action Card
struct ModernActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    let destructive: Bool
    
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isPressed = false
    
    init(title: String, subtitle: String, icon: String, color: Color, destructive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.destructive = destructive
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(destructive ? .red : color)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(destructive ? .red : (themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText))
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            }
            .padding(16)
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
} 

// MARK: - TEMPORARY: Premium Reset Section (Remove this entire section later)
struct TemporaryPremiumResetSection: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var premiumManager = PremiumManager.shared
    @State private var showingResetAlert = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.orange)
                
                Text("Developer Tools")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Spacer()
            }
            
            // Reset Premium Button
            Button(action: {
                showingResetAlert = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset Premium Status")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red)
                        
                        Text("Remove premium access (temporary)")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                }
                .padding(16)
                .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .alert("Reset Premium Status", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetPremiumStatus()
                }
            } message: {
                Text("This will remove your premium access and reset you to free user status. This action cannot be undone.")
            }
        }
        .padding(.vertical, 8)
    }
    
    private func resetPremiumStatus() {
        // Reset premium status
        premiumManager.isPremium = false
        premiumManager.subscriptionStatus = .free
        premiumManager.aiMessagesRemaining = 5
        premiumManager.aiMessagesUsedToday = 0
        premiumManager.lastMessageResetDate = Date()
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "isPremium")
        UserDefaults.standard.removeObject(forKey: "subscriptionStatus")
        UserDefaults.standard.removeObject(forKey: "aiMessagesRemaining")
        UserDefaults.standard.removeObject(forKey: "aiMessagesUsedToday")
        UserDefaults.standard.removeObject(forKey: "lastMessageResetDate")
        
        print("🔄 Premium status reset to free user")
    }
} 
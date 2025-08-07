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
                    
                    // Essential Settings
                    EssentialSettingsSection()
                    
                    // Account & Support
                    AccountSupportSection()
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
        VStack(spacing: 24) {
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
                        .frame(width: 70, height: 70)
                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                    
                    if let user = authViewModel.currentUser {
                        Text(String(user.name.prefix(1)).uppercased())
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(authViewModel.currentUser?.name ?? "Guest User")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Text(authViewModel.currentUser?.email ?? "Not signed in")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(premiumManager.isPremium ? Color.green : Color.orange)
                            .frame(width: 10, height: 10)
                        
                        Text(premiumManager.isPremium ? "Premium Member" : "Free User")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(premiumManager.isPremium ? .green : .orange)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Settings Icon
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
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
            
            // Premium Upgrade Button (for free users)
            if !premiumManager.isPremium {
                Button(action: {
                    premiumManager.showPremiumUpgrade()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 18, weight: .semibold))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade to Premium")
                                .font(.system(size: 16, weight: .bold))
                            
                            Text("Unlock unlimited watchlist & advanced features")
                                .font(.system(size: 14, weight: .medium))
                                .opacity(0.9)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(20)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Essential Settings Section
struct EssentialSettingsSection: View {
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
                            title: "Market Open Alerts",
                            subtitle: "Daily market opening notifications",
                            icon: "clock.fill",
                            isOn: $viewModel.marketOpenAlerts
                        )
                    }
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
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                
                Text(title)
                    .font(.system(size: 20, weight: .bold))
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
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(
            color: themeManager.isDarkMode ? Color.black.opacity(0.1) : Color.black.opacity(0.03),
            radius: 8,
            x: 0,
            y: 2
        )
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

// MARK: - Account Support Section
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
                        color: .red
                    ) {
                        viewModel.showingSignOutAlert = true
                    }
                }
            }
            
            // Support Section
            ModernSettingsSection(title: "Support", icon: "questionmark.circle.fill") {
                VStack(spacing: 12) {
                    ModernActionCard(
                        title: "Help & FAQ",
                        subtitle: "Get help and find answers",
                        icon: "questionmark.circle.fill",
                        color: .purple
                    ) {
                        // Action
                    }
                    
                    ModernActionCard(
                        title: "Contact Support",
                        subtitle: "Get in touch with our team",
                        icon: "envelope.fill",
                        color: .orange
                    ) {
                        // Action
                    }
                    
                    ModernActionCard(
                        title: "Rate App",
                        subtitle: "Share your feedback",
                        icon: "star.fill",
                        color: .yellow
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
    
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(
                color: themeManager.isDarkMode ? Color.black.opacity(0.1) : Color.black.opacity(0.03),
                radius: 8,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

 

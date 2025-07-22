//
//  ContentView.swift
//  ChartSense
//
//  Created by Aidan Quach on 7/22/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    @ObservedObject private var authViewModel = AuthViewModel.shared

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                // Main App
                ZStack {
                    // Background color that respects theme
                    (themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Main Content Area
                        ZStack {
                            switch appViewModel.selectedTab {
                            case 0:
                                HomeView()
                                    .environmentObject(appViewModel)
                                    .environment(\.theme, themeManager.isDarkMode ? AppTheme.dark : AppTheme.light)
                            case 1:
                                DiscoverView()
                                    .environmentObject(appViewModel)
                                    .environment(\.theme, themeManager.isDarkMode ? AppTheme.dark : AppTheme.light)
                            case 2:
                                AIView()
                                    .environmentObject(appViewModel)
                                    .environment(\.theme, themeManager.isDarkMode ? AppTheme.dark : AppTheme.light)
                            case 3:
                                WatchlistView()
                                    .environmentObject(appViewModel)
                                    .environment(\.theme, themeManager.isDarkMode ? AppTheme.dark : AppTheme.light)
                            case 4:
                                SettingsView()
                                    .environment(\.theme, themeManager.isDarkMode ? AppTheme.dark : AppTheme.light)
                            default:
                                HomeView()
                                    .environmentObject(appViewModel)
                                    .environment(\.theme, themeManager.isDarkMode ? AppTheme.dark : AppTheme.light)
                            }
                        }
                
                        // Custom Bottom Tab Bar
                        CustomTabBar(
                            selectedTab: $appViewModel.selectedTab,
                            themeManager: themeManager
                        )
                    }
                }
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                .onReceive(themeManager.$isDarkMode) { _ in
                    // Force UI update when theme changes
                }
            } else {
                // Login Screen
                AuthView()
            }
        }
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @ObservedObject var themeManager: ThemeManager
    
    private let tabs = [
        TabItem(icon: "house.fill", index: 0),
        TabItem(icon: "magnifyingglass", index: 1),
        TabItem(icon: "brain.head.profile", index: 2),
        TabItem(icon: "heart.fill", index: 3),
        TabItem(icon: "gearshape.fill", index: 4)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Subtle top border
            Rectangle()
                .fill(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border)
                .frame(height: 0.3)
            
            // Tab bar content
            HStack(spacing: 0) {
                ForEach(tabs, id: \.index) { tab in
                    CustomTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab.index,
                        themeManager: themeManager
                    ) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedTab = tab.index
                        }
                    }
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
        }
    }
}

struct TabItem {
    let icon: String
    let index: Int
}

struct CustomTabButton: View {
    let tab: TabItem
    let isSelected: Bool
    @ObservedObject var themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            // Icon only - no text, no VStack
            Image(systemName: tab.icon)
                .font(.system(size: isSelected ? 22 : 20, weight: isSelected ? .semibold : .medium))
                .foregroundColor(
                    isSelected 
                        ? (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                        : (themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Main App Container with Enhanced Features
struct MainAppView: View {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    @ObservedObject private var authViewModel = AuthViewModel.shared
    @State private var showingSplashScreen = true
    
    var body: some View {
        ZStack {
            if showingSplashScreen {
                SplashScreenView()
                    .transition(.opacity)
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.8), value: showingSplashScreen)
        .onAppear {
            // Show splash screen for 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showingSplashScreen = false
            }
        }
        .preferredColorScheme(authViewModel.isAuthenticated ? (themeManager.isDarkMode ? .dark : .light) : .light)
    }
}

struct SplashScreenView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @ObservedObject private var authViewModel = AuthViewModel.shared
    @State private var animateText = false
    
    var body: some View {
        ZStack {
            // Background - Always light for splash screen
            AppTheme.light.colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // App Icon/Logo - Clean and Simple (always light mode style)
                Image("AppIconImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // App Title
                VStack(spacing: 12) {
                    Text("ChartSense")
                        .font(.system(size: 36, weight: .bold, design: .default))
                        .foregroundColor(AppTheme.light.colors.primaryText)
                        .opacity(animateText ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 1.0).delay(0.3), value: animateText)
                    
                    Text("AI-Powered Stock Sentiment Analysis")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(AppTheme.light.colors.secondaryText)
                        .opacity(animateText ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 1.0).delay(0.6), value: animateText)
                }
            }
        }
        .preferredColorScheme(.light) // Force light mode for splash screen
        .onAppear {
            animateText = true
        }
    }
}

// MARK: - Enhanced UI Components
extension View {
    func gradientBackground(isDarkMode: Bool) -> some View {
        self.background(
            LinearGradient(
                gradient: Gradient(colors: [
                    isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background,
                    isDarkMode ? AppTheme.dark.colors.secondaryBackground : AppTheme.light.colors.secondaryBackground
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
    
    func cardStyle(theme: AppTheme) -> some View {
        self
            .padding(16)
            .background(theme.colors.cardBackground)
            .cornerRadius(12)
            .shadow(
                color: theme.shadows.card.color,
                radius: theme.shadows.card.radius,
                x: theme.shadows.card.x,
                y: theme.shadows.card.y
            )
    }
}

// MARK: - Performance Optimizations
struct LazyContent<Content: View>: View {
    let content: () -> Content
    @State private var isLoaded = false
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        Group {
            if isLoaded {
                content()
            } else {
                ProgressView()
                    .onAppear {
                        DispatchQueue.main.async {
                            isLoaded = true
                        }
                    }
            }
        }
    }
}

// MARK: - Error Handling Views
struct ErrorBoundary<Content: View>: View {
    let content: Content
    @State private var hasError = false
    @State private var errorMessage = ""
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        Group {
            if hasError {
                ErrorView(message: errorMessage) {
                    hasError = false
                    errorMessage = ""
                }
            } else {
                content
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AppError"))) { notification in
                        if let error = notification.userInfo?["error"] as? String {
                            errorMessage = error
                            hasError = true
                        }
                    }
            }
        }
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.warning : AppTheme.light.colors.warning)
            
            Text("Something Went Wrong")
                .font(.title2)
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            
            Text(message)
                .font(.body)
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Button("Try Again") {
                onRetry()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding(32)
    }
}

// MARK: - Accessibility Enhancements
extension View {
    func accessibleLabel(_ label: String) -> some View {
        self.accessibilityLabel(label)
    }
    
    func accessibleHint(_ hint: String) -> some View {
        self.accessibilityHint(hint)
    }
    
    func accessibleValue(_ value: String) -> some View {
        self.accessibilityValue(value)
    }
}

// MARK: - Debug and Development Tools
#if DEBUG
struct DebugOverlay: View {
    @State private var showDebugInfo = false
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("Debug") {
                    showDebugInfo.toggle()
                }
                .padding(8)
                .background(Color.red.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.trailing, 16)
            }
            Spacer()
        }
        .sheet(isPresented: $showDebugInfo) {
            DebugView()
        }
    }
}

struct DebugView: View {
    var body: some View {
        NavigationView {
            List {
                Section("Performance") {
                    Text("Memory Usage: Normal")
                    Text("Network: Connected")
                    Text("Cache Size: 12.5 MB")
                }
                
                Section("Data") {
                    Text("Stocks Loaded: 10")
                    Text("News Items: 45")
                    Text("Last Update: 30s ago")
                }
                
                Section("Actions") {
                    Button("Clear Cache") {
                        // Clear cache
                    }
                    Button("Reset App State") {
                        // Reset state
                    }
                    Button("Generate Sample Data") {
                        // Generate data
                    }
                }
            }
            .navigationTitle("Debug Info")
        }
    }
}
#endif

#Preview {
    ContentView()
        .modelContainer(for: Stock.self, inMemory: true)
}

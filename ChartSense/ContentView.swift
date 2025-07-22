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
    
    var body: some View {
        ZStack {
            // Background color that respects theme
            (themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
                .ignoresSafeArea()
            
            TabView(selection: $appViewModel.selectedTab) {
                // Search Tab
                SearchView()
                    .environmentObject(appViewModel)
                    .environment(\.theme, themeManager.isDarkMode ? AppTheme.dark : AppTheme.light)
                    .tabItem {
                        VStack {
                            Image(systemName: "magnifyingglass")
                            Text("Search")
                        }
                    }
                    .tag(0)
                
                // Sentiment Tab
                SentimentView()
                    .environmentObject(appViewModel)
                    .environment(\.theme, themeManager.isDarkMode ? AppTheme.dark : AppTheme.light)
                    .tabItem {
                        VStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                            Text("Sentiment")
                        }
                    }
                    .tag(1)
                
                // Watchlist Tab
                WatchlistView()
                    .environmentObject(appViewModel)
                    .environment(\.theme, themeManager.isDarkMode ? AppTheme.dark : AppTheme.light)
                    .tabItem {
                        VStack {
                            Image(systemName: "heart.fill")
                            Text("Watchlist")
                        }
                    }
                    .tag(2)
                
                // Settings Tab
                SettingsView()
                    .environment(\.theme, themeManager.isDarkMode ? AppTheme.dark : AppTheme.light)
                    .tabItem {
                        VStack {
                            Image(systemName: "gearshape.fill")
                            Text("Settings")
                        }
                    }
                    .tag(3)
            }
            .accentColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
        }
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        .onReceive(themeManager.$isDarkMode) { _ in
            // Force UI update when theme changes
        }
    }
}

// MARK: - Main App Container with Enhanced Features
struct MainAppView: View {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var themeManager = ThemeManager.shared
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
    }
}

struct SplashScreenView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var animateIcon = false
    @State private var animateText = false
    
    var body: some View {
        ZStack {
            // Background
            (themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // App Icon/Logo
                ZStack {
                    // Icon Container with subtle gradient
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary,
                                    themeManager.isDarkMode ? AppTheme.dark.colors.secondary : AppTheme.light.colors.secondary
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(animateIcon ? 1.1 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: animateIcon
                        )
                    
                    // App Icon with proper masking and dark mode handling
                    if themeManager.isDarkMode {
                        // For dark mode, use a styled version
                        Image("AppIconImage")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary, lineWidth: 2)
                            )
                            .scaleEffect(animateIcon ? 1.0 : 0.8)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: animateIcon
                            )
                    } else {
                        // For light mode, use the original icon
                        Image("AppIconImage")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .scaleEffect(animateIcon ? 1.0 : 0.8)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: animateIcon
                            )
                    }
                }
                
                // App Title
                VStack(spacing: 8) {
                    Text("ChartSense")
                        .font(.system(size: 36, weight: .bold, design: .default))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        .opacity(animateText ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 1.0).delay(0.5), value: animateText)
                    
                    Text("AI-Powered Stock Sentiment Analysis")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                        .opacity(animateText ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 1.0).delay(0.8), value: animateText)
                }
            }
        }
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        .onAppear {
            animateIcon = true
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

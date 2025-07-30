//
//  ChartSenseApp.swift
//  ChartSense
//
//  Created by Aidan Quach on 7/22/25.
//

import SwiftUI
import SwiftData

@main
struct ChartSenseApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Stock.self,
            WatchlistItem.self,
            SearchHistory.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainAppView()
                .modelContainer(sharedModelContainer)
                .onAppear {
                    setupAppearance()
                    validateConfiguration()
                    warmCache()
                    startRealTimeUpdates()
                }
        }
    }
    
    private func validateConfiguration() {
        print("🔍 Validating app configuration...")
        
        // Validate Config.plist setup
        if Config.validateConfiguration() {
            print("✅ Configuration validation passed")
            Config.printDebugInfo()
            
            // Debug Supabase configuration
            SupabaseService.shared.debugConfiguration()
            
            // Test Supabase connection
            Config.testSupabaseConnection()
        } else {
            print("❌ Configuration validation failed. Please check your Config.plist file.")
            print("💡 Make sure you've added your API keys to ChartSense/Config.plist")
            print("💡 Ensure Config.plist is in your .gitignore file")
            print("💡 Verify Config.plist is included in your Xcode project bundle")
            
            // Check if Config.plist exists in bundle
            if let path = Bundle.main.path(forResource: "Config", ofType: "plist") {
                print("✅ Config.plist found at: \(path)")
            } else {
                print("❌ Config.plist not found in app bundle")
                print("💡 Add Config.plist to your Xcode project target")
            }
        }
    }
    
    private func setupAppearance() {
        // Customize tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        // Set tab bar item colors
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        // Customize navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor.systemBackground
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }
    
    private func warmCache() {
        Task {
            await StockDataService.shared.warmCache()
        }
    }
    
    private func startRealTimeUpdates() {
        // Start WebSocket connection for real-time updates
        WebSocketService.shared.startConnection()
        
        // Subscribe to popular stocks
        let popularSymbols = ["AAPL", "TSLA", "GOOGL", "MSFT", "NVDA"]
        WebSocketService.shared.subscribeToSymbols(popularSymbols)
    }
}

// MARK: - App Delegate for additional setup
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Setup notifications
        setupNotifications()
        
        // Setup background refresh
        setupBackgroundRefresh()
        
        return true
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupBackgroundRefresh() {
        // Note: In a real app, you would use BackgroundTasks framework
        // For now, we'll just log that this would be implemented
        print("Background refresh setup would be implemented with BackgroundTasks framework")
    }
}

// MARK: - App State Management
class AppStateManager: ObservableObject {
    @Published var isFirstLaunch: Bool
    @Published var currentVersion: String
    @Published var previousVersion: String?
    
    init() {
        let userDefaults = UserDefaults.standard
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let previousVersion = userDefaults.string(forKey: "AppVersion")
        
        self.currentVersion = currentVersion
        self.previousVersion = previousVersion
        self.isFirstLaunch = previousVersion == nil
        
        // Update stored version
        userDefaults.set(currentVersion, forKey: "AppVersion")
        
        if isFirstLaunch {
            performFirstLaunchSetup()
        } else if let previousVersion = previousVersion, previousVersion != currentVersion {
            performVersionMigration(from: previousVersion, to: currentVersion)
        }
    }
    
    private func performFirstLaunchSetup() {
        print("First launch detected - performing setup")
        
        // Set default preferences
        let userDefaults = UserDefaults.standard
        userDefaults.set(true, forKey: "notificationsEnabled")
        userDefaults.set(true, forKey: "priceAlertsEnabled")
        userDefaults.set(false, forKey: "newsAlertsEnabled")
        userDefaults.set(true, forKey: "marketOpenAlerts")
        userDefaults.set("5 minutes", forKey: "refreshInterval")

        
        // Show onboarding or welcome screen
        // This could be implemented as a separate view
    }
    
    private func performVersionMigration(from oldVersion: String, to newVersion: String) {
        print("Migrating from version \(oldVersion) to \(newVersion)")
        
        // Perform any necessary data migrations
        // This is where you'd handle breaking changes between versions
    }
}

// MARK: - Memory Management
extension ChartSenseApp {
    func applicationDidReceiveMemoryWarning() {
        // Handle memory warnings
        NotificationCenter.default.post(name: NSNotification.Name("MemoryWarning"), object: nil)
    }
}

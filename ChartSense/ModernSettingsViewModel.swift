import SwiftUI
import Combine

@MainActor
class ModernSettingsViewModel: ObservableObject {
    // MARK: - Published Properties (Streamlined)
    @Published var isDarkMode: Bool = false
    @Published var aiInsightsEnabled: Bool = true
    @Published var realTimeData: Bool = true
    @Published var analyticsEnabled: Bool = true
    
    // MARK: - UI State (Streamlined)
    @Published var showingProfileEditor: Bool = false
    @Published var showingSignOutAlert: Bool = false
    
    // MARK: - User Data
    @Published var userStats = UserStats(watchlistCount: 0, searchCount: 0, lastActive: Date())
    @Published var appVersion: String = "1.0.0"
    @Published var buildNumber: String = "1"
    
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadSettings()
        setupObservers()
        updateUserStats()
    }
    
    init(watchlistCount: Int, searchCount: Int, lastActive: Date) {
        self.userStats = UserStats(watchlistCount: watchlistCount, searchCount: searchCount, lastActive: lastActive)
        loadSettings()
        setupObservers()
    }
    
    // MARK: - Settings Management (Streamlined)
    private func loadSettings() {
        isDarkMode = ThemeManager.shared.isDarkMode
        aiInsightsEnabled = userDefaults.bool(forKey: "aiInsightsEnabled")
        realTimeData = userDefaults.bool(forKey: "realTimeData")
        analyticsEnabled = userDefaults.bool(forKey: "analyticsEnabled")
    }
    
    private func setupObservers() {
        // Observe settings changes and save to UserDefaults (Streamlined)
        $isDarkMode
            .sink { [weak self] value in
                ThemeManager.shared.isDarkMode = value
            }
            .store(in: &cancellables)
        
        $aiInsightsEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: "aiInsightsEnabled")
            }
            .store(in: &cancellables)
        
        $realTimeData
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: "realTimeData")
            }
            .store(in: &cancellables)
        
        $analyticsEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: "analyticsEnabled")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func exportData() {
        // Export user data to JSON
        let exportData = ExportData(
            settings: getCurrentSettings(),
            watchlist: getWatchlistData(),
            searchHistory: getSearchHistory(),
            timestamp: Date()
        )
        
        // Save to documents directory
        if let data = try? JSONEncoder().encode(exportData) {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsPath.appendingPathComponent("chartsense_export_\(Date().timeIntervalSince1970).json")
            
            try? data.write(to: fileURL)
            print("📁 Data exported to: \(fileURL.path)")
        }
    }
    
    func clearCache() {
        // Clear various caches
        URLCache.shared.removeAllCachedResponses()
        
        // Clear UserDefaults cache
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        
        // Clear stock data cache
        StockDataService.shared.clearCache()
        
        print("🧹 Cache cleared successfully")
    }
    
    func resetToDefaults() {
        // Reset all settings to defaults (Streamlined)
        isDarkMode = false
        aiInsightsEnabled = true
        realTimeData = true
        analyticsEnabled = true
        
        print("🔄 Settings reset to defaults")
    }
    
    func rateApp() {
        // Open App Store rating page
        if let url = URL(string: "https://apps.apple.com/app/id1234567890?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
    
    func contactSupport() {
        // Open support email
        if let url = URL(string: "mailto:support@chartsense.app?subject=ChartSense Support") {
            UIApplication.shared.open(url)
        }
    }
    
    func openHelpCenter() {
        // Open help center website
        if let url = URL(string: "https://help.chartsense.app") {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Private Methods (Streamlined)
    // Note: updateTheme() is no longer needed as isDarkMode is managed by ThemeManager.shared
    
    private func updateUserStats() {
        // Update user statistics
        userStats = UserStats(
            watchlistCount: getWatchlistCount(),
            searchCount: getSearchCount(),
            lastActive: Date()
        )
    }
    

    
    private func getCurrentSettings() -> [String: String] {
        return [
            "isDarkMode": String(isDarkMode),
            "aiInsightsEnabled": String(aiInsightsEnabled),
            "realTimeData": String(realTimeData),
            "analyticsEnabled": String(analyticsEnabled)
        ]
    }
    
    private func getWatchlistData() -> [String] {
        // Get watchlist data from SwiftData
        return [] // TODO: Implement
    }
    
    private func getSearchHistory() -> [String] {
        // Get search history from SwiftData
        return [] // TODO: Implement
    }
    
    private func getWatchlistCount() -> Int {
        // Get watchlist count from SwiftData
        return 12 // TODO: Implement
    }
    
    private func getSearchCount() -> Int {
        // Get search count from SwiftData
        return 47 // TODO: Implement
    }
}

// MARK: - Supporting Models (Streamlined)
struct UserStats {
    let watchlistCount: Int
    let searchCount: Int
    let lastActive: Date
}

struct ExportData: Codable {
    let settings: [String: String] // Changed from [String: Any] to [String: String] for Codable conformance
    let watchlist: [String]
    let searchHistory: [String]
    let timestamp: Date
    
    init(settings: [String: String], watchlist: [String], searchHistory: [String], timestamp: Date) {
        self.settings = settings
        self.watchlist = watchlist
        self.searchHistory = searchHistory
        self.timestamp = timestamp
    }
} 
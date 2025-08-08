import SwiftUI
import Combine

@MainActor
class ModernSettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isDarkMode: Bool = false
    @Published var chartStyle: String = "Candlestick"
    @Published var notificationsEnabled: Bool = true
    @Published var priceAlertsEnabled: Bool = true
    @Published var newsAlertsEnabled: Bool = true
    @Published var marketOpenAlerts: Bool = false
    @Published var aiInsightsEnabled: Bool = true
    @Published var refreshInterval: String = "5 minutes"
    @Published var autoRefreshEnabled: Bool = true
    @Published var highQualityCharts: Bool = true
    @Published var offlineModeEnabled: Bool = false
    @Published var newsSources: String = "All Sources"
    @Published var showConfidenceScores: Bool = true
    @Published var autoAnalyzeWatchlist: Bool = false
    @Published var compactLayout: Bool = false
    @Published var realTimeData: Bool = true
    @Published var extendedHours: Bool = false
    @Published var autoRefresh: Bool = true
    @Published var analyticsEnabled: Bool = true
    @Published var crashReports: Bool = true
    
    // MARK: - UI State
    @Published var showingProfileEditor: Bool = false
    @Published var showingDataExport: Bool = false
    @Published var showingSignOutAlert: Bool = false
    @Published var showingHelpCenter: Bool = false
    @Published var showingContactSupport: Bool = false
    
    // MARK: - User Data
    @Published var userStats = UserStats(watchlistCount: 0, alertCount: 0, searchCount: 0, lastActive: Date())
    @Published var appVersion: String = "1.0.0"
    @Published var buildNumber: String = "1"
    
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadSettings()
        setupObservers()
        updateUserStats()
    }
    
    init(watchlistCount: Int, alertCount: Int, searchCount: Int, lastActive: Date) {
        self.userStats = UserStats(watchlistCount: watchlistCount, alertCount: alertCount, searchCount: searchCount, lastActive: lastActive)
        loadSettings()
        setupObservers()
    }
    
    // MARK: - Settings Management
    private func loadSettings() {
        isDarkMode = ThemeManager.shared.isDarkMode
        chartStyle = userDefaults.string(forKey: "chartStyle") ?? "Candlestick"
        notificationsEnabled = userDefaults.bool(forKey: "notificationsEnabled")
        priceAlertsEnabled = userDefaults.bool(forKey: "priceAlertsEnabled")
        newsAlertsEnabled = userDefaults.bool(forKey: "newsAlertsEnabled")
        marketOpenAlerts = userDefaults.bool(forKey: "marketOpenAlerts")
        aiInsightsEnabled = userDefaults.bool(forKey: "aiInsightsEnabled")
        refreshInterval = userDefaults.string(forKey: "refreshInterval") ?? "5 minutes"
        autoRefreshEnabled = userDefaults.bool(forKey: "autoRefreshEnabled")
        highQualityCharts = userDefaults.bool(forKey: "highQualityCharts")
        offlineModeEnabled = userDefaults.bool(forKey: "offlineModeEnabled")
        newsSources = userDefaults.string(forKey: "newsSources") ?? "All Sources"
        showConfidenceScores = userDefaults.bool(forKey: "showConfidenceScores")
        autoAnalyzeWatchlist = userDefaults.bool(forKey: "autoAnalyzeWatchlist")
        compactLayout = userDefaults.bool(forKey: "compactLayout")
        realTimeData = userDefaults.bool(forKey: "realTimeData")
        extendedHours = userDefaults.bool(forKey: "extendedHours")
        autoRefresh = userDefaults.bool(forKey: "autoRefresh")
        analyticsEnabled = userDefaults.bool(forKey: "analyticsEnabled")
        crashReports = userDefaults.bool(forKey: "crashReports")
    }
    
    private func setupObservers() {
        // Observe settings changes and save to UserDefaults
        $isDarkMode
            .sink { [weak self] value in
                ThemeManager.shared.isDarkMode = value
            }
            .store(in: &cancellables)
        
        $chartStyle
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: "chartStyle")
            }
            .store(in: &cancellables)
        
        $notificationsEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: "notificationsEnabled")
                self?.updateNotificationSettings()
            }
            .store(in: &cancellables)
        
        $priceAlertsEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: "priceAlertsEnabled")
            }
            .store(in: &cancellables)
        
        $newsAlertsEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: "newsAlertsEnabled")
            }
            .store(in: &cancellables)
        
        $marketOpenAlerts
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: "marketOpenAlerts")
            }
            .store(in: &cancellables)
        
        $aiInsightsEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: "aiInsightsEnabled")
            }
            .store(in: &cancellables)
        
        $refreshInterval
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: "refreshInterval")
                self?.updateRefreshInterval()
            }
            .store(in: &cancellables)
        
        $autoRefreshEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: "autoRefreshEnabled")
            }
            .store(in: &cancellables)
        
        $highQualityCharts
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: "highQualityCharts")
            }
            .store(in: &cancellables)
        
        $offlineModeEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: "offlineModeEnabled")
                self?.updateOfflineMode()
            }
            .store(in: &cancellables)
        
        $newsSources
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: "newsSources")
            }
            .store(in: &cancellables)
        
        $showConfidenceScores
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: "showConfidenceScores")
            }
            .store(in: &cancellables)
        
        $autoAnalyzeWatchlist
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: "autoAnalyzeWatchlist")
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
        
        // Clear image cache
        clearImageCache()
        
        // Clear stock data cache
        StockDataService.shared.clearCache()
        
        print("🧹 Cache cleared successfully")
    }
    
    func resetToDefaults() {
        // Reset all settings to defaults
        isDarkMode = false
        chartStyle = "Candlestick"
        notificationsEnabled = true
        priceAlertsEnabled = true
        newsAlertsEnabled = true
        marketOpenAlerts = false
        aiInsightsEnabled = true
        refreshInterval = "5 minutes"
        autoRefreshEnabled = true
        highQualityCharts = true
        offlineModeEnabled = false
        newsSources = "All Sources"
        showConfidenceScores = true
        autoAnalyzeWatchlist = false
        
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
    
    // MARK: - Private Methods
    // Note: updateTheme() is no longer needed as isDarkMode is managed by ThemeManager.shared
    
    private func updateNotificationSettings() {
        // Update notification permissions and settings
        if notificationsEnabled {
            requestNotificationPermissions()
        }
    }
    
    private func updateRefreshInterval() {
        // Update data refresh interval
        let interval: TimeInterval
        switch refreshInterval {
        case "1 minute": interval = 60
        case "5 minutes": interval = 300
        case "15 minutes": interval = 900
        case "30 minutes": interval = 1800
        default: interval = 300
        }
        
        // Update StockDataService refresh interval
        // TODO: Implement refresh interval update in StockDataService
        print("🔄 Refresh interval updated to \(interval) seconds")
    }
    
    private func updateOfflineMode() {
        // Configure offline mode
        if offlineModeEnabled {
            enableOfflineMode()
        } else {
            disableOfflineMode()
        }
    }
    
    private func updateUserStats() {
        // Update user statistics
        userStats = UserStats(
            watchlistCount: getWatchlistCount(),
            alertCount: getAlertCount(),
            searchCount: getSearchCount(),
            lastActive: Date()
        )
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("🔔 Notification permissions granted")
            } else {
                print("❌ Notification permissions denied")
            }
        }
    }
    
    private func clearImageCache() {
        // Clear image cache
        let imageCache = NSCache<NSString, UIImage>()
        imageCache.removeAllObjects()
    }
    
    private func enableOfflineMode() {
        // Enable offline mode functionality
        print("📱 Offline mode enabled")
    }
    
    private func disableOfflineMode() {
        // Disable offline mode functionality
        print("📱 Offline mode disabled")
    }
    
    private func getCurrentSettings() -> [String: Any] {
        return [
            "isDarkMode": isDarkMode,

            "chartStyle": chartStyle,
            "notificationsEnabled": notificationsEnabled,
            "priceAlertsEnabled": priceAlertsEnabled,
            "newsAlertsEnabled": newsAlertsEnabled,
            "marketOpenAlerts": marketOpenAlerts,
            "aiInsightsEnabled": aiInsightsEnabled,
            "refreshInterval": refreshInterval,
            "autoRefreshEnabled": autoRefreshEnabled,
            "highQualityCharts": highQualityCharts,
            "offlineModeEnabled": offlineModeEnabled,
            "newsSources": newsSources,
            "showConfidenceScores": showConfidenceScores,
            "autoAnalyzeWatchlist": autoAnalyzeWatchlist
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
    
    private func getAlertCount() -> Int {
        // Get alert count from SwiftData
        return 5 // TODO: Implement
    }
    
    private func getSearchCount() -> Int {
        // Get search count from SwiftData
        return 47 // TODO: Implement
    }
}

// MARK: - Supporting Models
struct UserStats {
    let watchlistCount: Int
    let alertCount: Int
    let searchCount: Int
    let lastActive: Date
}

struct ExportData: Codable {
    let settings: [String: Any]
    let watchlist: [String]
    let searchHistory: [String]
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case settings, watchlist, searchHistory, timestamp
    }
    
    init(settings: [String: Any], watchlist: [String], searchHistory: [String], timestamp: Date) {
        self.settings = settings
        self.watchlist = watchlist
        self.searchHistory = searchHistory
        self.timestamp = timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        settings = [:] // TODO: Implement proper decoding
        watchlist = try container.decode([String].self, forKey: .watchlist)
        searchHistory = try container.decode([String].self, forKey: .searchHistory)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // TODO: Implement proper encoding for settings
        try container.encode(watchlist, forKey: .watchlist)
        try container.encode(searchHistory, forKey: .searchHistory)
        try container.encode(timestamp, forKey: .timestamp)
    }
} 
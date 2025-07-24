import Foundation
import StoreKit
import Combine
import SwiftUI

// MARK: - Premium Subscription Manager
@MainActor
class PremiumManager: ObservableObject {
    static let shared = PremiumManager()
    
    // MARK: - Published Properties
    @Published var isPremium: Bool = false
    @Published var subscriptionStatus: SubscriptionStatus = .free
    @Published var aiMessagesRemaining: Int = 5
    @Published var aiMessagesUsedToday: Int = 0
    @Published var lastMessageResetDate: Date = Date()
    
    // Image Analysis Tracking
    @Published var imageAnalysisRemaining: Int = 1
    @Published var imageAnalysisUsedToday: Int = 0
    @Published var lastImageAnalysisResetDate: Date = Date()
    @Published var showingPremiumUpgrade: Bool = false
    @Published var isLoading: Bool = false
    
    // MARK: - Premium Features
    @Published var premiumFeatures: [PremiumFeature] = [
        PremiumFeature(
            id: "unlimited_ai",
            title: "Unlimited AI Messages",
            description: "Chat with AI assistant without daily limits",
            icon: "brain.head.profile",
            isEnabled: false
        ),
        PremiumFeature(
            id: "real_time_alerts",
            title: "Real-time Price Alerts",
            description: "Get instant notifications for price movements",
            icon: "bell.badge",
            isEnabled: false
        ),
        PremiumFeature(
            id: "advanced_charts",
            title: "Advanced Charts",
            description: "Access to professional charting tools",
            icon: "chart.line.uptrend.xyaxis",
            isEnabled: false
        ),
        PremiumFeature(
            id: "image_analysis",
            title: "Unlimited Image Analysis",
            description: "Analyze charts and graphs without daily limits",
            icon: "camera.viewfinder",
            isEnabled: false
        )
    ]
    
    // MARK: - Subscription Plans
    let subscriptionPlans: [SubscriptionPlan] = [
        SubscriptionPlan(
            id: "monthly",
            title: "Monthly",
            price: "$4.99",
            period: "month",
            description: "Perfect for trying out premium features",
            isPopular: false,
            savings: nil
        ),
        SubscriptionPlan(
            id: "yearly",
            title: "Yearly",
            price: "$49.99",
            period: "year",
            description: "Best value for long-term users",
            isPopular: true,
            savings: "Save 17%"
        ),
        SubscriptionPlan(
            id: "lifetime",
            title: "Lifetime",
            price: "$99.99",
            period: "one-time",
            description: "One-time payment, forever access",
            isPopular: false,
            savings: "Save 83%"
        )
    ]
    
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadSubscriptionStatus()
        loadImageAnalysisCount()
        setupMessageResetTimer()
        updatePremiumFeatures()
    }
    
    // MARK: - Public Methods
    
    /// Check if user can send an AI message
    func canSendAIMessage() -> Bool {
        if isPremium {
            return true
        }
        return aiMessagesRemaining > 0
    }
    
    /// Use an AI message (decrement counter for free users)
    func useAIMessage() -> Bool {
        if isPremium {
            return true
        }
        
        if aiMessagesRemaining > 0 {
            aiMessagesRemaining -= 1
            aiMessagesUsedToday += 1
            saveMessageCount()
            return true
        }
        
        showingPremiumUpgrade = true
        return false
    }
    
    /// Check if user can perform image analysis
    func canPerformImageAnalysis() -> Bool {
        if isPremium {
            return true
        }
        return imageAnalysisRemaining > 0
    }
    
    /// Use image analysis (decrement counter for free users)
    func useImageAnalysis() -> Bool {
        if isPremium {
            return true
        }
        
        if imageAnalysisRemaining > 0 {
            imageAnalysisRemaining -= 1
            imageAnalysisUsedToday += 1
            saveImageAnalysisCount()
            return true
        }
        
        showingPremiumUpgrade = true
        return false
    }
    
    /// Check if a premium feature is available
    func isFeatureAvailable(_ featureId: String) -> Bool {
        if isPremium {
            return true
        }
        
        // Some features might be available for free users
        switch featureId {
        case "export_data":
            return true // Basic export is free
        default:
            return false
        }
    }
    
    /// Purchase premium subscription
    func purchasePremium(planId: String) async {
        isLoading = true
        
        // Simulate purchase process
        do {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Simulate successful purchase
            await activatePremium(planId: planId)
            
        } catch {
            print("❌ Purchase failed: \(error)")
        }
        
        isLoading = false
    }
    
    /// Restore purchases
    func restorePurchases() async {
        isLoading = true
        
        // Simulate restore process
        do {
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // Simulate successful restore
            await activatePremium(planId: "yearly")
            
        } catch {
            print("❌ Restore failed: \(error)")
        }
        
        isLoading = false
    }
    
    /// Show premium upgrade modal
    func showPremiumUpgrade() {
        showingPremiumUpgrade = true
    }
    
    // MARK: - Private Methods
    
    private func activatePremium(planId: String) async {
        isPremium = true
        subscriptionStatus = .premium(planId: planId)
        aiMessagesRemaining = Int.max
        
        updatePremiumFeatures()
        saveSubscriptionStatus()
        
        print("✅ Premium activated: \(planId)")
    }
    
    private func updatePremiumFeatures() {
        for i in 0..<premiumFeatures.count {
            premiumFeatures[i].isEnabled = isPremium
        }
    }
    
    private func setupMessageResetTimer() {
        // Check if we need to reset daily message count
        let calendar = Calendar.current
        if !calendar.isDate(lastMessageResetDate, inSameDayAs: Date()) {
            resetDailyMessageCount()
        }
        
        // Set up timer to check daily reset
        Timer.publish(every: 3600, on: .main, in: .common) // Check every hour
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkDailyReset()
            }
            .store(in: &cancellables)
    }
    
    private func checkDailyReset() {
        let calendar = Calendar.current
        if !calendar.isDate(lastMessageResetDate, inSameDayAs: Date()) {
            resetDailyMessageCount()
        }
        if !calendar.isDate(lastImageAnalysisResetDate, inSameDayAs: Date()) {
            resetImageAnalysisCount()
        }
    }
    
    private func resetDailyMessageCount() {
        aiMessagesRemaining = 5
        aiMessagesUsedToday = 0
        lastMessageResetDate = Date()
        saveMessageCount()
        print("🔄 Daily AI message count reset")
    }
    
    private func loadSubscriptionStatus() {
        isPremium = userDefaults.bool(forKey: "isPremium")
        aiMessagesRemaining = userDefaults.integer(forKey: "aiMessagesRemaining")
        aiMessagesUsedToday = userDefaults.integer(forKey: "aiMessagesUsedToday")
        
        if aiMessagesRemaining == 0 {
            aiMessagesRemaining = 5 // Default for new users
        }
        
        if let dateData = userDefaults.data(forKey: "lastMessageResetDate"),
           let date = try? JSONDecoder().decode(Date.self, from: dateData) {
            lastMessageResetDate = date
        }
        
        if let statusData = userDefaults.data(forKey: "subscriptionStatus"),
           let status = try? JSONDecoder().decode(SubscriptionStatus.self, from: statusData) {
            subscriptionStatus = status
        }
    }
    
    private func saveSubscriptionStatus() {
        userDefaults.set(isPremium, forKey: "isPremium")
        
        if let statusData = try? JSONEncoder().encode(subscriptionStatus) {
            userDefaults.set(statusData, forKey: "subscriptionStatus")
        }
    }
    
    private func saveMessageCount() {
        userDefaults.set(aiMessagesRemaining, forKey: "aiMessagesRemaining")
        userDefaults.set(aiMessagesUsedToday, forKey: "aiMessagesUsedToday")
        
        if let dateData = try? JSONEncoder().encode(lastMessageResetDate) {
            userDefaults.set(dateData, forKey: "lastMessageResetDate")
        }
    }
    
    private func saveImageAnalysisCount() {
        userDefaults.set(imageAnalysisRemaining, forKey: "imageAnalysisRemaining")
        userDefaults.set(imageAnalysisUsedToday, forKey: "imageAnalysisUsedToday")
        
        if let dateData = try? JSONEncoder().encode(lastImageAnalysisResetDate) {
            userDefaults.set(dateData, forKey: "lastImageAnalysisResetDate")
        }
    }
    
    private func loadImageAnalysisCount() {
        imageAnalysisRemaining = userDefaults.integer(forKey: "imageAnalysisRemaining")
        imageAnalysisUsedToday = userDefaults.integer(forKey: "imageAnalysisUsedToday")
        
        if imageAnalysisRemaining == 0 {
            imageAnalysisRemaining = 1 // Default for new users
        }
        
        if let dateData = userDefaults.data(forKey: "lastImageAnalysisResetDate"),
           let date = try? JSONDecoder().decode(Date.self, from: dateData) {
            lastImageAnalysisResetDate = date
        }
        
        // Check if we need to reset daily count
        if !Calendar.current.isDate(lastImageAnalysisResetDate, inSameDayAs: Date()) {
            resetImageAnalysisCount()
        }
    }
    
    private func resetImageAnalysisCount() {
        imageAnalysisRemaining = 1
        imageAnalysisUsedToday = 0
        lastImageAnalysisResetDate = Date()
        saveImageAnalysisCount()
        print("🔄 Daily image analysis count reset")
    }
}

// MARK: - Supporting Models

enum SubscriptionStatus: Codable {
    case free
    case premium(planId: String)
    case trial(expiresAt: Date)
}

struct PremiumFeature: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    var isEnabled: Bool
}

struct SubscriptionPlan: Identifiable {
    let id: String
    let title: String
    let price: String
    let period: String
    let description: String
    let isPopular: Bool
    let savings: String?
}

 
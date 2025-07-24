import SwiftUI

// MARK: - Premium Upgrade View
struct PremiumUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var premiumManager = PremiumManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedPlan: String = "yearly"
    @State private var showingFeatures = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Section
                    PremiumHeroSection()
                    
                    // Features Preview
                    PremiumFeaturesPreview()
                    
                    // Plans Section
                    PremiumPlansSection(
                        selectedPlan: $selectedPlan,
                        plans: premiumManager.subscriptionPlans
                    )
                    
                    // Action Section
                    PremiumActionSection(
                        selectedPlan: selectedPlan,
                        isLoading: premiumManager.isLoading,
                        onPurchase: {
                            Task {
                                await premiumManager.purchasePremium(planId: selectedPlan)
                                dismiss()
                            }
                        },
                        onRestore: {
                            Task {
                                await premiumManager.restorePurchases()
                                dismiss()
                            }
                        }
                    )
                    
                    // Footer
                    PremiumFooter()
                }
            }
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
            .navigationBarHidden(true)
            .overlay(
                // Custom Navigation Bar
                VStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                                .frame(width: 32, height: 32)
                                .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
                                .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        Text("Premium")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        
                        Spacer()
                        
                        // Invisible spacer for balance
                        Color.clear
                            .frame(width: 32, height: 32)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
                    
                    Spacer()
                }
            )
        }
    }
}

// MARK: - Premium Hero Section
struct PremiumHeroSection: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Hero Content
            VStack(spacing: 24) {
                // Premium Badge
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("PREMIUM")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(1.2)
                }
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
                
                // Main Title
                VStack(spacing: 12) {
                    Text("Unlock the full potential")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text("of ChartSense")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                        .multilineTextAlignment(.center)
                }
                
                // Subtitle
                Text("Transform your trading experience with unlimited AI insights, advanced analytics, and professional tools.")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 20)
            }
            
            // Hero Visual
            ZStack {
                // Background gradient
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                themeManager.isDarkMode ? AppTheme.dark.colors.primary.opacity(0.1) : AppTheme.light.colors.primary.opacity(0.1),
                                themeManager.isDarkMode ? AppTheme.dark.colors.secondary.opacity(0.05) : AppTheme.light.colors.secondary.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 200)
                
                // Feature icons grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                    PremiumFeatureIcon(icon: "brain.head.profile", title: "AI", isAnimating: isAnimating, delay: 0)
                    PremiumFeatureIcon(icon: "chart.line.uptrend.xyaxis", title: "Charts", isAnimating: isAnimating, delay: 0.2)
                    PremiumFeatureIcon(icon: "bell.badge", title: "Alerts", isAnimating: isAnimating, delay: 0.4)
                    PremiumFeatureIcon(icon: "chart.pie", title: "Analytics", isAnimating: isAnimating, delay: 0.6)
                    PremiumFeatureIcon(icon: "camera.viewfinder", title: "Analysis", isAnimating: isAnimating, delay: 0.8)
                    PremiumFeatureIcon(icon: "star.fill", title: "Premium", isAnimating: isAnimating, delay: 1.0)
                }
                .padding(32)
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 80) // Account for navigation bar
        .padding(.bottom, 40)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Premium Feature Icon
struct PremiumFeatureIcon: View {
    let icon: String
    let title: String
    let isAnimating: Bool
    let delay: Double
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.6).delay(delay), value: isAnimating)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.6).delay(delay + 0.1), value: isAnimating)
            }
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                .opacity(isAnimating ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.6).delay(delay + 0.2), value: isAnimating)
        }
    }
}

// MARK: - Premium Features Preview
struct PremiumFeaturesPreview: View {
    @StateObject private var themeManager = ThemeManager.shared
    let features = PremiumManager.shared.premiumFeatures
    
    var body: some View {
        VStack(spacing: 24) {
            // Section Header
            VStack(spacing: 8) {
                Text("Everything you need")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Text("to succeed in trading")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
            }
            
            // Features Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(features) { feature in
                    PremiumFeatureCard(feature: feature)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 40)
    }
}

// MARK: - Premium Feature Card
struct PremiumFeatureCard: View {
    let feature: PremiumFeature
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(feature.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Text(feature.description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    .lineLimit(3)
            }
        }
        .padding(20)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border,
                    lineWidth: 0.5
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isHovered = false
            }
        }
    }
}



// MARK: - Premium Plans Section
struct PremiumPlansSection: View {
    @Binding var selectedPlan: String
    let plans: [SubscriptionPlan]
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 32) {
            // Section Header
            VStack(spacing: 8) {
                Text("Choose your plan")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Text("Start your journey to better trading")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            }
            
            // Plans
            VStack(spacing: 16) {
                ForEach(plans) { plan in
                    PremiumPlanCard(
                        plan: plan,
                        isSelected: selectedPlan == plan.id,
                        onSelect: { selectedPlan = plan.id }
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 40)
    }
}

// MARK: - Premium Plan Card
struct PremiumPlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onSelect: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 0) {
                // Selection indicator
                VStack {
                    ZStack {
                        Circle()
                            .stroke(
                                isSelected ? 
                                (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary) :
                                (themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border),
                                lineWidth: 2
                            )
                            .frame(width: 24, height: 24)
                        
                        if isSelected {
                            Circle()
                                .fill(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                                .frame(width: 16, height: 16)
                        }
                    }
                    Spacer()
                }
                .padding(.leading, 20)
                .padding(.top, 20)
                
                // Plan content
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(plan.title)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                                
                                if plan.isPopular {
                                    Text("MOST POPULAR")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.orange)
                                        .cornerRadius(4)
                                }
                            }
                            
                            Text(plan.description)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(plan.price)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                            
                            Text("/ \(plan.period)")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                            
                            if let savings = plan.savings {
                                Text("Save \(savings)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                
                Spacer()
            }
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? 
                        (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary) :
                        (themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border),
                        lineWidth: isSelected ? 2 : 0.5
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Subscription Plan Card
struct SubscriptionPlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onSelect: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? 
                            (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary) :
                            (themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                            .frame(width: 16, height: 16)
                    }
                }
                
                // Plan details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        
                        if plan.isPopular {
                            Text("MOST POPULAR")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text(plan.price)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                        
                        Text("/ \(plan.period)")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                        
                        if let savings = plan.savings {
                            Text("Save \(savings)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    
                    Text(plan.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                }
            }
            .padding(16)
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? 
                        (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary) :
                        (themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border),
                        lineWidth: isSelected ? 2 : 0.5
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Premium Action Section
struct PremiumActionSection: View {
    let selectedPlan: String
    let isLoading: Bool
    let onPurchase: () -> Void
    let onRestore: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Main Action Button
            Button(action: onPurchase) {
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 20, weight: .medium))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isLoading ? "Processing..." : "Start Premium")
                            .font(.system(size: 18, weight: .bold))
                        
                        Text("Unlock all features instantly")
                            .font(.system(size: 14, weight: .regular))
                            .opacity(0.8)
                    }
                    
                    Spacer()
                    
                    if !isLoading {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.blue.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .disabled(isLoading)
            .buttonStyle(PlainButtonStyle())
            
            // Restore Button
            Button(action: onRestore) {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary))
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text(isLoading ? "Restoring..." : "Restore Purchases")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                .padding(.vertical, 12)
            }
            .disabled(isLoading)
            .buttonStyle(PlainButtonStyle())
            
            // Trust Indicators
            VStack(spacing: 16) {
                HStack(spacing: 24) {
                    TrustIndicator(icon: "shield.checkered", text: "Secure")
                    TrustIndicator(icon: "clock.arrow.circlepath", text: "Cancel anytime")
                    TrustIndicator(icon: "checkmark.seal", text: "30-day guarantee")
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 40)
    }
}

// MARK: - Trust Indicator
struct TrustIndicator: View {
    let icon: String
    let text: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
        }
    }
}

// MARK: - Premium Footer
struct PremiumFooter: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Divider
            Rectangle()
                .fill(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border)
                .frame(height: 0.5)
                .padding(.horizontal, 20)
            
            // Footer content
            VStack(spacing: 12) {
                Text("Questions? Contact our support team")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                
                HStack(spacing: 24) {
                    Button("Privacy Policy") {
                        // TODO: Open privacy policy
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                    
                    Button("Terms of Service") {
                        // TODO: Open terms of service
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                }
            }
            .padding(.vertical, 20)
        }
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
    }
} 
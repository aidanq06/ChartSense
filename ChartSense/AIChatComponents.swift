import SwiftUI
import Combine
import PhotosUI
import UIKit

// Global AI accent gradient for consistent theming
private let aiGradient = LinearGradient(colors: [Color.purple, Color.blue], startPoint: .leading, endPoint: .trailing)

// MARK: - AI Chat Models
// Using ChatMessage from Item.swift

struct AISuggestion: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let action: () -> Void
}

// MARK: - Image Analysis Models
struct ImageAnalysisResult {
    let image: UIImage
    let analysis: String
    let timestamp: Date
    let confidence: Double
}

// MARK: - Modern AI Chat View
struct ModernAIChatView: View {
    @StateObject private var viewModel = AIChatViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var premiumManager = PremiumManager.shared
    @FocusState private var isInputFocused: Bool
    @State private var showingImagePicker = false
    @State private var showingImageAnalysis = false
    @State private var selectedImage: UIImage?
    private let bottomAnchorId = "bottom"
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            AIChatHeader()
                .padding(.top, 0)
                .padding(.bottom, 0)
                .background(
                    (themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
                        .ignoresSafeArea(edges: .top)
                )
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 14) {
                        // Welcome message
                        if viewModel.messages.isEmpty {
                            WelcomeMessage(
                                onAskStock: { isInputFocused = true },
                                onUploadChart: { showingImagePicker = true },
                                quickActions: viewModel.suggestions
                            )
                        }
                        
                        // Chat messages with day dividers
                        ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                            if shouldShowDayDivider(at: index) {
                                DayDivider(date: message.timestamp)
                            }
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        // Loading indicator
                        if viewModel.isTyping {
                            AITypingIndicator()
                                .id("typing")
                        }
                        
                        // Bottom anchor for smooth scrolling
                        Color.clear
                            .frame(height: 1)
                            .id(bottomAnchorId)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onTapGesture { isInputFocused = false }
                .onChange(of: viewModel.messages.count) { _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: viewModel.isTyping) { isTyping in
                    if isTyping { scrollToBottom(proxy) }
                }
                .onChange(of: isInputFocused) { focused in
                    if focused { scrollToBottom(proxy) }
                }
                .onAppear {
                    scrollToBottom(proxy)
                }
            }
            
            // Input area
            ModernChatInput(
                text: $viewModel.inputText,
                onSend: viewModel.sendMessage,
                suggestions: viewModel.suggestions,
                onImageUpload: {
                    showingImagePicker = true
                }
            )
            .focused($isInputFocused)
        }
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
        .navigationBarHidden(true)
        .sheet(isPresented: $premiumManager.showingPremiumUpgrade) {
            PremiumUpgradeView()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
                .onDisappear {
                    if let image = selectedImage {
                        showingImageAnalysis = true
                    }
                }
        }
        .sheet(isPresented: $showingImageAnalysis) {
            if let image = selectedImage {
                ImageAnalysisView(
                    image: image,
                    onAnalysisComplete: { result in
                        viewModel.addImageAnalysisMessage(result)
                        selectedImage = nil
                        showingImageAnalysis = false
                    }
                )
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(bottomAnchorId, anchor: .bottom)
            }
        }
    }

    private func shouldShowDayDivider(at index: Int) -> Bool {
        guard index > 0 else { return true }
        let current = viewModel.messages[index].timestamp
        let previous = viewModel.messages[index - 1].timestamp
        return !Calendar.current.isDate(current, inSameDayAs: previous)
    }
}

// MARK: - Image Analysis View
struct ImageAnalysisView: View {
    let image: UIImage
    let onAnalysisComplete: (ImageAnalysisResult) -> Void
    
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var premiumManager = PremiumManager.shared
    @State private var analysisResult: ImageAnalysisResult?
    @State private var isAnalyzing = false
    @State private var analysisProgress: Double = 0.0
    @Environment(\.dismiss) private var dismiss
    
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
                    
                    Text("Chart Analysis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Spacer()
                    
                    Button("Done") {
                        if let result = analysisResult {
                            onAnalysisComplete(result)
                        }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(analysisResult != nil ? (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary) : Color.gray)
                    .disabled(analysisResult == nil)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border),
                    alignment: .bottom
                )
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Image display
                        VStack(spacing: 16) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 300)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border, lineWidth: 0.5)
                                )
                            
                            // Premium status indicator
                            if !premiumManager.isPremium {
                                HStack(spacing: 8) {
                                    Image(systemName: "camera.viewfinder")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                                    
                                    Text("\(premiumManager.imageAnalysisRemaining) analysis left today")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryBackground : AppTheme.light.colors.tertiaryBackground)
                                .cornerRadius(8)
                            }
                        }
                        
                        // Analysis button or result
                        if let result = analysisResult {
                            // Analysis result
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.green)
                                    
                                    Text("Analysis Complete")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(result.confidence * 100))% confidence")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                                }
                                
                                NotionCard {
                                    Text(result.analysis)
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                        } else if isAnalyzing {
                            // Analysis in progress
                            VStack(spacing: 16) {
                                ProgressView(value: analysisProgress)
                                    .progressViewStyle(LinearProgressViewStyle(tint: themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary))
                                    .scaleEffect(x: 1, y: 2, anchor: .center)
                                
                                Text("Analyzing chart patterns...")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                                
                                Text("\(Int(analysisProgress * 100))%")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                            }
                            .padding(.vertical, 20)
                        } else {
                            // Start analysis button
                            Button(action: startAnalysis) {
                                HStack(spacing: 12) {
                                    Image(systemName: "brain.head.profile")
                                        .font(.system(size: 18, weight: .medium))
                                    
                                    Text("Analyze Chart")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                            .disabled(!premiumManager.canPerformImageAnalysis())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
        }
        .onAppear {
            if premiumManager.canPerformImageAnalysis() {
                startAnalysis()
            }
        }
    }
    
    private func startAnalysis() {
        guard premiumManager.canPerformImageAnalysis() else {
            premiumManager.showPremiumUpgrade()
            return
        }
        
        // Use image analysis
        if !premiumManager.useImageAnalysis() {
            return
        }
        
        isAnalyzing = true
        analysisProgress = 0.0
        
        // Simulate analysis progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            analysisProgress += 0.02
            if analysisProgress >= 1.0 {
                timer.invalidate()
                completeAnalysis()
            }
        }
    }
    
    private func completeAnalysis() {
        isAnalyzing = false
        
        // Generate analysis result (replace with actual AI analysis)
        let analysis = generateChartAnalysis()
        let confidence = Double.random(in: 0.75...0.95)
        
        analysisResult = ImageAnalysisResult(
            image: image,
            analysis: analysis,
            timestamp: Date(),
            confidence: confidence
        )
    }
    
    private func generateChartAnalysis() -> String {
        // Simulate AI chart analysis (replace with actual AI service)
        let analyses = [
            """
            📈 **Chart Analysis: Bullish Pattern Detected**
            
            **Pattern Recognition:**
            • **Ascending Triangle** formation identified
            • Price consolidating above key support level
            • Volume showing accumulation pattern
            
            **Technical Indicators:**
            • RSI: 58 (neutral, trending upward)
            • MACD: Bullish crossover imminent
            • Moving Averages: Price above 50-day MA
            
            **Key Levels:**
            • **Support:** $145.20 (critical level to watch)
            • **Resistance:** $152.80 (breakout target)
            • **Stop Loss:** $142.50 (risk management)
            
            **Recommendation:** 
            Consider a long position with tight stop loss. Breakout above $152.80 could trigger significant upside momentum. Monitor volume for confirmation.
            """,
            
            """
            📊 **Chart Analysis: Consolidation Phase**
            
            **Pattern Recognition:**
            • **Rectangle Pattern** forming
            • Price oscillating between defined levels
            • Decreasing volatility suggests breakout approaching
            
            **Technical Indicators:**
            • Bollinger Bands: Price near upper band
            • Stochastic: Overbought conditions
            • Volume: Below average, indicating indecision
            
            **Key Levels:**
            • **Upper Boundary:** $168.40
            • **Lower Boundary:** $162.10
            • **Breakout Target:** $175.20 (if bullish)
            
            **Recommendation:**
            Wait for clear breakout direction. Current consolidation suggests major move ahead. Consider straddle options strategy for breakout play.
            """,
            
            """
            ⚠️ **Chart Analysis: Bearish Signals Emerging**
            
            **Pattern Recognition:**
            • **Head and Shoulders** pattern developing
            • Right shoulder forming at resistance
            • Volume declining on rallies
            
            **Technical Indicators:**
            • RSI: 42 (bearish momentum)
            • MACD: Bearish divergence
            • Moving Averages: Death cross potential
            
            **Key Levels:**
            • **Neckline:** $134.50 (critical breakdown level)
            • **Target:** $125.80 (measured move)
            • **Stop Loss:** $138.20 (above right shoulder)
            
            **Recommendation:**
            Exercise caution. Consider reducing position size or implementing protective puts. Breakdown below neckline would confirm bearish pattern.
            """
        ]
        
        return analyses.randomElement() ?? analyses[0]
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}

// MARK: - AI Chat Header
struct AIChatHeader: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var premiumManager = PremiumManager.shared
    private let dailyFreeLimit: Double = 5
    #if DEBUG
    @AppStorage("debug_forceFreeHeader") private var debugForceFreeHeader = false
    #endif
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top Row: Icon, Title, Upgrade
            HStack(spacing: 12) {
                AppRoundedIcon(size: 34)
                    #if DEBUG
                    .onLongPressGesture { debugForceFreeHeader.toggle() }
                    #endif

                Text("ChartSense AI")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .truncationMode(.tail)

                Spacer(minLength: 8)

                AIGradientPillButton(title: premiumManager.isPremium ? "Premium Active" : "Upgrade") {
                    if !premiumManager.isPremium {
                        premiumManager.showPremiumUpgrade()
                    }
                }
            }

            // Metrics – ultra-minimal capsule (always shown; premium displays ∞)
            HStack(spacing: 12) {
                // Chats metric
                HStack(spacing: 6) {
                    Image(systemName: "ellipsis.bubble")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Chats")
                        .font(.system(size: 12, weight: .semibold))
                    Text(premiumManager.isPremium ? "Unlimited" : "\(Int(max(0, premiumManager.aiMessagesRemaining)))/\(Int(dailyFreeLimit))")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)

                // Divider dot
                Circle()
                    .fill(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border)
                    .frame(width: 4, height: 4)

                // Images metric
                HStack(spacing: 6) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Images")
                        .font(.system(size: 12, weight: .semibold))
                    Text(premiumManager.isPremium ? "Unlimited" : "\(Int(max(0, premiumManager.imageAnalysisRemaining)))/1")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryBackground : AppTheme.light.colors.tertiaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(aiGradient, lineWidth: 1)
                            .opacity(0.6)
                    )
            )
            .lineLimit(1)
            .minimumScaleFactor(0.9)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border),
            alignment: .bottom
        )
    }
    
    private var progressValue: Double {
        guard !premiumManager.isPremium else { return 1 }
        let remaining = Double(max(premiumManager.aiMessagesRemaining, 0))
        return min(max(remaining / dailyFreeLimit, 0), 1)
    }
    
    private var shouldShowLimitUI: Bool {
        #if DEBUG
        if debugForceFreeHeader { return true }
        #endif
        return !premiumManager.isPremium
    }
}

// MARK: - AI Chat Avatar
struct AIChatAvatar: View {
    var size: CGFloat = 28
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            
            Image(systemName: "brain.head.profile")
                .font(.system(size: size * 0.5, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Welcome Message
struct WelcomeMessage: View {
    let onAskStock: () -> Void
    let onUploadChart: () -> Void
    let quickActions: [AISuggestion]
    
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 10) {
            // Unified, ultra-clean hero card with two clear actions
            NotionCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("What do you want to do?")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        .lineLimit(2)
                        .truncationMode(.tail)
                    
                    VStack(spacing: 8) {
                        Button(action: onAskStock) {
                            HStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ask about a stock")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                                        .lineLimit(1)
                                     Text("Concise answers with clean visuals")
                                         .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                                         .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(aiGradient)
                            }
                            .padding(10)
                            .background(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryBackground : AppTheme.light.colors.secondaryBackground)
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: onUploadChart) {
                            HStack(spacing: 10) {
                                Image(systemName: "photo")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Upload a chart")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                                        .lineLimit(1)
                                     Text("Get patterns, levels, and a plan")
                                         .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                                         .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(aiGradient)
                            }
                            .padding(10)
                            .background(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryBackground : AppTheme.light.colors.secondaryBackground)
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Compact suggestion row
            HStack(spacing: 6) {
                ForEach(quickActions.prefix(3)) { suggestion in
                    SuggestionChip(title: suggestion.title, icon: suggestion.icon, action: suggestion.action)
                }
            }
        }
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isAppearing = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if message.isUser {
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 6) {
                    // User message
                    MarkdownText(message.content)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                        .cornerRadius(14)
                        .cornerRadius(4, corners: .topLeft)
                        .textSelection(.enabled)
                        .lineSpacing(2)
                    
                    // Timestamp
                    Text(message.timestamp, style: .time)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                    
                    // Error indicator if needed
                    if case .error = message.status {
                        Text("Failed to send")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
                .scaleEffect(isAppearing ? 1.0 : 0.8)
                .opacity(isAppearing ? 1.0 : 0.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isAppearing)
                
            } else {
                // AI Avatar
                AIChatAvatar(size: 28)
                    .frame(width: 28, height: 28)
                
                VStack(alignment: .leading, spacing: 6) {
                    // AI message
                    MarkdownText(message.content)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
                        .cornerRadius(14)
                        .cornerRadius(4, corners: .topRight)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border, lineWidth: 0.5)
                        )
                        .textSelection(.enabled)
                        .lineSpacing(2)
                    
                    // Timestamp
                    Text(message.timestamp, style: .time)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                    
                    // Error indicator if needed
                    if case .error = message.status {
                        Text("Failed to send")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
                .scaleEffect(isAppearing ? 1.0 : 0.8)
                .opacity(isAppearing ? 1.0 : 0.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isAppearing)
                
                Spacer(minLength: 60)
            }
        }
        .onAppear {
            isAppearing = true
        }
        .contextMenu {
            Button(action: { UIPasteboard.general.string = message.content }) {
                Label("Copy", systemImage: "doc.on.doc")
            }
            ShareLink(item: message.content) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }
}

// MARK: - MarkdownText helper
private struct MarkdownText: View {
    let content: String
    
    init(_ content: String) { self.content = content }
    
    var body: some View {
        Group {
            if let attr = try? AttributedString(
                markdown: content,
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
            ) {
                Text(attr)
            } else {
                Text(content)
            }
        }
    }
}

// MARK: - AI Typing Indicator
struct AITypingIndicator: View {
    @State private var dotOffset: CGFloat = 0
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            AIChatAvatar(size: 28)
                .frame(width: 28, height: 28)
            
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                        .frame(width: 6, height: 6)
                        .offset(y: dotOffset)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: dotOffset
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
            .cornerRadius(18)
            .cornerRadius(4, corners: .topRight)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border, lineWidth: 0.5)
            )
            
            Spacer(minLength: 60)
        }
        .onAppear {
            dotOffset = -5
        }
    }
}

// MARK: - Day Divider
private struct DayDivider: View {
    let date: Date
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
    
    var body: some View {
        HStack {
            Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1)
            Text(Self.formatter.string(from: date))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.gray)
                .padding(.horizontal, 8)
            Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Haptics
enum AIHaptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - Modern Chat Input
struct ModernChatInput: View {
    @Binding var text: String
    @FocusState var isFocused: Bool
    let onSend: (String) -> Void
    let suggestions: [AISuggestion]
    let onImageUpload: (() -> Void)?
    
    @StateObject private var themeManager = ThemeManager.shared
    @State private var inputHeight: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 0) {
            // Suggestions (only when empty; ultra-compact)
            if !suggestions.isEmpty && text.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(suggestions) { suggestion in
                            SuggestionChip(title: suggestion.title, icon: "sparkles", action: suggestion.action)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
                .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border),
                    alignment: .top
                )
            }
            
            // Input area
            HStack(spacing: 12) {
                // Minimal upload button
                Button(action: {
                    AIHaptics.light()
                    onImageUpload?()
                }) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryBackground : AppTheme.light.colors.tertiaryBackground)
                        .frame(width: 34, height: 34)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(aiGradient, lineWidth: 1)
                                .opacity(0.8)
                        )
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Text input
                HStack(spacing: 8) {
                    TextField("Ask me anything about stocks...", text: $text, axis: .vertical)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        .focused($isFocused)
                        .lineLimit(1...6)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryBackground : AppTheme.light.colors.tertiaryBackground)
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(isFocused ? AnyShapeStyle(aiGradient) : AnyShapeStyle(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border), lineWidth: isFocused ? 2 : 0.5)
                        )
                        .animation(.easeInOut(duration: 0.2), value: isFocused)
                    
                    // Send button (clean arrow without SF symbol blockiness)
                    Button(action: {
                        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            AIHaptics.light()
                            onSend(text)
                            text = ""
                        }
                    }) {
                        Circle()
                            .fill(text.isEmpty ? AnyShapeStyle(Color.gray.opacity(0.2)) : AnyShapeStyle(aiGradient))
                            .frame(width: 34, height: 34)
                            .overlay(
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .scaleEffect(text.isEmpty ? 0.9 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border),
                alignment: .top
            )
        }
    }
}

// MARK: - Suggestion Chip
struct SuggestionChip: View {
    let title: String
    let icon: String
    let action: (() -> Void)?
    
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isPressed = false
    
    init(title: String, icon: String, action: (() -> Void)? = nil) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            AIHaptics.light()
            action?()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                    .opacity(0.1)
            )
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// Using NotionCard from Components.swift

// Using cornerRadius extension from Components.swift 

// MARK: - AI Gradient Pill Button (local to AI screen)
struct AIGradientPillButton: View {
    let title: String
    let action: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 11, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(aiGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: Color.blue.opacity(0.25), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
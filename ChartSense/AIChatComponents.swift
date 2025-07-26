import SwiftUI
import Combine
import PhotosUI

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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            AIChatHeader()
            
            // Messages
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Welcome message
                    if viewModel.messages.isEmpty {
                        WelcomeMessage()
                    }
                    
                    // Chat messages
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    
                    // Loading indicator
                    if viewModel.isTyping {
                        AITypingIndicator()
                            .id("typing")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .onChange(of: viewModel.messages.count) { _ in
                // Auto-scroll to bottom when new messages arrive
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        // Scroll to bottom
                    }
                }
            }
            .onChange(of: viewModel.isTyping) { isTyping in
                if isTyping {
                    // Auto-scroll to bottom when typing starts
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            // Scroll to bottom
                        }
                    }
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
    @StateObject private var webSocketService = WebSocketService.shared
    @StateObject private var premiumManager = PremiumManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // AI Avatar
            AIChatAvatar()
            
            VStack(alignment: .leading, spacing: 2) {
                Text("ChartSense AI")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(aiStatusColor)
                        .frame(width: 6, height: 6)
                    
                    Text(aiStatusText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                }
            }
            
            Spacer()
            
            // Premium indicator (for free users)
            if !premiumManager.isPremium {
                HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "message.circle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    
                        Text("\(premiumManager.aiMessagesRemaining)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                        
                        Text("\(premiumManager.imageAnalysisRemaining)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryBackground : AppTheme.light.colors.tertiaryBackground)
                .cornerRadius(8)
            }
            
            // Connection status
            ConnectionStatusView()
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
    }
    
    private var aiStatusColor: Color {
        switch webSocketService.connectionStatus {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .disconnected, .error:
            return .red
        }
    }
    
    private var aiStatusText: String {
        switch webSocketService.connectionStatus {
        case .connected:
            return "Online"
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Offline"
        case .error:
            return "Error"
        }
    }
}

// MARK: - AI Chat Avatar
struct AIChatAvatar: View {
    @State private var isAnimating = false
    
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
                .frame(width: 36, height: 36)
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
            
            Image(systemName: "brain.head.profile")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Welcome Message
struct WelcomeMessage: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Welcome card
            NotionCard {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Text("Welcome to ChartSense AI")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    }
                    
                    Text("I'm your AI financial assistant. I can help you analyze stocks, explain charts, and provide investment insights. What would you like to know?")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                        .multilineTextAlignment(.leading)
                }
            }
            
            // Image analysis feature card
            NotionCard {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.purple)
                        
                        Text("Chart Analysis")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    }
                    
                    Text("Upload a screenshot of any chart and I'll provide detailed technical analysis, pattern recognition, and trading recommendations.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                        .multilineTextAlignment(.leading)
                }
            }
            
            // Quick suggestions
            VStack(spacing: 8) {
                Text("Try asking:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                
                HStack(spacing: 8) {
                    SuggestionChip(title: "Analyze AAPL", icon: "chart.line.uptrend.xyaxis")
                    SuggestionChip(title: "Market trends", icon: "chart.bar.fill")
                }
                
                HStack(spacing: 8) {
                    SuggestionChip(title: "Upload chart", icon: "camera.viewfinder") {
                        // This will be handled by the parent view
                    }
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
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 4) {
                    // User message
                    Text(message.content)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(18)
                        .cornerRadius(4, corners: .topLeft)
                    
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
                AIChatAvatar()
                    .frame(width: 28, height: 28)
                
                VStack(alignment: .leading, spacing: 4) {
                    // AI message
                    Text(message.content)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
                        .cornerRadius(18)
                        .cornerRadius(4, corners: .topRight)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border, lineWidth: 0.5)
                        )
                    
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
    }
}

// MARK: - AI Typing Indicator
struct AITypingIndicator: View {
    @State private var dotOffset: CGFloat = 0
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            AIChatAvatar()
                .frame(width: 28, height: 28)
            
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.gray)
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
            .background(Color(.systemGray6))
            .cornerRadius(18)
            .cornerRadius(4, corners: .topRight)
            
            Spacer(minLength: 60)
        }
        .onAppear {
            dotOffset = -5
        }
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
            // Suggestions
            if !suggestions.isEmpty && text.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestions) { suggestion in
                            SuggestionChip(
                                title: suggestion.title,
                                icon: suggestion.icon,
                                action: suggestion.action
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
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
                // Image upload button
                Button(action: {
                    onImageUpload?()
                }) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill((themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary).opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Text input
                HStack(spacing: 8) {
                    TextField("Ask me anything about stocks...", text: $text, axis: .vertical)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                        .focused($isFocused)
                        .lineLimit(1...4)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryBackground : AppTheme.light.colors.tertiaryBackground)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    isFocused ? Color.blue : (themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border),
                                    lineWidth: isFocused ? 2 : 0.5
                                )
                        )
                        .animation(.easeInOut(duration: 0.2), value: isFocused)
                    
                    // Send button
                    Button(action: {
                        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onSend(text)
                            text = ""
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(text.isEmpty ? Color.gray : Color.blue)
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .scaleEffect(text.isEmpty ? 0.9 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
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
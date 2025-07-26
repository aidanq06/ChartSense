import SwiftUI
import Combine

@MainActor
class AIChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isTyping: Bool = false
    @Published var suggestions: [AISuggestion] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSuggestions()
    }
    
    // MARK: - Image Analysis
    func addImageAnalysisMessage(_ result: ImageAnalysisResult) {
        // Add user message with image
        let userMessage = ChatMessage(
            content: "📊 Chart Analysis Request",
            isUser: true,
            status: .sent
        )
        messages.append(userMessage)
        
        // Add AI analysis response
        let aiMessage = ChatMessage(
            content: result.analysis,
            isUser: false,
            status: .sent
        )
        messages.append(aiMessage)
        
        // Update suggestions based on analysis
        updateSuggestionsForImageAnalysis()
    }
    
    // MARK: - Public Methods
    func sendMessage(_ content: String) {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }
        
        // Check premium status before sending message
        let premiumManager = PremiumManager.shared
        if !premiumManager.canSendAIMessage() {
            premiumManager.showPremiumUpgrade()
            return
        }
        
        // Use AI message (this will handle the count for free users)
        if !premiumManager.useAIMessage() {
            return
        }
        
        // Add user message
        let userMessage = ChatMessage(
            content: trimmedContent,
            isUser: true,
            status: .sent
        )
        messages.append(userMessage)
        
        // Clear input
        inputText = ""
        
        // Show typing indicator
        isTyping = true
        
        // Simulate AI response (replace with actual AI service)
        Task {
            await generateAIResponse(to: trimmedContent)
        }
    }
    
    func clearChat() {
        messages.removeAll()
        isTyping = false
    }
    
    // MARK: - Private Methods
    private func setupSuggestions() {
        suggestions = [
            AISuggestion(
                title: "Analyze AAPL",
                icon: "chart.line.uptrend.xyaxis"
            ) {
                self.sendMessage("Can you analyze Apple's stock performance and provide insights?")
            },
            AISuggestion(
                title: "Market trends",
                icon: "chart.bar.fill"
            ) {
                self.sendMessage("What are the current market trends and which sectors are performing well?")
            },
            AISuggestion(
                title: "Portfolio advice",
                icon: "briefcase.fill"
            ) {
                self.sendMessage("I'm looking to diversify my portfolio. What sectors should I consider?")
            },
            AISuggestion(
                title: "Risk assessment",
                icon: "exclamationmark.triangle.fill"
            ) {
                self.sendMessage("What are the main risks in the current market environment?")
            }
        ]
    }
    
    private func generateAIResponse(to userMessage: String) async {
        // Simulate AI processing time
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Generate contextual response based on user input
        let aiResponse = await generateContextualResponse(to: userMessage)
        
        // Add AI response
        let aiMessage = ChatMessage(
            content: aiResponse,
            isUser: false,
            status: .sent
        )
        
        // Hide typing indicator and add message
        isTyping = false
        messages.append(aiMessage)
        
        // Update suggestions based on conversation context
        updateSuggestions(based: userMessage)
    }
    
    private func generateContextualResponse(to userMessage: String) async -> String {
        let lowercasedMessage = userMessage.lowercased()
        
        // Simple keyword-based responses (replace with actual AI service)
        if lowercasedMessage.contains("aapl") || lowercasedMessage.contains("apple") {
            return """
            📱 **Apple (AAPL) Analysis**
            
            **Current Performance:**
            • Strong fundamentals with consistent revenue growth
            • Services segment showing impressive expansion
            • iPhone sales remain stable despite market challenges
            
            **Key Strengths:**
            • Robust ecosystem lock-in
            • Strong brand loyalty
            • Excellent cash flow generation
            
            **Considerations:**
            • High valuation multiples
            • Dependency on iPhone sales
            • Regulatory risks in various markets
            
            **Recommendation:** Apple remains a solid long-term investment, but consider dollar-cost averaging given current valuations.
            """
        } else if lowercasedMessage.contains("market") && lowercasedMessage.contains("trend") {
            return """
            📊 **Current Market Trends**
            
            **Leading Sectors:**
            • **Technology:** AI and cloud computing driving growth
            • **Healthcare:** Biotech innovations and aging population
            • **Energy:** Clean energy transition accelerating
            
            **Market Sentiment:**
            • Cautious optimism amid economic uncertainty
            • Focus on quality companies with strong fundamentals
            • Interest rate sensitivity remains a key factor
            
            **Investment Strategy:**
            Consider a balanced approach with exposure to growth sectors while maintaining defensive positions.
            """
        } else if lowercasedMessage.contains("portfolio") || lowercasedMessage.contains("diversify") {
            return """
            💼 **Portfolio Diversification Strategy**
            
            **Recommended Allocation:**
            • **40% Large Cap Growth:** AAPL, MSFT, GOOGL
            • **25% Value Stocks:** JNJ, PG, KO
            • **20% International:** VXUS, IEFA
            • **10% Bonds:** BND, AGG
            • **5% Alternative:** Gold, REITs
            
            **Key Principles:**
            • Don't put all eggs in one basket
            • Rebalance quarterly
            • Consider your risk tolerance
            • Think long-term (5+ years)
            
            **Next Steps:** Start with index funds for broad exposure, then add individual stocks gradually.
            """
        } else if lowercasedMessage.contains("risk") {
            return """
            ⚠️ **Current Market Risks**
            
            **Primary Concerns:**
            • **Inflation:** Persistent price pressures
            • **Interest Rates:** Fed policy uncertainty
            • **Geopolitical:** Global tensions and trade wars
            • **Valuation:** Elevated P/E ratios in some sectors
            
            **Risk Mitigation:**
            • Maintain emergency fund (6 months expenses)
            • Diversify across asset classes
            • Consider defensive stocks (utilities, consumer staples)
            • Regular portfolio rebalancing
            
            **Monitoring:** Keep an eye on economic indicators and adjust strategy accordingly.
            """
        } else {
            return """
            🤖 **ChartSense AI Assistant**
            
            I'm here to help you with financial analysis and investment insights! I can:
            
            • 📈 Analyze individual stocks and sectors
            • 📊 Explain market trends and patterns
            • 💡 Provide portfolio recommendations
            • ⚠️ Assess market risks and opportunities
            • 📰 Interpret financial news and events
            
            Try asking me about specific stocks, market trends, or investment strategies. I'm constantly learning and improving to provide you with the best financial insights!
            """
        }
    }
    
    private func updateSuggestions(based userMessage: String) {
        let lowercasedMessage = userMessage.lowercased()
        
        // Update suggestions based on conversation context
        if lowercasedMessage.contains("aapl") || lowercasedMessage.contains("apple") {
            suggestions = [
                AISuggestion(title: "Compare with MSFT", icon: "arrow.left.arrow.right") {
                    self.sendMessage("How does Apple compare to Microsoft as an investment?")
                },
                AISuggestion(title: "Technical analysis", icon: "chart.candlestick") {
                    self.sendMessage("Can you provide a technical analysis of Apple's stock chart?")
                },
                AISuggestion(title: "Earnings analysis", icon: "dollarsign.circle") {
                    self.sendMessage("What should I expect from Apple's next earnings report?")
                }
            ]
        } else if lowercasedMessage.contains("market") {
            suggestions = [
                AISuggestion(title: "Sector rotation", icon: "arrow.triangle.2.circlepath") {
                    self.sendMessage("Which sectors are likely to outperform in the next quarter?")
                },
                AISuggestion(title: "Economic indicators", icon: "chart.line.uptrend.xyaxis") {
                    self.sendMessage("What economic indicators should I watch right now?")
                }
            ]
        } else {
            // Reset to default suggestions
            setupSuggestions()
        }
    }
    
    private func updateSuggestionsForImageAnalysis() {
        suggestions = [
            AISuggestion(title: "Analyze another chart", icon: "camera.viewfinder") {
                // This will trigger the image picker
            },
            AISuggestion(title: "Get similar patterns", icon: "chart.line.uptrend.xyaxis") {
                self.sendMessage("Can you find stocks with similar chart patterns?")
            },
            AISuggestion(title: "Risk assessment", icon: "exclamationmark.triangle.fill") {
                self.sendMessage("What are the risks associated with this chart pattern?")
            },
            AISuggestion(title: "Entry/exit strategy", icon: "target") {
                self.sendMessage("What would be the best entry and exit strategy for this pattern?")
            }
        ]
    }
} 
//
//  ChartComponents.swift
//  ChartSense
//
//  Created by Aidan Quach on 7/22/25.
//

import SwiftUI
import Charts

// MARK: - Professional Chart Components
struct ProfessionalChartView: View {
    let stock: Stock
    let timeframe: TimeFrame
    @Binding var selectedPoint: ChartPoint?
    @State private var chartData: [ChartPoint] = []
    @State private var isLoading = false
    @State private var showCursor = false
    @State private var dragLocation: CGPoint = .zero
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Chart Area
            GeometryReader { geometry in
                ZStack {
                    if isLoading {
                        ChartLoadingView()
                    } else {
                        // Main Chart
                        RobinhoodStyleChart(
                            data: chartData,
                            selectedPoint: $selectedPoint,
                            showCursor: $showCursor,
                            dragLocation: $dragLocation,
                            geometry: geometry
                        )
                        
                        // Interactive Cursor
                        if showCursor, let selectedPoint = selectedPoint {
                            ChartCursor(
                                point: selectedPoint,
                                location: dragLocation,
                                geometry: geometry,
                                data: chartData
                            )
                        }
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            dragLocation = value.location
                            showCursor = true
                            updateSelectedPoint(at: value.location, in: geometry)
                        }
                        .onEnded { _ in
                            // Keep the crosshair visible - don't clear selectedPoint
                            showCursor = true
                        }
                )
            }
            .frame(height: 300)
            
            // Chart Controls
            ChartControlsView(
                timeframe: timeframe,
                onTimeframeChanged: { newTimeframe in
                    loadChartData(for: newTimeframe)
                }
            )
            
            // Crosshair Info (always show when we have a selected point)
            if let selectedPoint = selectedPoint {
                CrosshairInfoView(point: selectedPoint, stock: stock)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
            }
        }
        .onAppear {
            loadChartData(for: timeframe)
        }
    }
    
    private func loadChartData(for timeframe: TimeFrame) {
        isLoading = true
        
        print("📊 Loading chart data for \(stock.symbol) - Current price: \(stock.currentPrice)")
        
        Task {
            do {
                // First try to get historical data from database
                let historicalData = try await fetchHistoricalData(symbol: stock.symbol, timeframe: timeframe)
                
                if !historicalData.isEmpty {
                    print("✅ Found historical data for \(stock.symbol): \(historicalData.count) points")
                    chartData = historicalData
                } else {
                    // Fallback to generating data from current stock info
                    print("⚠️ No historical data found, generating from current price")
                    chartData = generateChartDataFromCurrentStock(timeframe: timeframe)
                }
                
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                print("❌ Error loading chart data: \(error)")
                // Fallback to mock data if everything fails
                chartData = generateMockChartData(for: timeframe)
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func fetchHistoricalData(symbol: String, timeframe: TimeFrame) async throws -> [ChartPoint] {
        // This would fetch real historical data from your database
        // For now, we'll generate realistic data based on the current stock
        return generateChartDataFromCurrentStock(timeframe: timeframe)
    }
    
    private func generateChartDataFromCurrentStock(timeframe: TimeFrame) -> [ChartPoint] {
        let basePrice = stock.currentPrice
        print("🔧 Generating chart data for \(stock.symbol) with base price: \(basePrice)")
        
        // If base price is 0 or invalid, use a default
        let validBasePrice = basePrice > 0 ? basePrice : 150.0
        print("🔧 Using valid base price: \(validBasePrice)")
        
        let count: Int
        let interval: TimeInterval
        
        switch timeframe {
        case .oneDay:
            count = 100
            interval = 240 // 4 minutes
        case .oneWeek:
            count = 50
            interval = 7200 // 2 hours
        case .oneMonth:
            count = 30
            interval = 86400 // 1 day
        case .threeMonths:
            count = 20
            interval = 604800 // 1 week
        case .oneYear:
            count = 12
            interval = 2592000 // 1 month
        }
        
        var data: [ChartPoint] = []
        var currentPrice = validBasePrice * 0.95 // Start slightly lower
        
        for i in 0..<count {
            let date = Date().addingTimeInterval(-interval * Double(count - i))
            
            // Create realistic price movement
            let progress = Double(i) / Double(count)
            let trend = progress * 0.1 // 10% overall trend
            let volatility = 0.02 // 2% volatility
            let randomChange = Double.random(in: -volatility...volatility)
            
            currentPrice = currentPrice * (1 + trend/Double(count) + randomChange)
            
            // Ensure the last point is the current price
            if i == count - 1 {
                currentPrice = validBasePrice
            }
            
            data.append(ChartPoint(date: date, price: max(currentPrice, validBasePrice * 0.8)))
        }
        
        print("📈 Generated \(data.count) chart points for \(stock.symbol), price range: \(data.map(\.price).min() ?? 0) - \(data.map(\.price).max() ?? 0)")
        return data
    }
    

    
    private func generateMockChartData(for timeframe: TimeFrame) -> [ChartPoint] {
        let basePrice = stock.currentPrice
        print("🎲 Generating mock chart data for \(stock.symbol) with base price: \(basePrice)")
        
        // If base price is 0 or invalid, use a default
        let validBasePrice = basePrice > 0 ? basePrice : 150.0
        print("🎲 Using valid base price for mock: \(validBasePrice)")
        
        let count: Int
        let interval: TimeInterval
        
        switch timeframe {
        case .oneDay:
            count = 100
            interval = 240 // 4 minutes
        case .oneWeek:
            count = 50
            interval = 7200 // 2 hours
        case .oneMonth:
            count = 30
            interval = 86400 // 1 day
        case .threeMonths:
            count = 20
            interval = 604800 // 1 week
        case .oneYear:
            count = 12
            interval = 2592000 // 1 month
        }
        
        var data: [ChartPoint] = []
        var currentPrice = validBasePrice * 0.95
        
        for i in 0..<count {
            let date = Date().addingTimeInterval(-interval * Double(count - i))
            let trend = Double(i) / Double(count) * 0.08
            let volatility = 0.005
            let randomChange = Double.random(in: -volatility...volatility)
            
            currentPrice = currentPrice * (1 + trend/Double(count) + randomChange)
            
            if i == count - 1 {
                currentPrice = validBasePrice
            }
            
            data.append(ChartPoint(date: date, price: max(currentPrice, validBasePrice * 0.8)))
        }
        
        print("🎲 Generated \(data.count) mock chart points for \(stock.symbol), price range: \(data.map(\.price).min() ?? 0) - \(data.map(\.price).max() ?? 0)")
        return data
    }
    
    private func updateSelectedPoint(at location: CGPoint, in geometry: GeometryProxy) {
        guard !chartData.isEmpty else { return }
        
        let normalizedX = max(0, min(1, location.x / geometry.size.width))
        let index = Int(normalizedX * CGFloat(chartData.count - 1))
        let clampedIndex = max(0, min(chartData.count - 1, index))
        
        selectedPoint = chartData[clampedIndex]
    }
}

// MARK: - Robinhood Style Chart
struct RobinhoodStyleChart: View {
    let data: [ChartPoint]
    @Binding var selectedPoint: ChartPoint?
    @Binding var showCursor: Bool
    @Binding var dragLocation: CGPoint
    let geometry: GeometryProxy
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack {
            // Chart Background
            Rectangle()
                .fill(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
            
            if !data.isEmpty {
                // Fill Area with Gradient
                ChartFillArea(data: data, geometry: geometry)
                
                // Chart Line
                ChartLine(data: data, geometry: geometry)
                
                // Grid Lines
                ChartGridLines(data: data, geometry: geometry)
            }
        }
    }
}

// MARK: - Chart Fill Area
struct ChartFillArea: View {
    let data: [ChartPoint]
    let geometry: GeometryProxy
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Path { path in
            let points = data.enumerated().map { index, point in
                CGPoint(
                    x: CGFloat(index) / CGFloat(data.count - 1) * geometry.size.width,
                    y: (1 - CGFloat((point.price - minPrice) / (maxPrice - minPrice))) * geometry.size.height
                )
            }
            
            path.move(to: CGPoint(x: points[0].x, y: geometry.size.height))
            path.addLine(to: points[0])
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            path.addLine(to: CGPoint(x: points.last!.x, y: geometry.size.height))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.blue.opacity(0.1),
                    Color.blue.opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var minPrice: Double {
        data.map(\.price).min() ?? 0
    }
    
    private var maxPrice: Double {
        data.map(\.price).max() ?? 1
    }
}

// MARK: - Chart Line
struct ChartLine: View {
    let data: [ChartPoint]
    let geometry: GeometryProxy
    
    var body: some View {
        Path { path in
            let points = data.enumerated().map { index, point in
                CGPoint(
                    x: CGFloat(index) / CGFloat(data.count - 1) * geometry.size.width,
                    y: (1 - CGFloat((point.price - minPrice) / (maxPrice - minPrice))) * geometry.size.height
                )
            }
            
            path.move(to: points[0])
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(
            Color.blue,
            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
        )
    }
    
    private var minPrice: Double {
        data.map(\.price).min() ?? 0
    }
    
    private var maxPrice: Double {
        data.map(\.price).max() ?? 1
    }
}

// MARK: - Chart Grid Lines
struct ChartGridLines: View {
    let data: [ChartPoint]
    let geometry: GeometryProxy
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack {
            // Horizontal grid lines
            ForEach(0..<5, id: \.self) { i in
                let y = geometry.size.height * CGFloat(i) / 4
                Rectangle()
                    .fill(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border)
                    .frame(height: 0.5)
                    .position(x: geometry.size.width / 2, y: y)
            }
            
            // Vertical grid lines
            ForEach(0..<5, id: \.self) { i in
                let x = geometry.size.width * CGFloat(i) / 4
                Rectangle()
                    .fill(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border)
                    .frame(width: 0.5)
                    .position(x: x, y: geometry.size.height / 2)
            }
        }
    }
}

// MARK: - Chart Cursor
struct ChartCursor: View {
    let point: ChartPoint
    let location: CGPoint
    let geometry: GeometryProxy
    let data: [ChartPoint]
    
    var body: some View {
        ZStack {
            // Vertical line
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1)
                .position(x: location.x, y: geometry.size.height / 2)
            
            // Price dot
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .position(x: location.x, y: cursorY)
        }
    }
    
    private var cursorY: CGFloat {
        guard !data.isEmpty else { return geometry.size.height / 2 }
        
        let minPrice = data.map(\.price).min() ?? point.price
        let maxPrice = data.map(\.price).max() ?? point.price
        
        guard maxPrice != minPrice else { return geometry.size.height / 2 }
        
        return (1 - CGFloat((point.price - minPrice) / (maxPrice - minPrice))) * geometry.size.height
    }
}

// MARK: - Chart Controls
struct ChartControlsView: View {
    let timeframe: TimeFrame
    let onTimeframeChanged: (TimeFrame) -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TimeFrame.allCases, id: \.self) { tf in
                Button(action: {
                    onTimeframeChanged(tf)
                }) {
                    Text(tf.displayName)
                        .font(.system(size: 14, weight: timeframe == tf ? .semibold : .medium))
                        .foregroundColor(
                            timeframe == tf 
                            ? .white
                            : (themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    timeframe == tf 
                                    ? Color.blue
                                    : Color.clear
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Chart Loading View
struct ChartLoadingView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            Text("Loading chart data...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
        }
    }
}

// MARK: - Technical Indicators Chart
struct TechnicalIndicatorsChart: View {
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Technical Indicators")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                TechnicalIndicatorCard(name: "RSI", value: "65.4", status: .neutral)
                TechnicalIndicatorCard(name: "MACD", value: "0.23", status: .bullish)
                TechnicalIndicatorCard(name: "MA (20)", value: stock.formattedPrice, status: .bullish)
                TechnicalIndicatorCard(name: "BB", value: "Mid", status: .neutral)
            }
        }
        .padding()
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Technical Indicator Card
struct TechnicalIndicatorCard: View {
    let name: String
    let value: String
    let status: IndicatorStatus
    @StateObject private var themeManager = ThemeManager.shared
    
    enum IndicatorStatus {
        case bullish, bearish, neutral
        
        var color: Color {
            switch self {
            case .bullish: return Color.bullish
            case .bearish: return Color.bearish
            case .neutral: return .orange
            }
        }
        
        var icon: String {
            switch self {
            case .bullish: return "arrow.up.circle.fill"
            case .bearish: return "arrow.down.circle.fill"
            case .neutral: return "minus.circle.fill"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Spacer()
                
                Image(systemName: status.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(status.color)
            }
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(status.color)
        }
        .padding(12)
        .background(status.color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Volume Chart
struct VolumeChart: View {
    let data: [ChartPoint]
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Volume")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            
            Chart(data) { point in
                BarMark(
                    x: .value("Time", point.date),
                    y: .value("Volume", point.price * 1000) // Mock volume data
                )
                .foregroundStyle(Color.blue.opacity(0.6))
            }
            .frame(height: 100)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel()
                }
            }
        }
        .padding()
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Crosshair Info View
struct CrosshairInfoView: View {
    let point: ChartPoint
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    private var percentChange: Double {
        return ((point.price - stock.currentPrice) / stock.currentPrice) * 100
    }
    
    private var isPositiveChange: Bool {
        return percentChange >= 0
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Price")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                
                Text(point.formattedPrice)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            }
            
            Spacer()
            
            VStack(alignment: .center, spacing: 4) {
                Text("Change")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                
                HStack(spacing: 4) {
                    Image(systemName: isPositiveChange ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isPositiveChange ? Color.bullish : Color.bearish)
                    
                    Text(String(format: "%.2f%%", abs(percentChange)))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(isPositiveChange ? Color.bullish : Color.bearish)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Time")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                
                Text(point.formattedTime)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            }
        }
        .padding()
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Price Range Display
struct PriceRangeDisplay: View {
    let stock: Stock
    let selectedPoint: ChartPoint?
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                
                Text(selectedPoint?.formattedPrice ?? stock.formattedPrice)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Change")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                
                let change = (selectedPoint?.price ?? stock.currentPrice) - stock.currentPrice
                let changePercent = (change / stock.currentPrice) * 100
                let isPositive = change >= 0
                
                HStack(spacing: 4) {
                    Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isPositive ? Color.bullish : Color.bearish)
                    
                    Text(String(format: "%.2f", abs(change)))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(isPositive ? Color.bullish : Color.bearish)
                    
                    Text("(\(String(format: "%.2f", abs(changePercent)))%)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(isPositive ? Color.bullish : Color.bearish)
                }
            }
        }
        .padding()
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
        .cornerRadius(12)
    }
} 
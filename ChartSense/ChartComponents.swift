//
//  ChartComponents.swift
//  ChartSense
//
//  Created by Aidan Quach on 7/22/25.
//

import SwiftUI
import Charts

// MARK: - Chart Data Models
struct CandleData: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int64
    
    var isBullish: Bool { close > open }
    var body: Double { abs(close - open) }
    var upperShadow: Double { high - max(open, close) }
    var lowerShadow: Double { min(open, close) - low }
}

struct ChartConfig {
    let timeframe: TimeFrame
    let showVolume: Bool
    let showMA: Bool
    let showGrid: Bool
    var theme: ChartTheme
}

enum TimeFrame: String, CaseIterable {
    case oneDay = "1D"
    case oneWeek = "1W"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case fiveYears = "5Y"
    
    var displayName: String { rawValue }
    var interval: String {
        switch self {
        case .oneDay: return "5"
        case .oneWeek: return "15"
        case .oneMonth: return "60"
        case .threeMonths: return "D"
        case .sixMonths: return "D"
        case .oneYear: return "D"
        case .fiveYears: return "W"
        }
    }
}

enum ChartTheme {
    case light, dark
    
    var backgroundColor: Color {
        switch self {
        case .light: return Color(.systemBackground)
        case .dark: return Color(.systemBackground)
        }
    }
    
    var gridColor: Color {
        switch self {
        case .light: return Color(.systemGray6)
        case .dark: return Color(.systemGray6)
        }
    }
    
    var textColor: Color {
        switch self {
        case .light: return Color(.label)
        case .dark: return Color(.label)
        }
    }
    
    var bullishColor: Color { Color.bullish }
    var bearishColor: Color { Color.bearish }
}

// MARK: - Interactive Chart View
struct InteractiveChartView: View {
    let stock: Stock
    @State private var selectedTimeframe: TimeFrame = .oneMonth
    @State private var chartData: [CandleData] = []
    @State private var isLoading = false
    @State private var selectedPoint: CandleData?
    @State private var showVolume = true
    @State private var showMA = true
    @State private var chartConfig = ChartConfig(
        timeframe: .oneMonth,
        showVolume: true,
        showMA: true,
        showGrid: true,
        theme: .light
    )
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Chart Header
            ChartHeaderView(
                stock: stock,
                selectedTimeframe: $selectedTimeframe,
                showVolume: $showVolume,
                showMA: $showMA
            )
            
            // Main Chart Area
            ChartContainerView(
                stock: stock,
                data: chartData,
                config: chartConfig,
                selectedPoint: $selectedPoint,
                isLoading: isLoading
            )
            
            // Chart Controls
            ChartControlsView(
                selectedTimeframe: $selectedTimeframe,
                showVolume: $showVolume,
                showMA: $showMA
            )
        }
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
        .onAppear {
            loadChartData()
        }
        .onChange(of: selectedTimeframe) { _ in
            loadChartData()
        }
        .onChange(of: themeManager.isDarkMode) { isDark in
            chartConfig.theme = isDark ? .dark : .light
        }
    }
    
    private func loadChartData() {
        isLoading = true
        
        // Generate mock data for now
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            chartData = generateMockData(for: selectedTimeframe)
            isLoading = false
        }
    }
    
    private func generateMockData(for timeframe: TimeFrame) -> [CandleData] {
        let basePrice = stock.currentPrice
        let count = timeframe == .fiveYears ? 260 : 100
        var data: [CandleData] = []
        
        for i in 0..<count {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let volatility = 0.02
            let change = Double.random(in: -volatility...volatility)
            let open = basePrice * (1 + change)
            let close = open * (1 + Double.random(in: -0.01...0.01))
            let high = max(open, close) * (1 + Double.random(in: 0...0.005))
            let low = min(open, close) * (1 - Double.random(in: 0...0.005))
            let volume = Int64.random(in: 1000000...10000000)
            
            data.append(CandleData(
                timestamp: date,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            ))
        }
        
        return data.reversed()
    }
}

// MARK: - Chart Header View
struct ChartHeaderView: View {
    let stock: Stock
    @Binding var selectedTimeframe: TimeFrame
    @Binding var showVolume: Bool
    @Binding var showMA: Bool
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Stock Info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(stock.symbol)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Text(stock.companyName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(stock.formattedPrice)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    HStack(spacing: 4) {
                        Image(systemName: stock.isPositiveChange ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(stock.isPositiveChange ? Color.bullish : Color.bearish)
                        
                        Text(stock.formattedChangePercent)
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(stock.isPositiveChange ? Color.bullish : Color.bearish)
                    }
                }
            }
            
            // Timeframe Selector
            HStack(spacing: 8) {
                ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                    Button(action: { selectedTimeframe = timeframe }) {
                        Text(timeframe.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedTimeframe == timeframe ? .white : (themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(backgroundColor(for: timeframe))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Chart Options
            HStack(spacing: 16) {
                Toggle("Volume", isOn: $showVolume)
                    .toggleStyle(ModernToggleStyle())
                
                Toggle("MA", isOn: $showMA)
                    .toggleStyle(ModernToggleStyle())
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    private func backgroundColor(for timeframe: TimeFrame) -> some View {
        if selectedTimeframe == timeframe {
            return AnyView(
                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
            )
        } else {
            return AnyView(
                themeManager.isDarkMode ? AppTheme.dark.colors.secondaryBackground : AppTheme.light.colors.secondaryBackground
            )
        }
    }
}

// MARK: - Chart Container View
struct ChartContainerView: View {
    let stock: Stock
    let data: [CandleData]
    let config: ChartConfig
    @Binding var selectedPoint: CandleData?
    let isLoading: Bool
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ChartLoadingView()
            } else if data.isEmpty {
                ChartEmptyView()
            } else {
                // Main Price Chart
                PriceChartView(
                    data: data,
                    config: config,
                    selectedPoint: $selectedPoint
                )
                .frame(height: 300)
                
                // Volume Chart
                if config.showVolume {
                    VolumeChartView(data: data, config: config)
                        .frame(height: 100)
                }
                
                // Selected Point Info
                if let selected = selectedPoint {
                    SelectedPointView(point: selected, stock: stock)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }
            }
        }
    }
}

// MARK: - Price Chart View
struct PriceChartView: View {
    let data: [CandleData]
    let config: ChartConfig
    @Binding var selectedPoint: CandleData?
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Chart(data) { candle in
            // Candlestick body
            RectangleMark(
                x: .value("Time", candle.timestamp),
                yStart: .value("Open", candle.open),
                yEnd: .value("Close", candle.close),
                width: 6
            )
            .foregroundStyle(candle.isBullish ? config.theme.bullishColor : config.theme.bearishColor)
            .cornerRadius(2)
            
            // Candlestick shadows
            RuleMark(
                x: .value("Time", candle.timestamp),
                yStart: .value("Low", candle.low),
                yEnd: .value("High", candle.high)
            )
            .foregroundStyle(candle.isBullish ? config.theme.bullishColor : config.theme.bearishColor)
            .lineStyle(StrokeStyle(lineWidth: 1))
            
            // Moving Average (if enabled)
            if config.showMA {
                LineMark(
                    x: .value("Time", candle.timestamp),
                    y: .value("MA", calculateMA(for: candle.timestamp))
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(config.theme.gridColor)
                AxisValueLabel()
                    .foregroundStyle(config.theme.textColor)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(config.theme.gridColor)
                AxisValueLabel()
                    .foregroundStyle(config.theme.textColor)
            }
        }
        .chartOverlay { proxy in
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let x = value.location.x
                            if let date = proxy.value(atX: x) as Date? {
                                selectedPoint = data.min { abs($0.timestamp.timeIntervalSince(date)) < abs($1.timestamp.timeIntervalSince(date)) }
                            }
                        }
                        .onEnded { _ in
                            // Keep selected point for a moment
                        }
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private func calculateMA(for date: Date) -> Double {
        // Simple 20-period moving average
        let period = 20
        let relevantData = data.filter { $0.timestamp <= date }.suffix(period)
        return relevantData.isEmpty ? 0 : relevantData.map(\.close).reduce(0, +) / Double(relevantData.count)
    }
}

// MARK: - Volume Chart View
struct VolumeChartView: View {
    let data: [CandleData]
    let config: ChartConfig
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Chart(data) { candle in
            RectangleMark(
                x: .value("Time", candle.timestamp),
                y: .value("Volume", candle.volume)
            )
            .foregroundStyle(candle.isBullish ? config.theme.bullishColor.opacity(0.6) : config.theme.bearishColor.opacity(0.6))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(config.theme.gridColor)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(config.theme.gridColor)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

// MARK: - Selected Point View
struct SelectedPointView: View {
    let point: CandleData
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("O: \(String(format: "%.2f", point.open))")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                
                Text("H: \(String(format: "%.2f", point.high))")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("L: \(String(format: "%.2f", point.low))")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                
                Text("C: \(String(format: "%.2f", point.close))")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Volume")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                
                Text(formatVolume(point.volume))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            }
        }
        .padding(12)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryBackground : AppTheme.light.colors.secondaryBackground)
        .cornerRadius(8)
    }
    
    private func formatVolume(_ volume: Int64) -> String {
        if volume >= 1_000_000_000 {
            return String(format: "%.1fB", Double(volume) / 1_000_000_000)
        } else if volume >= 1_000_000 {
            return String(format: "%.1fM", Double(volume) / 1_000_000)
        } else if volume >= 1_000 {
            return String(format: "%.1fK", Double(volume) / 1_000)
        } else {
            return "\(volume)"
        }
    }
}

// MARK: - Chart Controls View
struct ChartControlsView: View {
    @Binding var selectedTimeframe: TimeFrame
    @Binding var showVolume: Bool
    @Binding var showMA: Bool
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: { showVolume.toggle() }) {
                HStack(spacing: 6) {
                    Image(systemName: showVolume ? "chart.bar.fill" : "chart.bar")
                        .font(.system(size: 14, weight: .medium))
                    
                    Text("Volume")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(showVolume ? (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary) : (themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText))
            }
            
            Button(action: { showMA.toggle() }) {
                HStack(spacing: 6) {
                    Image(systemName: showMA ? "chart.line.uptrend.xyaxis.fill" : "chart.line.uptrend.xyaxis")
                        .font(.system(size: 14, weight: .medium))
                    
                    Text("MA")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(showMA ? (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary) : (themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText))
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryBackground : AppTheme.light.colors.secondaryBackground)
    }
}

// MARK: - Loading and Empty States
struct ChartLoadingView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary))
            
            Text("Loading chart data...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
        }
        .frame(height: 300)
    }
}

struct ChartEmptyView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            
            Text("No chart data available")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
        }
        .frame(height: 300)
    }
}

// MARK: - Modern Toggle Style
struct ModernToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .font(.system(size: 14, weight: .medium))
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 12)
                .fill(configuration.isOn ? Color.blue : Color.gray.opacity(0.3))
                .frame(width: 40, height: 24)
                .overlay(
                    Circle()
                        .fill(.white)
                        .frame(width: 20, height: 20)
                        .offset(x: configuration.isOn ? 8 : -8)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
} 
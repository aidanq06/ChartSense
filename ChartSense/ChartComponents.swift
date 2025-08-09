//
//  ChartComponents.swift
//  ChartSense
//
//  Created by Aidan Quach on 7/22/25.
//

import SwiftUI
import Charts
import UIKit

// MARK: - Haptics
enum Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

// MARK: - Professional Chart Components
struct ProfessionalChartView: View {
    let stock: Stock
    @Binding var selectedTimeframe: TimeFrame
    @Binding var selectedPoint: ChartPoint?
    @State private var chartData: [ChartPoint] = []
    @State private var isLoading = false
    @State private var showCursor = false
    @State private var dragLocation: CGPoint = .zero
    @StateObject private var themeManager = ThemeManager.shared
    // Unique interaction toggles
    @State private var showLens = true
    @State private var showRibbon = true
    @State private var showLevels = true
    @State private var isPlaying = false
    @State private var playIndex: Int = 0
    @State private var playTimer: Timer? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Chart Area
            GeometryReader { geometry in
                ZStack {
                    if isLoading {
                        ChartLoadingView()
                    } else {
                        UltraCleanChart(
                            data: chartData,
                            timeframe: selectedTimeframe,
                            selectedPoint: $selectedPoint,
                            showCursor: $showCursor,
                            geometry: geometry,
                            stock: stock
                        )
                    }
                }
                // Gestures managed inside UltraCleanChart
            }
            .frame(height: 360)
            
            // Timeframe controls — single row, minimal
            ChartControlsView(timeframe: $selectedTimeframe)
                .onChange(of: selectedTimeframe) { newTimeframe in
                    loadChartData(for: newTimeframe)
                    selectedPoint = nil
                    showCursor = false
                }
        }
        .onAppear {
            loadChartData(for: selectedTimeframe)
        }
        .onChange(of: isPlaying) { playing in
            if playing { startPlayback() } else { stopPlayback() }
        }
    }
    
    private func startPlayback() {
        stopPlayback()
        guard !chartData.isEmpty else { return }
        playIndex = 0
        showCursor = true
        playTimer = Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { _ in
            if playIndex >= chartData.count { stopPlayback(); return }
            selectedPoint = chartData[playIndex]
            playIndex += 1
        }
    }
    
    private func stopPlayback() {
        playTimer?.invalidate()
        playTimer = nil
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

// MARK: - Key Levels Overlay
private struct KeyLevelsOverlay: View {
    let data: [ChartPoint]
    let geometry: GeometryProxy
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        let minP = data.map(\.price).min() ?? 0
        let maxP = data.map(\.price).max() ?? 1
        let mid = (minP + maxP) / 2
        
        return ZStack {
            LevelLine(value: maxP, color: .gray.opacity(0.25), label: "High")
            LevelLine(value: mid, color: .blue.opacity(0.18), label: "Pivot")
            LevelLine(value: minP, color: .gray.opacity(0.25), label: "Low")
        }
        .allowsHitTesting(false)
    }
    
    private func y(for value: Double) -> CGFloat {
        let minP = data.map(\.price).min() ?? 0
        let maxP = data.map(\.price).max() ?? 1
        guard maxP != minP else { return geometry.size.height / 2 }
        return (1 - CGFloat((value - minP) / (maxP - minP))) * geometry.size.height
    }
    
    private func LevelLine(value: Double, color: Color, label: String) -> some View {
        let yPos = y(for: value)
        return AnyView(
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(color)
                    .frame(height: 0.75)
                    .position(x: geometry.size.width / 2, y: yPos)
                Text("\(label)  \(String(format: "$%.2f", value))")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background((themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground).opacity(0.6))
                    .cornerRadius(6)
                    .position(x: 56, y: max(12, min(geometry.size.height - 12, yPos - 10)))
            }
        )
    }
}

// MARK: - Trend Ribbon
private struct TrendRibbon: View {
    let data: [ChartPoint]
    let geometry: GeometryProxy
    
    var body: some View {
        let prices = data.map(\.price)
        let moving = movingAverage(prices, period: 8)
        let baseline = moving.last ?? (prices.last ?? 0)
        let last = prices.last ?? 0
        let pct = baseline == 0 ? 0 : ((last - baseline) / baseline)
        let color = pct >= 0 ? Color.green.opacity(0.18) : Color.red.opacity(0.18)
        
        return Rectangle()
            .fill(color)
            .frame(height: 10)
    }
    
    private func movingAverage(_ arr: [Double], period: Int) -> [Double] {
        guard period > 0, arr.count >= period else { return arr }
        var result: [Double] = []
        var sum: Double = 0
        for i in 0..<arr.count {
            sum += arr[i]
            if i >= period { sum -= arr[i - period] }
            if i >= period - 1 { result.append(sum / Double(period)) }
        }
        return result
    }
}

// MARK: - Insight Banner
private struct InsightBanner: View {
    let data: [ChartPoint]
    let point: ChartPoint
    
    var body: some View {
        let text = insightText()
        return Group {
            if let text = text {
                Text(text)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.28))
                    .cornerRadius(8)
            }
        }
    }
    
    private func insightText() -> String? {
        guard let first = data.first, let last = data.last else { return nil }
        let p = point.price
        let range = (data.map(\.price).min() ?? p, data.map(\.price).max() ?? p)
        if p == range.1 { return "New intraperiod high" }
        if p == range.0 { return "New intraperiod low" }
        let mid = (range.0 + range.1) / 2
        if abs(p - mid) / mid < 0.01 { return "At pivot region" }
        // momentum check
        let idx = data.firstIndex { $0.id == point.id } ?? (data.count - 1)
        let windowStart = max(0, idx - 5)
        let momentum = p - data[windowStart].price
        if abs(momentum) / p > 0.015 { return momentum > 0 ? "Strong short-term momentum" : "Weak short-term momentum" }
        // end of series improvement
        if point.id == last.id { return "Latest tick" }
        return nil
    }
}

// MARK: - Chart Toolbar
private struct ChartToolbar: View {
    @Binding var showLens: Bool
    @Binding var showRibbon: Bool
    @Binding var showLevels: Bool
    @Binding var isPlaying: Bool
    let onPlay: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            ToolbarPill(icon: showLens ? "scope" : "scope", active: showLens) { showLens.toggle() }
            ToolbarPill(icon: "waveform.path", active: showRibbon) { showRibbon.toggle() }
            ToolbarPill(icon: "line.3.horizontal.decrease", active: showLevels) { showLevels.toggle() }
            ToolbarPill(icon: isPlaying ? "pause.fill" : "play.fill", active: true) { onPlay() }
        }
    }
}

private struct ToolbarPill: View {
    let icon: String
    let active: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(active ? .white : .gray)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    active
                    ? AnyShapeStyle(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing))
                    : AnyShapeStyle(Color.black.opacity(0.12))
                )
                .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Robinhood Style Chart
struct RobinhoodStyleChart: View {
    let data: [ChartPoint]
    @Binding var selectedPoint: ChartPoint?
    @Binding var showCursor: Bool
    @Binding var dragLocation: CGPoint
    let geometry: GeometryProxy
    let timeframe: TimeFrame
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack {
            // Chart Background
            (themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
                .ignoresSafeArea()
            if !data.isEmpty {
                // Fill Area with Gradient
                ChartFillArea(data: data, geometry: geometry)
                
                // Chart Line
                ChartLine(data: data, geometry: geometry)
                
                // Grid Lines and session shading
                ChartGridLines(data: data, geometry: geometry)
                SessionBackground(geometry: geometry, timeframe: timeframe, data: data)
            }
        }
    }
}

// MARK: - UltraCleanChart (all-in-one, glitch-free)
private struct UltraCleanChart: View {
    let data: [ChartPoint]
    let timeframe: TimeFrame
    @Binding var selectedPoint: ChartPoint?
    @Binding var showCursor: Bool
    let geometry: GeometryProxy
    let stock: Stock
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack {
            // Base layers
            RobinhoodStyleChart(
                data: data,
                selectedPoint: $selectedPoint,
                showCursor: $showCursor,
                dragLocation: .constant(.zero),
                geometry: geometry,
                timeframe: timeframe
            )
            .drawingGroup()
            
            // HUD (price, session, time)
            ChartHUD(stock: stock, point: selectedPoint, timeframe: timeframe, data: data)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height, alignment: .topLeading)
            
            // Cursor + Tooltip when active
            if showCursor, let sp = selectedPoint {
                ChartCursor(point: sp, geometry: geometry, data: data)
                ChartTooltip(point: sp, geometry: geometry, data: data)
            }
        }
        .contentShape(Rectangle())
        .highPriorityGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    showCursor = true
                    updateSelectedPoint(at: value.location)
                }
                .onEnded { _ in
                    // keep the cursor
                }
        )
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showCursor.toggle()
                    if !showCursor { selectedPoint = nil }
                }
            }
        )
    }
    
    private func updateSelectedPoint(at location: CGPoint) {
        guard !data.isEmpty else { return }
        let normalizedX = max(0, min(1, location.x / geometry.size.width))
        let index = Int(normalizedX * CGFloat(max(1, data.count - 1)))
        selectedPoint = data[index]
    }
}

// MARK: - Animated Gradient Sweep
private struct AnimatedSweep: View {
    @State private var phase: CGFloat = -0.4
    var body: some View {
        LinearGradient(colors: [Color.white.opacity(0.0), Color.white.opacity(0.12), Color.white.opacity(0.0)], startPoint: .leading, endPoint: .trailing)
            .blendMode(.plusLighter)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(colors: [.black.opacity(0), .black, .black.opacity(0)], startPoint: .leading, endPoint: .trailing)
                    )
                    .offset(x: phase * UIScreen.main.bounds.width)
            )
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    phase = 1.4
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
                    Color.blue.opacity(0.22),
                    Color.blue.opacity(0.06),
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
            guard !points.isEmpty else { return }
            path.move(to: points[0])
            for i in 1..<points.count {
                let prev = points[i - 1]
                let current = points[i]
                let mid = CGPoint(x: (prev.x + current.x) / 2, y: (prev.y + current.y) / 2)
                if i == 1 {
                    path.addQuadCurve(to: mid, control: controlPoint(p1: prev, p2: current))
                } else {
                    let prevMid = CGPoint(x: (points[i - 2].x + prev.x) / 2, y: (points[i - 2].y + prev.y) / 2)
                    path.addCurve(to: mid, control1: controlPoint(p1: prevMid, p2: prev), control2: controlPoint(p1: prev, p2: current))
                }
            }
            if let last = points.last {
                path.addLine(to: last)
            }
        }
        .stroke(
            LinearGradient(colors: [Color.blue, Color.blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing),
            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
        )
    }
    
    private var minPrice: Double {
        data.map(\.price).min() ?? 0
    }
    
    private var maxPrice: Double {
        data.map(\.price).max() ?? 1
    }

    private func controlPoint(p1: CGPoint, p2: CGPoint) -> CGPoint {
        let smoothing: CGFloat = 0.2
        return CGPoint(x: p1.x + (p2.x - p1.x) * smoothing, y: p1.y + (p2.y - p1.y) * smoothing)
    }
}

// MARK: - Chart Grid Lines
struct ChartGridLines: View {
    let data: [ChartPoint]
    let geometry: GeometryProxy
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack {
            // Horizontal grid lines (very subtle)
            ForEach(0..<3, id: \.self) { i in
                let y = geometry.size.height * CGFloat(i + 1) / 4
                Rectangle()
                    .fill((themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border).opacity(0.25))
                    .frame(height: 0.5)
                    .position(x: geometry.size.width / 2, y: y)
            }
        }
    }
}

// MARK: - Session Background (pre/regular/after hours)
struct SessionBackground: View {
    let geometry: GeometryProxy
    let timeframe: TimeFrame
    let data: [ChartPoint]
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        guard timeframe == .oneDay, let first = data.first, let last = data.last else { return AnyView(EmptyView()) } 
        let start = first.date
        let end = last.date
        guard end > start else { return AnyView(EmptyView()) }

        // Define session boundaries (approx, local timezone)
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: end)
        let preStart = calendar.date(bySettingHour: 4, minute: 0, second: 0, of: day) ?? start
        let marketOpen = calendar.date(bySettingHour: 9, minute: 30, second: 0, of: day) ?? start
        let marketClose = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: day) ?? end
        let afterEnd = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: day) ?? end

        // Helper to map a date to X position
        func x(_ date: Date) -> CGFloat {
            let clamped = min(max(date.timeIntervalSince1970, start.timeIntervalSince1970), end.timeIntervalSince1970)
            let p = (clamped - start.timeIntervalSince1970) / (end.timeIntervalSince1970 - start.timeIntervalSince1970)
            return CGFloat(p) * geometry.size.width
        }

        let overlay = (themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border)

        return AnyView(
            ZStack {
                // Pre-market shade
                if marketOpen > start {
                    Rectangle()
                        .fill(overlay.opacity(0.16))
                        .frame(width: max(0, x(marketOpen) - x(preStart)), height: geometry.size.height)
                        .position(x: (x(marketOpen) + x(preStart)) / 2, y: geometry.size.height / 2)
                }
                // After-hours shade
                if end > marketClose {
                    Rectangle()
                        .fill(overlay.opacity(0.16))
                        .frame(width: max(0, x(min(afterEnd, end)) - x(marketClose)), height: geometry.size.height)
                        .position(x: (x(min(afterEnd, end)) + x(marketClose)) / 2, y: geometry.size.height / 2)
                }
                // Session boundary markers (very subtle)
            Rectangle()
                .fill(overlay.opacity(0.25))
                    .frame(width: 0.5, height: geometry.size.height)
                    .position(x: x(marketOpen), y: geometry.size.height / 2)
            Rectangle()
                .fill(overlay.opacity(0.25))
                    .frame(width: 0.5, height: geometry.size.height)
                    .position(x: x(marketClose), y: geometry.size.height / 2)
            }
        )
    }
}

// MARK: - Minimal Chart HUD (non-intrusive)
struct ChartHUD: View {
    let stock: Stock
    let point: ChartPoint?
    let timeframe: TimeFrame
    let data: [ChartPoint]
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        HStack(spacing: 8) {
            // Price
            let priceText = point?.formattedPrice ?? stock.formattedPrice
            CapsuleLabel(text: priceText)
            
            // Time (only when we have a point)
            if let p = point {
                CapsuleSubtle(text: timeText(for: p))
            }
            
            // Session label
            if let label = sessionLabel {
                CapsuleSubtle(text: label)
            }
            
            // Change since first visible point (when crosshair active)
            // Keep hidden by default for minimalism
        }
    }

    private var sessionLabel: String? {
        guard timeframe == .oneDay, let ref = (point ?? data.last) else { return nil }
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: ref.date)
        switch hour {
        case 4..<9: return "Pre-Market"
        case 9..<16: return "Market Hours"
        case 16..<20: return "After Hours"
        default: return nil
        }
    }

    private func timeText(for point: ChartPoint) -> String {
        if timeframe == .oneDay { return point.formattedTime }
        return point.formattedDateOnly
    }
    
    private var changeFromStart: (value: Double, percent: Double)? {
        guard let start = data.first, let ref = point else { return nil }
        guard start.price != 0 else { return nil }
        let value = ref.price - start.price
        let percent = (value / start.price) * 100
        return (value, percent)
    }
}

// MARK: - HUD Capsule Styles
private struct CapsuleLabel: View {
    let text: String
    @StateObject private var themeManager = ThemeManager.shared
    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundStyle(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill((themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground).opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke((themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border).opacity(0.6), lineWidth: 0.75)
                    )
            )
    }
}

private struct CapsuleSubtle: View {
    let text: String
    @StateObject private var themeManager = ThemeManager.shared
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground).opacity(0.5))
            .cornerRadius(8)
    }
}

private struct CapsuleDelta: View {
    let change: Double
    let percent: Double
    var body: some View {
        let isUp = change >= 0
        HStack(spacing: 4) {
            Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isUp ? Color.bullish : Color.bearish)
            Text(String(format: "%@%.2f (%.2f%%)", isUp ? "+" : "-", abs(change), abs(percent)))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(isUp ? Color.bullish : Color.bearish)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((isUp ? Color.green.opacity(0.12) : Color.red.opacity(0.12)))
        .cornerRadius(8)
    }
}

// MARK: - Chart Cursor
struct ChartCursor: View {
    let point: ChartPoint
    let geometry: GeometryProxy
    let data: [ChartPoint]
    
    var body: some View {
        ZStack {
            // Vertical line
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 1)
                .position(x: cursorX, y: geometry.size.height / 2)
            
            // Price dot
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle().stroke(Color.white, lineWidth: 2)
                )
                .position(x: cursorX, y: cursorY)
        }
    }
    
    private var cursorX: CGFloat {
        guard let index = data.firstIndex(where: { $0.date == point.date && $0.price == point.price }) else {
            return 0
        }
        let progress = CGFloat(index) / CGFloat(max(1, data.count - 1))
        return progress * geometry.size.width
    }
    
    private var cursorY: CGFloat {
        guard !data.isEmpty else { return geometry.size.height / 2 }
        let minPrice = data.map(\.price).min() ?? point.price
        let maxPrice = data.map(\.price).max() ?? point.price
        guard maxPrice != minPrice else { return geometry.size.height / 2 }
        return (1 - CGFloat((point.price - minPrice) / (maxPrice - minPrice))) * geometry.size.height
    }
}

// MARK: - Chart Tooltip
struct ChartTooltip: View {
    let point: ChartPoint
    let geometry: GeometryProxy
    let data: [ChartPoint]
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        let x = cursorX
        let y = cursorY
        
        // Minimal price tag that hugs the dot (no date text to reduce clutter)
        Text(point.formattedPrice)
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(
                    LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)
                )
            )
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            .opacity(0.98)
            .position(x: min(max(30, x), geometry.size.width - 30), y: max(16, y - 18))
        
        // Bottom readout removed for ultra-clean
    }
    
    private var cursorX: CGFloat {
        guard let index = data.firstIndex(where: { $0.date == point.date && $0.price == point.price }) else {
            return 0
        }
        let progress = CGFloat(index) / CGFloat(max(1, data.count - 1))
        return progress * geometry.size.width
    }
    
    private var cursorY: CGFloat {
        guard !data.isEmpty else { return geometry.size.height / 2 }
        let minPrice = data.map(\.price).min() ?? point.price
        let maxPrice = data.map(\.price).max() ?? point.price
        guard maxPrice != minPrice else { return geometry.size.height / 2 }
        return (1 - CGFloat((point.price - minPrice) / (maxPrice - minPrice))) * geometry.size.height
    }
}

// MARK: - Chart Magnifier (overlay zoom window)
private struct ChartMagnifier: View {
    let data: [ChartPoint]
    let geometry: GeometryProxy
    let location: CGPoint
    
    var body: some View {
        let width: CGFloat = 96
        let height: CGFloat = 64
        let normalizedX = max(0, min(1, location.x / geometry.size.width))
        let centerIndex = Int(normalizedX * CGFloat(max(1, data.count - 1)))
        let lower = max(0, centerIndex - 12)
        let upper = min(data.count - 1, centerIndex + 12)
        let window = Array(data[lower...upper])
        
        return VStack(alignment: .trailing, spacing: 6) {
            Canvas { context, size in
                guard window.count > 1 else { return }
                let minP = window.map { $0.price }.min() ?? 0
                let maxP = window.map { $0.price }.max() ?? 1
                var path = Path()
                for (i, pt) in window.enumerated() {
                    let x = CGFloat(i) / CGFloat(window.count - 1) * size.width
                    let y = (1 - CGFloat((pt.price - minP) / (maxP - minP))) * size.height
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
                context.stroke(path, with: .color(.blue), lineWidth: 2)
            }
            .frame(width: width, height: height)
            .background(.thinMaterial)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.6), lineWidth: 0.5)
            )
            
            HStack(spacing: 8) {
                Text("x: \(Int(location.x))")
                    .font(.system(size: 10, weight: .medium))
                Text("y: \(Int(location.y))")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(.white)
        }
    }
}

// MARK: - Chart Controls
struct ChartControlsView: View {
    @Binding var timeframe: TimeFrame
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TimeFrame.allCases, id: \.self) { tf in
                Button(action: {
                    if timeframe != tf {
                        timeframe = tf
                        Haptics.light()
                    }
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

// MARK: - Overlaid Timeframe Control
struct TimeframePillControl: View {
    @Binding var timeframe: TimeFrame
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(TimeFrame.allCases, id: \.self) { tf in
                Button(action: {
                    if timeframe != tf {
                        timeframe = tf
                        Haptics.light()
                    }
                }) {
                    Text(tf.displayName)
                        .font(.system(size: 13, weight: timeframe == tf ? .semibold : .medium))
                        .foregroundColor(foregroundColor(for: tf))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(backgroundStyle(for: tf))
                        )
                        .overlay(
                            Capsule().stroke(borderColor.opacity(borderOpacity(for: tf)), lineWidth: 0.75)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            Capsule().fill((themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background).opacity(0.6))
        )
        .overlay(
            Capsule().stroke((themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border).opacity(0.6), lineWidth: 0.75)
        )
        .blur(radius: 0.2)
    }

    // MARK: - Helpers (break up complex expressions)
    private func foregroundColor(for tf: TimeFrame) -> Color {
        if timeframe == tf { return .white }
        return themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText
    }
    
    private func backgroundStyle(for tf: TimeFrame) -> AnyShapeStyle {
        if timeframe == tf {
            let gradient = LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)
            return AnyShapeStyle(gradient)
        } else {
            let color = (themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground).opacity(0.7)
            return AnyShapeStyle(color)
        }
    }
    
    private var borderColor: Color {
        themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border
    }
    
    private func borderOpacity(for tf: TimeFrame) -> Double {
        timeframe == tf ? 0.0 : 0.6
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
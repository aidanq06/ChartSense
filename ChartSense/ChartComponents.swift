//
//  ChartComponents.swift
//  ChartSense
//
//  Created by Aidan Quach on 7/22/25.
//

import SwiftUI
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

// MARK: - Charts were removed per request

// (removed: KeyLevelsOverlay)

// MARK: - Trend Ribbon
// (removed: TrendRibbon)

// MARK: - Insight Banner
// (removed: InsightBanner)

// MARK: - Chart Toolbar
// (removed: ChartToolbar)

// (removed: ToolbarPill)

// MARK: - Robinhood Style Chart
// (removed: RobinhoodStyleChart)

// MARK: - UltraCleanChart (all-in-one, glitch-free)
// (removed: UltraCleanChart)

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
// (removed: ChartFillArea)

// MARK: - Chart Line
// (removed: ChartLine)

// MARK: - Chart Grid Lines
// (removed: ChartGridLines)

// MARK: - Session Background (pre/regular/after hours)
// (removed: SessionBackground)

// MARK: - Minimal Chart HUD (non-intrusive)
// (removed: ChartHUD)

// MARK: - HUD Capsule Styles
// (removed: CapsuleLabel)

// (removed: CapsuleSubtle)

// (removed: CapsuleDelta)

// MARK: - Chart Cursor
// (removed: ChartCursor)

// MARK: - Chart Tooltip
// (removed: ChartTooltip)

// MARK: - Chart Magnifier (overlay zoom window)
// (removed: ChartMagnifier)

// MARK: - Chart Controls
// (removed: ChartControlsView)

// MARK: - Overlaid Timeframe Control
// (removed: TimeframePillControl)

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

// MARK: - Chart Range
enum ChartRange: String, CaseIterable, Identifiable {
    case oneDay = "1D"
    case oneWeek = "1W"
    case oneMonth = "1M"
    case oneYear = "1Y"
    case all = "All"
    var id: String { rawValue }
    var display: String { rawValue }
}

// MARK: - Chart Data Point
struct ChartPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let price: Double
}

// MARK: - Ultra-Clean Chart Tab
struct UltraCleanChartTab: View {
    let stock: Stock
    @State private var range: ChartRange = .oneDay
    @State private var points: [ChartPoint] = []
    @State private var isLoading: Bool = true
    @State private var isScrubbing: Bool = false
    @State private var scrubIndex: Int? = nil
    @State private var crossedBaselinePreviouslyAbove: Bool? = nil
    @State private var fadeIn: Bool = false
    @StateObject private var themeManager = ThemeManager.shared

    private var trendColor: Color { stock.dailyChange >= 0 ? Color.bullish : Color.bearish }
    private var primaryText: Color { themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText }
    private var secondaryText: Color { themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText }
    private var lineColor: Color { (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary) }

    private var displayPrice: Double {
        if let i = scrubIndex, i >= 0, i < points.count { return points[i].price }
        return points.last?.price ?? stock.currentPrice
    }

    private var baseline: Double {
        points.first?.price ?? stock.currentPrice
    }

    private var delta: Double { displayPrice - baseline }
    private var deltaPercent: Double { baseline == 0 ? 0 : (delta / baseline * 100.0) }
    private var isPositiveDelta: Bool { delta >= 0 }

    var body: some View {
        VStack(spacing: 16) {

            // Chart Area
            ZStack {
                if isLoading {
                    // Calm skeleton
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill((themeManager.isDarkMode ? AppTheme.dark.colors.secondaryBackground : AppTheme.light.colors.secondaryBackground))
                        .shimmer()
                        .frame(height: 260)
                        .padding(.horizontal, 12)
                } else {
                    UltraCleanChart(
                        points: points,
                        lineGradient: LinearGradient(
                            colors: [
                                (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary),
                                (themeManager.isDarkMode ? AppTheme.dark.colors.secondary : AppTheme.light.colors.secondary)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        fillGradient: LinearGradient(
                            colors: [
                                (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary).opacity(0.25),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        showFill: false,
                        isScrubbing: $isScrubbing,
                        scrubIndex: $scrubIndex,
                        baseline: baseline,
                        onScrubBegan: { Haptics.light() },
                        onScrubEnded: { Haptics.selection() },
                        onCrossBaseline: { crossedAbove in
                            if let prev = crossedBaselinePreviouslyAbove, prev != crossedAbove { Haptics.selection() }
                            crossedBaselinePreviouslyAbove = crossedAbove
                        }
                    )
                    .frame(height: 260)
                    .padding(.horizontal, 0)
                    .transition(.opacity)
                }
            }

            // Range Selector
            RangeSelector(range: $range)
                .padding(.horizontal, 20)
        }
        .padding(.top, 8)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
        .onAppear { loadData(animated: true) }
        .onChange(of: range) { _ in
            Haptics.selection()
            loadData(animated: true)
        }
    }

    private func loadData(animated: Bool) {
        isLoading = true
        fadeIn = false
        DispatchQueue.global(qos: .userInitiated).async {
            let generated = generatePoints(for: stock, range: range)
            let downsampled = downsample(points: generated, targetCount: 240)
            DispatchQueue.main.async {
                withAnimation(animated ? .easeInOut(duration: 0.35) : .none) {
                    self.points = downsampled
                    self.isLoading = false
                    self.scrubIndex = nil
                    self.isScrubbing = false
                    self.fadeIn = true
                }
            }
        }
    }

    private func generatePoints(for stock: Stock, range: ChartRange) -> [ChartPoint] {
        let now = Date()
        let count: Int
        switch range {
        case .oneDay: count = 160
        case .oneWeek: count = 220
        case .oneMonth: count = 260
        case .oneYear: count = 300
        case .all: count = 240
        }

        let base = max(stock.currentPrice, 1)
        let biasUp = stock.dailyChangePercent >= 0
        let volatility = base * 0.012
        let drift = base * (biasUp ? 0.0009 : -0.0009)

        var pts: [ChartPoint] = []
        var price = base - (biasUp ? base*0.01 : -base*0.01)
        for i in 0..<count {
            let t: TimeInterval
            switch range {
            case .oneDay: t = -TimeInterval(count - i) * 60 * 3
            case .oneWeek: t = -TimeInterval(count - i) * 60 * 20
            case .oneMonth: t = -TimeInterval(count - i) * 60 * 60 * 3
            case .oneYear: t = -TimeInterval(count - i) * 60 * 60 * 24
            case .all: t = -TimeInterval(count - i) * 60 * 60 * 24 * 3
            }
            let noise = Double.random(in: -volatility...volatility)
            price = max(0.01, price + noise + drift)
            pts.append(ChartPoint(date: now.addingTimeInterval(t), price: price))
        }
        return pts
    }

    private func downsample(points: [ChartPoint], targetCount: Int) -> [ChartPoint] {
        guard points.count > targetCount else { return points }
        let step = Double(points.count) / Double(targetCount)
        var result: [ChartPoint] = []
        var index: Double = 0
        while Int(index) < points.count {
            let i0 = Int(index)
            let i1 = min(points.count - 1, Int(index + step))
            let slice = points[i0...i1]
            if let minP = slice.min(by: { $0.price < $1.price }), let maxP = slice.max(by: { $0.price < $1.price }) {
                result.append(minP)
                if maxP.id != minP.id { result.append(maxP) }
            } else {
                result.append(points[i0])
            }
            index += step
        }
        return result.sorted { $0.date < $1.date }
    }
}

// MARK: - Range Selector (enhanced pills)
private struct RangeSelector: View {
    @Binding var range: ChartRange
    @StateObject private var themeManager = ThemeManager.shared
    var body: some View {
        HStack(spacing: 10) {
            ForEach(ChartRange.allCases) { r in
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { range = r } }) {
                    let isSelected = (range == r)
                    let primary = themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary
                    let secondary = themeManager.isDarkMode ? AppTheme.dark.colors.secondary : AppTheme.light.colors.secondary
                    let glow = primary.opacity(0.25)
                    let backgroundStyle: AnyShapeStyle = isSelected
                        ? AnyShapeStyle(LinearGradient(colors: [primary, secondary], startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(primary.opacity(0.10))

                    Text(r.display)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isSelected ? .white : primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(backgroundStyle)
                        )
                        .overlay(
                            Capsule().stroke(primary.opacity(0.18), lineWidth: isSelected ? 0 : 1)
                        )
                        .shadow(color: primary.opacity(isSelected ? 0.28 : 0.0), radius: isSelected ? 10 : 0, x: 0, y: 6)
                        .modifier(SelectedGlow(isSelected: isSelected, primary: primary, secondary: secondary))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct SelectedGlow: ViewModifier {
    let isSelected: Bool
    let primary: Color
    let secondary: Color
    func body(content: Content) -> some View {
        if isSelected {
            content
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(colors: [primary.opacity(0.6), secondary.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                        .blur(radius: 0.5)
                )
        } else {
            content
        }
    }
}

// MARK: - Ultra-Clean Chart (Path/Canvas)
private struct UltraCleanChart: View {
    let points: [ChartPoint]
    let lineGradient: LinearGradient
    let fillGradient: LinearGradient
    let showFill: Bool
    @Binding var isScrubbing: Bool
    @Binding var scrubIndex: Int?
    let baseline: Double
    var onScrubBegan: () -> Void = {}
    var onScrubEnded: () -> Void = {}
    var onCrossBaseline: (Bool) -> Void = { _ in }

    @State private var lastCrossAbove: Bool? = nil

    var body: some View {
        GeometryReader { geo in
            let frame = geo.frame(in: .local)
            let normalized = normalize(points: points, in: frame.size)
            let baselineY = (normalized.map { $0.y }.max() ?? frame.height) * 0.92
            let areaPoints: [CGPoint] = {
                guard normalized.count > 1 else { return [] }
                var pts = normalized
                if let last = normalized.last, let first = normalized.first {
                    pts.append(CGPoint(x: last.x, y: baselineY))
                    pts.append(CGPoint(x: first.x, y: baselineY))
                }
                return pts
            }()

            ZStack {
                // Fill under the line
                if showFill, !areaPoints.isEmpty {
                    Path { p in
                        guard let first = areaPoints.first else { return }
                        p.move(to: first)
                        for pt in areaPoints.dropFirst() { p.addLine(to: pt) }
                        p.closeSubpath()
                    }
                    .fill(fillGradient)
                    .overlay(
                        LinearGradient(
                            colors: [Color.white.opacity(0.10), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .blendMode(.plusLighter)
                        .mask(
                            Path { p in
                                guard let first = areaPoints.first else { return }
                                p.move(to: first)
                                for pt in areaPoints.dropFirst() { p.addLine(to: pt) }
                                p.closeSubpath()
                            }
                        )
                    )
                }

                // Baseline (whisper-light)
                if let y = yForPrice(baseline, in: frame.size, points: points) {
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: frame.width, y: y))
                    }
                    .stroke(Color.primary.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                }

                // Line with subtle glow
                Path { p in
                    if let first = normalized.first { p.move(to: first) }
                    for pt in normalized.dropFirst() { p.addLine(to: pt) }
                }
                .stroke(lineGradient, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                .shadow(color: Color.white.opacity(0.06), radius: 2, x: 0, y: 0)

                // Scrub overlay
                if let idx = scrubIndex, idx >= 0, idx < normalized.count, isScrubbing {
                    let pt = normalized[idx]
                    // Vertical hairline
                    Path { p in
                        p.move(to: CGPoint(x: pt.x, y: 0))
                        p.addLine(to: CGPoint(x: pt.x, y: frame.height))
                    }
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)

                    // Focus dot
                    Circle()
                        .fill(lineGradient)
                        .frame(width: 8, height: 8)
                        .position(pt)

                    // Tooltip
                    if idx < points.count {
                        let price = points[idx].price
                        let date = points[idx].date
                        FloatingTooltip(price: price, date: date, baseline: baseline)
                            .position(x: clamp(pt.x + 60, min: 70, max: frame.width - 70), y: max(24, pt.y - 28))
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isScrubbing { isScrubbing = true; onScrubBegan() }
                        let idx = indexForLocation(value.location, in: frame.size, points: points)
                        if scrubIndex != idx { scrubIndex = idx }
                        if let idx = idx, idx < points.count {
                            let above = points[idx].price >= baseline
                            if let last = lastCrossAbove, last != above { onCrossBaseline(above) }
                            lastCrossAbove = above
                        }
                    }
                    .onEnded { _ in
                        isScrubbing = false
                        scrubIndex = nil
                        onScrubEnded()
                    }
            )
        }
    }

    private func normalize(points: [ChartPoint], in size: CGSize) -> [CGPoint] {
        guard let firstDate = points.first?.date, let lastDate = points.last?.date, firstDate != lastDate else { return [] }
        let minPrice = points.map { $0.price }.min() ?? 0
        let maxPrice = points.map { $0.price }.max() ?? 1
        let pad = (maxPrice - minPrice) * 0.06
        let lo = minPrice - pad
        let hi = maxPrice + pad
        let dt = lastDate.timeIntervalSince(firstDate)
        return points.map { pt in
            let x = CGFloat(pt.date.timeIntervalSince(firstDate) / dt) * size.width
            let yNorm = (pt.price - lo) / max(hi - lo, 0.0001)
            let y = size.height - CGFloat(yNorm) * size.height
            return CGPoint(x: x, y: y)
        }
    }

    private func indexForLocation(_ location: CGPoint, in size: CGSize, points: [ChartPoint]) -> Int? {
        guard let firstDate = points.first?.date, let lastDate = points.last?.date, size.width > 0 else { return nil }
        let dt = lastDate.timeIntervalSince(firstDate)
        let t = Double(location.x / size.width) * dt
        let targetDate = firstDate.addingTimeInterval(t)
        var best: (idx: Int, dist: TimeInterval)? = nil
        for (i, p) in points.enumerated() {
            let d = abs(p.date.timeIntervalSince(targetDate))
            if best == nil || d < best!.dist { best = (i, d) }
        }
        return best?.idx
    }

    private func yForPrice(_ price: Double, in size: CGSize, points: [ChartPoint]) -> CGFloat? {
        let minPrice = points.map { $0.price }.min() ?? 0
        let maxPrice = points.map { $0.price }.max() ?? 1
        let pad = (maxPrice - minPrice) * 0.06
        let lo = minPrice - pad
        let hi = maxPrice + pad
        guard hi - lo > 0 else { return nil }
        let yNorm = (price - lo) / (hi - lo)
        return size.height - CGFloat(yNorm) * size.height
    }
}

// MARK: - Floating Tooltip
private struct FloatingTooltip: View {
    let price: Double
    let date: Date
    let baseline: Double
    @StateObject private var themeManager = ThemeManager.shared
    var body: some View {
        let bg = themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground
        let border = themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border
        let delta = price - baseline
        let percent = baseline == 0 ? 0 : (delta / baseline * 100.0)
        let positive = delta >= 0
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Text(String(format: "$%.2f", price))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                Text(String(format: "%@%.2f%%", positive ? "+" : "", abs(percent)))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(positive ? .green : .red)
            }
            Text(shortTime(date))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(bg)
                .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0.35 : 0.08), radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(border, lineWidth: 0.5)
                )
        )
    }

    private func shortTime(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMM d, h:mm a"
        return df.string(from: date)
    }
}

// MARK: - Utilities
fileprivate func clamp<T: Comparable>(_ value: T, min minValue: T, max maxValue: T) -> T {
    return Swift.min(Swift.max(value, minValue), maxValue)
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

// (removed: VolumeChart)

// MARK: - Crosshair Info View
// (removed: CrosshairInfoView)

// MARK: - Price Range Display
// (removed: PriceRangeDisplay)
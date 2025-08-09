//
//  SenseChart.swift
//  ChartSense
//
//  A ground-up, minimal, highly-interactive stock chart.
//

import SwiftUI

// MARK: - Sense Chart Host
struct SenseChartHost: View {
    let stock: Stock
    @Binding var selectedTimeframe: TimeFrame
    @Binding var selectedPoint: ChartPoint?

    @State private var data: [ChartPoint] = []
    @State private var isLoading = false
    @State private var viewport: ClosedRange<Date>? = nil
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ZStack {
                    if isLoading {
                        ChartLoadingView()
                    } else {
                        SenseChartView(
                            stock: stock,
                            data: data,
                            timeframe: selectedTimeframe,
                            viewport: $viewport,
                            selectedPoint: $selectedPoint,
                            size: geo.size
                        )
                    }
                }
            }
            .frame(height: 360)

            ChartTimeframeControl(timeframe: $selectedTimeframe)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .onChange(of: selectedTimeframe) { newTF in
                    selectedPoint = nil
                    viewport = nil
                    loadData(for: newTF)
                }
        }
        .onAppear { loadData(for: selectedTimeframe) }
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
    }

    private func loadData(for timeframe: TimeFrame) {
        isLoading = true
        Task {
            let points = await generateDataFromCurrent(stock: stock, timeframe: timeframe)
            await MainActor.run {
                self.data = points
                self.isLoading = false
            }
        }
    }
}

// MARK: - Sense Chart View
struct SenseChartView: View {
    let stock: Stock
    let data: [ChartPoint]
    let timeframe: TimeFrame
    @Binding var viewport: ClosedRange<Date>?
    @Binding var selectedPoint: ChartPoint?
    let size: CGSize

    @State private var dragActive = false
    @State private var dragX: CGFloat = .zero
    @State private var lastDragMid: Date? = nil
    @State private var magBaseRange: TimeInterval? = nil
    @State private var chartPhase: CGFloat = 0
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        ZStack {
            // Background layers
            (themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
            gridLayer
            sessionLayer

            // Area fill + line
            if pointsInView.count > 1 {
                areaFillLayer
                lineLayer
            }

            // HUD
            ChartHUD(stock: stock, point: selectedPoint, timeframe: timeframe, data: data)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .frame(maxWidth: size.width, maxHeight: size.height, alignment: .topLeading)

            // Crosshair
            if let sp = selectedPoint {
                crosshair(for: sp)
                tooltip(for: sp)
            }

            // Market open/close markers (always shown for 1D)
            if timeframe == .oneDay {
                marketMarkers
            }
        }
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .gesture(magnificationGesture)
        .simultaneousGesture(doubleTapGesture)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9)) { chartPhase = 1 }
        }
        .animation(.easeInOut(duration: 0.25), value: viewport)
        .animation(.easeOut(duration: 0.15), value: selectedPoint?.id)
        .drawingGroup()
    }

    // MARK: - Layers
    private var gridLayer: some View {
        Canvas { ctx, sz in
            let rows = 4
            let color = (themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border).opacity(0.25)
            for r in 1..<rows { // subtle horizontals
                let y = sz.height * CGFloat(r) / CGFloat(rows)
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: sz.width, y: y))
                ctx.stroke(path, with: .color(color), lineWidth: 0.5)
            }
        }
    }

    private var sessionLayer: some View {
        Group {
            if timeframe == .oneDay, let first = data.first, let last = data.last {
                let day = Calendar.current.startOfDay(for: last.date)
                let pre = Calendar.current.date(bySettingHour: 4, minute: 0, second: 0, of: day) ?? day
                let open = Calendar.current.date(bySettingHour: 9, minute: 30, second: 0, of: day) ?? day
                let close = Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: day) ?? day
                let after = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: day) ?? day

                let start = first.date
                let end = last.date
                let overlay = themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border

                Canvas { ctx, sz in
                    func x(_ d: Date) -> CGFloat {
                        let v = viewRange
                        guard v.lowerBound < v.upperBound else { return 0 }
                        let p = (d.timeIntervalSince1970 - v.lowerBound.timeIntervalSince1970) /
                                (v.upperBound.timeIntervalSince1970 - v.lowerBound.timeIntervalSince1970)
                        return CGFloat(max(0, min(1, p))) * sz.width
                    }

                    // Pre-market
                    if open > start {
                        let x0 = x(max(pre, viewRange.lowerBound))
                        let x1 = x(min(open, viewRange.upperBound))
                        if x1 > x0 {
                            let rect = CGRect(x: x0, y: 0, width: x1 - x0, height: sz.height)
                            ctx.fill(Path(rect), with: .color(overlay.opacity(0.16)))
                        }
                    }
                    // After-hours
                    if end > close {
                        let x0 = x(max(close, viewRange.lowerBound))
                        let x1 = x(min(after, viewRange.upperBound))
                        if x1 > x0 {
                            let rect = CGRect(x: x0, y: 0, width: x1 - x0, height: sz.height)
                            ctx.fill(Path(rect), with: .color(overlay.opacity(0.16)))
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var areaFillLayer: some View {
        Canvas { ctx, sz in
            let pts = pointsInView
            guard pts.count > 1 else { return }
            let (minY, maxY) = visibleYRange

            var path = Path()
            for (i, p) in pts.enumerated() {
                let x = xFor(p.date, width: sz.width)
                let y = yFor(p.price, height: sz.height, minY: minY, maxY: maxY)
                if i == 0 { path.move(to: CGPoint(x: x, y: sz.height)) ; path.addLine(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
                if i == pts.count - 1 { path.addLine(to: CGPoint(x: x, y: sz.height)) }
            }
            path.closeSubpath()

            let grad = Gradient(colors: [Color.blue.opacity(0.22), Color.blue.opacity(0.06), Color.blue.opacity(0.0)])
            ctx.fill(path, with: .linearGradient(grad, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: sz.height)))
        }
        .allowsHitTesting(false)
    }

    private var lineLayer: some View {
        Canvas { ctx, sz in
            let pts = pointsInView
            guard pts.count > 1 else { return }
            let (minY, maxY) = visibleYRange

            var path = Path()
            var lastPoint: CGPoint? = nil
            for (i, p) in pts.enumerated() {
                let x = xFor(p.date, width: sz.width)
                let y = yFor(p.price, height: sz.height, minY: minY, maxY: maxY)
                let pt = CGPoint(x: x, y: y)
                if i == 0 { path.move(to: pt) }
                else if let lp = lastPoint {
                    let mid = CGPoint(x: (lp.x + pt.x)/2, y: (lp.y + pt.y)/2)
                    path.addQuadCurve(to: mid, control: controlPoint(p1: lp, p2: pt))
                    path.addLine(to: pt)
                }
                lastPoint = pt
            }

            let stroke = StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            let grad = Gradient(colors: [Color.blue, Color.blue.opacity(0.8)])
            ctx.stroke(path, with: .linearGradient(grad, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: sz.width, y: 0)), style: stroke)

            if let last = pts.last {
                let x = xFor(last.date, width: sz.width)
                let y = yFor(last.price, height: sz.height, minY: minY, maxY: maxY)
                let dot = Path(ellipseIn: CGRect(x: x - 5, y: y - 5, width: 10, height: 10))
                ctx.fill(dot, with: .color(.blue))
                let outline = Path(ellipseIn: CGRect(x: x - 8, y: y - 8, width: 16, height: 16))
                ctx.stroke(outline, with: .color(.white.opacity(0.8)), lineWidth: 1)
            }
        }
        .allowsHitTesting(false)
        .opacity(Double(chartPhase))
    }

    private var marketMarkers: some View {
        Canvas { ctx, sz in
            guard let last = data.last else { return }
            let day = Calendar.current.startOfDay(for: last.date)
            let open = Calendar.current.date(bySettingHour: 9, minute: 30, second: 0, of: day) ?? day
            let close = Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: day) ?? day

            let color = (themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border).opacity(0.25)
            let xOpen = xFor(open, width: sz.width)
            let xClose = xFor(close, width: sz.width)
            var p1 = Path(); p1.move(to: CGPoint(x: xOpen, y: 0)); p1.addLine(to: CGPoint(x: xOpen, y: sz.height))
            var p2 = Path(); p2.move(to: CGPoint(x: xClose, y: 0)); p2.addLine(to: CGPoint(x: xClose, y: sz.height))
            ctx.stroke(p1, with: .color(color), lineWidth: 0.75)
            ctx.stroke(p2, with: .color(color), lineWidth: 0.75)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Gestures
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                dragActive = true
                dragX = value.location.x
                updateSelected(atX: dragX, width: size.width)
            }
            .onEnded { _ in
                dragActive = false
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { scale in
                guard data.count > 1 else { return }
                let full = fullRange
                let base = magBaseRange ?? viewRange.duration
                let newDuration = max(full.duration * 0.05, min(full.duration, base / scale))

                // Center around last drag mid or center of current view
                let mid = lastDragMid ?? Date(timeIntervalSince1970: (viewRange.lowerBound.timeIntervalSince1970 + viewRange.upperBound.timeIntervalSince1970)/2)
                let half = newDuration / 2
                var start = mid.addingTimeInterval(-half)
                var end = mid.addingTimeInterval(half)
                if start < full.lowerBound { start = full.lowerBound; end = start.addingTimeInterval(newDuration) }
                if end > full.upperBound { end = full.upperBound; start = end.addingTimeInterval(-newDuration) }
                viewport = start...end
            }
            .onEnded { _ in
                magBaseRange = viewRange.duration
            }
    }

    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2).onEnded {
            // Toggle crosshair or reset viewport if zoomed
            if viewport != nil { viewport = nil } else {
                selectedPoint = nil
            }
        }
    }

    // MARK: - Helpers
    private var fullRange: ClosedRange<Date> {
        guard let first = data.first?.date, let last = data.last?.date, first < last else {
            let now = Date(); return now...now
        }
        return first...last
    }

    private var viewRange: ClosedRange<Date> {
        viewport ?? fullRange
    }

    private var pointsInView: [ChartPoint] {
        data.filter { $0.date >= viewRange.lowerBound && $0.date <= viewRange.upperBound }
    }

    private var visibleYRange: (min: Double, max: Double) {
        let ys = pointsInView.map { $0.price }
        guard let minY = ys.min(), let maxY = ys.max(), minY != maxY else {
            let y = ys.first ?? 1
            return (y * 0.98, y * 1.02)
        }
        let pad = (maxY - minY) * 0.08
        return (minY - pad, maxY + pad)
    }

    private func xFor(_ date: Date, width: CGFloat) -> CGFloat {
        let v = viewRange
        guard v.lowerBound < v.upperBound else { return 0 }
        let p = (date.timeIntervalSince1970 - v.lowerBound.timeIntervalSince1970) /
                (v.upperBound.timeIntervalSince1970 - v.lowerBound.timeIntervalSince1970)
        return CGFloat(max(0, min(1, p))) * width
    }

    private func yFor(_ price: Double, height: CGFloat, minY: Double, maxY: Double) -> CGFloat {
        guard maxY > minY else { return height/2 }
        let p = (price - minY) / (maxY - minY)
        return (1 - CGFloat(max(0, min(1, p)))) * height
    }

    private func controlPoint(p1: CGPoint, p2: CGPoint) -> CGPoint {
        let s: CGFloat = 0.2
        return CGPoint(x: p1.x + (p2.x - p1.x) * s, y: p1.y + (p2.y - p1.y) * s)
    }

    private func updateSelected(atX x: CGFloat, width: CGFloat) {
        guard !pointsInView.isEmpty else { return }
        let p = max(0, min(1, x / max(1, width)))
        let di = Int(round(p * CGFloat(pointsInView.count - 1)))
        let idx = max(0, min(pointsInView.count - 1, di))
        let sp = pointsInView[idx]
        selectedPoint = sp
        lastDragMid = sp.date
    }

    private func crosshair(for point: ChartPoint) -> some View {
        Canvas { ctx, sz in
            let (minY, maxY) = visibleYRange
            let x = xFor(point.date, width: sz.width)
            let y = yFor(point.price, height: sz.height, minY: minY, maxY: maxY)
            var v = Path(); v.move(to: CGPoint(x: x, y: 0)); v.addLine(to: CGPoint(x: x, y: sz.height))
            ctx.stroke(v, with: .color(.gray.opacity(0.2)), lineWidth: 1)
            let dot = Path(ellipseIn: CGRect(x: x - 4, y: y - 4, width: 8, height: 8))
            ctx.fill(dot, with: .color(.blue))
            let ring = Path(ellipseIn: CGRect(x: x - 7, y: y - 7, width: 14, height: 14))
            ctx.stroke(ring, with: .color(.white.opacity(0.8)), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }

    private func tooltip(for point: ChartPoint) -> some View {
        let (minY, maxY) = visibleYRange
        let x = xFor(point.date, width: size.width)
        let y = yFor(point.price, height: size.height, minY: minY, maxY: maxY)
        return Text(point.formattedPrice)
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
            .position(x: min(max(30, x), size.width - 30), y: max(16, y - 18))
            .allowsHitTesting(false)
    }
}

// MARK: - Timeframe Control (minimal)
struct ChartTimeframeControl: View {
    @Binding var timeframe: TimeFrame
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        HStack(spacing: 6) {
            ForEach(TimeFrame.allCases, id: \.self) { tf in
                Button {
                    if timeframe != tf { timeframe = tf; Haptics.light() }
                } label: {
                    Text(tf.displayName)
                        .font(.system(size: 13, weight: timeframe == tf ? .semibold : .medium))
                        .foregroundColor(timeframe == tf ? .white : (themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(
                                timeframe == tf
                                ? AnyShapeStyle(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing))
                                : AnyShapeStyle((themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground).opacity(0.7))
                            )
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
    }
}

// MARK: - Data Generation (placeholder until real historical is wired)
private func generateDataFromCurrent(stock: Stock, timeframe: TimeFrame) async -> [ChartPoint] {
    let basePrice = max(1, stock.currentPrice)
    let count: Int
    let interval: TimeInterval

    switch timeframe {
    case .oneDay: count = 180; interval = 60 * 2 // every 2 minutes
    case .oneWeek: count = 5 * 48; interval = 60 * 30
    case .oneMonth: count = 30; interval = 24 * 60 * 60
    case .threeMonths: count = 13; interval = 7 * 24 * 60 * 60
    case .oneYear: count = 12; interval = 30 * 24 * 60 * 60
    }

    var points: [ChartPoint] = []
    var price = basePrice
    let now = Date()
    for i in 0..<count {
        let t = now.addingTimeInterval(-interval * Double(count - 1 - i))
        let trend = Double(i) / Double(max(1, count - 1)) * 0.1
        let vol = 0.018
        let noise = Double.random(in: -vol...vol)
        price = price * (1 + trend / Double(count) + noise)
        if i == count - 1 { price = basePrice }
        points.append(ChartPoint(date: t, price: max(price, basePrice * 0.8)))
    }
    return points
}

// MARK: - Utilities
private extension ClosedRange where Bound == Date {
    var duration: TimeInterval { upperBound.timeIntervalSince1970 - lowerBound.timeIntervalSince1970 }
}



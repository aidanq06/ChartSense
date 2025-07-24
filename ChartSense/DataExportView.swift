import SwiftUI

struct DataExportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var exportViewModel = DataExportViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Export Options
                    ExportOptionsSection(exportViewModel: exportViewModel)
                    
                    // Data Preview
                    if !exportViewModel.selectedDataTypes.isEmpty {
                        DataPreviewSection(exportViewModel: exportViewModel)
                    }
                    
                    // Export Button
                    ExportButton(
                        exportViewModel: exportViewModel,
                        onExport: exportViewModel.exportData
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                }
            }
            .alert("Export Complete", isPresented: $exportViewModel.showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your data has been exported successfully to the Files app.")
            }
        }
    }
}

// MARK: - Export Options Section
struct ExportOptionsSection: View {
    @ObservedObject var exportViewModel: DataExportViewModel
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Data to Export")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            
            VStack(spacing: 12) {
                ForEach(exportViewModel.availableDataTypes, id: \.id) { dataType in
                    ExportOptionCard(
                        dataType: dataType,
                        isSelected: exportViewModel.selectedDataTypes.contains(dataType.id),
                        onToggle: {
                            exportViewModel.toggleDataType(dataType.id)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Export Option Card
struct ExportOptionCard: View {
    let dataType: DataType
    let isSelected: Bool
    let onToggle: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            isSelected ? 
                            (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary) :
                            (themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryBackground : AppTheme.light.colors.tertiaryBackground)
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: dataType.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(
                            isSelected ? .white : (themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                        )
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(dataType.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    
                    Text(dataType.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    
                    Text("\(dataType.itemCount) items")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryText : AppTheme.light.colors.tertiaryText)
                }
                
                Spacer()
                
                // Checkbox
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
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Data Preview Section
struct DataPreviewSection: View {
    @ObservedObject var exportViewModel: DataExportViewModel
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export Preview")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            
            VStack(spacing: 12) {
                ForEach(Array(exportViewModel.selectedDataTypes), id: \.self) { dataTypeId in
                    if let dataType = exportViewModel.availableDataTypes.first(where: { $0.id == dataTypeId }) {
                        DataPreviewCard(dataType: dataType)
                    }
                }
            }
            
            // Export Summary
            ExportSummaryCard(exportViewModel: exportViewModel)
        }
    }
}

// MARK: - Data Preview Card
struct DataPreviewCard: View {
    let dataType: DataType
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: dataType.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                
                Text(dataType.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Spacer()
                
                Text("\(dataType.itemCount) items")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
            }
            
            // Sample data preview
            Text(dataType.sampleData)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                .lineLimit(3)
                .padding(12)
                .background(themeManager.isDarkMode ? AppTheme.dark.colors.tertiaryBackground : AppTheme.light.colors.tertiaryBackground)
                .cornerRadius(8)
        }
        .padding(16)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border, lineWidth: 0.5)
        )
    }
}

// MARK: - Export Summary Card
struct ExportSummaryCard: View {
    @ObservedObject var exportViewModel: DataExportViewModel
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Export Summary")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Items")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    
                    Text("\(exportViewModel.totalItemCount)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("File Size")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
                    
                    Text(exportViewModel.estimatedFileSize)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                }
            }
        }
        .padding(16)
        .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border, lineWidth: 0.5)
        )
    }
}

// MARK: - Export Button
struct ExportButton: View {
    @ObservedObject var exportViewModel: DataExportViewModel
    let onExport: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onExport) {
            HStack(spacing: 8) {
                if exportViewModel.isExporting {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(exportViewModel.isExporting ? "Exporting..." : "Export Data")
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
            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(exportViewModel.selectedDataTypes.isEmpty || exportViewModel.isExporting)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Data Export View Model
@MainActor
class DataExportViewModel: ObservableObject {
    @Published var selectedDataTypes: Set<String> = []
    @Published var isExporting = false
    @Published var showingSuccessAlert = false
    
    let availableDataTypes: [DataType] = [
        DataType(
            id: "watchlist",
            title: "Watchlist",
            description: "Your saved stocks and watchlists",
            icon: "list.bullet",
            itemCount: 12,
            sampleData: "AAPL, TSLA, GOOGL, MSFT, NVDA, AMZN, META, NFLX, AMD, INTC, CRM, ADBE"
        ),
        DataType(
            id: "settings",
            title: "Settings",
            description: "App preferences and configuration",
            icon: "gearshape.fill",
            itemCount: 15,
            sampleData: "Dark mode: true, Notifications: enabled, Refresh interval: 5 minutes, Chart style: candlestick"
        ),
        DataType(
            id: "search_history",
            title: "Search History",
            description: "Your recent stock searches",
            icon: "magnifyingglass",
            itemCount: 47,
            sampleData: "AAPL, TSLA, GOOGL, MSFT, NVDA, AMZN, META, NFLX, AMD, INTC, CRM, ADBE"
        ),
        DataType(
            id: "alerts",
            title: "Price Alerts",
            description: "Your configured price alerts",
            icon: "bell.fill",
            itemCount: 5,
            sampleData: "AAPL > $180, TSLA < $200, GOOGL > $140, MSFT > $350, NVDA > $800"
        )
    ]
    
    var totalItemCount: Int {
        selectedDataTypes.reduce(0) { total, dataTypeId in
            if let dataType = availableDataTypes.first(where: { $0.id == dataTypeId }) {
                return total + dataType.itemCount
            }
            return total
        }
    }
    
    var estimatedFileSize: String {
        let totalItems = totalItemCount
        let estimatedKB = totalItems * 2 // Rough estimate: 2KB per item
        if estimatedKB < 1024 {
            return "\(estimatedKB) KB"
        } else {
            let mb = Double(estimatedKB) / 1024.0
            return String(format: "%.1f MB", mb)
        }
    }
    
    func toggleDataType(_ dataTypeId: String) {
        if selectedDataTypes.contains(dataTypeId) {
            selectedDataTypes.remove(dataTypeId)
        } else {
            selectedDataTypes.insert(dataTypeId)
        }
    }
    
    func exportData() {
        isExporting = true
        
        // Simulate export process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isExporting = false
            self.showingSuccessAlert = true
        }
    }
}

// MARK: - Data Type Model
struct DataType {
    let id: String
    let title: String
    let description: String
    let icon: String
    let itemCount: Int
    let sampleData: String
} 
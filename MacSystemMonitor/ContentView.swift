import SwiftUI

struct ContentView: View {
    @EnvironmentObject var monitoringService: MonitoringService
    @State private var showingSettings = false
    @State private var showingExport = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Main content
            HStack(spacing: 0) {
                // Sidebar
                sidebarView
                    .frame(width: 250)
                
                // Main content area
                mainContentView
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingExport) {
            ExportView(activities: monitoringService.activities)
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Image(systemName: "shield.checkered")
                .font(.title2)
                .foregroundColor(.blue)
            
            Text("Mac System Monitor")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            // Status indicators
            HStack(spacing: 16) {
                statusIndicator(
                    title: "Monitoring",
                    status: monitoringService.monitoringStatus,
                    icon: "eye"
                )
                
                statusIndicator(
                    title: "USB Blocking",
                    status: monitoringService.usbBlockingStatus,
                    icon: "usb"
                )
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Settings") {
                    showingSettings = true
                }
                .buttonStyle(.bordered)
                
                Button("Export") {
                    showingExport = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .border(Color.gray.opacity(0.3), width: 1)
    }
    
    // MARK: - Sidebar View
    
    private var sidebarView: some View {
        VStack(spacing: 0) {
            // Control panel
            VStack(spacing: 16) {
                Text("Controls")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 12) {
                    Button(action: {
                        if monitoringService.monitoringStatus.isRunning {
                            monitoringService.stopMonitoring()
                        } else {
                            monitoringService.startMonitoring()
                        }
                    }) {
                        HStack {
                            Image(systemName: monitoringService.monitoringStatus.isRunning ? "stop.circle" : "play.circle")
                            Text(monitoringService.monitoringStatus.isRunning ? "Stop Monitoring" : "Start Monitoring")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Test N8N Connection") {
                        testN8nConnection()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!monitoringService.monitoringStatus.isRunning)
                }
                
                Divider()
                
                // Statistics
                VStack(alignment: .leading, spacing: 8) {
                    Text("Statistics")
                        .font(.headline)
                    
                    StatisticRow(title: "Total Activities", value: "\(monitoringService.activities.count)")
                    StatisticRow(title: "High Severity", value: "\(monitoringService.activities.filter { $0.severity == .high || $0.severity == .critical }.count)")
                    StatisticRow(title: "USB Events", value: "\(monitoringService.activities.filter { $0.type == .usbDrive || $0.type == .usbBlocked }.count)")
                }
            }
            .padding()
            
            Spacer()
        }
        .background(Color(NSColor.controlBackgroundColor))
        .border(Color.gray.opacity(0.3), width: 1)
    }
    
    // MARK: - Main Content View
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Activity log header
            HStack {
                Text("Activity Log")
                    .font(.headline)
                
                Spacer()
                
                Button("Clear") {
                    monitoringService.activities.removeAll()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // Activity list
            List(monitoringService.activities) { activity in
                ActivityRowView(activity: activity)
            }
            .listStyle(PlainListStyle())
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Status Indicator
    
    private func statusIndicator(title: String, status: MonitoringStatus, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(statusColor(status))
                Text(title)
                    .font(.caption)
            }
            
            Text(status.displayName)
                .font(.caption2)
                .foregroundColor(statusColor(status))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor(status).opacity(0.1))
        .cornerRadius(6)
    }
    
    private func statusColor(_ status: MonitoringStatus) -> Color {
        switch status {
        case .running:
            return .green
        case .stopped:
            return .red
        case .error:
            return .orange
        }
    }
    
    private func statusColor(_ status: UsbBlockingStatus) -> Color {
        switch status {
        case .enabled:
            return .green
        case .disabled:
            return .red
        case .error:
            return .orange
        }
    }
    
    // MARK: - Actions
    
    private func testN8nConnection() {
        let testActivity = ActivityEvent(
            type: .system,
            description: "N8N connection test",
            severity: .low,
            details: ["Test": "true"]
        )
        
        Task {
            // This will trigger the N8N send
            await monitoringService.sendToN8n(testActivity)
        }
    }
}

// MARK: - Activity Row View

struct ActivityRowView: View {
    let activity: ActivityEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: activity.type.icon)
                    .foregroundColor(severityColor(activity.severity))
                
                Text(activity.type.displayName)
                    .font(.headline)
                
                Spacer()
                
                Text(activity.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(activity.description)
                .font(.body)
            
            if !activity.details.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(activity.details.keys.sorted()), id: \.self) { key in
                        if let value = activity.details[key] {
                            HStack {
                                Text(key)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(value)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .padding(.leading)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func severityColor(_ severity: ActivitySeverity) -> Color {
        switch severity {
        case .low:
            return .green
        case .medium:
            return .yellow
        case .high:
            return .orange
        case .critical:
            return .red
        }
    }
}

// MARK: - Statistic Row View

struct StatisticRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Activity Type Icon Extension

extension ActivityType {
    var icon: String {
        switch self {
        case .usbDrive:
            return "externaldrive"
        case .usbBlocked:
            return "externaldrive.badge.xmark"
        case .uninstallDetected:
            return "trash"
        case .fileTransfer:
            return "doc.on.doc"
        case .appInstallation:
            return "app.badge.plus"
        case .blacklistedApp:
            return "exclamationmark.triangle"
        case .networkActivity:
            return "network"
        case .system:
            return "gear"
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("Settings")
                .font(.title)
            
            Text("Settings functionality will be implemented here.")
                .foregroundColor(.secondary)
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

// MARK: - Export View

struct ExportView: View {
    let activities: [ActivityEvent]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("Export Activities")
                .font(.title)
            
            Text("Export functionality will be implemented here.")
                .foregroundColor(.secondary)
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

#Preview {
    ContentView()
        .environmentObject(MonitoringService())
} 
import SwiftUI

struct ContentView: View {
    @StateObject private var monitoringService = MonitoringService()
    @State private var selectedTab = 0
    @State private var showingSettings = false
    @State private var isTestMode = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Mac System Monitor")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        StatusIndicator(status: monitoringService.monitoringStatus)
                        Text(monitoringService.monitoringStatus.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if isTestMode {
                            Text("TEST MODE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                // Test Mode Toggle
                Toggle("Test Mode", isOn: $isTestMode)
                    .toggleStyle(SwitchToggleStyle())
                    .onChange(of: isTestMode) { newValue in
                        toggleTestMode(newValue)
                    }
                
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gear")
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // Tab View
            TabView(selection: $selectedTab) {
                // Dashboard Tab
                DashboardView(monitoringService: monitoringService)
                    .tabItem {
                        Image(systemName: "chart.bar")
                        Text("Dashboard")
                    }
                    .tag(0)
                
                // Activities Tab
                ActivitiesView(activities: monitoringService.activities)
                    .tabItem {
                        Image(systemName: "list.bullet")
                        Text("Activities")
                    }
                    .tag(1)
                
                // USB Blocking Tab
                UsbBlockingView(monitoringService: monitoringService)
                    .tabItem {
                        Image(systemName: "externaldrive")
                        Text("USB Control")
                    }
                    .tag(2)
                
                // Settings Tab
                SettingsView(monitoringService: monitoringService)
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .tag(3)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showingSettings) {
            SettingsView(monitoringService: monitoringService)
        }
    }
    
    private func toggleTestMode(_ enabled: Bool) {
        // Stop current monitoring
        monitoringService.stopMonitoring()
        
        // Update configuration
        var config = AppConfig.loadFromFile()
        config.testModeSettings.enableTestMode = enabled
        
        // Save configuration
        config.saveToFile()
        
        // Restart monitoring with new configuration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            monitoringService.startMonitoring()
        }
    }
}

// MARK: - Status Indicator

struct StatusIndicator: View {
    let status: MonitoringStatus
    
    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
    }
    
    private var statusColor: Color {
        switch status {
        case .running:
            return .green
        case .stopped:
            return .red
        case .error:
            return .orange
        }
    }
}

// MARK: - Dashboard View

struct DashboardView: View {
    @ObservedObject var monitoringService: MonitoringService
    
    var body: some View {
        VStack(spacing: 20) {
            // Control Buttons
            HStack(spacing: 20) {
                Button(action: {
                    if monitoringService.monitoringStatus.isRunning {
                        monitoringService.stopMonitoring()
                    } else {
                        monitoringService.startMonitoring()
                    }
                }) {
                    HStack {
                        Image(systemName: monitoringService.monitoringStatus.isRunning ? "stop.fill" : "play.fill")
                        Text(monitoringService.monitoringStatus.isRunning ? "Stop Monitoring" : "Start Monitoring")
                    }
                    .padding()
                    .background(monitoringService.monitoringStatus.isRunning ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    monitoringService.activities.removeAll()
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear Activities")
                    }
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            
            // Statistics
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                StatCard(title: "Total Activities", value: "\(monitoringService.activities.count)", color: .blue)
                StatCard(title: "USB Events", value: "\(usbEventCount)", color: .green)
                StatCard(title: "File Transfers", value: "\(fileTransferCount)", color: .orange)
                StatCard(title: "App Installations", value: "\(appInstallationCount)", color: .purple)
                StatCard(title: "Network Events", value: "\(networkEventCount)", color: .red)
                StatCard(title: "Blocked Devices", value: "\(blockedDeviceCount)", color: .red)
            }
            
            // Recent Activities
            VStack(alignment: .leading) {
                Text("Recent Activities")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(monitoringService.activities.prefix(10)) { activity in
                            ActivityRow(activity: activity)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
    }
    
    private var usbEventCount: Int {
        monitoringService.activities.filter { $0.type == .usbDrive || $0.type == .usbBlocked }.count
    }
    
    private var fileTransferCount: Int {
        monitoringService.activities.filter { $0.type == .fileTransfer }.count
    }
    
    private var appInstallationCount: Int {
        monitoringService.activities.filter { $0.type == .appInstallation || $0.type == .blacklistedApp }.count
    }
    
    private var networkEventCount: Int {
        monitoringService.activities.filter { $0.type == .networkActivity }.count
    }
    
    private var blockedDeviceCount: Int {
        monitoringService.activities.filter { $0.type == .usbBlocked }.count
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let activity: ActivityEvent
    
    var body: some View {
        HStack {
            Image(systemName: activity.severity.icon)
                .foregroundColor(Color(activity.severity.color))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.description)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(activity.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(activity.type.displayName)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Activities View

struct ActivitiesView: View {
    let activities: [ActivityEvent]
    
    var body: some View {
        VStack {
            HStack {
                Text("Activity Log")
                    .font(.headline)
                
                Spacer()
                
                Text("\(activities.count) events")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            List(activities) { activity in
                ActivityRow(activity: activity)
            }
        }
    }
}

// MARK: - USB Blocking View

struct UsbBlockingView: View {
    @ObservedObject var monitoringService: MonitoringService
    
    var body: some View {
        VStack(spacing: 20) {
            // USB Blocking Status
            VStack(spacing: 10) {
                Text("USB Blocking Status")
                    .font(.headline)
                
                HStack {
                    Circle()
                        .fill(monitoringService.usbBlockingStatus.isEnabled ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    
                    Text(monitoringService.usbBlockingStatus.displayName)
                        .font(.subheadline)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // USB Blocking Controls
            VStack(spacing: 10) {
                Text("USB Blocking Controls")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    Button("Refresh Whitelist") {
                        Task {
                            await monitoringService.usbBlockingService?.refreshWhitelist()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Test USB Event") {
                        // This would trigger a test USB event in test mode
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var monitoringService: MonitoringService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            HStack {
                Text("Settings")
                    .font(.title)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
            }
            .padding()
            
            TabView {
                // General Settings
                VStack(alignment: .leading, spacing: 10) {
                    Text("General Settings")
                        .font(.headline)
                    
                    Toggle("Enable USB Monitoring", isOn: .constant(true))
                    Toggle("Enable File Transfer Monitoring", isOn: .constant(true))
                    Toggle("Enable App Installation Monitoring", isOn: .constant(true))
                    Toggle("Enable Network Monitoring", isOn: .constant(true))
                    Toggle("Send to N8N", isOn: .constant(true))
                    
                    Spacer()
                }
                .padding()
                .tabItem {
                    Image(systemName: "gear")
                    Text("General")
                }
                
                // Test Mode Settings
                VStack(alignment: .leading, spacing: 10) {
                    Text("Test Mode Settings")
                        .font(.headline)
                    
                    Toggle("Enable Test Mode", isOn: .constant(false))
                    Toggle("Simulate USB Events", isOn: .constant(true))
                    Toggle("Simulate File Transfers", isOn: .constant(true))
                    Toggle("Simulate App Installations", isOn: .constant(true))
                    Toggle("Simulate Network Activity", isOn: .constant(true))
                    Toggle("Use Test Webhook", isOn: .constant(true))
                    
                    Spacer()
                }
                .padding()
                .tabItem {
                    Image(systemName: "testtube.2")
                    Text("Test Mode")
                }
            }
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - Activity Severity Extension

extension ActivitySeverity {
    var icon: String {
        switch self {
        case .low:
            return "info.circle"
        case .medium:
            return "exclamationmark.triangle"
        case .high:
            return "exclamationmark.octagon"
        case .critical:
            return "xmark.octagon.fill"
        }
    }
    
    var color: String {
        switch self {
        case .low:
            return "green"
        case .medium:
            return "yellow"
        case .high:
            return "orange"
        case .critical:
            return "red"
        }
    }
} 
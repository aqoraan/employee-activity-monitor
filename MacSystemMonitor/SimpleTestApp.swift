import Foundation
import SwiftUI

// MARK: - Simple Test Application

@main
struct SimpleTestApp: App {
    @StateObject private var testService = SimpleTestService()
    
    var body: some Scene {
        WindowGroup {
            SimpleTestView()
                .environmentObject(testService)
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Generate Test Event") {
                    testService.generateTestEvent()
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])
                
                Button("Toggle Test Mode") {
                    testService.toggleTestMode()
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
            }
        }
    }
}

// MARK: - Simple Test Service

class SimpleTestService: ObservableObject {
    @Published var events: [TestEvent] = []
    @Published var isTestModeEnabled = true
    @Published var statistics = TestStatistics()
    
    private var testTimer: Timer?
    
    init() {
        startTestMode()
    }
    
    func toggleTestMode() {
        if isTestModeEnabled {
            stopTestMode()
        } else {
            startTestMode()
        }
    }
    
    func startTestMode() {
        isTestModeEnabled = true
        print("Test mode enabled - simulating events safely")
        
        // Start generating test events
        testTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            self.generateTestEvents()
        }
        
        // Generate initial events
        generateTestEvents()
    }
    
    func stopTestMode() {
        isTestModeEnabled = false
        testTimer?.invalidate()
        testTimer = nil
        print("Test mode disabled")
    }
    
    func generateTestEvent() {
        let event = TestEvent(
            type: .system,
            description: "Manual test event generated",
            severity: .medium,
            details: ["ManualTest": "true", "Timestamp": ISO8601DateFormatter().string(from: Date())]
        )
        
        addEvent(event)
    }
    
    private func generateTestEvents() {
        guard isTestModeEnabled else { return }
        
        let testEvents = [
            generateUsbEvent(),
            generateFileEvent(),
            generateAppEvent(),
            generateNetworkEvent()
        ]
        
        for event in testEvents {
            addEvent(event)
        }
    }
    
    private func generateUsbEvent() -> TestEvent {
        let devices = [
            ("SanDisk USB Drive", "USB\\VID_0781&PID_5567"),
            ("Kingston DataTraveler", "USB\\VID_0951&PID_1666"),
            ("Samsung USB Flash", "USB\\VID_04e8&PID_201d")
        ]
        
        let randomDevice = devices.randomElement()!
        let isBlocked = Bool.random()
        
        return TestEvent(
            type: isBlocked ? .usbBlocked : .usbDrive,
            description: isBlocked ? "TEST: USB device blocked: \(randomDevice.0)" : "TEST: USB device connected: \(randomDevice.0)",
            severity: isBlocked ? .high : .medium,
            details: [
                "DeviceID": randomDevice.1,
                "DeviceName": randomDevice.0,
                "TestEvent": "true",
                "Blocked": String(isBlocked)
            ]
        )
    }
    
    private func generateFileEvent() -> TestEvent {
        let files = [
            "document.pdf",
            "presentation.pptx",
            "spreadsheet.xlsx",
            "image.jpg",
            "video.mp4"
        ]
        
        let randomFile = files.randomElement()!
        let eventTypes = ["Created", "Modified", "Deleted"]
        let randomEvent = eventTypes.randomElement()!
        
        return TestEvent(
            type: .fileTransfer,
            description: "TEST: File \(randomEvent.lowercased()): \(randomFile)",
            severity: .medium,
            details: [
                "FilePath": "/Volumes/USB_DRIVE/\(randomFile)",
                "EventType": randomEvent,
                "TestEvent": "true"
            ]
        )
    }
    
    private func generateAppEvent() -> TestEvent {
        let apps = [
            ("Chrome", "Google Chrome"),
            ("Firefox", "Mozilla Firefox"),
            ("Slack", "Slack Technologies"),
            ("Zoom", "Zoom Video Communications"),
            ("Discord", "Discord Inc.")
        ]
        
        let randomApp = apps.randomElement()!
        let isBlacklisted = Bool.random()
        
        return TestEvent(
            type: isBlacklisted ? .blacklistedApp : .appInstallation,
            description: isBlacklisted ? "TEST: Blacklisted app detected: \(randomApp.0)" : "TEST: App installation: \(randomApp.0)",
            severity: isBlacklisted ? .high : .medium,
            details: [
                "AppName": randomApp.0,
                "Publisher": randomApp.1,
                "TestEvent": "true"
            ]
        )
    }
    
    private func generateNetworkEvent() -> TestEvent {
        let domains = [
            "mega.nz",
            "dropbox.com",
            "we-transfer.com",
            "file.io"
        ]
        
        let randomDomain = domains.randomElement()!
        
        return TestEvent(
            type: .networkActivity,
            description: "TEST: Suspicious network connection: \(randomDomain)",
            severity: .high,
            details: [
                "Domain": randomDomain,
                "ConnectionType": "HTTPS",
                "TestEvent": "true"
            ]
        )
    }
    
    private func addEvent(_ event: TestEvent) {
        DispatchQueue.main.async {
            self.events.insert(event, at: 0)
            
            // Update statistics
            self.updateStatistics()
            
            // Limit events
            if self.events.count > 100 {
                self.events = Array(self.events.prefix(100))
            }
            
            print("Test event generated: \(event.description)")
        }
    }
    
    private func updateStatistics() {
        statistics.totalEvents = events.count
        statistics.usbEvents = events.filter { $0.type == .usbDrive || $0.type == .usbBlocked }.count
        statistics.fileEvents = events.filter { $0.type == .fileTransfer }.count
        statistics.appEvents = events.filter { $0.type == .appInstallation || $0.type == .blacklistedApp }.count
        statistics.networkEvents = events.filter { $0.type == .networkActivity }.count
        statistics.blockedDevices = events.filter { $0.type == .usbBlocked }.count
    }
}

// MARK: - Test Event

struct TestEvent: Identifiable {
    let id = UUID()
    let type: TestEventType
    let description: String
    let timestamp: Date
    let severity: TestEventSeverity
    let details: [String: String]
    
    init(type: TestEventType, description: String, severity: TestEventSeverity = .medium, details: [String: String] = [:]) {
        self.type = type
        self.description = description
        self.timestamp = Date()
        self.severity = severity
        self.details = details
    }
}

// MARK: - Test Event Types

enum TestEventType: String, CaseIterable {
    case usbDrive = "USB Drive"
    case usbBlocked = "USB Blocked"
    case fileTransfer = "File Transfer"
    case appInstallation = "App Installation"
    case blacklistedApp = "Blacklisted App"
    case networkActivity = "Network Activity"
    case system = "System"
    
    var icon: String {
        switch self {
        case .usbDrive:
            return "externaldrive"
        case .usbBlocked:
            return "externaldrive.badge.xmark"
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
    
    var color: Color {
        switch self {
        case .usbDrive:
            return .green
        case .usbBlocked:
            return .red
        case .fileTransfer:
            return .orange
        case .appInstallation:
            return .blue
        case .blacklistedApp:
            return .red
        case .networkActivity:
            return .purple
        case .system:
            return .gray
        }
    }
}

// MARK: - Test Event Severity

enum TestEventSeverity: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var color: Color {
        switch self {
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
}

// MARK: - Test Statistics

struct TestStatistics {
    var totalEvents: Int = 0
    var usbEvents: Int = 0
    var fileEvents: Int = 0
    var appEvents: Int = 0
    var networkEvents: Int = 0
    var blockedDevices: Int = 0
}

// MARK: - Simple Test View

struct SimpleTestView: View {
    @EnvironmentObject var testService: SimpleTestService
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Mac System Monitor - Test Mode")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Circle()
                            .fill(testService.isTestModeEnabled ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text(testService.isTestModeEnabled ? "Test Mode Active" : "Test Mode Inactive")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if testService.isTestModeEnabled {
                            Text("SAFE TESTING")
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
                Toggle("Test Mode", isOn: $testService.isTestModeEnabled)
                    .toggleStyle(SwitchToggleStyle())
                    .onChange(of: testService.isTestModeEnabled) { newValue in
                        testService.toggleTestMode()
                    }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // Tab View
            TabView(selection: $selectedTab) {
                // Dashboard Tab
                DashboardTestView()
                    .tabItem {
                        Image(systemName: "chart.bar")
                        Text("Dashboard")
                    }
                    .tag(0)
                
                // Events Tab
                EventsTestView()
                    .tabItem {
                        Image(systemName: "list.bullet")
                        Text("Events")
                    }
                    .tag(1)
                
                // Settings Tab
                SettingsTestView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .tag(2)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

// MARK: - Dashboard Test View

struct DashboardTestView: View {
    @EnvironmentObject var testService: SimpleTestService
    
    var body: some View {
        VStack(spacing: 20) {
            // Control Buttons
            HStack(spacing: 20) {
                Button(action: {
                    testService.generateTestEvent()
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Generate Test Event")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    testService.events.removeAll()
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear Events")
                    }
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            
            // Statistics
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                StatCard(title: "Total Events", value: "\(testService.statistics.totalEvents)", color: .blue)
                StatCard(title: "USB Events", value: "\(testService.statistics.usbEvents)", color: .green)
                StatCard(title: "File Events", value: "\(testService.statistics.fileEvents)", color: .orange)
                StatCard(title: "App Events", value: "\(testService.statistics.appEvents)", color: .purple)
                StatCard(title: "Network Events", value: "\(testService.statistics.networkEvents)", color: .red)
                StatCard(title: "Blocked Devices", value: "\(testService.statistics.blockedDevices)", color: .red)
            }
            
            // Recent Events
            VStack(alignment: .leading) {
                Text("Recent Test Events")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(testService.events.prefix(10)) { event in
                            TestEventRow(event: event)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
    }
}

// MARK: - Events Test View

struct EventsTestView: View {
    @EnvironmentObject var testService: SimpleTestService
    
    var body: some View {
        VStack {
            HStack {
                Text("Test Events")
                    .font(.headline)
                
                Spacer()
                
                Text("\(testService.events.count) events")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            List(testService.events) { event in
                TestEventRow(event: event)
            }
        }
    }
}

// MARK: - Settings Test View

struct SettingsTestView: View {
    @EnvironmentObject var testService: SimpleTestService
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Test Mode Settings")
                .font(.title)
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Test Mode Information")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(title: "Status", value: testService.isTestModeEnabled ? "Active" : "Inactive")
                    InfoRow(title: "Events Generated", value: "\(testService.statistics.totalEvents)")
                    InfoRow(title: "Test Interval", value: "10 seconds")
                    InfoRow(title: "Max Events", value: "100")
                }
                
                Divider()
                
                Text("Safety Features")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    SafetyFeatureRow(title: "No System Monitoring", description: "Real system activities are not monitored")
                    SafetyFeatureRow(title: "No USB Blocking", description: "USB devices are never actually blocked")
                    SafetyFeatureRow(title: "No File Monitoring", description: "Real files are never monitored")
                    SafetyFeatureRow(title: "No Process Monitoring", description: "Real processes are never monitored")
                    SafetyFeatureRow(title: "No Network Monitoring", description: "Real network connections are never monitored")
                    SafetyFeatureRow(title: "No System Changes", description: "No registry or file system modifications")
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

// MARK: - Supporting Views

struct TestEventRow: View {
    let event: TestEvent
    
    var body: some View {
        HStack {
            Image(systemName: event.severity.icon)
                .foregroundColor(event.severity.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.description)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(event.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(event.type.rawValue)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(event.type.color.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
}

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

struct InfoRow: View {
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
                .fontWeight(.medium)
        }
    }
}

struct SafetyFeatureRow: View {
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
} 
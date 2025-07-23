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
        
        // Enhanced logging with device information
        logEnhancedEvent(event)
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
            // Enhanced logging with device information
            logEnhancedEvent(event)
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
    
    // MARK: - Enhanced Logging Integration
    
    private func logEnhancedEvent(_ event: TestEvent) {
        // Get device information
        let deviceInfo = getDeviceInfo()
        
        // Create enhanced log entry
        let enhancedLogEntry = createEnhancedLogEntry(event: event, deviceInfo: deviceInfo)
        
        // Print enhanced log to console
        printEnhancedLog(enhancedLogEntry)
        
        // Also log to file if possible
        logToFile(enhancedLogEntry)
    }
    
    private func getDeviceInfo() -> [String: Any] {
        let hostname = ProcessInfo.processInfo.hostName
        
        // Get system information
        let serialNumber = getSystemSerialNumber()
        let macAddresses = getMacAddresses()
        let hardwareUUID = getHardwareUUID()
        let modelIdentifier = getModelIdentifier()
        let processorInfo = getProcessorInfo()
        let memoryInfo = getMemoryInfo()
        let diskInfo = getDiskInfo()
        
        return [
            "serialNumber": serialNumber,
            "primaryMacAddress": macAddresses.first ?? "Unknown",
            "allMacAddresses": macAddresses,
            "biosSerialNumber": serialNumber,
            "motherboardSerialNumber": serialNumber,
            "hardwareUUID": hardwareUUID,
            "modelIdentifier": modelIdentifier,
            "processorInfo": processorInfo,
            "memoryInfo": memoryInfo,
            "diskInfo": diskInfo,
            "installationPath": "/Applications/MacSystemMonitor.app",
            "deviceFingerprint": createDeviceFingerprint(hostname: hostname, serialNumber: serialNumber)
        ]
    }
    
    private func getSystemSerialNumber() -> String {
        let task = Process()
        task.launchPath = "/usr/sbin/system_profiler"
        task.arguments = ["SPHardwareDataType"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            if let range = output.range(of: "Serial Number: "),
               let endRange = output[range.upperBound...].firstIndex(of: "\n") {
                return String(output[range.upperBound..<endRange]).trimmingCharacters(in: .whitespaces)
            }
        } catch {
            print("Error getting serial number: \(error)")
        }
        
        return "Unknown"
    }
    
    private func getMacAddresses() -> [String] {
        var addresses: [String] = []
        
        // Get primary MAC address
        let task = Process()
        task.launchPath = "/sbin/ifconfig"
        task.arguments = ["en0"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            if let range = output.range(of: "ether "),
               let endRange = output[range.upperBound...].firstIndex(of: " ") {
                let mac = String(output[range.upperBound..<endRange]).trimmingCharacters(in: .whitespaces)
                addresses.append(mac)
            }
        } catch {
            print("Error getting MAC address: \(error)")
        }
        
        return addresses.isEmpty ? ["Unknown"] : addresses
    }
    
    private func getHardwareUUID() -> String {
        let task = Process()
        task.launchPath = "/usr/sbin/system_profiler"
        task.arguments = ["SPHardwareDataType"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            if let range = output.range(of: "Hardware UUID: "),
               let endRange = output[range.upperBound...].firstIndex(of: "\n") {
                return String(output[range.upperBound..<endRange]).trimmingCharacters(in: .whitespaces)
            }
        } catch {
            print("Error getting Hardware UUID: \(error)")
        }
        
        return "Unknown"
    }
    
    private func getModelIdentifier() -> String {
        let task = Process()
        task.launchPath = "/usr/sbin/system_profiler"
        task.arguments = ["SPHardwareDataType"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            if let range = output.range(of: "Model Identifier: "),
               let endRange = output[range.upperBound...].firstIndex(of: "\n") {
                return String(output[range.upperBound..<endRange]).trimmingCharacters(in: .whitespaces)
            }
        } catch {
            print("Error getting Model Identifier: \(error)")
        }
        
        return "Unknown"
    }
    
    private func getProcessorInfo() -> String {
        let task = Process()
        task.launchPath = "/usr/sbin/system_profiler"
        task.arguments = ["SPHardwareDataType"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            if let range = output.range(of: "Chip: "),
               let endRange = output[range.upperBound...].firstIndex(of: "\n") {
                return String(output[range.upperBound..<endRange]).trimmingCharacters(in: .whitespaces)
            }
        } catch {
            print("Error getting Processor Info: \(error)")
        }
        
        return "Unknown"
    }
    
    private func getMemoryInfo() -> String {
        let task = Process()
        task.launchPath = "/usr/sbin/system_profiler"
        task.arguments = ["SPHardwareDataType"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            if let range = output.range(of: "Memory: "),
               let endRange = output[range.upperBound...].firstIndex(of: "\n") {
                return String(output[range.upperBound..<endRange]).trimmingCharacters(in: .whitespaces)
            }
        } catch {
            print("Error getting Memory Info: \(error)")
        }
        
        return "Unknown"
    }
    
    private func getDiskInfo() -> String {
        let task = Process()
        task.launchPath = "/bin/df"
        task.arguments = ["-h", "/"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            let lines = output.components(separatedBy: "\n")
            if lines.count > 1 {
                let parts = lines[1].components(separatedBy: " ")
                if parts.count > 1 {
                    return parts[1]
                }
            }
        } catch {
            print("Error getting Disk Info: \(error)")
        }
        
        return "Unknown"
    }
    
    private func createDeviceFingerprint(hostname: String, serialNumber: String) -> String {
        let fingerprint = "\(hostname)-\(serialNumber)-\(Date().timeIntervalSince1970)"
        return fingerprint.data(using: .utf8)?.base64EncodedString() ?? "Unknown"
    }
    
    private func createEnhancedLogEntry(event: TestEvent, deviceInfo: [String: Any]) -> [String: Any] {
        return [
            "timestamp": ISO8601DateFormatter().string(from: event.timestamp),
            "type": event.type.rawValue,
            "severity": event.severity.rawValue,
            "description": event.description,
            "computer": ProcessInfo.processInfo.hostName,
            "user": NSUserName(),
            "details": event.details,
            "deviceInfo": deviceInfo,
            "testEvent": true
        ]
    }
    
    private func printEnhancedLog(_ logEntry: [String: Any]) {
        print("🔍 ENHANCED LOG ENTRY:")
        print("📅 Time: \(logEntry["timestamp"] ?? "Unknown")")
        print("🖥️ Computer: \(logEntry["computer"] ?? "Unknown")")
        print("👤 User: \(logEntry["user"] ?? "Unknown")")
        
        if let deviceInfo = logEntry["deviceInfo"] as? [String: Any] {
            print("📱 Serial Number: \(deviceInfo["serialNumber"] ?? "Unknown")")
            print("🌐 MAC Address: \(deviceInfo["primaryMacAddress"] ?? "Unknown")")
            print("🔧 Hardware UUID: \(deviceInfo["hardwareUUID"] ?? "Unknown")")
            print("💻 Model: \(deviceInfo["modelIdentifier"] ?? "Unknown")")
            print("⚡ Processor: \(deviceInfo["processorInfo"] ?? "Unknown")")
            print("💾 Memory: \(deviceInfo["memoryInfo"] ?? "Unknown")")
            print("💿 Disk: \(deviceInfo["diskInfo"] ?? "Unknown")")
        } else {
            print("📱 Serial Number: Unknown")
            print("🌐 MAC Address: Unknown")
            print("🔧 Hardware UUID: Unknown")
            print("💻 Model: Unknown")
            print("⚡ Processor: Unknown")
            print("💾 Memory: Unknown")
            print("💿 Disk: Unknown")
        }
        
        print("🎯 Event: \(logEntry["description"] ?? "Unknown")")
        
        if let details = logEntry["details"] as? [String: String] {
            print("📋 Details:")
            for (key, value) in details {
                print("   \(key): \(value)")
            }
        }
        
        print("---")
    }
    
    private func logToFile(_ logEntry: [String: Any]) {
        // Create log directory if it doesn't exist
        let logDir = "/tmp/mac-system-monitor-test"
        let logFile = "\(logDir)/enhanced-test.log"
        
        do {
            if !FileManager.default.fileExists(atPath: logDir) {
                try FileManager.default.createDirectory(atPath: logDir, withIntermediateDirectories: true)
            }
            
            let logData = try JSONSerialization.data(withJSONObject: logEntry, options: .prettyPrinted)
            let logString = String(data: logData, encoding: .utf8)! + "\n---\n"
            
            if let fileHandle = FileHandle(forWritingAtPath: logFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(logString.data(using: .utf8)!)
                fileHandle.closeFile()
            } else {
                try logString.write(toFile: logFile, atomically: true, encoding: .utf8)
            }
        } catch {
            print("Failed to write to log file: \(error)")
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
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main event row
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
                
                Button(action: {
                    showDetails.toggle()
                }) {
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            
            // Enhanced log details (expandable)
            if showDetails {
                VStack(alignment: .leading, spacing: 6) {
                    Divider()
                    
                    // Device Information
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Device Information")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        DeviceInfoRow(icon: "number", label: "Serial Number", value: getDeviceSerialNumber())
                        DeviceInfoRow(icon: "network", label: "MAC Address", value: getDeviceMacAddress())
                        DeviceInfoRow(icon: "cpu", label: "Hardware UUID", value: getDeviceHardwareUUID())
                        DeviceInfoRow(icon: "desktopcomputer", label: "Model", value: getDeviceModel())
                        DeviceInfoRow(icon: "memorychip", label: "Processor", value: getDeviceProcessor())
                        DeviceInfoRow(icon: "memorychip", label: "Memory", value: getDeviceMemory())
                        DeviceInfoRow(icon: "externaldrive", label: "Disk", value: getDeviceDisk())
                    }
                    
                    Divider()
                    
                    // Event Details
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Event Details")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        ForEach(Array(event.details.keys.sorted()), id: \.self) { key in
                            if let value = event.details[key] {
                                DeviceInfoRow(icon: "info.circle", label: key, value: value)
                            }
                        }
                    }
                }
                .padding(.leading, 20)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
            }
        }
    }
    
    // Device information getters
    private func getDeviceSerialNumber() -> String {
        let task = Process()
        task.launchPath = "/usr/sbin/system_profiler"
        task.arguments = ["SPHardwareDataType"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            if let range = output.range(of: "Serial Number: "),
               let endRange = output[range.upperBound...].firstIndex(of: "\n") {
                return String(output[range.upperBound..<endRange]).trimmingCharacters(in: .whitespaces)
            }
        } catch {
            return "Unknown"
        }
        
        return "Unknown"
    }
    
    private func getDeviceMacAddress() -> String {
        let task = Process()
        task.launchPath = "/sbin/ifconfig"
        task.arguments = ["en0"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            if let range = output.range(of: "ether "),
               let endRange = output[range.upperBound...].firstIndex(of: " ") {
                return String(output[range.upperBound..<endRange]).trimmingCharacters(in: .whitespaces)
            }
        } catch {
            return "Unknown"
        }
        
        return "Unknown"
    }
    
    private func getDeviceHardwareUUID() -> String {
        let task = Process()
        task.launchPath = "/usr/sbin/system_profiler"
        task.arguments = ["SPHardwareDataType"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            if let range = output.range(of: "Hardware UUID: "),
               let endRange = output[range.upperBound...].firstIndex(of: "\n") {
                return String(output[range.upperBound..<endRange]).trimmingCharacters(in: .whitespaces)
            }
        } catch {
            return "Unknown"
        }
        
        return "Unknown"
    }
    
    private func getDeviceModel() -> String {
        let task = Process()
        task.launchPath = "/usr/sbin/system_profiler"
        task.arguments = ["SPHardwareDataType"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            if let range = output.range(of: "Model Identifier: "),
               let endRange = output[range.upperBound...].firstIndex(of: "\n") {
                return String(output[range.upperBound..<endRange]).trimmingCharacters(in: .whitespaces)
            }
        } catch {
            return "Unknown"
        }
        
        return "Unknown"
    }
    
    private func getDeviceProcessor() -> String {
        let task = Process()
        task.launchPath = "/usr/sbin/system_profiler"
        task.arguments = ["SPHardwareDataType"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            if let range = output.range(of: "Chip: "),
               let endRange = output[range.upperBound...].firstIndex(of: "\n") {
                return String(output[range.upperBound..<endRange]).trimmingCharacters(in: .whitespaces)
            }
        } catch {
            return "Unknown"
        }
        
        return "Unknown"
    }
    
    private func getDeviceMemory() -> String {
        let task = Process()
        task.launchPath = "/usr/sbin/system_profiler"
        task.arguments = ["SPHardwareDataType"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            if let range = output.range(of: "Memory: "),
               let endRange = output[range.upperBound...].firstIndex(of: "\n") {
                return String(output[range.upperBound..<endRange]).trimmingCharacters(in: .whitespaces)
            }
        } catch {
            return "Unknown"
        }
        
        return "Unknown"
    }
    
    private func getDeviceDisk() -> String {
        let task = Process()
        task.launchPath = "/bin/df"
        task.arguments = ["-h", "/"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            let lines = output.components(separatedBy: "\n")
            if lines.count > 1 {
                let parts = lines[1].components(separatedBy: " ")
                if parts.count > 1 {
                    return parts[1]
                }
            }
        } catch {
            return "Unknown"
        }
        
        return "Unknown"
    }
}

struct DeviceInfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 12)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
                .lineLimit(1)
        }
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
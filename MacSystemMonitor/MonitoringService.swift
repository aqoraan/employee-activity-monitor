import Foundation
import IOKit
import SystemConfiguration

class MonitoringService: ObservableObject {
    @Published var monitoringStatus: MonitoringStatus = .stopped
    @Published var usbBlockingStatus: UsbBlockingStatus = .disabled
    @Published var activities: [ActivityEvent] = []
    
    private let config: AppConfig
    private var usbBlockingService: UsbBlockingService?
    private var sheetsManager: GoogleSheetsManager?
    private var uninstallDetectionService: UninstallDetectionService?
    private var isMonitoring: Bool = false
    private var testModeTimer: Timer?
    
    weak var delegate: MonitoringServiceDelegate?
    
    init(config: AppConfig = AppConfig.loadFromFile()) {
        self.config = config
        
        // Initialize USB blocking if enabled and not in test mode
        if !config.testModeSettings.enableTestMode &&
           config.usbBlockingSettings.enableUsbBlocking &&
           !config.usbBlockingSettings.googleSheetsApiKey.isEmpty &&
           !config.usbBlockingSettings.googleSheetsSpreadsheetId.isEmpty {
            
            sheetsManager = GoogleSheetsManager(
                apiKey: config.usbBlockingSettings.googleSheetsApiKey,
                spreadsheetId: config.usbBlockingSettings.googleSheetsSpreadsheetId,
                range: config.usbBlockingSettings.googleSheetsRange,
                cacheExpirationMinutes: config.usbBlockingSettings.cacheExpirationMinutes
            )
            
            usbBlockingService = UsbBlockingService(sheetsManager: sheetsManager!, enableBlocking: true)
            usbBlockingService?.delegate = self
        }
        
        // Initialize uninstall detection (only if not in test mode)
        if !config.testModeSettings.enableTestMode && !config.n8nWebhookUrl.isEmpty {
            uninstallDetectionService = UninstallDetectionService(n8nWebhookUrl: config.n8nWebhookUrl)
            uninstallDetectionService?.initializeUninstallDetection()
            uninstallDetectionService?.setupProcessExitHandling()
        }
    }
    
    // MARK: - Monitoring Control
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        monitoringStatus = .running
        
        if config.testModeSettings.enableTestMode {
            startTestMode()
        } else {
            startRealMonitoring()
        }
        
        print("Monitoring started" + (config.testModeSettings.enableTestMode ? " (TEST MODE)" : ""))
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        monitoringStatus = .stopped
        
        if config.testModeSettings.enableTestMode {
            stopTestMode()
        } else {
            stopRealMonitoring()
        }
        
        print("Monitoring stopped")
    }
    
    // MARK: - Test Mode
    
    private func startTestMode() {
        print("Starting test mode - simulating events without system changes")
        
        // Start test timer
        testModeTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(config.testModeSettings.testIntervalSeconds), repeats: true) { _ in
            self.generateTestEvents()
        }
        
        // Generate initial test events
        generateTestEvents()
    }
    
    private func stopTestMode() {
        testModeTimer?.invalidate()
        testModeTimer = nil
    }
    
    private func generateTestEvents() {
        guard config.testModeSettings.enableTestMode else { return }
        
        let testEvents = [
            generateTestUsbEvent(),
            generateTestFileTransferEvent(),
            generateTestAppInstallationEvent(),
            generateTestNetworkEvent()
        ]
        
        for event in testEvents {
            if event != nil {
                addActivity(event!)
            }
        }
    }
    
    private func generateTestUsbEvent() -> ActivityEvent? {
        guard config.testModeSettings.simulateUsbEvents else { return nil }
        
        let testDevices = [
            ("SanDisk USB Drive", "USB\\VID_0781&PID_5567"),
            ("Kingston DataTraveler", "USB\\VID_0951&PID_1666"),
            ("Samsung USB Flash", "USB\\VID_04e8&PID_201d")
        ]
        
        let randomDevice = testDevices.randomElement()!
        let isBlocked = Bool.random()
        
        return ActivityEvent(
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
    
    private func generateTestFileTransferEvent() -> ActivityEvent? {
        guard config.testModeSettings.simulateFileTransfers else { return nil }
        
        let testFiles = [
            "document.pdf",
            "presentation.pptx",
            "spreadsheet.xlsx",
            "image.jpg",
            "video.mp4"
        ]
        
        let randomFile = testFiles.randomElement()!
        let eventTypes = ["Created", "Modified", "Deleted"]
        let randomEvent = eventTypes.randomElement()!
        
        return ActivityEvent(
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
    
    private func generateTestAppInstallationEvent() -> ActivityEvent? {
        guard config.testModeSettings.simulateAppInstallations else { return nil }
        
        let testApps = [
            ("Chrome", "Google Chrome"),
            ("Firefox", "Mozilla Firefox"),
            ("Slack", "Slack Technologies"),
            ("Zoom", "Zoom Video Communications"),
            ("Discord", "Discord Inc.")
        ]
        
        let randomApp = testApps.randomElement()!
        let isBlacklisted = Bool.random()
        
        return ActivityEvent(
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
    
    private func generateTestNetworkEvent() -> ActivityEvent? {
        guard config.testModeSettings.simulateNetworkActivity else { return nil }
        
        let testDomains = [
            "mega.nz",
            "dropbox.com",
            "we-transfer.com",
            "file.io"
        ]
        
        let randomDomain = testDomains.randomElement()!
        
        return ActivityEvent(
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
    
    // MARK: - Real Monitoring
    
    private func startRealMonitoring() {
        // Start USB blocking first if enabled
        if let usbService = usbBlockingService {
            usbService.startBlocking()
            usbBlockingStatus = .enabled
        }
        
        // Start various monitoring components
        if config.monitoringSettings.enableUsbMonitoring {
            startUsbMonitoring()
        }
        
        if config.monitoringSettings.enableAppInstallationMonitoring ||
           config.monitoringSettings.enableBlacklistedAppMonitoring {
            startProcessMonitoring()
        }
        
        if config.monitoringSettings.enableFileTransferMonitoring {
            startFileTransferMonitoring()
        }
        
        if config.monitoringSettings.enableNetworkMonitoring {
            startNetworkMonitoring()
        }
    }
    
    private func stopRealMonitoring() {
        usbBlockingService?.stopBlocking()
        usbBlockingStatus = .disabled
    }
    
    // MARK: - USB Monitoring
    
    private func startUsbMonitoring() {
        // USB monitoring is handled by UsbBlockingService
        print("USB monitoring started")
    }
    
    // MARK: - Process Monitoring
    
    private func startProcessMonitoring() {
        // Monitor for new processes using system_profiler and ps
        let queue = DispatchQueue.global(qos: .background)
        queue.async {
            self.monitorProcesses()
        }
    }
    
    private func monitorProcesses() {
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-ax", "-o", "pid,comm,args"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                
                for line in lines {
                    let components = line.components(separatedBy: .whitespaces)
                    if components.count >= 2 {
                        let processName = components[1]
                        let commandLine = line
                        
                        // Check for blacklisted applications
                        if config.monitoringSettings.enableBlacklistedAppMonitoring &&
                           isBlacklistedApp(processName) {
                            
                            let activity = ActivityEvent(
                                type: .blacklistedApp,
                                description: "Blacklisted application detected: \(processName)",
                                severity: .high,
                                details: [
                                    "ProcessName": processName,
                                    "CommandLine": commandLine
                                ]
                            )
                            
                            DispatchQueue.main.async {
                                self.addActivity(activity)
                            }
                        }
                        
                        // Check for installation activities
                        if config.monitoringSettings.enableAppInstallationMonitoring &&
                           isInstallationProcess(processName, commandLine: commandLine) {
                            
                            let activity = ActivityEvent(
                                type: .appInstallation,
                                description: "Application installation detected: \(processName)",
                                severity: .medium,
                                details: [
                                    "ProcessName": processName,
                                    "CommandLine": commandLine
                                ]
                            )
                            
                            DispatchQueue.main.async {
                                self.addActivity(activity)
                            }
                        }
                    }
                }
            }
        } catch {
            print("Failed to monitor processes: \(error)")
        }
        
        // Schedule next check
        DispatchQueue.global().asyncAfter(deadline: .now() + 10.0) {
            self.monitorProcesses()
        }
    }
    
    private func isBlacklistedApp(_ processName: String) -> Bool {
        return config.blacklistedApps.contains { processName.lowercased().contains($0.lowercased()) }
    }
    
    private func isInstallationProcess(_ processName: String, commandLine: String) -> Bool {
        let installKeywords = ["install", "setup", "pkg", "dmg", "installer", "uninstall"]
        let processNameLower = processName.lowercased()
        let commandLineLower = commandLine.lowercased()
        
        return installKeywords.contains { keyword in
            processNameLower.contains(keyword) || commandLineLower.contains(keyword)
        }
    }
    
    // MARK: - File Transfer Monitoring
    
    private func startFileTransferMonitoring() {
        // Monitor common external storage locations
        let externalPaths = [
            "/Volumes",
            NSHomeDirectory() + "/Desktop",
            NSHomeDirectory() + "/Downloads"
        ]
        
        for path in externalPaths {
            monitorDirectory(path)
        }
    }
    
    private func monitorDirectory(_ path: String) {
        let queue = DispatchQueue.global(qos: .background)
        queue.async {
            self.watchDirectory(path)
        }
    }
    
    private func watchDirectory(_ path: String) {
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: path) else { return }
        
        // Get initial file list
        var initialFiles: Set<String> = []
        do {
            let files = try fileManager.contentsOfDirectory(atPath: path)
            initialFiles = Set(files)
        } catch {
            print("Failed to get initial file list for \(path): \(error)")
            return
        }
        
        // Monitor for changes
        DispatchQueue.global().asyncAfter(deadline: .now() + 5.0) {
            do {
                let currentFiles = try fileManager.contentsOfDirectory(atPath: path)
                let currentFileSet = Set(currentFiles)
                
                // Check for new files
                let newFiles = currentFileSet.subtracting(initialFiles)
                for file in newFiles {
                    let filePath = path + "/" + file
                    let activity = ActivityEvent(
                        type: .fileTransfer,
                        description: "File created: \(file)",
                        severity: .medium,
                        details: [
                            "FilePath": filePath,
                            "Directory": path,
                            "EventType": "Created"
                        ]
                    )
                    
                    DispatchQueue.main.async {
                        self.addActivity(activity)
                    }
                }
                
                // Check for deleted files
                let deletedFiles = initialFiles.subtracting(currentFileSet)
                for file in deletedFiles {
                    let activity = ActivityEvent(
                        type: .fileTransfer,
                        description: "File deleted: \(file)",
                        severity: .low,
                        details: [
                            "FilePath": path + "/" + file,
                            "Directory": path,
                            "EventType": "Deleted"
                        ]
                    )
                    
                    DispatchQueue.main.async {
                        self.addActivity(activity)
                    }
                }
                
                // Update initial files for next check
                initialFiles = currentFileSet
            } catch {
                print("Failed to monitor directory \(path): \(error)")
            }
            
            // Continue monitoring
            self.watchDirectory(path)
        }
    }
    
    // MARK: - Network Activity Monitoring
    
    private func startNetworkMonitoring() {
        // Monitor network connections using netstat
        let queue = DispatchQueue.global(qos: .background)
        queue.async {
            self.monitorNetworkConnections()
        }
    }
    
    private func monitorNetworkConnections() {
        let task = Process()
        task.launchPath = "/usr/bin/netstat"
        task.arguments = ["-an"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                
                for line in lines {
                    if line.contains("ESTABLISHED") {
                        // Check for suspicious connections
                        for domain in config.suspiciousDomains {
                            if line.contains(domain) {
                                let activity = ActivityEvent(
                                    type: .networkActivity,
                                    description: "Suspicious network connection detected",
                                    severity: .high,
                                    details: [
                                        "Connection": line,
                                        "SuspiciousDomain": domain
                                    ]
                                )
                                
                                DispatchQueue.main.async {
                                    self.addActivity(activity)
                                }
                                break
                            }
                        }
                    }
                }
            }
        } catch {
            print("Failed to monitor network connections: \(error)")
        }
        
        // Schedule next check
        DispatchQueue.global().asyncAfter(deadline: .now() + 30.0) {
            self.monitorNetworkConnections()
        }
    }
    
    // MARK: - Activity Management
    
    func addActivity(_ activity: ActivityEvent) {
        DispatchQueue.main.async {
            self.activities.insert(activity, at: 0)
            
            // Limit the number of activities
            if self.activities.count > self.config.monitoringSettings.maxLogEntries {
                self.activities = Array(self.activities.prefix(self.config.monitoringSettings.maxLogEntries))
            }
            
            // Send to N8N if enabled
            if self.config.monitoringSettings.sendToN8n {
                Task {
                    await self.sendToN8n(activity)
                }
            }
            
            // Notify delegate
            self.delegate?.activityDetected(activity)
        }
    }
    
    // MARK: - N8N Integration
    
    private func sendToN8n(_ activity: ActivityEvent) async {
        let webhookUrl = config.testModeSettings.enableTestMode && config.testModeSettings.useTestWebhook 
            ? config.testModeSettings.testWebhookUrl 
            : config.n8nWebhookUrl
        
        guard !webhookUrl.isEmpty else { return }
        
        for attempt in 1...config.monitoringSettings.n8nRetryAttempts {
            do {
                let payload = N8nPayload(from: activity)
                let jsonData = try JSONEncoder().encode(payload)
                
                var request = URLRequest(url: URL(string: webhookUrl)!)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = jsonData
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("Activity sent to N8N successfully" + (config.testModeSettings.enableTestMode ? " (TEST MODE)" : ""))
                        break
                    } else {
                        throw NSError(domain: "N8N", code: httpResponse.statusCode, userInfo: nil)
                    }
                }
            } catch {
                print("Failed to send to N8N (attempt \(attempt)): \(error)")
                
                if attempt < config.monitoringSettings.n8nRetryAttempts {
                    try? await Task.sleep(nanoseconds: UInt64(config.monitoringSettings.n8nRetryDelayMs * 1_000_000))
                }
            }
        }
    }
    
    // MARK: - Uninstall Notification
    
    func sendUninstallNotification() async {
        await uninstallDetectionService?.sendUninstallNotification()
    }
}

// MARK: - Monitoring Service Delegate

protocol MonitoringServiceDelegate: AnyObject {
    func activityDetected(_ activity: ActivityEvent)
}

// MARK: - USB Blocking Service Delegate Implementation

extension MonitoringService: UsbBlockingServiceDelegate {
    func usbDeviceBlocked(_ event: UsbBlockingEvent) {
        let activity = ActivityEvent(
            type: .usbBlocked,
            description: "USB device blocked: \(event.deviceName ?? event.deviceId)",
            severity: .high,
            details: [
                "DeviceID": event.deviceId,
                "Reason": event.reason,
                "Blocked": String(event.blocked)
            ]
        )
        
        addActivity(activity)
    }
    
    func usbDeviceRemoved(_ deviceInfo: UsbDeviceInfo) {
        let activity = ActivityEvent(
            type: .usbDrive,
            description: "USB device removed: \(deviceInfo.displayName)",
            severity: .medium,
            details: [
                "DeviceID": deviceInfo.deviceId,
                "DeviceName": deviceInfo.displayName
            ]
        )
        
        addActivity(activity)
    }
} 
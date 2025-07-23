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
    
    weak var delegate: MonitoringServiceDelegate?
    
    init(config: AppConfig = AppConfig.loadFromFile()) {
        self.config = config
        
        // Initialize USB blocking if enabled
        if config.usbBlockingSettings.enableUsbBlocking &&
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
        
        // Initialize uninstall detection
        if !config.n8nWebhookUrl.isEmpty {
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
        
        print("Monitoring started")
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        monitoringStatus = .stopped
        
        usbBlockingService?.stopBlocking()
        usbBlockingStatus = .disabled
        
        print("Monitoring stopped")
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
    
    private func addActivity(_ activity: ActivityEvent) {
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
        guard !config.n8nWebhookUrl.isEmpty else { return }
        
        for attempt in 1...config.monitoringSettings.n8nRetryAttempts {
            do {
                let payload = N8nPayload(from: activity)
                let jsonData = try JSONEncoder().encode(payload)
                
                var request = URLRequest(url: URL(string: config.n8nWebhookUrl)!)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = jsonData
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("Activity sent to N8N successfully")
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
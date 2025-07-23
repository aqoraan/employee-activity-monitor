import Foundation

class UninstallDetectionService {
    private let n8nWebhookUrl: String
    private let uninstallFlagFile: String
    private let configPath: String
    
    init(n8nWebhookUrl: String) {
        self.n8nWebhookUrl = n8nWebhookUrl
        self.uninstallFlagFile = "/Library/Application Support/MacSystemMonitor/uninstall_detected.flag"
        self.configPath = "/Library/Application Support/MacSystemMonitor/config.json"
    }
    
    // MARK: - Uninstall Detection Initialization
    
    func initializeUninstallDetection() {
        do {
            // Create uninstall flag file to detect uninstallation
            let directory = "/Library/Application Support/MacSystemMonitor"
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
            
            // Write current process info to flag file
            let processInfo = [
                "processId": ProcessInfo.processInfo.processIdentifier,
                "startTime": ISO8601DateFormatter().string(from: Date()),
                "installationPath": Bundle.main.bundlePath,
                "userName": NSUserName(),
                "computerName": Host.current().localizedName ?? "Unknown"
            ]
            
            let processInfoData = try JSONSerialization.data(withJSONObject: processInfo, options: .prettyPrinted)
            try processInfoData.write(to: URL(fileURLWithPath: uninstallFlagFile))
            
            // Set up file system monitoring for uninstall detection
            setupUninstallMonitoring()
            
            print("Uninstall detection initialized")
        } catch {
            print("Failed to initialize uninstall detection: \(error)")
        }
    }
    
    private func setupUninstallMonitoring() {
        // Monitor the application bundle for changes
        let appPath = Bundle.main.bundlePath
        let fileManager = FileManager.default
        
        // Set up file system monitoring
        let queue = DispatchQueue.global(qos: .background)
        queue.async {
            self.monitorApplicationBundle(at: appPath)
        }
    }
    
    private func monitorApplicationBundle(at path: String) {
        let fileManager = FileManager.default
        
        // Check if application bundle still exists
        if !fileManager.fileExists(atPath: path) {
            print("Application bundle removed - uninstall detected")
            Task {
                await sendUninstallNotification()
            }
            return
        }
        
        // Check for uninstall flags
        if fileManager.fileExists(atPath: uninstallFlagFile) {
            print("Uninstall flag detected")
            Task {
                await sendUninstallNotification()
            }
            return
        }
        
        // Schedule next check
        DispatchQueue.global().asyncAfter(deadline: .now() + 5.0) {
            self.monitorApplicationBundle(at: path)
        }
    }
    
    // MARK: - Uninstall Notification
    
    func sendUninstallNotification() async {
        do {
            let deviceInfo = DeviceInfoManager.getDeviceInfo()
            
            let uninstallData: [String: Any] = [
                "eventType": "UninstallDetected",
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "severity": "Critical",
                "computer": deviceInfo.computerName,
                "user": deviceInfo.userName,
                "deviceInfo": [
                    "serialNumber": deviceInfo.serialNumber,
                    "primaryMacAddress": deviceInfo.primaryMacAddress,
                    "allMacAddresses": deviceInfo.macAddresses,
                    "biosSerialNumber": deviceInfo.biosSerialNumber,
                    "motherboardSerialNumber": deviceInfo.motherboardSerialNumber,
                    "macOSProductId": deviceInfo.macOSProductId,
                    "installationPath": deviceInfo.installationPath,
                    "deviceFingerprint": DeviceInfoManager.getDeviceFingerprint()
                ],
                "uninstallDetails": [
                    "processId": ProcessInfo.processInfo.processIdentifier,
                    "processName": ProcessInfo.processInfo.processName,
                    "commandLine": ProcessInfo.processInfo.arguments.joined(separator: " "),
                    "uninstallTime": ISO8601DateFormatter().string(from: Date())
                ]
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: uninstallData, options: .prettyPrinted)
            
            var request = URLRequest(url: URL(string: n8nWebhookUrl)!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("Uninstall notification sent successfully")
                } else {
                    print("Failed to send uninstall notification: HTTP \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("Error sending uninstall notification: \(error)")
        }
    }
    
    // MARK: - Uninstall Detection Methods
    
    func checkForUninstallAttempts() -> Bool {
        let fileManager = FileManager.default
        
        // Check if application bundle still exists
        let appPath = Bundle.main.bundlePath
        if !fileManager.fileExists(atPath: appPath) {
            return true
        }
        
        // Check for uninstall flag file
        if fileManager.fileExists(atPath: uninstallFlagFile) {
            return true
        }
        
        // Check for uninstall-related processes
        if isUninstallProcessRunning() {
            return true
        }
        
        // Check for uninstall-related command line arguments
        let arguments = ProcessInfo.processInfo.arguments
        let uninstallKeywords = ["uninstall", "remove", "delete", "trash"]
        
        for argument in arguments {
            for keyword in uninstallKeywords {
                if argument.lowercased().contains(keyword) {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func isUninstallProcessRunning() -> Bool {
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-ax", "-o", "comm"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let uninstallProcesses = [
                    "App Store", "Software Update", "Installer", "pkgutil",
                    "rm", "mv", "trash", "uninstall"
                ]
                
                for process in uninstallProcesses {
                    if output.contains(process) {
                        return true
                    }
                }
            }
        } catch {
            print("Failed to check for uninstall processes: \(error)")
        }
        
        return false
    }
    
    // MARK: - Cleanup Methods
    
    func cleanupUninstallDetection() {
        do {
            // Remove uninstall flag file
            if FileManager.default.fileExists(atPath: uninstallFlagFile) {
                try FileManager.default.removeItem(atPath: uninstallFlagFile)
            }
            
            // Clean up configuration directory
            let configDir = "/Library/Application Support/MacSystemMonitor"
            if FileManager.default.fileExists(atPath: configDir) {
                try FileManager.default.removeItem(atPath: configDir)
            }
            
            print("Uninstall detection cleanup completed")
        } catch {
            print("Error cleaning up uninstall detection: \(error)")
        }
    }
    
    // MARK: - Process Exit Handling
    
    func setupProcessExitHandling() {
        // Set up signal handlers for graceful shutdown
        signal(SIGTERM) { _ in
            print("SIGTERM received - sending uninstall notification")
            Task {
                await UninstallDetectionService(n8nWebhookUrl: "").sendUninstallNotification()
            }
            exit(0)
        }
        
        signal(SIGINT) { _ in
            print("SIGINT received - sending uninstall notification")
            Task {
                await UninstallDetectionService(n8nWebhookUrl: "").sendUninstallNotification()
            }
            exit(0)
        }
        
        // Set up application termination observer
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("Application will terminate - sending uninstall notification")
            Task {
                await self.sendUninstallNotification()
            }
        }
    }
    
    // MARK: - Device Information Enhancement
    
    func getEnhancedDeviceInfo() -> [String: Any] {
        let deviceInfo = DeviceInfoManager.getDeviceInfo()
        
        var enhancedInfo: [String: Any] = [
            "computerName": deviceInfo.computerName,
            "userName": deviceInfo.userName,
            "serialNumber": deviceInfo.serialNumber,
            "macAddresses": deviceInfo.macAddresses,
            "biosSerialNumber": deviceInfo.biosSerialNumber,
            "motherboardSerialNumber": deviceInfo.motherboardSerialNumber,
            "macOSProductId": deviceInfo.macOSProductId,
            "installationPath": deviceInfo.installationPath,
            "deviceFingerprint": DeviceInfoManager.getDeviceFingerprint()
        ]
        
        // Add additional system information
        enhancedInfo["hardwareUUID"] = DeviceInfoManager.getHardwareUUID()
        enhancedInfo["modelIdentifier"] = DeviceInfoManager.getModelIdentifier()
        enhancedInfo["processorInfo"] = DeviceInfoManager.getProcessorInfo()
        enhancedInfo["memoryInfo"] = DeviceInfoManager.getMemoryInfo()
        enhancedInfo["diskInfo"] = DeviceInfoManager.getDiskInfo()
        
        return enhancedInfo
    }
} 
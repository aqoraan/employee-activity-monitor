import Foundation
import IOKit
import SystemConfiguration

// MARK: - Enhanced Logging System

class EnhancedLogging {
    static let shared = EnhancedLogging()
    
    private let logQueue = DispatchQueue(label: "com.macsystemmonitor.logging", qos: .utility)
    private let logFile = "/var/log/mac-system-monitor.log"
    private let maxLogSize = 10 * 1024 * 1024 // 10MB
    
    private init() {}
    
    // MARK: - Main Logging Methods
    
    func logEvent(_ event: ActivityEvent, deviceInfo: DeviceInfo? = nil, additionalDetails: [String: Any] = [:]) {
        let logEntry = createDetailedLogEntry(event: event, deviceInfo: deviceInfo, additionalDetails: additionalDetails)
        
        logQueue.async {
            self.writeLogEntry(logEntry)
        }
        
        // Also print to console for debugging
        print("📝 LOGGED EVENT: \(event.description)")
    }
    
    func logUsbEvent(deviceInfo: UsbDeviceInfo, blocked: Bool, reason: String) {
        let event = ActivityEvent(
            type: blocked ? .usbBlocked : .usbDrive,
            description: blocked ? "USB device blocked: \(deviceInfo.deviceName ?? deviceInfo.deviceId)" : "USB device connected: \(deviceInfo.deviceName ?? deviceInfo.deviceId)",
            severity: blocked ? .high : .medium,
            details: [
                "DeviceID": deviceInfo.deviceId,
                "DeviceName": deviceInfo.deviceName ?? "Unknown",
                "VendorID": deviceInfo.vendorId ?? "Unknown",
                "ProductID": deviceInfo.productId ?? "Unknown",
                "SerialNumber": deviceInfo.serialNumber ?? "Unknown",
                "Blocked": String(blocked),
                "Reason": reason
            ]
        )
        
        let deviceInfo = DeviceInfoManager.getDeviceInfo()
        logEvent(event, deviceInfo: deviceInfo, additionalDetails: [
            "usbDeviceDetails": [
                "deviceId": deviceInfo.deviceId,
                "deviceName": deviceInfo.deviceName ?? "Unknown",
                "vendorId": deviceInfo.vendorId ?? "Unknown",
                "productId": deviceInfo.productId ?? "Unknown",
                "serialNumber": deviceInfo.serialNumber ?? "Unknown",
                "blocked": blocked,
                "reason": reason
            ]
        ])
    }
    
    func logFileTransfer(filePath: String, eventType: String, directory: String, fileSize: Int64? = nil) {
        let fileName = (filePath as NSString).lastPathComponent
        let event = ActivityEvent(
            type: .fileTransfer,
            description: "File \(eventType.lowercased()): \(fileName)",
            severity: .medium,
            details: [
                "FilePath": filePath,
                "FileName": fileName,
                "EventType": eventType,
                "Directory": directory,
                "FileSize": fileSize?.description ?? "Unknown"
            ]
        )
        
        let deviceInfo = DeviceInfoManager.getDeviceInfo()
        logEvent(event, deviceInfo: deviceInfo, additionalDetails: [
            "fileTransferDetails": [
                "fileName": fileName,
                "filePath": filePath,
                "eventType": eventType,
                "directory": directory,
                "fileSize": fileSize?.description ?? "Unknown"
            ]
        ])
    }
    
    func logAppInstallation(appName: String, publisher: String, installPath: String) {
        let event = ActivityEvent(
            type: .appInstallation,
            description: "App installation: \(appName)",
            severity: .medium,
            details: [
                "AppName": appName,
                "Publisher": publisher,
                "InstallPath": installPath
            ]
        )
        
        let deviceInfo = DeviceInfoManager.getDeviceInfo()
        logEvent(event, deviceInfo: deviceInfo, additionalDetails: [
            "appInstallationDetails": [
                "appName": appName,
                "publisher": publisher,
                "installPath": installPath
            ]
        ])
    }
    
    func logBlacklistedApp(appName: String, publisher: String, installPath: String) {
        let event = ActivityEvent(
            type: .blacklistedApp,
            description: "Blacklisted app detected: \(appName)",
            severity: .high,
            details: [
                "AppName": appName,
                "Publisher": publisher,
                "InstallPath": installPath,
                "Blacklisted": "true"
            ]
        )
        
        let deviceInfo = DeviceInfoManager.getDeviceInfo()
        logEvent(event, deviceInfo: deviceInfo, additionalDetails: [
            "blacklistedAppDetails": [
                "appName": appName,
                "publisher": publisher,
                "installPath": installPath
            ]
        ])
    }
    
    func logNetworkActivity(domain: String, connectionType: String, localPort: Int? = nil, remotePort: Int? = nil) {
        let event = ActivityEvent(
            type: .networkActivity,
            description: "Suspicious network connection: \(domain)",
            severity: .high,
            details: [
                "Domain": domain,
                "ConnectionType": connectionType,
                "LocalPort": localPort?.description ?? "Unknown",
                "RemotePort": remotePort?.description ?? "Unknown"
            ]
        )
        
        let deviceInfo = DeviceInfoManager.getDeviceInfo()
        logEvent(event, deviceInfo: deviceInfo, additionalDetails: [
            "networkActivityDetails": [
                "domain": domain,
                "connectionType": connectionType,
                "localPort": localPort?.description ?? "Unknown",
                "remotePort": remotePort?.description ?? "Unknown"
            ]
        ])
    }
    
    func logUninstallDetection(processId: Int32, processName: String, commandLine: String) {
        let event = ActivityEvent(
            type: .uninstallDetected,
            description: "Uninstall detected: \(processName)",
            severity: .critical,
            details: [
                "ProcessID": String(processId),
                "ProcessName": processName,
                "CommandLine": commandLine
            ]
        )
        
        let deviceInfo = DeviceInfoManager.getDeviceInfo()
        let uninstallDetails = UninstallDetectionEvent(
            processId: processId,
            processName: processName,
            commandLine: commandLine,
            uninstallTime: Date(),
            deviceInfo: deviceInfo
        )
        
        logEvent(event, deviceInfo: deviceInfo, additionalDetails: [
            "uninstallDetails": [
                "processId": processId,
                "processName": processName,
                "commandLine": commandLine,
                "uninstallTime": ISO8601DateFormatter().string(from: Date())
            ]
        ])
    }
    
    // MARK: - Detailed Log Entry Creation
    
    private func createDetailedLogEntry(event: ActivityEvent, deviceInfo: DeviceInfo?, additionalDetails: [String: Any]) -> [String: Any] {
        var logEntry: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: event.timestamp),
            "eventType": event.type.rawValue,
            "severity": event.severity.rawValue,
            "description": event.description,
            "computer": event.computer,
            "user": event.user,
            "details": event.details
        ]
        
        // Add device information
        if let deviceInfo = deviceInfo {
            logEntry["deviceInfo"] = [
                "serialNumber": deviceInfo.serialNumber,
                "primaryMacAddress": deviceInfo.primaryMacAddress,
                "allMacAddresses": deviceInfo.macAddresses,
                "biosSerialNumber": deviceInfo.biosSerialNumber,
                "motherboardSerialNumber": deviceInfo.motherboardSerialNumber,
                "macOSProductId": deviceInfo.macOSProductId,
                "installationPath": deviceInfo.installationPath,
                "deviceFingerprint": deviceInfo.deviceFingerprint,
                "hardwareUUID": DeviceInfoManager.getHardwareUUID(),
                "modelIdentifier": DeviceInfoManager.getModelIdentifier(),
                "processorInfo": DeviceInfoManager.getProcessorInfo(),
                "memoryInfo": DeviceInfoManager.getMemoryInfo(),
                "diskInfo": DeviceInfoManager.getDiskInfo()
            ]
        }
        
        // Add additional details
        for (key, value) in additionalDetails {
            logEntry[key] = value
        }
        
        return logEntry
    }
    
    // MARK: - File Operations
    
    private func writeLogEntry(_ logEntry: [String: Any]) {
        do {
            let logData = try JSONSerialization.data(withJSONObject: logEntry, options: .prettyPrinted)
            let logString = String(data: logData, encoding: .utf8)! + "\n---\n"
            
            // Check if log file exists and rotate if needed
            if FileManager.default.fileExists(atPath: logFile) {
                let attributes = try FileManager.default.attributesOfItem(atPath: logFile)
                let fileSize = attributes[.size] as? Int64 ?? 0
                
                if fileSize > maxLogSize {
                    rotateLogFile()
                }
            }
            
            // Write to log file
            if let fileHandle = FileHandle(forWritingAtPath: logFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(logString.data(using: .utf8)!)
                fileHandle.closeFile()
            } else {
                // Create new log file
                try logString.write(toFile: logFile, atomically: true, encoding: .utf8)
            }
            
        } catch {
            print("Failed to write log entry: \(error)")
        }
    }
    
    private func rotateLogFile() {
        let backupPath = logFile + ".1"
        
        do {
            // Remove old backup if it exists
            if FileManager.default.fileExists(atPath: backupPath) {
                try FileManager.default.removeItem(atPath: backupPath)
            }
            
            // Move current log to backup
            try FileManager.default.moveItem(atPath: logFile, toPath: backupPath)
            
        } catch {
            print("Failed to rotate log file: \(error)")
        }
    }
    
    // MARK: - Log Retrieval
    
    func getRecentLogs(limit: Int = 100) -> [[String: Any]] {
        do {
            let logContent = try String(contentsOfFile: logFile, encoding: .utf8)
            let entries = logContent.components(separatedBy: "\n---\n")
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .suffix(limit)
            
            var logs: [[String: Any]] = []
            for entry in entries {
                if let data = entry.data(using: .utf8),
                   let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    logs.append(json)
                }
            }
            
            return logs.reversed()
        } catch {
            print("Failed to read log file: \(error)")
            return []
        }
    }
    
    func getLogsByType(_ eventType: ActivityType, limit: Int = 50) -> [[String: Any]] {
        let allLogs = getRecentLogs(limit: 1000)
        return allLogs.filter { log in
            guard let type = log["eventType"] as? String else { return false }
            return type == eventType.rawValue
        }.prefix(limit).map { $0 }
    }
    
    func getLogsBySeverity(_ severity: ActivitySeverity, limit: Int = 50) -> [[String: Any]] {
        let allLogs = getRecentLogs(limit: 1000)
        return allLogs.filter { log in
            guard let logSeverity = log["severity"] as? String else { return false }
            return logSeverity == severity.rawValue
        }.prefix(limit).map { $0 }
    }
    
    // MARK: - Statistics
    
    func getLogStatistics() -> [String: Any] {
        let allLogs = getRecentLogs(limit: 10000)
        
        var statistics: [String: Any] = [
            "totalEvents": allLogs.count,
            "eventsByType": [:],
            "eventsBySeverity": [:],
            "recentActivity": []
        ]
        
        // Count by type
        var typeCounts: [String: Int] = [:]
        var severityCounts: [String: Int] = [:]
        
        for log in allLogs {
            if let type = log["eventType"] as? String {
                typeCounts[type, default: 0] += 1
            }
            if let severity = log["severity"] as? String {
                severityCounts[severity, default: 0] += 1
            }
        }
        
        statistics["eventsByType"] = typeCounts
        statistics["eventsBySeverity"] = severityCounts
        
        // Recent activity (last 10 events)
        statistics["recentActivity"] = Array(allLogs.prefix(10))
        
        return statistics
    }
}

// MARK: - Logging Extensions

extension ActivityEvent {
    func logWithDetails(deviceInfo: DeviceInfo? = nil, additionalDetails: [String: Any] = [:]) {
        EnhancedLogging.shared.logEvent(self, deviceInfo: deviceInfo, additionalDetails: additionalDetails)
    }
}

extension UsbDeviceInfo {
    func logConnection(blocked: Bool, reason: String) {
        EnhancedLogging.shared.logUsbEvent(deviceInfo: self, blocked: blocked, reason: reason)
    }
} 
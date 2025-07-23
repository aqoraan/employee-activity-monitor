import Foundation

// MARK: - Activity Types
enum ActivityType: String, CaseIterable, Codable {
    case usbDrive = "UsbDrive"
    case usbBlocked = "UsbBlocked"
    case uninstallDetected = "UninstallDetected"
    case fileTransfer = "FileTransfer"
    case appInstallation = "AppInstallation"
    case blacklistedApp = "BlacklistedApp"
    case networkActivity = "NetworkActivity"
    case system = "System"
    
    var displayName: String {
        switch self {
        case .usbDrive:
            return "USB Drive Activity"
        case .usbBlocked:
            return "USB Device Blocked"
        case .uninstallDetected:
            return "Uninstall Detected"
        case .fileTransfer:
            return "File Transfer"
        case .appInstallation:
            return "App Installation"
        case .blacklistedApp:
            return "Blacklisted App"
        case .networkActivity:
            return "Network Activity"
        case .system:
            return "System Event"
        }
    }
}

// MARK: - Activity Severity
enum ActivitySeverity: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
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

// MARK: - Activity Event
struct ActivityEvent: Identifiable, Codable {
    let id = UUID()
    let type: ActivityType
    let description: String
    let timestamp: Date
    let severity: ActivitySeverity
    let details: [String: String]
    let computer: String
    let user: String
    
    init(type: ActivityType, description: String, severity: ActivitySeverity = .medium, details: [String: String] = [:]) {
        self.type = type
        self.description = description
        self.timestamp = Date()
        self.severity = severity
        self.details = details
        self.computer = Host.current().localizedName ?? "Unknown"
        self.user = NSUserName()
    }
}

// MARK: - Device Information
struct DeviceInfo: Codable {
    let computerName: String
    let userName: String
    let timestamp: Date
    let serialNumber: String
    let macAddresses: [String]
    let biosSerialNumber: String
    let motherboardSerialNumber: String
    let macOSProductId: String
    let installationPath: String
    
    var primaryMacAddress: String {
        return macAddresses.first ?? "Unknown"
    }
    
    var deviceFingerprint: String {
        return "\(computerName)_\(serialNumber)_\(primaryMacAddress)"
    }
}

// MARK: - USB Blocking Event
struct UsbBlockingEvent: Codable {
    let deviceId: String
    let reason: String
    let blocked: Bool
    let timestamp: Date
    let deviceName: String?
    let vendorId: String?
    let productId: String?
}

// MARK: - Uninstall Detection Event
struct UninstallDetectionEvent: Codable {
    let processId: Int32
    let processName: String
    let commandLine: String
    let uninstallTime: Date
    let deviceInfo: DeviceInfo
}

// MARK: - N8N Payload
struct N8nPayload: Codable {
    let timestamp: String
    let type: String
    let description: String
    let severity: String
    let details: [String: String]
    let computer: String
    let user: String
    let deviceInfo: DeviceInfo?
    let uninstallDetails: UninstallDetectionEvent?
    
    init(from activity: ActivityEvent, deviceInfo: DeviceInfo? = nil, uninstallDetails: UninstallDetectionEvent? = nil) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        self.timestamp = formatter.string(from: activity.timestamp)
        self.type = activity.type.rawValue
        self.description = activity.description
        self.severity = activity.severity.rawValue
        self.details = activity.details
        self.computer = activity.computer
        self.user = activity.user
        self.deviceInfo = deviceInfo
        self.uninstallDetails = uninstallDetails
    }
}

// MARK: - Monitoring Status
enum MonitoringStatus {
    case running
    case stopped
    case error(String)
    
    var isRunning: Bool {
        switch self {
        case .running:
            return true
        default:
            return false
        }
    }
    
    var displayName: String {
        switch self {
        case .running:
            return "Running"
        case .stopped:
            return "Stopped"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    var color: String {
        switch self {
        case .running:
            return "green"
        case .stopped:
            return "red"
        case .error:
            return "orange"
        }
    }
}

// MARK: - USB Blocking Status
enum UsbBlockingStatus {
    case enabled
    case disabled
    case error(String)
    
    var isEnabled: Bool {
        switch self {
        case .enabled:
            return true
        default:
            return false
        }
    }
    
    var displayName: String {
        switch self {
        case .enabled:
            return "Enabled"
        case .disabled:
            return "Disabled"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    var color: String {
        switch self {
        case .enabled:
            return "green"
        case .disabled:
            return "red"
        case .error:
            return "orange"
        }
    }
} 
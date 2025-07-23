import Foundation

// MARK: - Main Configuration
struct AppConfig: Codable {
    var n8nWebhookUrl: String = "http://localhost:5678/webhook/monitoring"
    var blacklistedApps: [String] = []
    var suspiciousDomains: [String] = []
    var monitoringSettings: MonitoringSettings = MonitoringSettings()
    var emailSettings: EmailSettings = EmailSettings()
    var securitySettings: SecuritySettings = SecuritySettings()
    var usbBlockingSettings: UsbBlockingSettings = UsbBlockingSettings()
    var uninstallDetectionSettings: UninstallDetectionSettings = UninstallDetectionSettings()
    var testModeSettings: TestModeSettings = TestModeSettings()
    
    static func loadFromFile(filePath: String = "config.json") -> AppConfig {
        do {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
                let config = try JSONDecoder().decode(AppConfig.self, from: data)
                
                // Set defaults if not specified
                if config.blacklistedApps.isEmpty {
                    var updatedConfig = config
                    updatedConfig.blacklistedApps = getDefaultBlacklistedApps()
                    return updatedConfig
                }
                
                if config.suspiciousDomains.isEmpty {
                    var updatedConfig = config
                    updatedConfig.suspiciousDomains = getDefaultSuspiciousDomains()
                    return updatedConfig
                }
                
                return config
            }
        } catch {
            print("Failed to load config file: \(error.localizedDescription)")
        }
        
        // Return default configuration
        return AppConfig(
            blacklistedApps: getDefaultBlacklistedApps(),
            suspiciousDomains: getDefaultSuspiciousDomains()
        )
    }
    
    func saveToFile(filePath: String = "config.json") {
        do {
            let data = try JSONEncoder().encode(self)
            try data.write(to: URL(fileURLWithPath: filePath))
        } catch {
            print("Failed to save config file: \(error.localizedDescription)")
        }
    }
    
    private static func getDefaultBlacklistedApps() -> [String] {
        return [
            "tor", "vpn", "proxy", "anonymizer",
            "cryptolocker", "ransomware", "keylogger",
            "spyware", "malware", "trojan",
            "hacktool", "crack", "keygen", "patch"
        ]
    }
    
    private static func getDefaultSuspiciousDomains() -> [String] {
        return [
            "mega.nz", "dropbox.com", "google-drive.com", "onedrive.com",
            "we-transfer.com", "file.io", "transfernow.net", "wetransfer.com",
            "sendspace.com", "rapidshare.com", "mediafire.com", "4shared.com"
        ]
    }
}

// MARK: - Monitoring Settings
struct MonitoringSettings: Codable {
    var enableUsbMonitoring: Bool = true
    var enableFileTransferMonitoring: Bool = true
    var enableAppInstallationMonitoring: Bool = true
    var enableNetworkMonitoring: Bool = true
    var enableBlacklistedAppMonitoring: Bool = true
    var logLevel: String = "Medium"
    var maxLogEntries: Int = 10000
    var autoStartMonitoring: Bool = false
    var sendToN8n: Bool = true
    var n8nRetryAttempts: Int = 3
    var n8nRetryDelayMs: Int = 5000
    var requireAdminAccess: Bool = true
}

// MARK: - Email Settings
struct EmailSettings: Codable {
    var smtpServer: String = "smtp.gmail.com"
    var smtpPort: Int = 587
    var useSsl: Bool = true
    var username: String = ""
    var password: String = ""
    var fromEmail: String = "security@yourcompany.com"
    var toEmail: String = "admin@yourcompany.com"
    var ccEmail: String = ""
    var enableEmailAlerts: Bool = false
}

// MARK: - Security Settings
struct SecuritySettings: Codable {
    var googleWorkspaceAdmin: String = ""
    var googleWorkspaceToken: String = ""
    var preventUninstallation: Bool = true
    var protectConfiguration: Bool = true
    var logSecurityEvents: Bool = true
    var requireGoogleWorkspaceAdmin: Bool = false
    var autoStartOnBoot: Bool = true
    var runAsService: Bool = true
    var protectRegistry: Bool = true
    var addGatekeeperExclusion: Bool = true
}

// MARK: - USB Blocking Settings
struct UsbBlockingSettings: Codable {
    var enableUsbBlocking: Bool = true
    var googleSheetsApiKey: String = ""
    var googleSheetsSpreadsheetId: String = ""
    var googleSheetsRange: String = "A:A"
    var cacheExpirationMinutes: Int = 5
    var blockAllUsbStorage: Bool = false
    var allowWhitelistedOnly: Bool = true
    var logBlockedDevices: Bool = true
    var sendBlockingAlerts: Bool = true
    var localWhitelist: [String] = []
    var localBlacklist: [String] = []
}

// MARK: - Uninstall Detection Settings
struct UninstallDetectionSettings: Codable {
    var enableUninstallDetection: Bool = true
    var sendUninstallNotifications: Bool = true
    var captureDeviceInfo: Bool = true
    var logUninstallAttempts: Bool = true
    var requireAdminForUninstall: Bool = true
    var sendDeviceFingerprint: Bool = true
    var includeMacAddresses: Bool = true
    var includeSerialNumbers: Bool = true
    var includeProcessDetails: Bool = true
} 

// MARK: - Test Mode Settings
struct TestModeSettings: Codable {
    var enableTestMode: Bool = false
    var simulateUsbEvents: Bool = true
    var simulateFileTransfers: Bool = true
    var simulateAppInstallations: Bool = true
    var simulateNetworkActivity: Bool = true
    var testIntervalSeconds: Int = 30
    var logTestEvents: Bool = true
    var preventSystemChanges: Bool = true
    var useTestWebhook: Bool = true
    var testWebhookUrl: String = "http://localhost:5678/webhook/test"
    var maxTestEvents: Int = 100
} 
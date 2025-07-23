import SwiftUI

@main
struct MacSystemMonitorApp: App {
    @StateObject private var monitoringService = MonitoringService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(monitoringService)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
    
    init() {
        // Check command line arguments
        let arguments = CommandLine.arguments
        
        if arguments.count > 1 {
            switch arguments[1] {
            case "--install":
                if !SecurityManager.isRunningAsAdministrator() {
                    print("Error: Administrative privileges required to install service.")
                    exit(1)
                }
                
                SecurityManager.installAsService()
                SecurityManager.protectConfiguration()
                SecurityManager.preventUninstallation()
                SecurityManager.addGatekeeperExclusion()
                print("Service installed successfully.")
                exit(0)
                
            case "--uninstall":
                if !SecurityManager.isRunningAsAdministrator() {
                    print("Error: Administrative privileges required to uninstall service.")
                    exit(1)
                }
                
                // Send uninstall notification before removing service
                Task {
                    await monitoringService.sendUninstallNotification()
                }
                
                SecurityManager.uninstallService()
                print("Service uninstalled successfully.")
                exit(0)
                
            case "--service":
                // Run as background service
                print("Running as background service...")
                monitoringService.startMonitoring()
                
                // Keep the service running
                RunLoop.main.run()
                
            case "--validate-admin":
                let email = arguments.count > 2 ? arguments[2] : ""
                let token = arguments.count > 3 ? arguments[3] : ""
                
                if SecurityManager.validateAdminAccess(email: email, token: token) {
                    print("Admin access validated successfully.")
                    exit(0)
                } else {
                    print("Error: Admin access denied.")
                    exit(1)
                }
                
            case "--uninstall-notification":
                // Send uninstall notification only
                Task {
                    await monitoringService.sendUninstallNotification()
                }
                exit(0)
                
            default:
                break
            }
        }
        
        // Check if running as administrator for normal operation
        if !SecurityManager.isRunningAsAdministrator() {
            print("This application requires administrative privileges to monitor system activities.")
            
            // Try to restart with elevated privileges
            let task = Process()
            task.launchPath = "/usr/bin/osascript"
            task.arguments = [
                "-e",
                "do shell script \"\(Bundle.main.executablePath!)\" with administrator privileges"
            ]
            
            do {
                try task.run()
                exit(0)
            } catch {
                print("Failed to request administrative privileges.")
                exit(1)
            }
        }
        
        // Log security event
        SecurityManager.logSecurityEvent("Application started", NSUserName())
        
        // Check if service is installed and running
        if SecurityManager.isServiceInstalled() {
            if SecurityManager.isServiceRunning() {
                print("Mac System Monitor is already running as a service.")
                exit(0)
            }
        }
        
        // Set up monitoring service delegate
        monitoringService.delegate = self
    }
}

// MARK: - Monitoring Service Delegate Implementation

extension MacSystemMonitorApp: MonitoringServiceDelegate {
    func activityDetected(_ activity: ActivityEvent) {
        // Log activity to system log
        let logMessage = "[\(activity.type.displayName)] \(activity.description)"
        
        let task = Process()
        task.launchPath = "/usr/bin/logger"
        task.arguments = ["-t", "MacSystemMonitor", logMessage]
        
        do {
            try task.run()
        } catch {
            print("Failed to log activity: \(error)")
        }
    }
} 
import SwiftUI

@main
struct MacSystemMonitorApp: App {
    @StateObject private var monitoringService = MonitoringService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(monitoringService)
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Toggle Test Mode") {
                    toggleTestMode()
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
                
                Button("Generate Test Event") {
                    generateTestEvent()
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])
            }
        }
    }
    
    private func toggleTestMode() {
        var config = AppConfig.loadFromFile()
        config.testModeSettings.enableTestMode.toggle()
        config.saveToFile()
        
        // Restart monitoring with new configuration
        monitoringService.stopMonitoring()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            monitoringService.startMonitoring()
        }
        
        print("Test mode \(config.testModeSettings.enableTestMode ? "enabled" : "disabled")")
    }
    
    private func generateTestEvent() {
        let testActivity = ActivityEvent(
            type: .system,
            description: "Manual test event generated",
            severity: .medium,
            details: ["ManualTest": "true", "Timestamp": ISO8601DateFormatter().string(from: Date())]
        )
        
        monitoringService.addActivity(testActivity)
        print("Test event generated")
    }
}

// MARK: - Command Line Interface

class CommandLineInterface {
    static func processArguments() {
        let arguments = CommandLine.arguments
        
        if arguments.contains("--test-mode") {
            enableTestMode()
        } else if arguments.contains("--service") {
            runAsService()
        } else if arguments.contains("--help") {
            printHelp()
        } else if arguments.contains("--safe-test") {
            runSafeTest()
        }
    }
    
    private static func enableTestMode() {
        var config = AppConfig.loadFromFile()
        config.testModeSettings.enableTestMode = true
        config.testModeSettings.preventSystemChanges = true
        config.saveToFile()
        
        print("Test mode enabled - no system changes will be made")
        print("Configuration saved to: \(FileManager.default.currentDirectoryPath)/config.json")
    }
    
    private static func runAsService() {
        print("Starting Mac System Monitor as service...")
        
        // Initialize monitoring service
        let monitoringService = MonitoringService()
        monitoringService.startMonitoring()
        
        // Keep the service running
        RunLoop.main.run()
    }
    
    private static func runSafeTest() {
        print("Running safe test mode...")
        print("This will simulate events without making any system changes")
        
        var config = AppConfig.loadFromFile()
        config.testModeSettings.enableTestMode = true
        config.testModeSettings.preventSystemChanges = true
        config.testModeSettings.simulateUsbEvents = true
        config.testModeSettings.simulateFileTransfers = true
        config.testModeSettings.simulateAppInstallations = true
        config.testModeSettings.simulateNetworkActivity = true
        config.testModeSettings.testIntervalSeconds = 10
        config.saveToFile()
        
        let monitoringService = MonitoringService(config: config)
        monitoringService.startMonitoring()
        
        print("Safe test mode started. Press Ctrl+C to stop.")
        
        // Run for 60 seconds then stop
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            monitoringService.stopMonitoring()
            print("Safe test completed")
            exit(0)
        }
        
        RunLoop.main.run()
    }
    
    private static func printHelp() {
        print("""
        Mac System Monitor - Command Line Options
        
        --test-mode      Enable test mode (no system changes)
        --service        Run as background service
        --safe-test      Run a 60-second safe test
        --help          Show this help message
        
        Examples:
        ./MacSystemMonitor --safe-test    # Run safe test for 60 seconds
        ./MacSystemMonitor --test-mode    # Enable test mode
        ./MacSystemMonitor --service      # Run as service
        
        Test Mode Features:
        - Simulates USB events without blocking devices
        - Simulates file transfers without monitoring real files
        - Simulates app installations without monitoring processes
        - Simulates network activity without monitoring connections
        - Uses test webhook URL for N8N integration
        - Prevents all system changes and admin operations
        """)
    }
}

// MARK: - Main Entry Point

@main
struct MacSystemMonitorApp: App {
    init() {
        // Process command line arguments
        CommandLineInterface.processArguments()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Toggle Test Mode") {
                    toggleTestMode()
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
                
                Button("Generate Test Event") {
                    generateTestEvent()
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Run Safe Test") {
                    runSafeTest()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
    }
    
    private func toggleTestMode() {
        var config = AppConfig.loadFromFile()
        config.testModeSettings.enableTestMode.toggle()
        config.saveToFile()
        
        print("Test mode \(config.testModeSettings.enableTestMode ? "enabled" : "disabled")")
    }
    
    private func generateTestEvent() {
        let testActivity = ActivityEvent(
            type: .system,
            description: "Manual test event generated",
            severity: .medium,
            details: ["ManualTest": "true", "Timestamp": ISO8601DateFormatter().string(from: Date())]
        )
        
        // Add to monitoring service if available
        print("Test event generated")
    }
    
    private func runSafeTest() {
        print("Starting safe test mode...")
        
        var config = AppConfig.loadFromFile()
        config.testModeSettings.enableTestMode = true
        config.testModeSettings.preventSystemChanges = true
        config.testModeSettings.simulateUsbEvents = true
        config.testModeSettings.simulateFileTransfers = true
        config.testModeSettings.simulateAppInstallations = true
        config.testModeSettings.simulateNetworkActivity = true
        config.testModeSettings.testIntervalSeconds = 10
        config.saveToFile()
        
        let monitoringService = MonitoringService(config: config)
        monitoringService.startMonitoring()
        
        print("Safe test mode started. Will run for 60 seconds.")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            monitoringService.stopMonitoring()
            print("Safe test completed")
        }
    }
} 
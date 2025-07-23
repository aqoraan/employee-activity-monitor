import Foundation
import Security
import ServiceManagement

class SecurityManager {
    
    // MARK: - Administrative Privileges
    
    static func isRunningAsAdministrator() -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/id"
        task.arguments = ["-u"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                return output == "0"
            }
        } catch {
            print("Failed to check admin privileges: \(error)")
        }
        
        return false
    }
    
    static func requestAdministrativePrivileges() -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = [
            "-e",
            "do shell script \"echo 'Admin privileges granted'\" with administrator privileges"
        ]
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            print("Failed to request admin privileges: \(error)")
            return false
        }
    }
    
    // MARK: - Google Workspace Admin Validation
    
    static func validateAdminAccess(email: String, token: String) -> Bool {
        guard !email.isEmpty && !token.isEmpty else {
            return false
        }
        
        // Validate Google Workspace admin access
        let url = URL(string: "https://admin.googleapis.com/admin/directory/v1/users/\(email)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let semaphore = DispatchSemaphore(value: 0)
        var isValid = false
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            
            if let httpResponse = response as? HTTPURLResponse {
                isValid = httpResponse.statusCode == 200
            }
        }
        
        task.resume()
        semaphore.wait()
        
        return isValid
    }
    
    // MARK: - Service Management
    
    static func installAsService() -> Bool {
        guard isRunningAsAdministrator() else {
            print("Administrative privileges required to install service")
            return false
        }
        
        let appPath = Bundle.main.bundlePath
        let plistPath = "/Library/LaunchDaemons/com.company.MacSystemMonitor.plist"
        
        // Create launch daemon plist
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.company.MacSystemMonitor</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(appPath)/Contents/MacOS/MacSystemMonitor</string>
                <string>--service</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <true/>
            <key>StandardOutPath</key>
            <string>/var/log/MacSystemMonitor.log</string>
            <key>StandardErrorPath</key>
            <string>/var/log/MacSystemMonitor.error.log</string>
        </dict>
        </plist>
        """
        
        do {
            try plistContent.write(toFile: plistPath, atomically: true, encoding: .utf8)
            
            // Set proper permissions
            let task = Process()
            task.launchPath = "/bin/chmod"
            task.arguments = ["644", plistPath]
            try task.run()
            task.waitUntilExit()
            
            // Load the service
            let loadTask = Process()
            loadTask.launchPath = "/bin/launchctl"
            loadTask.arguments = ["load", plistPath]
            try loadTask.run()
            loadTask.waitUntilExit()
            
            return loadTask.terminationStatus == 0
        } catch {
            print("Failed to install service: \(error)")
            return false
        }
    }
    
    static func uninstallService() -> Bool {
        guard isRunningAsAdministrator() else {
            print("Administrative privileges required to uninstall service")
            return false
        }
        
        let plistPath = "/Library/LaunchDaemons/com.company.MacSystemMonitor.plist"
        
        do {
            // Unload the service
            let unloadTask = Process()
            unloadTask.launchPath = "/bin/launchctl"
            unloadTask.arguments = ["unload", plistPath]
            try unloadTask.run()
            unloadTask.waitUntilExit()
            
            // Remove the plist file
            try FileManager.default.removeItem(atPath: plistPath)
            
            return true
        } catch {
            print("Failed to uninstall service: \(error)")
            return false
        }
    }
    
    static func isServiceInstalled() -> Bool {
        let plistPath = "/Library/LaunchDaemons/com.company.MacSystemMonitor.plist"
        return FileManager.default.fileExists(atPath: plistPath)
    }
    
    static func isServiceRunning() -> Bool {
        let task = Process()
        task.launchPath = "/bin/launchctl"
        task.arguments = ["list", "com.company.MacSystemMonitor"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return !output.contains("Could not find service")
            }
        } catch {
            print("Failed to check service status: \(error)")
        }
        
        return false
    }
    
    // MARK: - Configuration Protection
    
    static func protectConfiguration() -> Bool {
        guard isRunningAsAdministrator() else {
            return false
        }
        
        let configPath = "/Library/Application Support/MacSystemMonitor/config.json"
        
        do {
            // Create directory if it doesn't exist
            let configDir = "/Library/Application Support/MacSystemMonitor"
            try FileManager.default.createDirectory(atPath: configDir, withIntermediateDirectories: true)
            
            // Set restrictive permissions
            let task = Process()
            task.launchPath = "/bin/chmod"
            task.arguments = ["600", configPath]
            try task.run()
            task.waitUntilExit()
            
            // Set ownership to root
            let chownTask = Process()
            chownTask.launchPath = "/usr/sbin/chown"
            chownTask.arguments = ["root:wheel", configPath]
            try chownTask.run()
            chownTask.waitUntilExit()
            
            return true
        } catch {
            print("Failed to protect configuration: \(error)")
            return false
        }
    }
    
    // MARK: - Uninstallation Prevention
    
    static func preventUninstallation() -> Bool {
        guard isRunningAsAdministrator() else {
            return false
        }
        
        let appPath = Bundle.main.bundlePath
        
        do {
            // Set immutable flag
            let task = Process()
            task.launchPath = "/bin/chflags"
            task.arguments = ["schg", appPath]
            try task.run()
            task.waitUntilExit()
            
            // Set restrictive permissions
            let chmodTask = Process()
            chmodTask.launchPath = "/bin/chmod"
            chmodTask.arguments = ["755", appPath]
            try chmodTask.run()
            chmodTask.waitUntilExit()
            
            return true
        } catch {
            print("Failed to prevent uninstallation: \(error)")
            return false
        }
    }
    
    // MARK: - Gatekeeper Exclusion
    
    static func addGatekeeperExclusion() -> Bool {
        guard isRunningAsAdministrator() else {
            return false
        }
        
        let appPath = Bundle.main.bundlePath
        
        do {
            let task = Process()
            task.launchPath = "/usr/sbin/spctl"
            task.arguments = ["--add", appPath]
            try task.run()
            task.waitUntilExit()
            
            return task.terminationStatus == 0
        } catch {
            print("Failed to add Gatekeeper exclusion: \(error)")
            return false
        }
    }
    
    // MARK: - Security Event Logging
    
    static func logSecurityEvent(_ message: String, user: String) {
        let timestamp = DateFormatter().string(from: Date())
        let logMessage = "[\(timestamp)] Security Event: \(message) (User: \(user))"
        
        // Log to system log
        let task = Process()
        task.launchPath = "/usr/bin/logger"
        task.arguments = ["-t", "MacSystemMonitor", logMessage]
        
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            print("Failed to log security event: \(error)")
        }
    }
    
    // MARK: - Auto-Start Configuration
    
    static func configureAutoStart() -> Bool {
        let appPath = Bundle.main.bundlePath
        let loginItemsPath = "~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.LoginItems"
        
        do {
            let task = Process()
            task.launchPath = "/usr/bin/osascript"
            task.arguments = [
                "-e",
                "tell application \"System Events\" to make login item at end with properties {path:\"\(appPath)\", hidden:true}"
            ]
            try task.run()
            task.waitUntilExit()
            
            return task.terminationStatus == 0
        } catch {
            print("Failed to configure auto-start: \(error)")
            return false
        }
    }
    
    // MARK: - File System Protection
    
    static func protectFileSystem() -> Bool {
        guard isRunningAsAdministrator() else {
            return false
        }
        
        let appPath = Bundle.main.bundlePath
        
        do {
            // Set system immutable flag
            let task = Process()
            task.launchPath = "/bin/chflags"
            task.arguments = ["schg", appPath]
            try task.run()
            task.waitUntilExit()
            
            // Set ownership to root
            let chownTask = Process()
            chownTask.launchPath = "/usr/sbin/chown"
            chownTask.arguments = ["root:wheel", appPath]
            try chownTask.run()
            chownTask.waitUntilExit()
            
            return true
        } catch {
            print("Failed to protect file system: \(error)")
            return false
        }
    }
} 
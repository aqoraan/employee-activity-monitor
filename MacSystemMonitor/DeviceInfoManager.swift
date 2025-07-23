import Foundation
import IOKit
import SystemConfiguration

class DeviceInfoManager {
    
    static func getDeviceInfo() -> DeviceInfo {
        let deviceInfo = DeviceInfo(
            computerName: getComputerName(),
            userName: NSUserName(),
            timestamp: Date(),
            serialNumber: getSystemSerialNumber(),
            macAddresses: getMacAddresses(),
            biosSerialNumber: getBiosSerialNumber(),
            motherboardSerialNumber: getMotherboardSerialNumber(),
            macOSProductId: getMacOSProductId(),
            installationPath: getInstallationPath()
        )
        
        return deviceInfo
    }
    
    private static func getComputerName() -> String {
        return Host.current().localizedName ?? "Unknown"
    }
    
    private static func getSystemSerialNumber() -> String {
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        defer { IOObjectRelease(service) }
        
        if service != 0 {
            if let serialNumber = IORegistryEntryCreateCFProperty(service, "IOPlatformSerialNumber" as CFString, kCFAllocatorDefault, 0) {
                return (serialNumber.takeRetainedValue() as? String) ?? "Unknown"
            }
        }
        
        return "Unknown"
    }
    
    private static func getMacAddresses() -> [String] {
        var macAddresses: [String] = []
        
        // Get all network interfaces
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else {
            return macAddresses
        }
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            let interface = ptr?.pointee
            let addrFamily = interface?.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_LINK) {
                let name = String(cString: (interface?.ifa_name)!)
                
                // Skip loopback and virtual interfaces
                if !name.hasPrefix("lo") && !name.hasPrefix("vmnet") && !name.hasPrefix("vboxnet") {
                    var mac = [UInt8](repeating: 0, count: Int(IFHWADDRLEN))
                    memcpy(&mac, interface?.ifa_addr.pointee.sa_data.2, Int(IFHWADDRLEN))
                    
                    let macString = mac.prefix(6).map { String(format: "%02x", $0) }.joined(separator: ":")
                    if !macString.isEmpty && macString != "00:00:00:00:00:00" {
                        macAddresses.append(macString)
                    }
                }
            }
        }
        
        return macAddresses
    }
    
    private static func getBiosSerialNumber() -> String {
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        defer { IOObjectRelease(service) }
        
        if service != 0 {
            if let serialNumber = IORegistryEntryCreateCFProperty(service, "IOPlatformSerialNumber" as CFString, kCFAllocatorDefault, 0) {
                return (serialNumber.takeRetainedValue() as? String) ?? "Unknown"
            }
        }
        
        return "Unknown"
    }
    
    private static func getMotherboardSerialNumber() -> String {
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        defer { IOObjectRelease(service) }
        
        if service != 0 {
            if let serialNumber = IORegistryEntryCreateCFProperty(service, "IOPlatformSerialNumber" as CFString, kCFAllocatorDefault, 0) {
                return (serialNumber.takeRetainedValue() as? String) ?? "Unknown"
            }
        }
        
        return "Unknown"
    }
    
    private static func getMacOSProductId() -> String {
        let task = Process()
        task.launchPath = "/usr/bin/sw_vers"
        task.arguments = ["-productVersion"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                return output
            }
        } catch {
            print("Failed to get macOS version: \(error)")
        }
        
        return "Unknown"
    }
    
    private static func getInstallationPath() -> String {
        return Bundle.main.bundlePath
    }
    
    static func getPrimaryMacAddress() -> String {
        let macAddresses = getMacAddresses()
        return macAddresses.first ?? "Unknown"
    }
    
    static func getDeviceFingerprint() -> String {
        let deviceInfo = getDeviceInfo()
        return deviceInfo.deviceFingerprint
    }
    
    // MARK: - Additional Device Information Methods
    
    static func getHardwareUUID() -> String {
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        defer { IOObjectRelease(service) }
        
        if service != 0 {
            if let uuid = IORegistryEntryCreateCFProperty(service, "IOPlatformUUID" as CFString, kCFAllocatorDefault, 0) {
                return (uuid.takeRetainedValue() as? String) ?? "Unknown"
            }
        }
        
        return "Unknown"
    }
    
    static func getModelIdentifier() -> String {
        let task = Process()
        task.launchPath = "/usr/sbin/sysctl"
        task.arguments = ["-n", "hw.model"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                return output
            }
        } catch {
            print("Failed to get model identifier: \(error)")
        }
        
        return "Unknown"
    }
    
    static func getProcessorInfo() -> String {
        let task = Process()
        task.launchPath = "/usr/sbin/sysctl"
        task.arguments = ["-n", "machdep.cpu.brand_string"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                return output
            }
        } catch {
            print("Failed to get processor info: \(error)")
        }
        
        return "Unknown"
    }
    
    static func getMemoryInfo() -> String {
        let task = Process()
        task.launchPath = "/usr/sbin/sysctl"
        task.arguments = ["-n", "hw.memsize"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                if let memSize = Int64(output) {
                    let gbSize = Double(memSize) / (1024 * 1024 * 1024)
                    return String(format: "%.1f GB", gbSize)
                }
            }
        } catch {
            print("Failed to get memory info: \(error)")
        }
        
        return "Unknown"
    }
    
    static func getDiskInfo() -> String {
        let task = Process()
        task.launchPath = "/usr/sbin/diskutil"
        task.arguments = ["info", "/"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Parse disk info from output
                let lines = output.components(separatedBy: .newlines)
                for line in lines {
                    if line.contains("Device / Media Name:") {
                        let components = line.components(separatedBy: ":")
                        if components.count > 1 {
                            return components[1].trimmingCharacters(in: .whitespaces)
                        }
                    }
                }
            }
        } catch {
            print("Failed to get disk info: \(error)")
        }
        
        return "Unknown"
    }
} 
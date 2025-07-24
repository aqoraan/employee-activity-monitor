import Foundation
import IOKit
import IOKit.usb

class UsbBlockingService {
    private let sheetsManager: GoogleSheetsManager
    private let enableBlocking: Bool
    private var isBlocking: Bool = false
    private var notificationPort: IONotificationPortRef?
    private var addedIterator: IOIterator = 0
    private var removedIterator: IOIterator = 0
    
    weak var delegate: UsbBlockingServiceDelegate?
    
    init(sheetsManager: GoogleSheetsManager, enableBlocking: Bool = true) {
        self.sheetsManager = sheetsManager
        self.enableBlocking = enableBlocking
    }
    
    // MARK: - USB Blocking Control
    
    func startBlocking() {
        guard enableBlocking && !isBlocking else { return }
        
        isBlocking = true
        startUsbMonitoring()
        
        print("USB blocking started")
    }
    
    func stopBlocking() {
        guard isBlocking else { return }
        
        isBlocking = false
        stopUsbMonitoring()
        
        print("USB blocking stopped")
    }
    
    // MARK: - USB Device Monitoring
    
    private func startUsbMonitoring() {
        notificationPort = IONotificationPortCreate(kIOMasterPortDefault)
        
        // Monitor USB device additions
        let addedCallback: IOServiceMatchingCallback = { userData, iterator in
            let service = IOIteratorNext(iterator)
            if service != 0 {
                let blockingService = Unmanaged<UsbBlockingService>.fromOpaque(userData!).takeUnretainedValue()
                blockingService.handleUsbDeviceAdded(service)
                IOObjectRelease(service)
            }
        }
        
        // Monitor USB device removals
        let removedCallback: IOServiceMatchingCallback = { userData, iterator in
            let service = IOIteratorNext(iterator)
            if service != 0 {
                let blockingService = Unmanaged<UsbBlockingService>.fromOpaque(userData!).takeUnretainedValue()
                blockingService.handleUsbDeviceRemoved(service)
                IOObjectRelease(service)
            }
        }
        
        let userData = Unmanaged.passUnretained(self).toOpaque()
        
        // Start monitoring for USB device additions
        let addedResult = IOServiceAddMatchingNotification(
            notificationPort,
            kIOFirstMatchNotification,
            IOServiceMatching(kIOUSBHostDevice),
            addedCallback,
            userData,
            &addedIterator
        )
        
        if addedResult == kIOReturnSuccess {
            // Trigger initial enumeration
            while IOIteratorNext(addedIterator) != 0 { }
        }
        
        // Start monitoring for USB device removals
        let removedResult = IOServiceAddMatchingNotification(
            notificationPort,
            kIOTerminatedNotification,
            IOServiceMatching(kIOUSBHostDevice),
            removedCallback,
            userData,
            &removedIterator
        )
        
        if removedResult != kIOReturnSuccess {
            print("Failed to start USB removal monitoring")
        }
        
        // Start the notification port run loop
        CFRunLoopAddSource(
            CFRunLoopGetCurrent(),
            IONotificationPortGetRunLoopSource(notificationPort),
            .commonModes
        )
    }
    
    private func stopUsbMonitoring() {
        if let port = notificationPort {
            IONotificationPortDestroy(port)
            notificationPort = nil
        }
        
        if addedIterator != 0 {
            IOObjectRelease(addedIterator)
            addedIterator = 0
        }
        
        if removedIterator != 0 {
            IOObjectRelease(removedIterator)
            removedIterator = 0
        }
    }
    
    // MARK: - USB Device Event Handling
    
    private func handleUsbDeviceAdded(_ service: io_object_t) {
        let deviceInfo = getUsbDeviceInfo(from: service)
        
        Task {
            await handleUsbDeviceConnected(service)
        }
    }
    
    private func handleUsbDeviceConnected(_ service: io_object_t) async {
        let deviceInfo = getUsbDeviceInfo(from: service)
        
        // Check if device is in whitelist
        if let sheetsManager = sheetsManager, !sheetsManager.isDeviceWhitelisted(deviceInfo) {
            // Use enhanced logging for blocked device
            EnhancedLogging.shared.logUsbEvent(deviceInfo: deviceInfo, blocked: true, reason: "Device not in whitelist")
            await blockUsbDevice(deviceInfo)
        } else {
            // Use enhanced logging for allowed device
            EnhancedLogging.shared.logUsbEvent(deviceInfo: deviceInfo, blocked: false, reason: "Device in whitelist")
            print("USB device allowed: \(deviceInfo.deviceName ?? deviceInfo.deviceId)")
        }
    }
    
    private func handleUsbDeviceRemoved(_ service: io_object_t) {
        let deviceInfo = getUsbDeviceInfo(from: service)
        
        // Log USB device removal
        let event = ActivityEvent(
            type: .usbDrive,
            description: "USB device removed: \(deviceInfo.deviceName ?? deviceInfo.deviceId)",
            severity: .low,
            details: [
                "DeviceID": deviceInfo.deviceId,
                "DeviceName": deviceInfo.deviceName ?? "Unknown",
                "EventType": "Removed"
            ]
        )
        
        let deviceInfoObj = DeviceInfoManager.getDeviceInfo()
        EnhancedLogging.shared.logEvent(event, deviceInfo: deviceInfoObj, additionalDetails: [
            "usbRemovalDetails": [
                "deviceId": deviceInfo.deviceId,
                "deviceName": deviceInfo.deviceName ?? "Unknown",
                "eventType": "Removed"
            ]
        ])
        
        print("USB device removed: \(deviceInfo.deviceName ?? deviceInfo.deviceId)")
        
        delegate?.usbDeviceRemoved(deviceInfo)
    }
    
    // MARK: - USB Device Information
    
    private func getUsbDeviceInfo(from service: io_object_t) -> UsbDeviceInfo {
        var deviceId = "Unknown"
        var vendorId: String?
        var productId: String?
        var deviceName: String?
        var serialNumber: String?
        
        // Get device ID
        if let deviceIdProperty = IORegistryEntryCreateCFProperty(service, "USB Product Name" as CFString, kCFAllocatorDefault, 0) {
            deviceId = (deviceIdProperty.takeRetainedValue() as? String) ?? "Unknown"
        }
        
        // Get vendor ID
        if let vendorIdProperty = IORegistryEntryCreateCFProperty(service, "idVendor" as CFString, kCFAllocatorDefault, 0) {
            if let vendorIdNumber = vendorIdProperty.takeRetainedValue() as? NSNumber {
                vendorId = String(format: "%04x", vendorIdNumber.intValue)
            }
        }
        
        // Get product ID
        if let productIdProperty = IORegistryEntryCreateCFProperty(service, "idProduct" as CFString, kCFAllocatorDefault, 0) {
            if let productIdNumber = productIdProperty.takeRetainedValue() as? NSNumber {
                productId = String(format: "%04x", productIdNumber.intValue)
            }
        }
        
        // Get device name
        if let deviceNameProperty = IORegistryEntryCreateCFProperty(service, "USB Product Name" as CFString, kCFAllocatorDefault, 0) {
            deviceName = deviceNameProperty.takeRetainedValue() as? String
        }
        
        // Get serial number
        if let serialNumberProperty = IORegistryEntryCreateCFProperty(service, "USB Serial Number" as CFString, kCFAllocatorDefault, 0) {
            serialNumber = serialNumberProperty.takeRetainedValue() as? String
        }
        
        // Construct device ID if vendor and product IDs are available
        if let vid = vendorId, let pid = productId {
            deviceId = "USB\\VID_\(vid)&PID_\(pid)"
        }
        
        return UsbDeviceInfo(
            deviceId: deviceId,
            vendorId: vendorId,
            productId: productId,
            deviceName: deviceName,
            serialNumber: serialNumber
        )
    }
    
    // MARK: - USB Device Blocking
    
    private func blockUsbDevice(_ deviceInfo: UsbDeviceInfo) async {
        print("Blocking unauthorized USB device: \(deviceInfo.deviceName ?? deviceInfo.deviceId)")
        
        // Eject the USB device using system commands
        let success = await ejectUsbDevice(deviceInfo)
        
        let blockingEvent = UsbBlockingEvent(
            deviceId: deviceInfo.deviceId,
            reason: "Device not in whitelist",
            blocked: success,
            timestamp: Date(),
            deviceName: deviceInfo.deviceName,
            vendorId: deviceInfo.vendorId,
            productId: deviceInfo.productId
        )
        
        delegate?.usbDeviceBlocked(blockingEvent)
        
        // Log the blocking result with enhanced logging
        let event = ActivityEvent(
            type: .usbBlocked,
            description: success ? "Successfully blocked USB device: \(deviceInfo.deviceName ?? deviceInfo.deviceId)" : "Failed to block USB device: \(deviceInfo.deviceName ?? deviceInfo.deviceId)",
            severity: success ? .high : .critical,
            details: [
                "DeviceID": deviceInfo.deviceId,
                "DeviceName": deviceInfo.deviceName ?? "Unknown",
                "Blocked": String(success),
                "Reason": "Device not in whitelist"
            ]
        )
        
        let deviceInfoObj = DeviceInfoManager.getDeviceInfo()
        EnhancedLogging.shared.logEvent(event, deviceInfo: deviceInfoObj, additionalDetails: [
            "usbBlockingDetails": [
                "deviceId": deviceInfo.deviceId,
                "deviceName": deviceInfo.deviceName ?? "Unknown",
                "blocked": success,
                "reason": "Device not in whitelist"
            ]
        ])
        
        if success {
            print("Successfully blocked USB device: \(deviceInfo.deviceName ?? deviceInfo.deviceId)")
        } else {
            print("Failed to block USB device: \(deviceInfo.deviceName ?? deviceInfo.deviceId)")
        }
    }
    
    private func ejectUsbDevice(_ deviceInfo: UsbDeviceInfo) async -> Bool {
        // Use diskutil to eject USB storage devices
        let task = Process()
        task.launchPath = "/usr/sbin/diskutil"
        task.arguments = ["eject", "force"]
        
        // Find USB storage devices
        let findTask = Process()
        findTask.launchPath = "/usr/sbin/system_profiler"
        findTask.arguments = ["SPUSBDataType", "-xml"]
        
        let pipe = Pipe()
        findTask.standardOutput = pipe
        
        do {
            try findTask.run()
            findTask.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Parse USB devices and eject storage devices
                return await ejectUsbStorageDevices(from: output)
            }
        } catch {
            print("Failed to get USB device information: \(error)")
        }
        
        return false
    }
    
    private func ejectUsbStorageDevices(from systemProfilerOutput: String) async -> Bool {
        // Parse system profiler output to find USB storage devices
        let lines = systemProfilerOutput.components(separatedBy: .newlines)
        var storageDevices: [String] = []
        
        for line in lines {
            if line.contains("Removable Media") || line.contains("USB Storage") {
                // Extract device path
                if let devicePath = extractDevicePath(from: line) {
                    storageDevices.append(devicePath)
                }
            }
        }
        
        // Eject each storage device
        var success = false
        for device in storageDevices {
            let task = Process()
            task.launchPath = "/usr/sbin/diskutil"
            task.arguments = ["eject", device]
            
            do {
                try task.run()
                task.waitUntilExit()
                success = success || task.terminationStatus == 0
            } catch {
                print("Failed to eject device \(device): \(error)")
            }
        }
        
        return success
    }
    
    private func extractDevicePath(from line: String) -> String? {
        // Simple extraction - in a real implementation, you'd want more robust parsing
        let components = line.components(separatedBy: ":")
        if components.count > 1 {
            let path = components[1].trimmingCharacters(in: .whitespaces)
            if path.hasPrefix("/dev/") {
                return path
            }
        }
        return nil
    }
    
    // MARK: - Whitelist Management
    
    func refreshWhitelist() async {
        _ = await sheetsManager.getWhitelistedDevices()
        print("USB whitelist refreshed")
    }
    
    func isDeviceWhitelisted(_ deviceId: String) async -> Bool {
        return await sheetsManager.isDeviceWhitelisted(deviceId)
    }
}

// MARK: - USB Blocking Service Delegate

protocol UsbBlockingServiceDelegate: AnyObject {
    func usbDeviceBlocked(_ event: UsbBlockingEvent)
    func usbDeviceRemoved(_ deviceInfo: UsbDeviceInfo)
}

// MARK: - USB Blocking Event

struct UsbBlockingEvent {
    let deviceId: String
    let reason: String
    let blocked: Bool
    let timestamp: Date
    let deviceName: String?
    let vendorId: String?
    let productId: String?
}

// MARK: - USB Device Information Extension

extension UsbDeviceInfo {
    var displayName: String {
        return deviceName ?? deviceId
    }
    
    var fullDeviceId: String {
        var id = deviceId
        if let vid = vendorId, let pid = productId {
            id = "USB\\VID_\(vid)&PID_\(pid)"
        }
        return id
    }
} 
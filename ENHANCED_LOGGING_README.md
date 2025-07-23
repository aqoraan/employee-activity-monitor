# Enhanced Logging System for Mac System Monitor

This document explains the enhanced logging system that captures detailed device information, file transfer details, and comprehensive event data for both macOS and Windows monitoring applications.

## Overview

The enhanced logging system provides:
- **Detailed Device Information**: Serial numbers, MAC addresses, hardware UUIDs, and device fingerprints
- **File Transfer Details**: File names, paths, sizes, and transfer types
- **USB Device Information**: Device IDs, vendor/product IDs, serial numbers, and blocking reasons
- **Comprehensive Event Logging**: All events with timestamps, severity levels, and detailed context
- **n8n Integration**: Automated email notifications with rich device information
- **Log Management**: Automatic log rotation, cleanup, and statistics

## Log File Locations

### macOS
- **Primary Log**: `/var/log/mac-system-monitor.log`
- **Backup Log**: `/var/log/mac-system-monitor.log.1`
- **Test Logs**: `/tmp/mac-system-monitor-test/`

### Windows
- **Primary Log**: `C:\ProgramData\EmployeeActivityMonitor\logs\system-monitor.log`
- **Backup Log**: `C:\ProgramData\EmployeeActivityMonitor\logs\system-monitor.log.1`
- **Test Logs**: `C:\ProgramData\EmployeeActivityMonitor\logs\test\`

## Log Format

All events are logged in JSON format with the following structure:

```json
{
  "timestamp": "2024-01-15T10:30:00.000Z",
  "type": "UsbBlocked",
  "severity": "High",
  "description": "Unauthorized USB device blocked: SanDisk USB Drive",
  "computer": "MACBOOK-PRO-001",
  "user": "john.doe",
  "details": {
    "DeviceID": "USB\\VID_0781&PID_5567",
    "DeviceName": "SanDisk USB Drive",
    "VendorID": "0781",
    "ProductID": "5567",
    "SerialNumber": "123456789",
    "Blocked": "true",
    "Reason": "Device not in whitelist"
  },
  "deviceInfo": {
    "serialNumber": "C02XYZ123456",
    "primaryMacAddress": "00:11:22:33:44:55",
    "allMacAddresses": ["00:11:22:33:44:55", "AA:BB:CC:DD:EE:FF"],
    "biosSerialNumber": "C02XYZ123456",
    "motherboardSerialNumber": "C02XYZ123456",
    "hardwareUUID": "12345678-1234-1234-1234-123456789ABC",
    "modelIdentifier": "MacBookPro18,1",
    "processorInfo": "Apple M1 Pro",
    "memoryInfo": "16 GB",
    "diskInfo": "512 GB SSD",
    "installationPath": "/Applications/MacSystemMonitor.app",
    "deviceFingerprint": "ABC123DEF456"
  },
  "usbDeviceDetails": {
    "deviceId": "USB\\VID_0781&PID_5567",
    "deviceName": "SanDisk USB Drive",
    "vendorId": "0781",
    "productId": "5567",
    "serialNumber": "123456789",
    "blocked": true,
    "reason": "Device not in whitelist"
  }
}
```

## Device Information Captured

### macOS Device Information
- **Serial Number**: Hardware serial number from system profiler
- **Primary MAC Address**: Main network interface MAC address
- **All MAC Addresses**: All network interface MAC addresses
- **BIOS Serial Number**: System serial number
- **Motherboard Serial Number**: Motherboard serial number
- **Hardware UUID**: Unique hardware identifier
- **Model Identifier**: Mac model identifier (e.g., MacBookPro18,1)
- **Processor Info**: CPU information (e.g., Apple M1 Pro)
- **Memory Info**: RAM configuration (e.g., 16 GB)
- **Disk Info**: Storage information (e.g., 512 GB SSD)
- **Installation Path**: Application installation location
- **Device Fingerprint**: Unique device hash for identification

### Windows Device Information
- **Serial Number**: BIOS serial number from WMI
- **Primary MAC Address**: Main network adapter MAC address
- **All MAC Addresses**: All network adapter MAC addresses
- **BIOS Serial Number**: BIOS serial number
- **Motherboard Serial Number**: Motherboard serial number
- **Windows Product ID**: Windows product identifier
- **Installation Path**: Application installation location
- **Device Fingerprint**: Unique device hash for identification
- **Processor Info**: CPU information from WMI
- **Memory Info**: RAM configuration from WMI
- **Disk Info**: Storage information from WMI
- **Network Info**: Network adapter information

## Event Types and Details

### 1. USB Events (UsbDrive, UsbBlocked)
```json
{
  "usbDeviceDetails": {
    "deviceId": "USB\\VID_0781&PID_5567",
    "deviceName": "SanDisk USB Drive",
    "vendorId": "0781",
    "productId": "5567",
    "serialNumber": "123456789",
    "blocked": true,
    "reason": "Device not in whitelist"
  }
}
```

### 2. File Transfer Events (FileTransfer)
```json
{
  "fileTransferDetails": {
    "fileName": "confidential_document.pdf",
    "filePath": "/Volumes/USB_DRIVE/confidential_document.pdf",
    "eventType": "Created",
    "directory": "/Volumes/USB_DRIVE",
    "fileSize": "2048576"
  }
}
```

### 3. App Installation Events (AppInstallation, BlacklistedApp)
```json
{
  "appInstallationDetails": {
    "appName": "Discord",
    "publisher": "Discord Inc.",
    "installPath": "/Applications/Discord.app"
  }
}
```

### 4. Network Activity Events (NetworkActivity)
```json
{
  "networkActivityDetails": {
    "domain": "mega.nz",
    "connectionType": "HTTPS",
    "localPort": "54321",
    "remotePort": "443"
  }
}
```

### 5. Uninstall Detection Events (UninstallDetected)
```json
{
  "uninstallDetails": {
    "processId": "12345",
    "processName": "uninstaller",
    "commandLine": "/Applications/MacSystemMonitor.app/Contents/MacOS/uninstaller --force",
    "uninstallTime": "2024-01-15T10:30:00.000Z"
  }
}
```

## n8n Integration

### Email Notifications

The n8n workflow sends detailed email notifications with:

#### USB Blocked Email
- **Subject**: 🚨 CRITICAL: Unauthorized USB Device Blocked
- **Content**: Device details, blocking reason, recommended actions

#### Uninstall Detection Email
- **Subject**: 🚨 CRITICAL: System Monitor Uninstallation Detected
- **Content**: Device fingerprint, process details, immediate action items

#### File Transfer Email
- **Subject**: 📁 INFO: File Transfer Activity Detected
- **Content**: File details, transfer type, device information

#### Network Activity Email
- **Subject**: ⚠️ WARNING: Suspicious Network Activity Detected
- **Content**: Domain, connection details, security recommendations

### Email Template Example

```
🔍 SECURITY ALERT - MAC SYSTEM MONITOR
=====================================

📅 EVENT DETAILS
---------------
• Time: 2024-01-15T10:30:00.000Z
• Type: UsbBlocked
• Severity: High
• Description: Unauthorized USB device blocked: SanDisk USB Drive
• Computer: MACBOOK-PRO-001
• User: john.doe

🖥️ DEVICE INFORMATION
--------------------
• Serial Number: C02XYZ123456
• Primary MAC Address: 00:11:22:33:44:55
• All MAC Addresses: 00:11:22:33:44:55, AA:BB:CC:DD:EE:FF
• BIOS Serial: C02XYZ123456
• Motherboard Serial: C02XYZ123456
• Hardware UUID: 12345678-1234-1234-1234-123456789ABC
• Model: MacBookPro18,1
• Processor: Apple M1 Pro
• Memory: 16 GB
• Disk: 512 GB SSD
• Installation Path: /Applications/MacSystemMonitor.app
• Device Fingerprint: ABC123DEF456

💾 USB DEVICE DETAILS
-------------------
• Device ID: USB\VID_0781&PID_5567
• Device Name: SanDisk USB Drive
• Vendor ID: 0781
• Product ID: 5567
• Blocked: YES
• Reason: Device not in whitelist

🎯 RECOMMENDED ACTIONS
-------------------
• Investigate unauthorized USB device attempt
• Review USB whitelist configuration
• Check for potential security breach
• Update device whitelist if needed

📊 EVENT STATISTICS
-----------------
• Total Events Today: 15
• High Severity Events: 3
• USB Blocking Events: 2
• File Transfer Events: 8

---
This alert was generated automatically by the Mac System Monitor.
For support, contact your system administrator.
```

## Testing the Enhanced Logging

### macOS Test Script
```bash
# Run the enhanced logging test
./test-enhanced-logging.sh

# This will:
# 1. Generate test events with real device information
# 2. Create detailed log entries
# 3. Test n8n webhook (if available)
# 4. Generate a summary report
```

### Windows Test Script
```powershell
# Run the enhanced logging test
.\test-enhanced-logging.ps1

# This will:
# 1. Generate test events with real device information
# 2. Create detailed log entries
# 3. Test n8n webhook (if available)
# 4. Generate a summary report
```

## Log Management

### Automatic Log Rotation
- **Max Size**: 10MB per log file
- **Backup**: Previous log saved as `.log.1`
- **Cleanup**: Old logs automatically removed

### Log Statistics
```bash
# Get log statistics
EnhancedLogging.shared.getLogStatistics()

# Returns:
{
  "totalEvents": 150,
  "eventsByType": {
    "UsbBlocked": 25,
    "FileTransfer": 45,
    "AppInstallation": 20,
    "BlacklistedApp": 5,
    "NetworkActivity": 15,
    "UninstallDetected": 2,
    "UsbDrive": 38
  },
  "eventsBySeverity": {
    "Critical": 2,
    "High": 30,
    "Medium": 88,
    "Low": 30
  },
  "recentActivity": [...]
}
```

### Log Retrieval
```bash
# Get recent logs
EnhancedLogging.shared.getRecentLogs(limit: 100)

# Get logs by type
EnhancedLogging.shared.getLogsByType(.usbBlocked, limit: 50)

# Get logs by severity
EnhancedLogging.shared.getLogsBySeverity(.high, limit: 50)
```

## Security Considerations

### Log File Security
1. **File Permissions**: Log files are protected with admin-only access
2. **Encryption**: Consider encrypting sensitive log data
3. **Retention**: Implement log rotation and retention policies
4. **Backup**: Regular backup of log files for compliance

### Device Information Security
1. **Fingerprinting**: Device fingerprints are hashed for security
2. **MAC Addresses**: All network interface addresses captured
3. **Serial Numbers**: Hardware serial numbers for device identification
4. **UUIDs**: Hardware UUIDs for unique device identification

## Troubleshooting

### Common Issues

1. **Log File Not Created**
   - Check directory permissions
   - Verify application has write access
   - Check disk space

2. **Device Information Missing**
   - Verify system profiler access (macOS)
   - Check WMI permissions (Windows)
   - Ensure admin privileges

3. **n8n Webhook Not Working**
   - Verify n8n is running
   - Check webhook URL
   - Test with curl command

### Debug Commands

```bash
# Check log file permissions
ls -la /var/log/mac-system-monitor.log

# View recent logs
tail -f /var/log/mac-system-monitor.log

# Test device information
system_profiler SPHardwareDataType

# Test n8n webhook
curl -X POST http://localhost:5678/webhook/monitoring \
  -H "Content-Type: application/json" \
  -d '{"test": "event"}'
```

## Integration with Monitoring Applications

### macOS Integration
```swift
// Log USB event with enhanced details
let deviceInfo = DeviceInfoManager.getDeviceInfo()
await EnhancedLogging.shared.logUsbEvent(
    deviceInfo: usbDevice,
    blocked: true,
    reason: "Device not in whitelist"
)

// Log file transfer with details
await EnhancedLogging.shared.logFileTransfer(
    filePath: "/Volumes/USB_DRIVE/document.pdf",
    eventType: "Created",
    directory: "/Volumes/USB_DRIVE",
    fileSize: 2048576
)
```

### Windows Integration
```csharp
// Log USB event with enhanced details
var deviceInfo = DeviceInfoManager.GetDeviceInfo();
await EnhancedLogging.Instance.LogUsbEventAsync(
    deviceInfo: usbDevice,
    blocked: true,
    reason: "Device not in whitelist"
);

// Log file transfer with details
await EnhancedLogging.Instance.LogFileTransferAsync(
    filePath: @"C:\USB_DRIVE\document.pdf",
    eventType: "Created",
    directory: @"C:\USB_DRIVE",
    fileSize: 2048576
);
```

## Next Steps

1. **Set up n8n**: Follow the n8n setup guide
2. **Configure email**: Set up SMTP credentials
3. **Test notifications**: Run test scripts
4. **Deploy monitoring**: Install monitoring applications
5. **Monitor logs**: Set up log monitoring and alerts

## Support

For issues with:
- **Enhanced Logging**: Check log file permissions and disk space
- **Device Information**: Verify system access and admin privileges
- **n8n Integration**: Follow the n8n setup guide
- **Email Notifications**: Check SMTP configuration
- **Log Management**: Review log rotation and cleanup settings 
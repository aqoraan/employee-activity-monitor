# Mac System Monitor

A comprehensive macOS application for monitoring employee activities, USB device blocking, and system security with integration to n8n for automated alerting and reporting.

## 🛡️ Safe Testing Features

**The application includes a comprehensive test mode that allows you to safely test all features without making any system changes:**

### Test Mode Features
- ✅ **Simulates USB events** without actually blocking devices
- ✅ **Simulates file transfers** without monitoring real files
- ✅ **Simulates app installations** without monitoring processes
- ✅ **Simulates network activity** without monitoring connections
- ✅ **Uses test webhook URL** for N8N integration
- ✅ **Prevents all system changes** and admin operations
- ✅ **No administrative privileges** required
- ✅ **Safe for testing** on any macOS system

### How to Test Safely

#### 1. Quick Safe Test (Recommended)
```bash
./test-mac-safe.sh
```
This script will:
- Check system requirements
- Create a test configuration
- Build the application
- Offer multiple test modes
- Run for 60 seconds without any system changes

#### 2. Command Line Test Mode
```bash
# Build the project
xcodebuild -project MacSystemMonitor/MacSystemMonitor.xcodeproj -scheme MacSystemMonitor build

# Run in test mode
./MacSystemMonitor/build/Debug/MacSystemMonitor.app/Contents/MacOS/MacSystemMonitor --test-mode
```

#### 3. GUI Test Mode
```bash
# Open the app in test mode
open MacSystemMonitor/build/Debug/MacSystemMonitor.app --args --test-mode
```

#### 4. Safe Test Mode (60 seconds)
```bash
./MacSystemMonitor/build/Debug/MacSystemMonitor.app/Contents/MacOS/MacSystemMonitor --safe-test
```

### Test Mode Configuration
The test mode uses a separate configuration that:
- Disables all system monitoring
- Enables simulation of events
- Uses test webhook URLs
- Prevents administrative operations
- Logs all test events

## 🚀 Features

### Core Monitoring
- **USB Device Monitoring**: Track USB drive connections and file transfers
- **File Transfer Monitoring**: Monitor file operations on external storage
- **App Installation Monitoring**: Detect new application installations
- **Blacklisted App Detection**: Identify unauthorized applications
- **Network Activity Monitoring**: Monitor suspicious network connections
- **Real-time Logging**: Comprehensive activity logging with timestamps

### USB Blocking System
- **Google Sheets Integration**: Whitelist management via Google Sheets API
- **Automatic Device Blocking**: Block unauthorized USB storage devices
- **Whitelist Caching**: Efficient whitelist management with caching
- **Device Fingerprinting**: Unique device identification and tracking

### Security Features
- **Administrative Privileges**: Requires admin access for full functionality
- **Google Workspace Admin Validation**: Verify admin access via Google API
- **Configuration Protection**: Secure configuration file management
- **Uninstallation Prevention**: Prevent unauthorized removal
- **Auto-start Capability**: Configure to start on system boot

### Uninstall Detection
- **Device Fingerprinting**: Capture detailed device information
- **Process Monitoring**: Detect uninstallation attempts
- **Admin Notifications**: Send detailed notifications to administrators
- **System Information**: Include serial numbers, MAC addresses, and more

### N8N Integration
- **Automated Alerting**: Send structured JSON data to n8n webhooks
- **Email Notifications**: Automated email reporting
- **Device Information**: Include comprehensive device details
- **Retry Logic**: Robust error handling and retry mechanisms

## 📋 Requirements

### System Requirements
- macOS 14.0 or later
- Xcode 15.0 or later (for building)
- Administrative privileges (for full functionality)
- Internet connection (for N8N integration)

### Development Requirements
- Swift 5.9+
- Xcode Command Line Tools
- Git (for version control)

## 🛠️ Installation

### 1. Clone the Repository
```bash
git clone <repository-url>
cd system_monitor_windows
```

### 2. Build the Project
```bash
# Using Xcode
xcodebuild -project MacSystemMonitor/MacSystemMonitor.xcodeproj -scheme MacSystemMonitor build

# Or using Swift Package Manager
swift build
```

### 3. Run Safe Test First
```bash
./test-mac-safe.sh
```

### 4. Deploy (After Testing)
```bash
./deploy-mac-secure.sh
```

## ⚙️ Configuration

### Test Mode Configuration
The application includes a comprehensive test mode configuration:

```json
{
  "testModeSettings": {
    "enableTestMode": true,
    "simulateUsbEvents": true,
    "simulateFileTransfers": true,
    "simulateAppInstallations": true,
    "simulateNetworkActivity": true,
    "testIntervalSeconds": 15,
    "logTestEvents": true,
    "preventSystemChanges": true,
    "useTestWebhook": true,
    "testWebhookUrl": "http://localhost:5678/webhook/test",
    "maxTestEvents": 50
  }
}
```

### Production Configuration
For production deployment, configure:

```json
{
  "n8nWebhookUrl": "http://your-n8n-instance:5678/webhook/monitoring",
  "usbBlockingSettings": {
    "enableUsbBlocking": true,
    "googleSheetsApiKey": "your-api-key",
    "googleSheetsSpreadsheetId": "your-spreadsheet-id",
    "googleSheetsRange": "A:A"
  },
  "securitySettings": {
    "requireAdminAccess": true,
    "preventUninstallation": true,
    "protectConfiguration": true
  }
}
```

## 🔧 Usage

### Test Mode Usage

#### 1. GUI Interface
- Launch the application
- Toggle "Test Mode" in the interface
- Monitor simulated events in real-time
- View statistics and activity logs

#### 2. Command Line
```bash
# Enable test mode
./MacSystemMonitor --test-mode

# Run safe test
./MacSystemMonitor --safe-test

# Show help
./MacSystemMonitor --help
```

#### 3. Keyboard Shortcuts
- `Cmd+Shift+T`: Toggle test mode
- `Cmd+Shift+G`: Generate test event
- `Cmd+Shift+R`: Run safe test

### Production Usage

#### 1. Service Mode
```bash
./MacSystemMonitor --service
```

#### 2. Install as Service
```bash
sudo ./deploy-mac-secure.sh
```

#### 3. Uninstall
```bash
sudo ./uninstall-mac-secure.sh
```

## 📊 Monitoring Dashboard

The application provides a comprehensive dashboard with:

### Real-time Statistics
- Total activities count
- USB events (connected/blocked)
- File transfer events
- App installation events
- Network activity events
- Blocked device count

### Activity Log
- Detailed activity timeline
- Event severity indicators
- Device information
- User and computer details
- Timestamp tracking

### USB Control Panel
- USB blocking status
- Whitelist management
- Device blocking controls
- Test USB events

## 🔒 Security Considerations

### Test Mode Security
- **No System Changes**: Test mode prevents all system modifications
- **No Admin Requirements**: Test mode doesn't require admin privileges
- **Isolated Testing**: All operations are simulated
- **Safe Configuration**: Uses test-specific settings

### Production Security
- **Administrative Access**: Requires admin privileges for full functionality
- **Configuration Protection**: Secure configuration file management
- **Service Installation**: Proper service installation and management
- **Uninstall Prevention**: Prevents unauthorized removal

## 🐛 Troubleshooting

### Test Mode Issues

#### 1. Build Errors
```bash
# Clean and rebuild
xcodebuild clean -project MacSystemMonitor/MacSystemMonitor.xcodeproj
xcodebuild -project MacSystemMonitor/MacSystemMonitor.xcodeproj -scheme MacSystemMonitor build
```

#### 2. Test Mode Not Working
- Check configuration file: `config-test.json`
- Verify test mode is enabled: `"enableTestMode": true`
- Check console output for errors

#### 3. No Test Events
- Verify simulation settings are enabled
- Check test interval: `"testIntervalSeconds": 15`
- Monitor console for test event generation

### Common Issues

#### 1. Permission Denied
```bash
# Check file permissions
chmod +x test-mac-safe.sh
chmod +x deploy-mac-secure.sh
chmod +x uninstall-mac-secure.sh
```

#### 2. Xcode Not Found
```bash
# Install Xcode command line tools
xcode-select --install
```

#### 3. Swift Build Errors
```bash
# Update Swift tools
swift package update
swift build
```

## 📝 Logging

### Test Mode Logging
- All test events are logged with "TEST:" prefix
- Console output shows test mode status
- Activity log includes test event details
- No system logs are modified

### Production Logging
- System logs: `/var/log/MacSystemMonitor.log`
- Error logs: `/var/log/MacSystemMonitor.error.log`
- Security events: System log with "MacSystemMonitor" tag

## 🔄 Updates and Maintenance

### Updating Test Configuration
```bash
# Edit test configuration
nano config-test.json

# Restart test mode
./test-mac-safe.sh
```

### Updating Production Configuration
```bash
# Edit production configuration
sudo nano /Library/Application\ Support/MacSystemMonitor/config.json

# Restart service
sudo launchctl unload /Library/LaunchDaemons/com.company.MacSystemMonitor.plist
sudo launchctl load /Library/LaunchDaemons/com.company.MacSystemMonitor.plist
```

## 📞 Support

### Test Mode Support
- All test mode issues are safe to troubleshoot
- No system changes are made in test mode
- Console output provides detailed debugging information

### Production Support
- Requires administrative access for troubleshooting
- Service logs provide detailed error information
- Configuration files can be modified for debugging

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes using the safe test mode
4. Submit a pull request

## ⚠️ Disclaimer

This application is designed for enterprise use and includes features that may affect system behavior. Always test thoroughly in a safe environment before deploying to production systems. The test mode provides a safe way to evaluate all features without making system changes. 
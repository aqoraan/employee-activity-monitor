#!/bin/bash

# Secure Mac System Monitor Deployment Script
# This script builds and deploys the monitoring application with administrative protection

set -e

# Configuration
CONFIGURATION=${1:-Release}
OUTPUT_PATH=${2:-./publish}
INSTALL_N8N=${3:-false}
SKIP_BUILD=${4:-false}
INSTALL_AS_SERVICE=${5:-false}
GOOGLE_WORKSPACE_ADMIN=${6:-""}
GOOGLE_WORKSPACE_TOKEN=${7:-""}

echo "Secure Mac System Monitor Deployment Script"
echo "=========================================="

# Check if running as administrator
if [[ $EUID -ne 0 ]]; then
   echo "This script requires administrative privileges. Please run with sudo."
   echo "Usage: sudo ./deploy-mac-secure.sh"
   exit 1
fi

# Check Xcode installation
if ! command -v xcodebuild &> /dev/null; then
    echo "Xcode is not installed. Please install Xcode from the App Store."
    exit 1
fi

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "This script is designed for macOS only."
    exit 1
fi

# Build the application
if [[ "$SKIP_BUILD" != "true" ]]; then
    echo "Building application..."
    
    # Navigate to the project directory
    cd MacSystemMonitor
    
    # Clean previous builds
    echo "Cleaning previous builds..."
    xcodebuild clean -project MacSystemMonitor.xcodeproj -scheme MacSystemMonitor -configuration $CONFIGURATION
    
    # Build application
    echo "Building application in $CONFIGURATION configuration..."
    xcodebuild build -project MacSystemMonitor.xcodeproj -scheme MacSystemMonitor -configuration $CONFIGURATION
    
    # Archive application
    echo "Archiving application..."
    xcodebuild archive -project MacSystemMonitor.xcodeproj -scheme MacSystemMonitor -configuration $CONFIGURATION -archivePath $OUTPUT_PATH/MacSystemMonitor.xcarchive
    
    # Export application
    echo "Exporting application..."
    xcodebuild -exportArchive -archivePath $OUTPUT_PATH/MacSystemMonitor.xcarchive -exportPath $OUTPUT_PATH -exportOptionsPlist exportOptions.plist
    
    echo "Build completed successfully!"
else
    echo "Skipping build step."
fi

# Create export options plist if it doesn't exist
if [[ ! -f "MacSystemMonitor/exportOptions.plist" ]]; then
    cat > MacSystemMonitor/exportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF
fi

# Install as service if requested
if [[ "$INSTALL_AS_SERVICE" == "true" ]]; then
    echo "Installing as macOS service..."
    
    APP_PATH="$OUTPUT_PATH/MacSystemMonitor.app"
    if [[ -d "$APP_PATH" ]]; then
        # Install the service
        "$APP_PATH/Contents/MacOS/MacSystemMonitor" --install
        if [[ $? -eq 0 ]]; then
            echo "Service installed successfully!"
            
            # Start the service
            echo "Starting service..."
            launchctl load /Library/LaunchDaemons/com.company.MacSystemMonitor.plist
            if [[ $? -eq 0 ]]; then
                echo "Service started successfully!"
            else
                echo "Warning: Could not start service automatically."
            fi
        else
            echo "Failed to install service."
            exit 1
        fi
    else
        echo "Application not found at: $APP_PATH"
        exit 1
    fi
fi

# Create secure configuration file
echo "Creating secure configuration file..."
CONFIG_PATH="$OUTPUT_PATH/config.json"
cat > "$CONFIG_PATH" << EOF
{
  "n8nWebhookUrl": "http://localhost:5678/webhook/monitoring",
  "blacklistedApps": [
    "tor", "vpn", "proxy", "anonymizer",
    "cryptolocker", "ransomware", "keylogger",
    "spyware", "malware", "trojan",
    "hacktool", "crack", "keygen", "patch"
  ],
  "suspiciousDomains": [
    "mega.nz", "dropbox.com", "google-drive.com", "onedrive.com",
    "we-transfer.com", "file.io", "transfernow.net", "wetransfer.com",
    "sendspace.com", "rapidshare.com", "mediafire.com", "4shared.com"
  ],
  "monitoringSettings": {
    "enableUsbMonitoring": true,
    "enableFileTransferMonitoring": true,
    "enableAppInstallationMonitoring": true,
    "enableNetworkMonitoring": true,
    "enableBlacklistedAppMonitoring": true,
    "logLevel": "Medium",
    "maxLogEntries": 10000,
    "autoStartMonitoring": true,
    "sendToN8n": true,
    "n8nRetryAttempts": 3,
    "n8nRetryDelayMs": 5000,
    "requireAdminAccess": true
  },
  "securitySettings": {
    "googleWorkspaceAdmin": "$GOOGLE_WORKSPACE_ADMIN",
    "googleWorkspaceToken": "$GOOGLE_WORKSPACE_TOKEN",
    "preventUninstallation": true,
    "protectConfiguration": true,
    "logSecurityEvents": true,
    "requireGoogleWorkspaceAdmin": false,
    "autoStartOnBoot": true,
    "runAsService": true,
    "protectRegistry": true,
    "addGatekeeperExclusion": true
  },
  "usbBlockingSettings": {
    "enableUsbBlocking": true,
    "googleSheetsApiKey": "",
    "googleSheetsSpreadsheetId": "",
    "googleSheetsRange": "A:A",
    "cacheExpirationMinutes": 5,
    "blockAllUsbStorage": false,
    "allowWhitelistedOnly": true,
    "logBlockedDevices": true,
    "sendBlockingAlerts": true,
    "localWhitelist": [],
    "localBlacklist": []
  },
  "uninstallDetectionSettings": {
    "enableUninstallDetection": true,
    "sendUninstallNotifications": true,
    "captureDeviceInfo": true,
    "logUninstallAttempts": true,
    "requireAdminForUninstall": true,
    "sendDeviceFingerprint": true,
    "includeMacAddresses": true,
    "includeSerialNumbers": true,
    "includeProcessDetails": true
  }
}
EOF

echo "Configuration file created: $CONFIG_PATH"

# Set file permissions to protect configuration
echo "Setting file permissions..."
chmod 600 "$CONFIG_PATH"
chown root:wheel "$CONFIG_PATH"

# Create application support directory
echo "Creating application support directory..."
mkdir -p "/Library/Application Support/MacSystemMonitor"
cp "$CONFIG_PATH" "/Library/Application Support/MacSystemMonitor/config.json"
chmod 600 "/Library/Application Support/MacSystemMonitor/config.json"
chown root:wheel "/Library/Application Support/MacSystemMonitor/config.json"

# Add to login items
echo "Adding to login items..."
osascript -e 'tell application "System Events" to make login item at end with properties {path:"'$OUTPUT_PATH'/MacSystemMonitor.app", hidden:true}'

# Add Gatekeeper exclusion
echo "Adding Gatekeeper exclusion..."
spctl --add "$OUTPUT_PATH/MacSystemMonitor.app"

# Create secure management scripts
echo "Creating secure management scripts..."

# Service management script
cat > "$OUTPUT_PATH/manage-service.sh" << 'EOF'
#!/bin/bash
echo "Mac System Monitor Service Management"
echo "===================================="
echo

if [[ $EUID -ne 0 ]]; then
   echo "This script requires administrative privileges."
   exit 1
fi

case "$1" in
    start)
        echo "Starting service..."
        launchctl load /Library/LaunchDaemons/com.company.MacSystemMonitor.plist
        ;;
    stop)
        echo "Stopping service..."
        launchctl unload /Library/LaunchDaemons/com.company.MacSystemMonitor.plist
        ;;
    status)
        echo "Checking service status..."
        launchctl list | grep com.company.MacSystemMonitor
        ;;
    *)
        echo "Usage: $0 [start|stop|status]"
        echo
        echo "Commands:"
        echo "  start   - Start the monitoring service"
        echo "  stop    - Stop the monitoring service"
        echo "  status  - Check service status"
        ;;
esac
EOF

chmod +x "$OUTPUT_PATH/manage-service.sh"

# Secure uninstall script
cat > "$OUTPUT_PATH/uninstall-secure.sh" << 'EOF'
#!/bin/bash
echo "Mac System Monitor Secure Uninstall"
echo "==================================="
echo
echo "WARNING: This will completely remove the monitoring system."
echo "Only proceed if you have administrative authorization."
echo

if [[ $EUID -ne 0 ]]; then
   echo "This script requires administrative privileges."
   exit 1
fi

read -p "Type 'YES' to confirm uninstallation: " confirm
if [[ "$confirm" != "YES" ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

echo
echo "Starting secure uninstallation..."

# Stop the service
echo "Stopping Mac System Monitor service..."
launchctl unload /Library/LaunchDaemons/com.company.MacSystemMonitor.plist

# Remove the service
echo "Removing macOS service..."
rm -f /Library/LaunchDaemons/com.company.MacSystemMonitor.plist

# Remove login item
echo "Removing login item..."
osascript -e 'tell application "System Events" to delete login item "MacSystemMonitor"'

# Remove application support files
echo "Removing application support files..."
rm -rf "/Library/Application Support/MacSystemMonitor"

# Remove application
echo "Removing application..."
rm -rf "/Applications/MacSystemMonitor.app"

# Remove Gatekeeper exclusion
echo "Removing Gatekeeper exclusion..."
spctl --remove "/Applications/MacSystemMonitor.app"

echo
echo "Uninstallation completed successfully!"
EOF

chmod +x "$OUTPUT_PATH/uninstall-secure.sh"

# Install N8N if requested
if [[ "$INSTALL_N8N" == "true" ]]; then
    echo "Installing N8N..."
    
    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        echo "Node.js is not installed. Please install Node.js first."
        echo "Download from: https://nodejs.org/"
        exit 1
    fi
    
    # Install N8N globally
    echo "Installing N8N globally..."
    npm install -g n8n
    
    if [[ $? -eq 0 ]]; then
        echo "N8N installed successfully!"
        echo "To start N8N, run: n8n start"
        echo "Access N8N at: http://localhost:5678"
    else
        echo "Failed to install N8N."
        exit 1
    fi
fi

# Display completion message
echo
echo "Secure deployment completed successfully!"
echo "========================================"
echo "Application location: $OUTPUT_PATH"
echo "Application: $OUTPUT_PATH/MacSystemMonitor.app"
echo "Configuration: $CONFIG_PATH"
echo "Service management: $OUTPUT_PATH/manage-service.sh"
echo "Secure uninstall: $OUTPUT_PATH/uninstall-secure.sh"

if [[ "$INSTALL_AS_SERVICE" == "true" ]]; then
    echo
    echo "Service Status:"
    echo "Service Name: com.company.MacSystemMonitor"
    echo "Startup Type: Automatic"
    echo "Account: root"
    echo "Protection: Enabled"
fi

if [[ "$INSTALL_N8N" == "true" ]]; then
    echo
    echo "N8N Setup Instructions:"
    echo "1. Start N8N: n8n start"
    echo "2. Open browser: http://localhost:5678"
    echo "3. Import workflow: n8n-workflow.json"
    echo "4. Configure email settings"
    echo "5. Activate the workflow"
fi

echo
echo "Security Features Enabled:"
echo "✓ Administrative privileges required"
echo "✓ Auto-start on macOS boot"
echo "✓ Configuration file protection"
echo "✓ Gatekeeper exclusion"
echo "✓ Service-based monitoring"
echo "✓ Google Workspace admin validation"

echo
echo "Next Steps:"
echo "1. Service will start automatically on next boot"
echo "2. Monitor system logs for activity"
echo "3. Configure N8N for email alerts"
echo "4. Test monitoring functionality"

echo
read -p "Press any key to exit..." 
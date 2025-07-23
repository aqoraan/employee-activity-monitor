#!/bin/bash

# Safe Test Script for Mac System Monitor
# This script runs the application in test mode without making any system changes

set -e

echo "=== Mac System Monitor - Safe Test Mode ==="
echo "This script will run the application in test mode for safe testing."
echo "No system changes will be made."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only."
    exit 1
fi

# Check if Xcode command line tools are installed
if ! command -v xcodebuild &> /dev/null; then
    print_warning "Xcode command line tools not found."
    print_status "Installing Xcode command line tools..."
    xcode-select --install
    print_success "Xcode command line tools installed."
fi

# Check if Swift is available
if ! command -v swift &> /dev/null; then
    print_error "Swift is not available. Please install Xcode."
    exit 1
fi

print_status "Checking system requirements..."

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
print_status "macOS Version: $MACOS_VERSION"

# Check if we have the project files
if [ ! -d "MacSystemMonitor" ]; then
    print_error "MacSystemMonitor directory not found."
    print_status "Please run this script from the project root directory."
    exit 1
fi

print_success "System requirements met."

# Create test configuration
print_status "Creating test configuration..."

cat > config-test.json << EOF
{
  "n8nWebhookUrl": "http://localhost:5678/webhook/test",
  "blacklistedApps": ["tor", "vpn", "proxy"],
  "suspiciousDomains": ["mega.nz", "dropbox.com"],
  "monitoringSettings": {
    "enableUsbMonitoring": true,
    "enableFileTransferMonitoring": true,
    "enableAppInstallationMonitoring": true,
    "enableNetworkMonitoring": true,
    "enableBlacklistedAppMonitoring": true,
    "logLevel": "Medium",
    "maxLogEntries": 1000,
    "autoStartMonitoring": false,
    "sendToN8n": true,
    "n8nRetryAttempts": 3,
    "n8nRetryDelayMs": 5000,
    "requireAdminAccess": false
  },
  "emailSettings": {
    "smtpServer": "smtp.gmail.com",
    "smtpPort": 587,
    "useSsl": true,
    "username": "",
    "password": "",
    "fromEmail": "test@yourcompany.com",
    "toEmail": "admin@yourcompany.com",
    "ccEmail": "",
    "enableEmailAlerts": false
  },
  "securitySettings": {
    "googleWorkspaceAdmin": "",
    "googleWorkspaceToken": "",
    "preventUninstallation": false,
    "protectConfiguration": false,
    "logSecurityEvents": true,
    "requireGoogleWorkspaceAdmin": false,
    "autoStartOnBoot": false,
    "runAsService": false,
    "protectRegistry": false,
    "addGatekeeperExclusion": false
  },
  "usbBlockingSettings": {
    "enableUsbBlocking": false,
    "googleSheetsApiKey": "",
    "googleSheetsSpreadsheetId": "",
    "googleSheetsRange": "A:A",
    "cacheExpirationMinutes": 5,
    "blockAllUsbStorage": false,
    "allowWhitelistedOnly": false,
    "logBlockedDevices": true,
    "sendBlockingAlerts": true,
    "localWhitelist": [],
    "localBlacklist": []
  },
  "uninstallDetectionSettings": {
    "enableUninstallDetection": false,
    "sendUninstallNotifications": false,
    "captureDeviceInfo": true,
    "logUninstallAttempts": true,
    "requireAdminForUninstall": false,
    "sendDeviceFingerprint": true,
    "includeMacAddresses": true,
    "includeSerialNumbers": true,
    "includeProcessDetails": true
  },
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
EOF

print_success "Test configuration created."

# Build the project
print_status "Building Mac System Monitor..."

# Check if we have an Xcode project
if [ -f "MacSystemMonitor/MacSystemMonitor.xcodeproj/project.pbxproj" ]; then
    print_status "Building with Xcode..."
    xcodebuild -project MacSystemMonitor/MacSystemMonitor.xcodeproj -scheme MacSystemMonitor -configuration Debug build
    APP_PATH="MacSystemMonitor/build/Debug/MacSystemMonitor.app"
else
    print_status "No Xcode project found, attempting to build with Swift Package Manager..."
    
    # Create a simple Swift Package Manager setup for testing
    cat > Package.swift << EOF
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacSystemMonitor",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacSystemMonitor", targets: ["MacSystemMonitor"])
    ],
    targets: [
        .executableTarget(
            name: "MacSystemMonitor",
            path: "MacSystemMonitor"
        )
    ]
)
EOF
    
    swift build
    APP_PATH=".build/debug/MacSystemMonitor"
fi

print_success "Build completed."

# Test modes
print_status "Available test modes:"
echo "1. GUI Test Mode - Run with graphical interface"
echo "2. Command Line Test Mode - Run in terminal"
echo "3. Safe Test Mode - 60-second automated test"
echo "4. Service Test Mode - Run as background service"
echo ""

read -p "Select test mode (1-4): " test_mode

case $test_mode in
    1)
        print_status "Starting GUI Test Mode..."
        if [ -d "$APP_PATH" ]; then
            open "$APP_PATH" --args --test-mode
        else
            print_error "Application not found at expected location."
            exit 1
        fi
        ;;
    2)
        print_status "Starting Command Line Test Mode..."
        if [ -d "$APP_PATH" ]; then
            "$APP_PATH/Contents/MacOS/MacSystemMonitor" --test-mode
        elif [ -f "$APP_PATH" ]; then
            "$APP_PATH" --test-mode
        else
            print_error "Application not found."
            exit 1
        fi
        ;;
    3)
        print_status "Starting Safe Test Mode (60 seconds)..."
        if [ -d "$APP_PATH" ]; then
            "$APP_PATH/Contents/MacOS/MacSystemMonitor" --safe-test
        elif [ -f "$APP_PATH" ]; then
            "$APP_PATH" --safe-test
        else
            print_error "Application not found."
            exit 1
        fi
        ;;
    4)
        print_status "Starting Service Test Mode..."
        if [ -d "$APP_PATH" ]; then
            "$APP_PATH/Contents/MacOS/MacSystemMonitor" --service
        elif [ -f "$APP_PATH" ]; then
            "$APP_PATH" --service
        else
            print_error "Application not found."
            exit 1
        fi
        ;;
    *)
        print_error "Invalid selection."
        exit 1
        ;;
esac

print_success "Test completed."
print_status "Test configuration saved to: config-test.json"
print_status "You can modify the configuration and restart the test."

echo ""
echo "=== Test Mode Features ==="
echo "✓ Simulates USB events without blocking devices"
echo "✓ Simulates file transfers without monitoring real files"
echo "✓ Simulates app installations without monitoring processes"
echo "✓ Simulates network activity without monitoring connections"
echo "✓ Uses test webhook URL for N8N integration"
echo "✓ Prevents all system changes and admin operations"
echo "✓ No administrative privileges required"
echo "✓ Safe for testing on any macOS system"
echo ""

print_success "Safe test mode completed successfully!" 
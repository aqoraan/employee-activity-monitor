#!/bin/bash

# Secure Uninstall Script for Mac System Monitor
# This script sends device information to admin before uninstalling

set -e

# Configuration
FORCE=${1:-false}
SKIP_NOTIFICATION=${2:-false}
ADMIN_EMAIL=${3:-"admin@yourcompany.com"}

echo "Secure Uninstall Script - Mac System Monitor"
echo "============================================"

# Check if running as administrator
if [[ $EUID -ne 0 ]]; then
   echo "This script requires administrative privileges. Please run with sudo."
   echo "Usage: sudo ./uninstall-mac-secure.sh"
   exit 1
fi

# Get device information
echo "Gathering device information..."

# Function to get device info
get_device_info() {
    local device_info=""
    
    # Get computer name
    local computer_name=$(scutil --get ComputerName)
    
    # Get user name
    local user_name=$(whoami)
    
    # Get serial number
    local serial_number=$(ioreg -l | grep IOPlatformSerialNumber | awk -F'"' '{print $4}')
    
    # Get MAC addresses
    local mac_addresses=$(ifconfig | grep ether | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')
    
    # Get hardware UUID
    local hardware_uuid=$(ioreg -l | grep IOPlatformUUID | awk -F'"' '{print $4}')
    
    # Get model identifier
    local model_identifier=$(sysctl -n hw.model)
    
    # Get macOS version
    local macos_version=$(sw_vers -productVersion)
    
    # Get processor info
    local processor_info=$(sysctl -n machdep.cpu.brand_string)
    
    # Get memory info
    local memory_size=$(sysctl -n hw.memsize)
    local memory_gb=$(echo "scale=1; $memory_size / 1024 / 1024 / 1024" | bc)
    
    # Get disk info
    local disk_info=$(diskutil info / | grep "Device / Media Name:" | awk -F': ' '{print $2}')
    
    # Get installation path
    local installation_path="/Applications/MacSystemMonitor.app"
    
    # Create JSON structure
    device_info=$(cat << EOF
{
  "computerName": "$computer_name",
  "userName": "$user_name",
  "serialNumber": "$serial_number",
  "macAddresses": ["$(echo $mac_addresses | sed 's/,/","/g')"],
  "hardwareUUID": "$hardware_uuid",
  "modelIdentifier": "$model_identifier",
  "macOSVersion": "$macos_version",
  "processorInfo": "$processor_info",
  "memoryInfo": "${memory_gb}GB",
  "diskInfo": "$disk_info",
  "installationPath": "$installation_path"
}
EOF
)
    
    echo "$device_info"
}

DEVICE_INFO=$(get_device_info)

# Display device information
echo "Device Information:"
echo "  Computer Name: $(echo "$DEVICE_INFO" | jq -r '.computerName')"
echo "  User Name: $(echo "$DEVICE_INFO" | jq -r '.userName')"
echo "  Serial Number: $(echo "$DEVICE_INFO" | jq -r '.serialNumber')"
echo "  Hardware UUID: $(echo "$DEVICE_INFO" | jq -r '.hardwareUUID')"
echo "  Model Identifier: $(echo "$DEVICE_INFO" | jq -r '.modelIdentifier')"
echo "  macOS Version: $(echo "$DEVICE_INFO" | jq -r '.macOSVersion')"
echo "  Processor: $(echo "$DEVICE_INFO" | jq -r '.processorInfo')"
echo "  Memory: $(echo "$DEVICE_INFO" | jq -r '.memoryInfo')"
echo "  Disk: $(echo "$DEVICE_INFO" | jq -r '.diskInfo')"
echo "  Installation Path: $(echo "$DEVICE_INFO" | jq -r '.installationPath')"

# Display MAC addresses
echo "  MAC Addresses:"
echo "$DEVICE_INFO" | jq -r '.macAddresses[]' | while read -r mac; do
    echo "    $mac"
done

# Send uninstall notification if not skipped
if [[ "$SKIP_NOTIFICATION" != "true" ]]; then
    echo
    echo "Sending uninstall notification..."
    
    # Create notification data
    NOTIFICATION_DATA=$(cat << EOF
{
  "eventType": "UninstallDetected",
  "timestamp": "$(date -u +"%Y-%m-%d %H:%M:%S")",
  "severity": "Critical",
  "computer": "$(echo "$DEVICE_INFO" | jq -r '.computerName')",
  "user": "$(echo "$DEVICE_INFO" | jq -r '.userName')",
  "deviceInfo": $DEVICE_INFO,
  "uninstallDetails": {
    "processId": $$,
    "processName": "bash",
    "commandLine": "$0 $*",
    "uninstallTime": "$(date -u +"%Y-%m-%d %H:%M:%S")"
  }
}
EOF
)
    
    # Send to N8N webhook
    WEBHOOK_URL="http://localhost:5678/webhook/monitoring"
    
    if curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$NOTIFICATION_DATA" \
        "$WEBHOOK_URL" > /dev/null; then
        echo "Uninstall notification sent successfully!"
    else
        echo "Warning: Failed to send uninstall notification."
        echo "Continuing with uninstallation..."
    fi
fi

# Confirm uninstallation
if [[ "$FORCE" != "true" ]]; then
    echo
    echo "⚠️  WARNING: This will completely remove the Mac System Monitor software."
    echo "All monitoring and security features will be disabled."
    echo
    echo "Device information has been captured and sent to administrators."
    
    read -p "Type 'YES' to confirm uninstallation: " confirm
    if [[ "$confirm" != "YES" ]]; then
        echo "Uninstallation cancelled."
        exit 0
    fi
fi

echo
echo "Starting secure uninstallation..."

# Stop the service
echo "Stopping Mac System Monitor service..."
launchctl unload /Library/LaunchDaemons/com.company.MacSystemMonitor.plist 2>/dev/null || true

# Remove the service
echo "Removing macOS service..."
rm -f /Library/LaunchDaemons/com.company.MacSystemMonitor.plist

# Remove login item
echo "Removing login item..."
osascript -e 'tell application "System Events" to delete login item "MacSystemMonitor"' 2>/dev/null || true

# Remove application support files
echo "Removing application support files..."
rm -rf "/Library/Application Support/MacSystemMonitor"

# Remove application
echo "Removing application..."
rm -rf "/Applications/MacSystemMonitor.app"

# Remove Gatekeeper exclusion
echo "Removing Gatekeeper exclusion..."
spctl --remove "/Applications/MacSystemMonitor.app" 2>/dev/null || true

# Remove uninstall detection files
echo "Cleaning up detection files..."
rm -f "/Library/Application Support/MacSystemMonitor/uninstall_detected.flag"

# Remove any remaining configuration files
echo "Removing configuration files..."
find /Library -name "*MacSystemMonitor*" -type f -delete 2>/dev/null || true
find /Library -name "*MacSystemMonitor*" -type d -empty -delete 2>/dev/null || true

# Remove from system logs
echo "Cleaning system logs..."
log delete --predicate 'process == "MacSystemMonitor"' 2>/dev/null || true

echo
echo "✅ Uninstallation completed successfully!"
echo "Device information has been sent to administrators for tracking."
echo
echo "Press any key to exit..."
read -n 1 
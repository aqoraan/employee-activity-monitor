#!/bin/bash

# Enhanced Logging Test Script
# This script demonstrates the enhanced logging functionality with detailed device information

set -e

echo "=== Enhanced Logging Test ==="
echo "This script will test the enhanced logging system with detailed device information."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

print_test() {
    echo -e "${PURPLE}[TEST]${NC} $1"
}

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only."
    exit 1
fi

print_status "Starting Enhanced Logging Test..."

# Create test log directory
TEST_LOG_DIR="/tmp/mac-system-monitor-test"
mkdir -p "$TEST_LOG_DIR"

print_test "Creating test log file..."
TEST_LOG_FILE="$TEST_LOG_DIR/enhanced-test.log"

# Function to generate device information
generate_device_info() {
    cat << EOF
{
  "serialNumber": "$(system_profiler SPHardwareDataType | grep "Serial Number" | awk '{print $3}' | head -1)",
  "primaryMacAddress": "$(ifconfig en0 | grep ether | awk '{print $2}')",
  "allMacAddresses": [
    "$(ifconfig en0 | grep ether | awk '{print $2}')",
    "$(ifconfig en1 | grep ether | awk '{print $2}' 2>/dev/null || echo 'N/A')",
    "$(ifconfig en2 | grep ether | awk '{print $2}' 2>/dev/null || echo 'N/A')"
  ],
  "biosSerialNumber": "$(system_profiler SPHardwareDataType | grep "Serial Number" | awk '{print $3}' | head -1)",
  "motherboardSerialNumber": "$(system_profiler SPHardwareDataType | grep "Serial Number" | awk '{print $3}' | head -1)",
  "hardwareUUID": "$(system_profiler SPHardwareDataType | grep "Hardware UUID" | awk '{print $3}')",
  "modelIdentifier": "$(system_profiler SPHardwareDataType | grep "Model Identifier" | awk '{print $3}')",
  "processorInfo": "$(system_profiler SPHardwareDataType | grep "Chip" | awk '{print $2, $3, $4}')",
  "memoryInfo": "$(system_profiler SPHardwareDataType | grep "Memory" | awk '{print $2, $3}')",
  "diskInfo": "$(df -h / | tail -1 | awk '{print $2}')",
  "installationPath": "/Applications/MacSystemMonitor.app",
  "deviceFingerprint": "$(echo "$(hostname)-$(system_profiler SPHardwareDataType | grep "Serial Number" | awk '{print $3}' | head -1)-$(date +%s)" | shasum | awk '{print $1}')"
}
EOF
}

# Function to create test event
create_test_event() {
    local event_type="$1"
    local description="$2"
    local severity="$3"
    local details="$4"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
    local computer=$(hostname)
    local user=$(whoami)
    
    cat << EOF
{
  "timestamp": "$timestamp",
  "type": "$event_type",
  "severity": "$severity",
  "description": "$description",
  "computer": "$computer",
  "user": "$user",
  "details": $details,
  "deviceInfo": $(generate_device_info)
}
EOF
}

# Test 1: USB Blocked Event
print_test "Test 1: USB Blocked Event"
USB_BLOCKED_EVENT=$(create_test_event "UsbBlocked" "Unauthorized USB device blocked: SanDisk USB Drive" "High" '{
  "DeviceID": "USB\\VID_0781&PID_5567",
  "DeviceName": "SanDisk USB Drive",
  "VendorID": "0781",
  "ProductID": "5567",
  "SerialNumber": "123456789",
  "Blocked": "true",
  "Reason": "Device not in whitelist"
}')

echo "$USB_BLOCKED_EVENT" | jq '.' >> "$TEST_LOG_FILE"
print_success "USB Blocked event logged"

# Test 2: File Transfer Event
print_test "Test 2: File Transfer Event"
FILE_TRANSFER_EVENT=$(create_test_event "FileTransfer" "File copied: confidential_document.pdf" "Medium" '{
  "FilePath": "/Volumes/USB_DRIVE/confidential_document.pdf",
  "FileName": "confidential_document.pdf",
  "EventType": "Created",
  "Directory": "/Volumes/USB_DRIVE",
  "FileSize": "2048576"
}')

echo "$FILE_TRANSFER_EVENT" | jq '.' >> "$TEST_LOG_FILE"
print_success "File Transfer event logged"

# Test 3: App Installation Event
print_test "Test 3: App Installation Event"
APP_INSTALL_EVENT=$(create_test_event "AppInstallation" "App installation: Discord" "Medium" '{
  "AppName": "Discord",
  "Publisher": "Discord Inc.",
  "InstallPath": "/Applications/Discord.app"
}')

echo "$APP_INSTALL_EVENT" | jq '.' >> "$TEST_LOG_FILE"
print_success "App Installation event logged"

# Test 4: Blacklisted App Event
print_test "Test 4: Blacklisted App Event"
BLACKLISTED_APP_EVENT=$(create_test_event "BlacklistedApp" "Blacklisted app detected: Tor Browser" "High" '{
  "AppName": "Tor Browser",
  "Publisher": "The Tor Project",
  "InstallPath": "/Applications/Tor Browser.app",
  "Blacklisted": "true"
}')

echo "$BLACKLISTED_APP_EVENT" | jq '.' >> "$TEST_LOG_FILE"
print_success "Blacklisted App event logged"

# Test 5: Network Activity Event
print_test "Test 5: Network Activity Event"
NETWORK_EVENT=$(create_test_event "NetworkActivity" "Suspicious network connection: mega.nz" "High" '{
  "Domain": "mega.nz",
  "ConnectionType": "HTTPS",
  "LocalPort": "54321",
  "RemotePort": "443"
}')

echo "$NETWORK_EVENT" | jq '.' >> "$TEST_LOG_FILE"
print_success "Network Activity event logged"

# Test 6: Uninstall Detection Event
print_test "Test 6: Uninstall Detection Event"
UNINSTALL_EVENT=$(create_test_event "UninstallDetected" "Uninstall detected: MacSystemMonitor" "Critical" '{
  "ProcessID": "12345",
  "ProcessName": "uninstaller",
  "CommandLine": "/Applications/MacSystemMonitor.app/Contents/MacOS/uninstaller --force"
}')

echo "$UNINSTALL_EVENT" | jq '.' >> "$TEST_LOG_FILE"
print_success "Uninstall Detection event logged"

# Test 7: USB Drive Connected Event
print_test "Test 7: USB Drive Connected Event"
USB_CONNECT_EVENT=$(create_test_event "UsbDrive" "USB device connected: Kingston DataTraveler" "Medium" '{
  "DeviceID": "USB\\VID_0951&PID_1666",
  "DeviceName": "Kingston DataTraveler",
  "VendorID": "0951",
  "ProductID": "1666",
  "SerialNumber": "987654321",
  "Blocked": "false",
  "Reason": "Device in whitelist"
}')

echo "$USB_CONNECT_EVENT" | jq '.' >> "$TEST_LOG_FILE"
print_success "USB Drive Connected event logged"

# Display log file contents
print_status "Log file contents:"
echo ""
echo "=== Enhanced Log File ==="
cat "$TEST_LOG_FILE"
echo ""

# Analyze log entries
print_status "Analyzing log entries..."

# Count events by type
print_test "Event Statistics:"
echo "Total Events: $(jq -s 'length' "$TEST_LOG_FILE")"
echo "USB Blocked Events: $(jq -s '[.[] | select(.type == "UsbBlocked")] | length' "$TEST_LOG_FILE")"
echo "File Transfer Events: $(jq -s '[.[] | select(.type == "FileTransfer")] | length' "$TEST_LOG_FILE")"
echo "App Installation Events: $(jq -s '[.[] | select(.type == "AppInstallation")] | length' "$TEST_LOG_FILE")"
echo "Blacklisted App Events: $(jq -s '[.[] | select(.type == "BlacklistedApp")] | length' "$TEST_LOG_FILE")"
echo "Network Activity Events: $(jq -s '[.[] | select(.type == "NetworkActivity")] | length' "$TEST_LOG_FILE")"
echo "Uninstall Detection Events: $(jq -s '[.[] | select(.type == "UninstallDetected")] | length' "$TEST_LOG_FILE")"
echo "USB Drive Events: $(jq -s '[.[] | select(.type == "UsbDrive")] | length' "$TEST_LOG_FILE")"

# Show device information from first event
print_test "Device Information (from first event):"
jq -r '.deviceInfo | to_entries[] | "\(.key): \(.value)"' "$TEST_LOG_FILE" | head -10

# Show file transfer details
print_test "File Transfer Details:"
jq -r 'select(.type == "FileTransfer") | "File: \(.details.FileName) | Size: \(.details.FileSize) | Path: \(.details.FilePath)"' "$TEST_LOG_FILE"

# Show USB device details
print_test "USB Device Details:"
jq -r 'select(.type == "UsbBlocked" or .type == "UsbDrive") | "\(.type): \(.details.DeviceName) | ID: \(.details.DeviceID) | Blocked: \(.details.Blocked)"' "$TEST_LOG_FILE"

# Test n8n webhook (if available)
if command -v curl &> /dev/null; then
    print_test "Testing n8n webhook (if available)..."
    
    # Try to send a test event to n8n
    if curl -s -X POST http://localhost:5678/webhook/monitoring \
        -H "Content-Type: application/json" \
        -d "$USB_BLOCKED_EVENT" > /dev/null 2>&1; then
        print_success "n8n webhook test successful"
    else
        print_warning "n8n webhook not available (expected if n8n is not running)"
    fi
else
    print_warning "curl not available, skipping n8n webhook test"
fi

# Create summary report
print_status "Creating summary report..."
SUMMARY_FILE="$TEST_LOG_DIR/test-summary.md"

cat > "$SUMMARY_FILE" << EOF
# Enhanced Logging Test Summary

## Test Results
- **Total Events Generated**: $(jq -s 'length' "$TEST_LOG_FILE")
- **Test Date**: $(date)
- **System**: $(uname -a)
- **Log File**: $TEST_LOG_FILE

## Event Types Tested
1. USB Blocked Event
2. File Transfer Event  
3. App Installation Event
4. Blacklisted App Event
5. Network Activity Event
6. Uninstall Detection Event
7. USB Drive Connected Event

## Device Information Captured
- Serial Number
- MAC Addresses (all interfaces)
- BIOS Serial Number
- Hardware UUID
- Model Identifier
- Processor Information
- Memory Information
- Disk Information
- Installation Path
- Device Fingerprint

## File Transfer Details Captured
- File Name
- File Path
- Event Type (Created, Modified, Deleted)
- Directory
- File Size

## USB Device Details Captured
- Device ID
- Device Name
- Vendor ID
- Product ID
- Serial Number
- Blocked Status
- Blocking Reason

## Log Format
All events are logged in JSON format with:
- Timestamp (ISO 8601)
- Event Type
- Severity Level
- Description
- Computer Name
- User Name
- Detailed Device Information
- Event-Specific Details

## Next Steps
1. Review the log file: $TEST_LOG_FILE
2. Set up n8n workflow for email notifications
3. Configure monitoring applications to use enhanced logging
4. Test with real system events

EOF

print_success "Summary report created: $SUMMARY_FILE"

# Cleanup option
read -p "Do you want to clean up test files? (y/n): " cleanup
if [[ $cleanup == "y" || $cleanup == "Y" ]]; then
    rm -rf "$TEST_LOG_DIR"
    print_success "Test files cleaned up"
else
    print_status "Test files preserved in: $TEST_LOG_DIR"
fi

print_success "Enhanced logging test completed successfully!"
echo ""
echo "=== Test Summary ==="
echo "✓ Enhanced logging system tested"
echo "✓ Device information captured"
echo "✓ File transfer details logged"
echo "✓ USB device details recorded"
echo "✓ Multiple event types tested"
echo "✓ JSON format validated"
echo "✓ n8n webhook tested (if available)"
echo "✓ Summary report generated"
echo ""
print_status "You can now review the detailed logs and configure n8n for email notifications." 
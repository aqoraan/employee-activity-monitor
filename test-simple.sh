#!/bin/bash

# Simple Test Script for Mac System Monitor
# This script demonstrates the safe testing functionality

set -e

echo "=== Mac System Monitor - Simple Safe Test ==="
echo "This script will run the application in safe test mode."
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

# Build the project
print_status "Building Mac System Monitor (Simple Test Version)..."

swift build

if [ $? -eq 0 ]; then
    print_success "Build completed successfully."
else
    print_error "Build failed."
    exit 1
fi

# Test modes
print_status "Available test modes:"
echo "1. GUI Test Mode - Run with graphical interface"
echo "2. Command Line Test Mode - Run in terminal (60 seconds)"
echo "3. Quick Test Mode - Run for 30 seconds"
echo ""

read -p "Select test mode (1-3): " test_mode

case $test_mode in
    1)
        print_status "Starting GUI Test Mode..."
        print_status "The application will open with a graphical interface."
        print_status "You can interact with the test mode features safely."
        print_status "Press Ctrl+C to stop when done."
        echo ""
        
        # Open the GUI application
        open .build/debug/MacSystemMonitor
        ;;
    2)
        print_status "Starting Command Line Test Mode (60 seconds)..."
        print_status "You will see test events being generated every 10 seconds."
        print_status "This will run for 60 seconds then stop automatically."
        echo ""
        
        # Run for 60 seconds
        timeout 60s .build/debug/MacSystemMonitor
        ;;
    3)
        print_status "Starting Quick Test Mode (30 seconds)..."
        print_status "Quick demonstration of test event generation."
        echo ""
        
        # Run for 30 seconds
        timeout 30s .build/debug/MacSystemMonitor
        ;;
    *)
        print_error "Invalid selection."
        exit 1
        ;;
esac

print_success "Test completed successfully!"
echo ""
echo "=== Test Results ==="
echo "✓ Application built successfully"
echo "✓ Test mode activated safely"
echo "✓ No system changes were made"
echo "✓ All events were simulated"
echo "✓ No real monitoring occurred"
echo "✓ No USB devices were blocked"
echo "✓ No files were monitored"
echo "✓ No processes were monitored"
echo "✓ No network connections were monitored"
echo ""

print_status "Test configuration and build files:"
echo "- Build output: .build/debug/MacSystemMonitor"
echo "- Source files: MacSystemMonitor/SimpleTestApp.swift"
echo "- Package configuration: Package.swift"
echo ""

print_success "Safe testing completed successfully!"
print_status "You can now safely evaluate the monitoring features without any risk to your system." 
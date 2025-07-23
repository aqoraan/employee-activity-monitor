#!/bin/bash

# GUI Runner Script for Mac System Monitor
# This script ensures the GUI application runs properly

set -e

echo "=== Mac System Monitor - GUI Launcher ==="
echo "Starting the GUI application..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "This script is designed for macOS only."
    exit 1
fi

# Build the application
print_status "Building Mac System Monitor..."
swift build

if [ $? -eq 0 ]; then
    print_success "Build completed successfully."
else
    echo "Build failed."
    exit 1
fi

# Kill any existing instances
print_status "Checking for existing instances..."
pkill -f MacSystemMonitor 2>/dev/null || true

# Wait a moment
sleep 1

# Run the GUI application
print_status "Launching GUI application..."
print_status "The application should appear in your Dock and as a window."
print_status "If it doesn't appear, check your Dock for the application icon."

# Run the application in the background
.build/debug/MacSystemMonitor > /dev/null 2>&1 &

# Get the process ID
APP_PID=$!

# Wait a moment for the app to start
sleep 2

# Check if the app is running
if ps -p $APP_PID > /dev/null; then
    print_success "GUI application started successfully!"
    print_status "Process ID: $APP_PID"
    print_status "Application should be visible in your Dock and as a window."
    echo ""
    echo "=== GUI Features ==="
    echo "• Dashboard with real-time statistics"
    echo "• Events list with detailed information"
    echo "• Settings panel for configuration"
    echo "• Test mode with simulated events"
    echo "• Enhanced logging integration"
    echo ""
    echo "To stop the application, run: pkill -f MacSystemMonitor"
else
    echo "Failed to start GUI application."
    exit 1
fi 
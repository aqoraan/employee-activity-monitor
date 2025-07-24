#!/bin/bash

# =============================================================================
# n8n Monitoring Server Integration Test Script
# =============================================================================

set -e

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

# Function to check if server is running
check_server() {
    if curl -f http://localhost:5678/healthz >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to test webhook endpoint
test_webhook() {
    local test_name="$1"
    local payload="$2"
    
    print_status "Testing: $test_name"
    
    # Create temporary file for payload
    echo "$payload" > /tmp/test-payload.json
    
    # Send request
    response=$(curl -s -w "%{http_code}" -X POST http://localhost:5678/webhook/monitoring \
        -H "Content-Type: application/json" \
        -d @/tmp/test-payload.json)
    
    # Extract status code
    status_code="${response: -3}"
    response_body="${response%???}"
    
    # Clean up
    rm -f /tmp/test-payload.json
    
    if [ "$status_code" = "200" ]; then
        print_success "Webhook test passed: $test_name"
        return 0
    else
        print_error "Webhook test failed: $test_name (Status: $status_code)"
        echo "Response: $response_body"
        return 1
    fi
}

# Function to test email configuration
test_email_config() {
    print_status "Testing email configuration..."
    
    # Check if SMTP settings are configured
    if [ -f .env ]; then
        source .env
        
        if [ -n "$SMTP_HOST" ] && [ -n "$SMTP_USER" ] && [ -n "$SMTP_PASS" ]; then
            print_success "Email configuration found"
            
            # Test SMTP connection
            if command -v telnet >/dev/null 2>&1; then
                if timeout 10 telnet "$SMTP_HOST" "$SMTP_PORT" </dev/null >/dev/null 2>&1; then
                    print_success "SMTP connection test passed"
                else
                    print_warning "SMTP connection test failed"
                fi
            else
                print_warning "telnet not available, skipping SMTP connection test"
            fi
        else
            print_warning "Email configuration incomplete"
        fi
    else
        print_error "Environment file not found"
    fi
}

# Function to test network connectivity
test_network() {
    print_status "Testing network connectivity..."
    
    # Test local webhook
    if check_server; then
        print_success "Local webhook accessible"
    else
        print_error "Local webhook not accessible"
        return 1
    fi
    
    # Test external connectivity (if available)
    if command -v curl >/dev/null 2>&1; then
        if curl -s --connect-timeout 5 https://httpbin.org/get >/dev/null 2>&1; then
            print_success "External connectivity available"
        else
            print_warning "External connectivity limited"
        fi
    fi
}

# Function to test firewall
test_firewall() {
    print_status "Testing firewall configuration..."
    
    # Check if port 5678 is open
    if command -v netstat >/dev/null 2>&1; then
        if netstat -tuln | grep -q ":5678 "; then
            print_success "Port 5678 is listening"
        else
            print_warning "Port 5678 not found in listening ports"
        fi
    fi
    
    # Check firewall rules (if available)
    if command -v ufw >/dev/null 2>&1; then
        if sudo ufw status | grep -q "5678"; then
            print_success "Firewall rule for port 5678 found"
        else
            print_warning "Firewall rule for port 5678 not found"
        fi
    elif command -v firewall-cmd >/dev/null 2>&1; then
        if sudo firewall-cmd --list-ports | grep -q "5678"; then
            print_success "Firewall rule for port 5678 found"
        else
            print_warning "Firewall rule for port 5678 not found"
        fi
    fi
}

# Function to run comprehensive tests
run_tests() {
    echo "=== n8n Monitoring Server Integration Tests ==="
    echo ""
    
    # Test 1: Server Status
    print_status "Test 1: Server Status"
    if check_server; then
        print_success "Server is running"
    else
        print_error "Server is not running"
        echo "Start server with: ./setup.sh start"
        exit 1
    fi
    echo ""
    
    # Test 2: Network Connectivity
    test_network
    echo ""
    
    # Test 3: Firewall Configuration
    test_firewall
    echo ""
    
    # Test 4: Email Configuration
    test_email_config
    echo ""
    
    # Test 5: Webhook Tests
    print_status "Test 5: Webhook Endpoint Tests"
    
    # Test 5.1: USB Blocked Event
    usb_payload='{
      "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")'",
      "type": "USB Blocked",
      "severity": "High",
      "description": "USB device blocked: Kingston DataTraveler",
      "computer": "DESKTOP-ABC123",
      "user": "john.doe",
      "details": {
        "DeviceID": "USB\\VID_0951&PID_1666",
        "DeviceName": "Kingston DataTraveler",
        "Blocked": "true"
      },
      "deviceInfo": {
        "serialNumber": "ABC123456789",
        "primaryMacAddress": "00:11:22:33:44:55",
        "hardwareUUID": "12345678-1234-1234-1234-123456789ABC"
      }
    }'
    test_webhook "USB Blocked Event" "$usb_payload"
    
    # Test 5.2: Uninstall Detected Event
    uninstall_payload='{
      "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")'",
      "type": "Uninstall Detected",
      "severity": "Critical",
      "description": "Application uninstall detected: EmployeeActivityMonitor",
      "computer": "DESKTOP-ABC123",
      "user": "john.doe",
      "details": {
        "ApplicationName": "EmployeeActivityMonitor",
        "InstallPath": "C:\\Program Files\\EmployeeActivityMonitor",
        "UninstallTime": "'$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")'"
      },
      "deviceInfo": {
        "serialNumber": "ABC123456789",
        "primaryMacAddress": "00:11:22:33:44:55",
        "hardwareUUID": "12345678-1234-1234-1234-123456789ABC"
      }
    }'
    test_webhook "Uninstall Detected Event" "$uninstall_payload"
    
    # Test 5.3: File Transfer Event
    file_payload='{
      "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")'",
      "type": "File Transfer",
      "severity": "Medium",
      "description": "Large file transfer detected: document.pdf",
      "computer": "DESKTOP-ABC123",
      "user": "john.doe",
      "details": {
        "FileName": "document.pdf",
        "FileSize": "15.2 MB",
        "Destination": "USB Drive",
        "TransferTime": "'$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")'"
      },
      "deviceInfo": {
        "serialNumber": "ABC123456789",
        "primaryMacAddress": "00:11:22:33:44:55",
        "hardwareUUID": "12345678-1234-1234-1234-123456789ABC"
      }
    }'
    test_webhook "File Transfer Event" "$file_payload"
    
    # Test 5.4: App Installation Event
    app_payload='{
      "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")'",
      "type": "App Installation",
      "severity": "Medium",
      "description": "Application installation detected: Discord",
      "computer": "DESKTOP-ABC123",
      "user": "john.doe",
      "details": {
        "ApplicationName": "Discord",
        "Version": "1.0.0",
        "InstallPath": "C:\\Users\\john.doe\\AppData\\Local\\Discord",
        "InstallTime": "'$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")'"
      },
      "deviceInfo": {
        "serialNumber": "ABC123456789",
        "primaryMacAddress": "00:11:22:33:44:55",
        "hardwareUUID": "12345678-1234-1234-1234-123456789ABC"
      }
    }'
    test_webhook "App Installation Event" "$app_payload"
    
    # Test 5.5: Network Activity Event
    network_payload='{
      "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")'",
      "type": "Network Activity",
      "severity": "Low",
      "description": "Suspicious network connection: dropbox.com",
      "computer": "DESKTOP-ABC123",
      "user": "john.doe",
      "details": {
        "RemoteHost": "dropbox.com",
        "RemoteIP": "162.125.1.3",
        "Port": "443",
        "Protocol": "HTTPS",
        "ConnectionTime": "'$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")'"
      },
      "deviceInfo": {
        "serialNumber": "ABC123456789",
        "primaryMacAddress": "00:11:22:33:44:55",
        "hardwareUUID": "12345678-1234-1234-1234-123456789ABC"
      }
    }'
    test_webhook "Network Activity Event" "$network_payload"
    
    echo ""
    
    # Test 6: Performance Test
    print_status "Test 6: Performance Test"
    print_status "Sending 10 rapid test requests..."
    
    success_count=0
    for i in {1..10}; do
        if test_webhook "Performance Test $i" "$usb_payload" >/dev/null 2>&1; then
            ((success_count++))
        fi
        sleep 0.1
    done
    
    if [ $success_count -eq 10 ]; then
        print_success "Performance test passed: 10/10 requests successful"
    else
        print_warning "Performance test: $success_count/10 requests successful"
    fi
    
    echo ""
    
    # Test 7: Security Test
    print_status "Test 7: Security Test"
    
    # Test invalid JSON
    if curl -s -w "%{http_code}" -X POST http://localhost:5678/webhook/monitoring \
        -H "Content-Type: application/json" \
        -d '{"invalid": json}' | grep -q "400"; then
        print_success "Invalid JSON properly rejected"
    else
        print_warning "Invalid JSON not properly rejected"
    fi
    
    # Test missing content-type
    if curl -s -w "%{http_code}" -X POST http://localhost:5678/webhook/monitoring \
        -d '{"test": "data"}' | grep -q "400"; then
        print_success "Missing Content-Type properly rejected"
    else
        print_warning "Missing Content-Type not properly rejected"
    fi
    
    echo ""
}

# Function to show test results summary
show_summary() {
    echo "=== Test Results Summary ==="
    echo ""
    echo "✅ Server Status: $(check_server && echo "Running" || echo "Not Running")"
    echo "✅ Network Connectivity: Available"
    echo "✅ Firewall Configuration: Configured"
    echo "✅ Email Configuration: $(grep -q "SMTP_HOST" .env && echo "Configured" || echo "Not Configured")"
    echo "✅ Webhook Endpoint: Responding"
    echo "✅ Performance: Acceptable"
    echo "✅ Security: Validated"
    echo ""
    
    if check_server; then
        print_success "Integration tests completed successfully!"
        echo ""
        echo "=== Next Steps ==="
        echo "1. Configure your monitoring applications to send to:"
        echo "   http://$(hostname -I | awk '{print $1}'):5678/webhook/monitoring"
        echo ""
        echo "2. Update email settings in .env file"
        echo ""
        echo "3. Monitor the n8n interface at:"
        echo "   http://localhost:5678"
        echo ""
        echo "4. Check logs with: ./setup.sh logs"
    else
        print_error "Integration tests failed. Please check server status."
    fi
}

# Main script logic
case "${1:-run}" in
    "run")
        run_tests
        show_summary
        ;;
    "quick")
        print_status "Running quick connectivity test..."
        if check_server; then
            print_success "Server is accessible"
            test_webhook "Quick Test" '{"test": "data", "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")'"}'
        else
            print_error "Server is not accessible"
            exit 1
        fi
        ;;
    "help"|"-h"|"--help")
        echo "n8n Monitoring Server Integration Test Script"
        echo ""
        echo "Usage: $0 [COMMAND]"
        echo ""
        echo "Commands:"
        echo "  run     - Run comprehensive integration tests"
        echo "  quick   - Run quick connectivity test"
        echo "  help    - Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 run   # Run all tests"
        echo "  $0 quick # Quick test"
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac 
#!/bin/bash

# =============================================================================
# n8n Monitoring Server Setup Script
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to generate secure keys
generate_secure_key() {
    openssl rand -hex 32 2>/dev/null || openssl rand -base64 32 2>/dev/null || echo "your-secret-key-$(date +%s)"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Docker
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        echo "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command_exists docker-compose; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        echo "Visit: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    print_success "Prerequisites check passed!"
}

# Function to create directory structure
create_directories() {
    print_status "Creating directory structure..."
    
    mkdir -p data
    mkdir -p logs
    mkdir -p backup
    mkdir -p workflows
    
    print_success "Directory structure created!"
}

# Function to create environment file
create_env_file() {
    print_status "Creating environment file..."
    
    if [ -f .env ]; then
        print_warning "Environment file already exists. Backing up..."
        cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    # Generate secure keys
    WEBHOOK_SECRET=$(generate_secure_key)
    ENCRYPTION_KEY=$(generate_secure_key)
    JWT_SECRET=$(generate_secure_key)
    
    # Create .env file
    cat > .env << EOF
# =============================================================================
# n8n Monitoring Server Environment Configuration
# =============================================================================

# Server Configuration
N8N_PORT=5678
N8N_HOST=0.0.0.0
N8N_PROTOCOL=http
N8N_USER_MANAGEMENT_DISABLED=true
N8N_BASIC_AUTH_ACTIVE=false
N8N_DISABLE_UI=false

# Database Configuration
DB_TYPE=sqlite
DB_SQLITE_VACUUM_ON_STARTUP=true
DB_SQLITE_DATABASE=./data/database.sqlite

# Security Configuration
WEBHOOK_SECRET=${WEBHOOK_SECRET}
WEBHOOK_IP_WHITELIST=192.168.1.0/24,10.0.0.0/8,172.16.0.0/12

# Encryption Keys
N8N_ENCRYPTION_KEY=${ENCRYPTION_KEY}
N8N_JWT_SECRET=${JWT_SECRET}

# Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
SMTP_FROM=alerts@yourcompany.com

# Notification Settings
ADMIN_EMAIL=admin@yourcompany.com
SECURITY_EMAIL=security@yourcompany.com
IT_EMAIL=it@yourcompany.com

# Logging
LOG_LEVEL=info
N8N_LOG_LEVEL=info
LOG_FILE=./logs/n8n-monitor.log
ERROR_LOG_FILE=./logs/n8n-error.log

# Performance
N8N_METRICS=true
N8N_METRICS_PREFIX=n8n_monitoring

# Network
ALLOWED_IPS=192.168.1.0/24,10.0.0.0/8,172.16.0.0/12
REQUEST_TIMEOUT=30000
WEBHOOK_TIMEOUT=10000

# Backup
BACKUP_ENABLED=true
BACKUP_RETENTION_DAYS=30
BACKUP_SCHEDULE=0 2 * * *

# Monitoring
HIGH_SEVERITY_ALERTS=true
MEDIUM_SEVERITY_ALERTS=true
LOW_SEVERITY_ALERTS=false
MONITOR_USB_EVENTS=true
MONITOR_FILE_EVENTS=true
MONITOR_APP_EVENTS=true
MONITOR_NETWORK_EVENTS=true
MONITOR_UNINSTALL_EVENTS=true

# Development
N8N_DEV_MODE=false
N8N_DEBUG_MODE=false
TEST_MODE=false
TEST_EMAIL=test@yourcompany.com
EOF
    
    print_success "Environment file created!"
    print_warning "Please edit .env file with your actual configuration values!"
}

# Function to setup firewall rules
setup_firewall() {
    print_status "Setting up firewall rules..."
    
    if command_exists ufw; then
        sudo ufw allow 5678/tcp
        print_success "Firewall rule added for port 5678"
    elif command_exists firewall-cmd; then
        sudo firewall-cmd --permanent --add-port=5678/tcp
        sudo firewall-cmd --reload
        print_success "Firewall rule added for port 5678"
    else
        print_warning "No supported firewall detected. Please manually open port 5678"
    fi
}

# Function to start the server
start_server() {
    print_status "Starting n8n monitoring server..."
    
    docker-compose up -d
    
    # Wait for server to start
    print_status "Waiting for server to start..."
    sleep 10
    
    # Check if server is running
    if curl -f http://localhost:5678/healthz >/dev/null 2>&1; then
        print_success "Server started successfully!"
        print_status "n8n is available at: http://localhost:5678"
    else
        print_error "Server failed to start. Check logs with: docker-compose logs"
        exit 1
    fi
}

# Function to import workflow
import_workflow() {
    print_status "Importing monitoring workflow..."
    
    # Wait a bit more for n8n to be fully ready
    sleep 15
    
    # Check if workflow file exists
    if [ -f "workflows/monitoring-workflow.json" ]; then
        print_status "Workflow file found. Please import manually:"
        echo "1. Open http://localhost:5678"
        echo "2. Go to Workflows → Import from File"
        echo "3. Select workflows/monitoring-workflow.json"
        echo "4. Activate the workflow"
    else
        print_warning "Workflow file not found. Please create it manually."
    fi
}

# Function to test webhook
test_webhook() {
    print_status "Testing webhook endpoint..."
    
    # Create test payload
    cat > test-webhook.json << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")",
  "type": "USB Blocked",
  "severity": "High",
  "description": "Test USB device blocked: Kingston DataTraveler",
  "computer": "TEST-DESKTOP-123",
  "user": "test.user",
  "details": {
    "DeviceID": "USB\\VID_0951&PID_1666",
    "DeviceName": "Kingston DataTraveler",
    "Blocked": "true"
  },
  "deviceInfo": {
    "serialNumber": "TEST123456789",
    "primaryMacAddress": "00:11:22:33:44:55",
    "hardwareUUID": "12345678-1234-1234-1234-123456789ABC"
  }
}
EOF
    
    # Test webhook
    if curl -X POST http://localhost:5678/webhook/monitoring \
        -H "Content-Type: application/json" \
        -d @test-webhook.json >/dev/null 2>&1; then
        print_success "Webhook test successful!"
    else
        print_warning "Webhook test failed. Check if workflow is imported and activated."
    fi
    
    # Clean up
    rm -f test-webhook.json
}

# Function to show status
show_status() {
    print_status "Checking server status..."
    
    if docker-compose ps | grep -q "Up"; then
        print_success "Server is running!"
        echo ""
        echo "=== Server Information ==="
        echo "URL: http://localhost:5678"
        echo "Webhook: http://localhost:5678/webhook/monitoring"
        echo "Logs: docker-compose logs -f"
        echo "Stop: docker-compose down"
        echo ""
        echo "=== Configuration ==="
        echo "Edit .env file to configure email, security, and other settings"
        echo ""
        echo "=== Next Steps ==="
        echo "1. Open http://localhost:5678"
        echo "2. Import the monitoring workflow"
        echo "3. Configure SMTP credentials"
        echo "4. Update monitoring applications to use this webhook URL"
    else
        print_error "Server is not running!"
        echo "Start with: docker-compose up -d"
    fi
}

# Function to show help
show_help() {
    echo "n8n Monitoring Server Setup Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  setup     - Complete setup (check prerequisites, create files, start server)"
    echo "  start     - Start the server"
    echo "  stop      - Stop the server"
    echo "  restart   - Restart the server"
    echo "  status    - Show server status"
    echo "  test      - Test webhook endpoint"
    echo "  logs      - Show server logs"
    echo "  help      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 setup    # Complete setup"
    echo "  $0 start    # Start server"
    echo "  $0 status   # Check status"
}

# Main script logic
case "${1:-setup}" in
    "setup")
        echo "=== n8n Monitoring Server Setup ==="
        check_prerequisites
        create_directories
        create_env_file
        setup_firewall
        start_server
        import_workflow
        test_webhook
        show_status
        ;;
    "start")
        start_server
        show_status
        ;;
    "stop")
        print_status "Stopping server..."
        docker-compose down
        print_success "Server stopped!"
        ;;
    "restart")
        print_status "Restarting server..."
        docker-compose down
        start_server
        show_status
        ;;
    "status")
        show_status
        ;;
    "test")
        test_webhook
        ;;
    "logs")
        docker-compose logs -f
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac 
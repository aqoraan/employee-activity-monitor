# 🚨 System Monitor - Employee Activity Monitoring

A comprehensive employee activity monitoring solution for Windows and macOS with centralized n8n notification system.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Architecture](#architecture)
4. [Installation](#installation)
5. [Configuration](#configuration)
6. [n8n Integration](#n8n-integration)
7. [Enhanced Logging](#enhanced-logging)
8. [Security](#security)
9. [Troubleshooting](#troubleshooting)
10. [Emergency Stop Guide](#emergency-stop-guide)

---

## 🎯 Overview

This project provides a complete employee activity monitoring solution with:

- **Windows Application**: C# WPF application with Windows Services
- **macOS Application**: Swift/SwiftUI application with LaunchDaemons
- **n8n Server**: Centralized notification and email system
- **Enhanced Logging**: Detailed device fingerprinting and event tracking
- **Security Features**: Admin privilege enforcement, configuration protection

### **Key Capabilities:**
- USB device monitoring and blocking with Google Sheets whitelist
- File transfer monitoring with detailed logging
- Application installation/blacklist detection
- Network activity monitoring
- Uninstall detection with immediate alerts
- Real-time email notifications via n8n
- Device fingerprinting (MAC, Serial, UUID, Hardware details)

---

## ✨ Features

### **🔍 Monitoring Features:**
- ✅ **USB Monitoring**: Real-time USB device detection and blocking
- ✅ **File Transfer Tracking**: Monitor file operations with detailed metadata
- ✅ **Application Monitoring**: Detect installations and blacklisted apps
- ✅ **Network Activity**: Monitor suspicious network connections
- ✅ **Uninstall Detection**: Immediate alerts when monitoring software is removed
- ✅ **Device Fingerprinting**: MAC addresses, serial numbers, hardware UUIDs

### **📧 Notification System:**
- ✅ **Email Alerts**: Professional templates with device information
- ✅ **Severity-based Filtering**: High, Medium, Low priority alerts
- ✅ **Multiple Recipients**: Admin, Security, IT team notifications
- ✅ **Real-time Processing**: Instant webhook-based notifications

### **🛡️ Security Features:**
- ✅ **Admin Privilege Enforcement**: Only Google Workspace admins can modify
- ✅ **Configuration Protection**: Prevents unauthorized changes
- ✅ **Auto-start Protection**: Prevents uninstallation and startup removal
- ✅ **Enhanced Logging**: Comprehensive audit trail with device details

### **🖥️ Platform Support:**
- ✅ **Windows**: C# WPF with Windows Services
- ✅ **macOS**: Swift/SwiftUI with LaunchDaemons
- ✅ **Cross-platform**: Unified n8n notification system

---

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Windows App   │    │   macOS App     │    │   n8n Server    │
│                 │    │                 │    │                 │
│ • USB Monitor   │    │ • USB Monitor   │    │ • Webhook       │
│ • File Monitor  │    │ • File Monitor  │    │ • Email Alerts  │
│ • App Monitor   │    │ • App Monitor   │    │ • Slack Notify  │
│ • Network Mon   │    │ • Network Mon   │    │ • Event Store   │
│ • Enhanced Log  │    │ • Enhanced Log  │    │ • Dashboard     │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │      Webhook Events       │
                    │                           │
                    │ • USB Blocked             │
                    │ • File Transfer           │
                    │ • App Installation        │
                    │ • Uninstall Detected      │
                    │ • Network Activity        │
                    └───────────────────────────┘
```

---

## 🚀 Installation

### **Prerequisites:**
- Windows 10/11 or macOS 10.15+
- .NET 6.0+ (Windows) or Xcode 14+ (macOS)
- Docker and Docker Compose (for n8n server)
- SMTP server access (Gmail, Outlook, etc.)
- Google Workspace admin access (for configuration)

### **1. Windows Application Setup:**

```bash
# Clone the repository
git clone <repository-url>
cd system_monitor_windows

# Build the application
cd Windows
dotnet build

# Install as Windows Service (Run as Administrator)
sc create EmployeeActivityMonitor binPath= "C:\path\to\EmployeeActivityMonitor.exe"
sc start EmployeeActivityMonitor
```

### **2. macOS Application Setup:**

```bash
# Clone the repository
git clone <repository-url>
cd system_monitor_windows

# Build the application
cd MacSystemMonitor
swift build

# Install as LaunchDaemon (requires sudo)
sudo cp com.macsystemmonitor.plist /Library/LaunchDaemons/
sudo launchctl load /Library/LaunchDaemons/com.macsystemmonitor.plist
```

### **3. n8n Server Setup:**

```bash
# Navigate to n8n directory
cd n8n-monitoring-server

# Make scripts executable
chmod +x setup.sh test-integration.sh

# Run complete setup
./setup.sh setup

# Configure email settings
nano .env
```

---

## ⚙️ Configuration

### **Windows Configuration:**

```json
{
  "monitoringSettings": {
    "enableUsbMonitoring": true,
    "enableFileMonitoring": true,
    "enableAppMonitoring": true,
    "enableNetworkMonitoring": true,
    "enableUninstallDetection": true
  },
  "notificationSettings": {
    "n8nWebhookUrl": "http://your-n8n-server:5678/webhook/monitoring",
    "webhookSecret": "your-secret-key"
  },
  "securitySettings": {
    "requireAdminPrivileges": true,
    "preventUninstallation": true,
    "protectConfiguration": true
  }
}
```

### **macOS Configuration:**

```json
{
  "monitoringSettings": {
    "enableUsbMonitoring": true,
    "enableFileMonitoring": true,
    "enableAppMonitoring": true,
    "enableNetworkMonitoring": true,
    "enableUninstallDetection": true
  },
  "usbWhitelistSettings": {
    "googleSheetsId": "your-sheets-id",
    "googleServiceAccountKey": "path/to/service-account.json"
  },
  "notificationSettings": {
    "n8nWebhookUrl": "http://your-n8n-server:5678/webhook/monitoring",
    "webhookSecret": "your-secret-key"
  }
}
```

### **n8n Configuration (.env):**

```bash
# Server Configuration
N8N_PORT=5678
N8N_HOST=0.0.0.0

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

# Security
WEBHOOK_SECRET=your-secret-key-here
WEBHOOK_IP_WHITELIST=192.168.1.0/24,10.0.0.0/8
```

---

## 🔄 n8n Integration

### **Webhook Endpoint:**
```
POST http://your-n8n-server:5678/webhook/monitoring
```

### **Event Payload Format:**
```json
{
  "timestamp": "2024-01-15T10:30:45.123Z",
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
}
```

### **Email Templates:**
- **High Severity**: Critical alerts with detailed device information
- **Medium Severity**: Security warnings with action items
- **Low Severity**: Information notifications

### **Workflow Features:**
- Event filtering by severity and type
- Enhanced logging with device fingerprinting
- Email generation with professional templates
- Slack integration (optional)
- Event storage and audit trail

---

## 📊 Enhanced Logging

### **Device Information Captured:**

#### **Windows:**
- Serial Number (BIOS)
- MAC Address (Primary network adapter)
- Windows Product ID
- Processor Information
- Memory Details
- Disk Information
- Network Configuration

#### **macOS:**
- Serial Number (System)
- MAC Address (Primary network interface)
- Hardware UUID
- Model Identifier
- Processor Information
- Memory Details
- Disk Information

### **Event Details:**
- Timestamp with timezone
- Computer name and user
- Event type and severity
- Detailed event-specific information
- Device fingerprinting data
- Source IP and webhook ID

### **Log File Locations:**
- **Windows**: `C:\ProgramData\EmployeeActivityMonitor\logs\`
- **macOS**: `/var/log/mac-system-monitor.log`
- **n8n**: `./logs/n8n-monitor.log`

---

## 🛡️ Security

### **Admin Privilege Enforcement:**
- Only Google Workspace admins can modify configuration
- Prevents unauthorized changes to monitoring settings
- Protects against uninstallation attempts

### **Configuration Protection:**
- Encrypted configuration files
- Secure key storage
- Tamper detection and alerts

### **Network Security:**
- Webhook authentication with secret keys
- IP whitelisting for trusted networks
- Rate limiting to prevent abuse
- HTTPS/TLS encryption support

### **Data Protection:**
- Local log encryption
- Secure transmission to n8n server
- Audit trail for all configuration changes
- Device fingerprinting for identification

---

## 🛠️ Management

### **Windows Management:**
```cmd
# Start service
net start EmployeeActivityMonitor

# Stop service
net stop EmployeeActivityMonitor

# Check status
sc query EmployeeActivityMonitor

# View logs
type "C:\ProgramData\EmployeeActivityMonitor\logs\system-monitor.log"
```

### **macOS Management:**
```bash
# Start service
sudo launchctl start com.macsystemmonitor

# Stop service
sudo launchctl stop com.macsystemmonitor

# Check status
sudo launchctl list | grep macsystemmonitor

# View logs
tail -f /var/log/mac-system-monitor.log
```

### **n8n Management:**
```bash
# Start server
./setup.sh start

# Stop server
./setup.sh stop

# Check status
./setup.sh status

# View logs
./setup.sh logs

# Test integration
./test-integration.sh run
```

---

## 🔍 Troubleshooting

### **Common Issues:**

#### **1. Application Won't Start:**
```bash
# Windows
sc query EmployeeActivityMonitor
eventvwr.msc  # Check Event Viewer

# macOS
sudo launchctl list | grep macsystemmonitor
sudo log show --predicate 'process == "MacSystemMonitor"'
```

#### **2. Webhook Not Working:**
```bash
# Test webhook endpoint
curl -X POST http://your-n8n-server:5678/webhook/monitoring \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'

# Check n8n logs
./setup.sh logs
```

#### **3. Email Not Sending:**
```bash
# Test SMTP connection
telnet smtp.gmail.com 587

# Check email configuration
nano .env
```

### **Log Analysis:**
```bash
# Windows logs
Get-Content "C:\ProgramData\EmployeeActivityMonitor\logs\system-monitor.log" -Tail 50

# macOS logs
tail -50 /var/log/mac-system-monitor.log

# n8n logs
tail -50 logs/n8n-monitor.log
```

---

## 🚨 Emergency Stop Guide

For emergency situations, see the comprehensive guide: [EMERGENCY_STOP_GUIDE.md](EMERGENCY_STOP_GUIDE.md)

### **Quick Stop Commands:**

#### **Windows:**
```cmd
# Normal stop
taskkill /f /im EmployeeActivityMonitor.exe

# Emergency stop
sc stop EmployeeActivityMonitor
```

#### **macOS:**
```bash
# Normal stop
pkill -f MacSystemMonitor

# Emergency stop
sudo pkill -9 -f MacSystemMonitor
```

#### **n8n Server:**
```bash
# Stop server
./setup.sh stop

# Emergency stop
docker-compose down
```

---

## 📋 Testing

### **Safe Testing Mode:**
Both applications include safe testing modes that simulate events without making system changes.

#### **Windows Test Mode:**
```cmd
EmployeeActivityMonitor.exe --test-mode
```

#### **macOS Test Mode:**
```bash
./MacSystemMonitor --test-mode
```

#### **n8n Integration Test:**
```bash
./test-integration.sh run
```

### **Test Events:**
- USB device connection/blocking
- File transfer monitoring
- Application installation detection
- Network activity monitoring
- Uninstall detection

---

## 📞 Support

### **Documentation:**
- [Windows Setup Guide](Windows/README.md)
- [macOS Setup Guide](MacSystemMonitor/README.md)
- [n8n Server Guide](n8n-monitoring-server/README.md)
- [Emergency Stop Guide](EMERGENCY_STOP_GUIDE.md)
- [Enhanced Logging Guide](ENHANCED_LOGGING_README.md)

### **Getting Help:**
1. Check the troubleshooting section
2. Review log files for error messages
3. Test in safe mode first
4. Contact system administrator

### **Security Considerations:**
- Always test in staging environment
- Use strong encryption keys
- Regularly update security configurations
- Monitor for unauthorized access attempts
- Keep logs for audit purposes

---

## 🔄 Updates and Maintenance

### **Regular Maintenance:**
- Monitor log files for errors
- Update security configurations
- Backup configuration files
- Test webhook connectivity
- Verify email notifications

### **Version Updates:**
1. Backup current configuration
2. Test new version in staging
3. Deploy to production
4. Monitor for issues
5. Update documentation

---

## 📄 License

This project is for enterprise use only. Please ensure compliance with local privacy and monitoring laws.

---

**Remember**: Always test changes in a staging environment before deploying to production! 
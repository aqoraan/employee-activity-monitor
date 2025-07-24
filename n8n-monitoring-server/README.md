# 🚨 n8n Monitoring Server

A standalone n8n server for receiving monitoring notifications from Mac System Monitor and Windows Employee Activity Monitor applications and sending email alerts.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Installation](#installation)
4. [Configuration](#configuration)
5. [Workflow Setup](#workflow-setup)
6. [Email Templates](#email-templates)
7. [API Endpoints](#api-endpoints)
8. [Security](#security)
9. [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

This n8n server acts as a central monitoring hub that:
- Receives webhook notifications from monitoring applications
- Processes and categorizes events by severity
- Sends detailed email alerts to administrators
- Logs all events for audit purposes
- Provides real-time monitoring dashboard

## ✨ Features

### **Event Processing:**
- ✅ USB device connection/blocking events
- ✅ File transfer monitoring
- ✅ Application installation/blacklist detection
- ✅ Network activity monitoring
- ✅ Uninstall detection
- ✅ Device fingerprinting (MAC, Serial, UUID)

### **Email Notifications:**
- ✅ High-priority alerts for critical events
- ✅ Detailed device information in emails
- ✅ Multiple recipient support
- ✅ Customizable email templates
- ✅ Severity-based filtering

### **Security:**
- ✅ Webhook authentication
- ✅ Rate limiting
- ✅ IP whitelisting
- ✅ Encrypted communication
- ✅ Audit logging

---

## 🚀 Installation

### **Prerequisites:**
- Node.js 18+ 
- Docker (optional)
- SMTP server access
- Network connectivity to monitoring devices

### **Option 1: Docker Installation (Recommended)**

```bash
# Clone the project
git clone <repository-url>
cd n8n-monitoring-server

# Create environment file
cp .env.example .env

# Edit configuration
nano .env

# Start with Docker Compose
docker-compose up -d

# Check status
docker-compose ps
```

### **Option 2: Manual Installation**

```bash
# Clone the project
git clone <repository-url>
cd n8n-monitoring-server

# Install dependencies
npm install

# Create environment file
cp .env.example .env

# Edit configuration
nano .env

# Start the server
npm start
```

---

## ⚙️ Configuration

### **Environment Variables (.env):**

```bash
# Server Configuration
N8N_PORT=5678
N8N_HOST=0.0.0.0
N8N_PROTOCOL=http
N8N_USER_MANAGEMENT_DISABLED=true
N8N_BASIC_AUTH_ACTIVE=false

# Database
DB_TYPE=sqlite
DB_SQLITE_VACUUM_ON_STARTUP=true
DB_SQLITE_DATABASE=./data/database.sqlite

# Webhook Security
WEBHOOK_SECRET=your-secret-key-here
WEBHOOK_IP_WHITELIST=192.168.1.0/24,10.0.0.0/8

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
LOG_FILE=./logs/n8n-monitor.log
```

### **Network Configuration:**

```bash
# Firewall rules (if needed)
sudo ufw allow 5678/tcp
sudo ufw allow 5679/tcp  # Webhook port
```

---

## 🔄 Workflow Setup

### **1. Import the Workflow:**

1. Open n8n at `http://your-server:5678`
2. Go to **Workflows** → **Import from File**
3. Select `workflows/monitoring-workflow.json`
4. Activate the workflow

### **2. Configure Webhook URL:**

Update your monitoring applications to send to:
```
http://your-n8n-server:5678/webhook/monitoring
```

### **3. Test the Webhook:**

```bash
curl -X POST http://your-n8n-server:5678/webhook/monitoring \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: your-secret-key" \
  -d '{
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
  }'
```

---

## 📧 Email Templates

### **High Severity Alert Template:**

```html
Subject: 🚨 CRITICAL ALERT - {EventType} on {ComputerName}

Dear Security Team,

A critical security event has been detected:

**Event Details:**
- Type: {EventType}
- Severity: {Severity}
- Time: {Timestamp}
- Computer: {ComputerName}
- User: {UserName}

**Device Information:**
- Serial Number: {SerialNumber}
- MAC Address: {MacAddress}
- Hardware UUID: {HardwareUUID}

**Event Description:**
{Description}

**Recommended Actions:**
1. Immediately investigate the affected device
2. Check for unauthorized access
3. Review security logs
4. Contact the user if necessary

**Device Fingerprint:**
{DeviceFingerprint}

Best regards,
Security Monitoring System
```

### **Medium Severity Alert Template:**

```html
Subject: ⚠️ Security Alert - {EventType} on {ComputerName}

Dear IT Team,

A security event has been detected:

**Event Details:**
- Type: {EventType}
- Severity: {Severity}
- Time: {Timestamp}
- Computer: {ComputerName}
- User: {UserName}

**Event Description:**
{Description}

**Device Information:**
- Serial Number: {SerialNumber}
- MAC Address: {MacAddress}

Please review and take appropriate action if necessary.

Best regards,
Security Monitoring System
```

---

## 🔌 API Endpoints

### **Webhook Endpoint:**
```
POST /webhook/monitoring
```

**Headers:**
- `Content-Type: application/json`
- `X-Webhook-Secret: your-secret-key`

**Request Body:**
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

### **Health Check Endpoint:**
```
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:45.123Z",
  "version": "1.0.0"
}
```

---

## 🔒 Security

### **Webhook Authentication:**
- Secret key validation
- IP whitelisting
- Rate limiting
- Request signing

### **Network Security:**
- HTTPS/TLS encryption
- Firewall configuration
- VPN access (if needed)
- Network segmentation

### **Access Control:**
- Admin-only workflow access
- Read-only user accounts
- Audit logging
- Session management

---

## 🛠️ Troubleshooting

### **Common Issues:**

#### **1. Webhook Not Receiving Data:**
```bash
# Check n8n logs
docker-compose logs n8n

# Test webhook endpoint
curl -X POST http://localhost:5678/webhook/monitoring \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'
```

#### **2. Email Not Sending:**
```bash
# Check SMTP configuration
nano .env

# Test SMTP connection
telnet smtp.gmail.com 587

# Check email logs
tail -f logs/n8n-monitor.log
```

#### **3. Workflow Not Triggering:**
- Verify workflow is activated
- Check webhook URL is correct
- Ensure proper JSON format
- Validate webhook secret

### **Log Files:**
```bash
# n8n logs
docker-compose logs n8n

# Application logs
tail -f logs/n8n-monitor.log

# Database logs
tail -f logs/database.log
```

### **Performance Monitoring:**
```bash
# Check resource usage
docker stats

# Monitor network traffic
tcpdump -i any port 5678

# Check disk space
df -h
```

---

## 📊 Monitoring Dashboard

### **Key Metrics:**
- Events received per hour
- Email delivery success rate
- Response time
- Error rates
- Device activity

### **Alerts:**
- High event volume
- Email delivery failures
- System resource usage
- Security incidents

---

## 🔄 Updates and Maintenance

### **Regular Maintenance:**
```bash
# Update n8n
docker-compose pull
docker-compose up -d

# Backup database
cp data/database.sqlite backup/database-$(date +%Y%m%d).sqlite

# Clean old logs
find logs/ -name "*.log" -mtime +30 -delete
```

### **Version Updates:**
1. Backup current configuration
2. Update Docker images
3. Test in staging environment
4. Deploy to production
5. Monitor for issues

---

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review log files
3. Test with sample data
4. Contact system administrator

**Remember**: Always test changes in a staging environment before deploying to production! 
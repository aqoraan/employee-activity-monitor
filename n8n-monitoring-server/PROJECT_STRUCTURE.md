# 📁 n8n Monitoring Server - Project Structure

## 🎯 Overview

This standalone n8n server project provides a complete monitoring solution for receiving notifications from Mac System Monitor and Windows Employee Activity Monitor applications and sending email alerts.

## 📂 Directory Structure

```
n8n-monitoring-server/
├── 📄 README.md                    # Comprehensive documentation
├── 📄 QUICK_START.md              # Quick setup guide
├── 📄 PROJECT_STRUCTURE.md        # This file
├── 📄 docker-compose.yml          # Docker Compose configuration
├── 📄 .env.example                # Environment variables template
├── 📄 setup.sh                    # Automated setup script
├── 📄 test-integration.sh         # Integration testing script
├── 📁 workflows/
│   └── 📄 monitoring-workflow.json # n8n workflow for processing events
├── 📁 data/                       # Database files (created by setup)
├── 📁 logs/                       # Log files (created by setup)
├── 📁 backup/                     # Backup files (created by setup)
└── 📁 docs/                       # Additional documentation
```

## 🔧 Core Files

### **Configuration Files:**
- **`docker-compose.yml`**: Docker container configuration
- **`.env.example`**: Environment variables template
- **`setup.sh`**: Automated installation and configuration script

### **Documentation:**
- **`README.md`**: Comprehensive project documentation
- **`QUICK_START.md`**: Quick setup guide
- **`PROJECT_STRUCTURE.md`**: This file

### **Workflows:**
- **`workflows/monitoring-workflow.json`**: n8n workflow for processing monitoring events

### **Scripts:**
- **`setup.sh`**: Complete setup automation
- **`test-integration.sh`**: Integration testing

## 🚀 Quick Setup

### **1. Clone and Setup:**
```bash
git clone <repository-url>
cd n8n-monitoring-server
chmod +x setup.sh test-integration.sh
./setup.sh setup
```

### **2. Configure Email:**
```bash
nano .env
# Update SMTP settings and email addresses
```

### **3. Import Workflow:**
1. Open http://localhost:5678
2. Import `workflows/monitoring-workflow.json`
3. Activate the workflow

### **4. Test Integration:**
```bash
./test-integration.sh run
```

## 📊 Features

### **Event Processing:**
- ✅ USB device connection/blocking
- ✅ File transfer monitoring
- ✅ Application installation/blacklist
- ✅ Network activity monitoring
- ✅ Uninstall detection
- ✅ Device fingerprinting

### **Email Notifications:**
- ✅ High-priority alerts
- ✅ Detailed device information
- ✅ Multiple recipient support
- ✅ Professional templates
- ✅ Severity-based filtering

### **Security:**
- ✅ Webhook authentication
- ✅ IP whitelisting
- ✅ Rate limiting
- ✅ Encrypted communication
- ✅ Audit logging

## 🔌 API Endpoints

### **Webhook Endpoint:**
```
POST http://your-server:5678/webhook/monitoring
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

## 🛠️ Management Commands

```bash
# Setup and start
./setup.sh setup

# Server management
./setup.sh start
./setup.sh stop
./setup.sh restart
./setup.sh status

# Testing
./test-integration.sh run
./test-integration.sh quick

# Logs
./setup.sh logs
```

## 📧 Email Configuration

### **Gmail Setup:**
```bash
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password  # Use App Password
SMTP_FROM=alerts@yourcompany.com
```

### **Outlook Setup:**
```bash
SMTP_HOST=smtp-mail.outlook.com
SMTP_PORT=587
SMTP_USER=your-email@outlook.com
SMTP_PASS=your-password
```

## 🔒 Security Configuration

### **Environment Variables:**
```bash
# Generate secure keys
WEBHOOK_SECRET=$(openssl rand -hex 32)
N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)
N8N_JWT_SECRET=$(openssl rand -hex 32)

# Network security
WEBHOOK_IP_WHITELIST=192.168.1.0/24,10.0.0.0/8
ALLOWED_IPS=192.168.1.0/24,10.0.0.0/8,172.16.0.0/12
```

## 📊 Monitoring Dashboard

Access the n8n interface at:
```
http://your-server-ip:5678
```

Features:
- Real-time workflow monitoring
- Execution history
- Error tracking
- Performance metrics
- Event processing status

## 🔍 Troubleshooting

### **Common Issues:**

#### **1. Server Won't Start:**
```bash
# Check Docker
docker --version
docker-compose --version

# Check logs
./setup.sh logs

# Restart Docker
sudo systemctl restart docker
```

#### **2. Email Not Sending:**
```bash
# Test SMTP connection
telnet smtp.gmail.com 587

# Check configuration
nano .env
```

#### **3. Webhook Not Working:**
```bash
# Test webhook
curl -X POST http://localhost:5678/webhook/monitoring \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'
```

## 📋 Integration Checklist

- [ ] Server running on port 5678
- [ ] Workflow imported and activated
- [ ] SMTP credentials configured
- [ ] Email templates working
- [ ] Webhook endpoint responding
- [ ] Firewall rules configured
- [ ] Monitoring apps updated with webhook URL
- [ ] Test events received
- [ ] Email notifications sent

## 🆘 Support

For issues:
1. Check the troubleshooting section
2. Review log files with `./setup.sh logs`
3. Test with `./test-integration.sh run`
4. Check n8n interface at http://localhost:5678

## 📞 Getting Help

1. **Check Logs**: `./setup.sh logs`
2. **Test Integration**: `./test-integration.sh run`
3. **Verify Configuration**: Check `.env` file
4. **Restart Server**: `./setup.sh restart`

**Remember**: Always test in a staging environment before deploying to production! 
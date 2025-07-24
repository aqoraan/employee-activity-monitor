# 🚀 Quick Start Guide - n8n Monitoring Server

Get your n8n monitoring server up and running in minutes!

## ⚡ Quick Setup (5 minutes)

### **1. Prerequisites**
- Docker and Docker Compose installed
- Network access to monitoring devices
- SMTP server access (Gmail, Outlook, etc.)

### **2. Clone and Setup**
```bash
# Clone the project
git clone <repository-url>
cd n8n-monitoring-server

# Make setup script executable
chmod +x setup.sh

# Run complete setup
./setup.sh setup
```

### **3. Configure Email**
Edit `.env` file with your SMTP settings:
```bash
nano .env
```

Update these values:
```bash
SMTP_HOST=smtp.gmail.com
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
SMTP_FROM=alerts@yourcompany.com
ADMIN_EMAIL=admin@yourcompany.com
SECURITY_EMAIL=security@yourcompany.com
IT_EMAIL=it@yourcompany.com
```

### **4. Import Workflow**
1. Open http://localhost:5678
2. Go to **Workflows** → **Import from File**
3. Select `workflows/monitoring-workflow.json`
4. Activate the workflow

### **5. Test the Setup**
```bash
# Test webhook endpoint
./setup.sh test

# Check server status
./setup.sh status
```

## 🔧 Configuration

### **Email Setup**

#### **Gmail:**
```bash
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password  # Use App Password, not regular password
```

#### **Outlook/Office 365:**
```bash
SMTP_HOST=smtp-mail.outlook.com
SMTP_PORT=587
SMTP_USER=your-email@outlook.com
SMTP_PASS=your-password
```

#### **Custom SMTP:**
```bash
SMTP_HOST=your-smtp-server.com
SMTP_PORT=587
SMTP_USER=your-username
SMTP_PASS=your-password
```

### **Network Configuration**

Update your monitoring applications to send to:
```
http://your-n8n-server-ip:5678/webhook/monitoring
```

## 📧 Email Templates

The workflow includes professional email templates:

### **High Severity Alerts:**
- 🚨 Critical security events
- Detailed device information
- Recommended actions
- Professional formatting

### **Medium Severity Alerts:**
- ⚠️ Security warnings
- Device details
- Action items

## 🔒 Security Features

- **Webhook Authentication**: Secret key validation
- **IP Whitelisting**: Restrict access to trusted networks
- **Rate Limiting**: Prevent abuse
- **Encrypted Communication**: HTTPS/TLS support

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

## 🛠️ Management Commands

```bash
# Start server
./setup.sh start

# Stop server
./setup.sh stop

# Restart server
./setup.sh restart

# Check status
./setup.sh status

# View logs
./setup.sh logs

# Test webhook
./setup.sh test
```

## 🔍 Troubleshooting

### **Server Won't Start:**
```bash
# Check Docker
docker --version
docker-compose --version

# Check logs
./setup.sh logs

# Restart Docker
sudo systemctl restart docker
```

### **Email Not Sending:**
```bash
# Test SMTP connection
telnet smtp.gmail.com 587

# Check email configuration
nano .env

# Verify credentials
```

### **Webhook Not Working:**
```bash
# Test webhook
curl -X POST http://localhost:5678/webhook/monitoring \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'

# Check workflow status
# Open http://localhost:5678 and verify workflow is active
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

## 🆘 Getting Help

1. **Check Logs**: `./setup.sh logs`
2. **Test Webhook**: `./setup.sh test`
3. **Verify Configuration**: Check `.env` file
4. **Restart Server**: `./setup.sh restart`

## 📞 Support

For issues:
1. Check the troubleshooting section
2. Review log files
3. Test with sample data
4. Contact system administrator

**Remember**: Always test in a staging environment before deploying to production! 
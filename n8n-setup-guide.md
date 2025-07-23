# n8n Setup Guide for Mac System Monitor

This guide will help you set up n8n to receive monitoring alerts and send detailed email notifications to administrators.

## Prerequisites

- n8n installed and running
- SMTP email server configured
- Slack workspace (optional, for additional notifications)

## Step 1: Install n8n

### Option A: Docker Installation (Recommended)

```bash
# Create n8n directory
mkdir n8n
cd n8n

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=your_secure_password
      - N8N_HOST=localhost
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=http://localhost:5678/
      - GENERIC_TIMEZONE=UTC
    volumes:
      - n8n_data:/home/node/.n8n
    networks:
      - n8n_network

volumes:
  n8n_data:

networks:
  n8n_network:
    driver: bridge
EOF

# Start n8n
docker-compose up -d
```

### Option B: Local Installation

```bash
# Install n8n globally
npm install -g n8n

# Start n8n
n8n start
```

## Step 2: Access n8n

1. Open your browser and go to `http://localhost:5678`
2. Login with the credentials:
   - Username: `admin`
   - Password: `your_secure_password`

## Step 3: Import the Workflow

1. In n8n, click on "Workflows" in the left sidebar
2. Click "Import from file" or "Import from URL"
3. Upload the `n8n-workflow.json` file from this project
4. The workflow will be imported with all nodes configured

## Step 4: Configure Email Settings

### Configure SMTP Credentials

1. In the workflow, click on the "Send Email" node
2. Click on the credentials field and select "Create New"
3. Choose "SMTP" as the credential type
4. Fill in your SMTP settings:

```
Host: smtp.gmail.com (or your SMTP server)
Port: 587
User: your_email@gmail.com
Password: your_app_password
Security: STARTTLS
```

### Update Email Recipients

1. Click on the "Send Email" node
2. Update the following fields:
   - **From Email**: `security@yourcompany.com`
   - **To Email**: `admin@yourcompany.com` (or your admin email)
   - **Subject**: Leave as is (dynamically generated)
   - **Text**: Leave as is (dynamically generated)

## Step 5: Configure Slack (Optional)

### Create Slack App

1. Go to https://api.slack.com/apps
2. Click "Create New App" → "From scratch"
3. Name your app: "Mac System Monitor"
4. Select your workspace

### Configure Bot Token

1. In your Slack app, go to "OAuth & Permissions"
2. Add these scopes:
   - `chat:write`
   - `chat:write.public`
3. Install the app to your workspace
4. Copy the "Bot User OAuth Token"

### Configure n8n Slack Credentials

1. In the workflow, click on the "Send Slack" node
2. Click on the credentials field and select "Create New"
3. Choose "Slack API" as the credential type
4. Enter your Bot User OAuth Token

### Update Slack Channels

1. Click on the "Send Slack" node
2. Update the channel settings:
   - **Channel**: `#security-alerts` (or your preferred channel)
   - **Text**: Leave as is (dynamically generated)
   - **Attachments**: Leave as is (dynamically generated)

## Step 6: Test the Webhook

### Get Webhook URL

1. In the workflow, click on the "Webhook Trigger" node
2. Copy the webhook URL (it will look like: `http://localhost:5678/webhook/monitoring`)

### Test with curl

```bash
# Test basic event
curl -X POST http://localhost:5678/webhook/monitoring \
  -H "Content-Type: application/json" \
  -d '{
    "timestamp": "2024-01-15T10:30:00.000Z",
    "type": "UsbBlocked",
    "severity": "High",
    "description": "Unauthorized USB device blocked",
    "computer": "MACBOOK-PRO-001",
    "user": "john.doe",
    "details": {
      "DeviceID": "USB\\VID_0781&PID_5567",
      "DeviceName": "SanDisk USB Drive",
      "VendorID": "0781",
      "ProductID": "5567",
      "SerialNumber": "123456789",
      "Blocked": "true",
      "Reason": "Device not in whitelist"
    },
    "deviceInfo": {
      "serialNumber": "C02XYZ123456",
      "primaryMacAddress": "00:11:22:33:44:55",
      "allMacAddresses": ["00:11:22:33:44:55", "AA:BB:CC:DD:EE:FF"],
      "biosSerialNumber": "C02XYZ123456",
      "motherboardSerialNumber": "C02XYZ123456",
      "hardwareUUID": "12345678-1234-1234-1234-123456789ABC",
      "modelIdentifier": "MacBookPro18,1",
      "processorInfo": "Apple M1 Pro",
      "memoryInfo": "16 GB",
      "diskInfo": "512 GB SSD",
      "installationPath": "/Applications/MacSystemMonitor.app"
    }
  }'
```

## Step 7: Configure Monitoring Applications

### Update Mac System Monitor Configuration

1. Open `MacSystemMonitor/AppConfig.swift`
2. Update the n8n webhook URL:

```swift
struct AppConfig {
    // ... existing code ...
    
    static let n8nWebhookUrl = "http://your-n8n-server:5678/webhook/monitoring"
    
    // ... existing code ...
}
```

### Update Windows Monitor Configuration

1. Open `Windows/AppConfig.cs`
2. Update the n8n webhook URL:

```csharp
public static class AppConfig
{
    // ... existing code ...
    
    public static string N8nWebhookUrl = "http://your-n8n-server:5678/webhook/monitoring";
    
    // ... existing code ...
}
```

## Step 8: Email Templates

The workflow includes detailed email templates for different event types:

### USB Blocked Email
- **Subject**: 🚨 CRITICAL: Unauthorized USB Device Blocked
- **Content**: Includes device details, blocking reason, and recommended actions

### Uninstall Detection Email
- **Subject**: 🚨 CRITICAL: System Monitor Uninstallation Detected
- **Content**: Includes device fingerprint, process details, and immediate action items

### File Transfer Email
- **Subject**: 📁 INFO: File Transfer Activity Detected
- **Content**: Includes file details, transfer type, and device information

### Network Activity Email
- **Subject**: ⚠️ WARNING: Suspicious Network Activity Detected
- **Content**: Includes domain, connection details, and security recommendations

## Step 9: Monitoring and Alerts

### Email Notifications

The system will send emails for:
- **High/Critical Severity Events**: All events with high or critical severity
- **USB Blocked Events**: When unauthorized USB devices are blocked
- **Uninstall Detection**: When monitoring software is uninstalled
- **Blacklisted App Detection**: When blacklisted applications are detected

### Slack Notifications

The system will send Slack messages to:
- **#security-alerts**: For high/critical severity events
- **#monitoring**: For medium severity events
- **#general**: For low severity events

### Log Storage

All events are stored in:
- **File**: `/var/log/mac-system-monitor.log` (macOS)
- **File**: `C:\ProgramData\EmployeeActivityMonitor\logs\system-monitor.log` (Windows)

## Step 10: Security Considerations

### Webhook Security

1. **Use HTTPS**: In production, use HTTPS for webhook URLs
2. **Authentication**: Consider adding webhook authentication
3. **IP Whitelisting**: Restrict webhook access to known IP addresses

### Email Security

1. **Use App Passwords**: For Gmail, use app-specific passwords
2. **Encryption**: Use STARTTLS or SSL for email transmission
3. **Spam Protection**: Configure proper SPF, DKIM, and DMARC records

### Log Security

1. **File Permissions**: Ensure log files are only readable by administrators
2. **Encryption**: Consider encrypting sensitive log data
3. **Retention**: Implement log rotation and retention policies

## Step 11: Troubleshooting

### Common Issues

1. **Webhook Not Receiving Events**
   - Check n8n is running and accessible
   - Verify webhook URL is correct
   - Check firewall settings

2. **Emails Not Sending**
   - Verify SMTP credentials
   - Check email server settings
   - Test with a simple email first

3. **Slack Notifications Not Working**
   - Verify Slack app permissions
   - Check bot token is correct
   - Ensure bot is added to channels

### Debug Mode

Enable debug logging in n8n:
1. Go to Settings → Logs
2. Set log level to "debug"
3. Check logs for detailed error information

### Test Events

Use the test scripts to generate sample events:
- **macOS**: `./test-simple.sh`
- **Windows**: Run the test mode in the application

## Step 12: Production Deployment

### n8n Production Setup

1. **Use Docker Compose** for easy deployment
2. **Set up SSL/TLS** for secure webhook communication
3. **Configure backups** for workflow data
4. **Set up monitoring** for n8n itself

### Email Server Setup

1. **Use a reliable SMTP service** (SendGrid, Mailgun, etc.)
2. **Set up proper DNS records** (SPF, DKIM, DMARC)
3. **Monitor email delivery** and bounce rates

### Log Management

1. **Set up log rotation** to prevent disk space issues
2. **Configure log monitoring** to detect issues
3. **Implement log backup** for compliance

## Support

For issues with:
- **n8n**: Check the [n8n documentation](https://docs.n8n.io/)
- **Email**: Check your SMTP provider's documentation
- **Slack**: Check the [Slack API documentation](https://api.slack.com/)
- **Monitoring Apps**: Check the project README files

## Example Email Output

Here's what an email notification looks like:

```
🔍 SECURITY ALERT - MAC SYSTEM MONITOR
=====================================

📅 EVENT DETAILS
---------------
• Time: 2024-01-15T10:30:00.000Z
• Type: UsbBlocked
• Severity: High
• Description: Unauthorized USB device blocked: SanDisk USB Drive
• Computer: MACBOOK-PRO-001
• User: john.doe

🖥️ DEVICE INFORMATION
--------------------
• Serial Number: C02XYZ123456
• Primary MAC Address: 00:11:22:33:44:55
• All MAC Addresses: 00:11:22:33:44:55, AA:BB:CC:DD:EE:FF
• BIOS Serial: C02XYZ123456
• Motherboard Serial: C02XYZ123456
• Hardware UUID: 12345678-1234-1234-1234-123456789ABC
• Model: MacBookPro18,1
• Processor: Apple M1 Pro
• Memory: 16 GB
• Disk: 512 GB SSD
• Installation Path: /Applications/MacSystemMonitor.app
• Device Fingerprint: ABC123DEF456

💾 USB DEVICE DETAILS
-------------------
• Device ID: USB\VID_0781&PID_5567
• Device Name: SanDisk USB Drive
• Vendor ID: 0781
• Product ID: 5567
• Blocked: YES
• Reason: Device not in whitelist

🎯 RECOMMENDED ACTIONS
-------------------
• Investigate unauthorized USB device attempt
• Review USB whitelist configuration
• Check for potential security breach
• Update device whitelist if needed

📊 EVENT STATISTICS
-----------------
• Total Events Today: 15
• High Severity Events: 3
• USB Blocking Events: 2
• File Transfer Events: 8

---
This alert was generated automatically by the Mac System Monitor.
For support, contact your system administrator.
``` 
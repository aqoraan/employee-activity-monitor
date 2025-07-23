# Employee Activity Monitor

A comprehensive Windows application for monitoring employee activities including USB drive usage, file transfers, application installations, and network activities. The system integrates with N8N for automated reporting and email alerts, and includes advanced USB device blocking with Google Sheets whitelist management.

## Features

### 🔍 Monitoring Capabilities
- **USB Drive Monitoring**: Detects connection/disconnection of USB devices
- **USB Device Blocking**: Blocks unauthorized USB drives using Google Sheets whitelist
- **File Transfer Monitoring**: Tracks file operations on USB drives and external storage
- **Application Installation Monitoring**: Detects software installation activities
- **Blacklisted Application Detection**: Identifies and alerts on prohibited software
- **Network Activity Monitoring**: Monitors suspicious network connections
- **Real-time Activity Logging**: Comprehensive logging of all detected activities

### 🛡️ USB Security Features
- **Google Sheets Integration**: Centralized USB whitelist management
- **Real-time Blocking**: Instantly blocks unauthorized USB devices
- **Device Identification**: Supports multiple USB device ID formats
- **Cache Management**: Efficient API caching with configurable expiration
- **Fallback Protection**: Local whitelist backup for offline scenarios
- **Audit Logging**: Complete audit trail of all blocking events

### 📧 Automated Reporting
- **N8N Integration**: Sends activity data to N8N workflows
- **Email Alerts**: Automated email notifications based on activity severity
- **Configurable Severity Levels**: Low, Medium, High, and Critical alerts
- **Detailed Activity Reports**: Includes computer name, user, timestamp, and activity details
- **USB Blocking Alerts**: Special alerts for unauthorized USB device attempts

### 🎨 Modern UI
- **Real-time Status Indicators**: Visual status for each monitoring component
- **Activity Log Display**: Live scrolling log of detected activities
- **Export Functionality**: Export activity logs to text files
- **Administrative Controls**: Start/stop monitoring and test connections
- **USB Blocking Status**: Visual indicators for USB security status

## System Requirements

- **Operating System**: Windows 10/11 (64-bit)
- **.NET Runtime**: .NET 6.0 or later
- **Administrative Privileges**: Required for system monitoring and USB blocking
- **N8N Instance**: For automated reporting (optional)
- **Google Cloud Project**: For USB whitelist management (optional)

## Installation

### 1. Build the Application

```bash
# Navigate to the project directory
cd SystemMonitor

# Restore NuGet packages
dotnet restore

# Build the application
dotnet build --configuration Release

# Publish the application
dotnet publish --configuration Release --output ./publish
```

### 2. Deploy with USB Blocking

```powershell
# Deploy with USB blocking enabled (requires admin)
.\deploy-secure.ps1 -InstallAsService
```

### 3. Configure Google Sheets Integration

Follow the detailed setup guide in [GOOGLE_SHEETS_SETUP.md](GOOGLE_SHEETS_SETUP.md) to:
- Create Google Cloud project
- Enable Google Sheets API
- Set up service account
- Create USB whitelist spreadsheet
- Configure application settings

## Configuration

### USB Blocking Configuration

Edit `config.json` to enable USB blocking:

```json
{
  "usbBlockingSettings": {
    "enableUsbBlocking": true,
    "googleSheetsApiKey": "YOUR_API_KEY",
    "googleSheetsSpreadsheetId": "YOUR_SPREADSHEET_ID",
    "googleSheetsRange": "A:A",
    "cacheExpirationMinutes": 5,
    "blockAllUsbStorage": false,
    "allowWhitelistedOnly": true,
    "logBlockedDevices": true,
    "sendBlockingAlerts": true,
    "localWhitelist": [
      "USB\\VID_0951&PID_1666",
      "USB\\VID_0781&PID_5567"
    ]
  }
}
```

### Google Sheets Whitelist Format

Create a Google Sheet with the following structure:

| Column A | Column B | Column C |
|----------|----------|----------|
| **Device ID** | **Description** | **Approved By** |
| USB\VID_0951&PID_1666 | Kingston DataTraveler | admin@company.com |
| USB\VID_0781&PID_5567 | SanDisk Cruzer | admin@company.com |

## Activity Types and Severity

| Activity Type | Description | Default Severity |
|---------------|-------------|------------------|
| **UsbDrive** | USB device connection/disconnection | Medium |
| **UsbBlocked** | Unauthorized USB device blocked | High |
| **FileTransfer** | File operations on external drives | Medium |
| **AppInstallation** | Software installation detected | Medium |
| **BlacklistedApp** | Prohibited application detected | High |
| **NetworkActivity** | Suspicious network connections | Medium |
| **System** | System-level events and errors | Variable |

### Severity Levels

- **Low**: Minor activities, informational only
- **Medium**: Standard monitoring events
- **High**: Security concerns requiring attention
- **Critical**: Immediate security threats

## N8N Integration

### Workflow Overview

The N8N workflow processes incoming webhook data and sends email alerts:

1. **Webhook Trigger**: Receives activity data from the monitoring application
2. **Data Processing**: Extracts and formats activity information
3. **Severity Filtering**: Routes alerts based on severity level
4. **Email Sending**: Sends alerts to appropriate recipients
5. **Response**: Confirms successful processing

### USB Blocking Alerts

Special handling for USB blocking events:
- **High Priority**: USB blocking events trigger immediate alerts
- **Detailed Information**: Includes device ID, reason, and timestamp
- **Security Warnings**: Clear indication of security incident
- **Action Required**: Prompts for immediate investigation

### Email Configuration

Update the email settings in the N8N workflow:

```json
{
  "fromEmail": "security@yourcompany.com",
  "toEmail": "admin@yourcompany.com"
}
```

## Security Features

### USB Device Control
- **Whitelist Management**: Centralized Google Sheets management
- **Real-time Blocking**: Instant blocking of unauthorized devices
- **Device Identification**: Multiple methods for device ID detection
- **Cache Optimization**: Efficient API usage with local caching
- **Fallback Protection**: Local whitelist for offline scenarios

### Administrative Protection
- **Admin Privileges Required**: All functions require administrative access
- **Google Workspace Integration**: Admin validation via Google Workspace
- **Service-based Operation**: Runs as Windows Service for persistence
- **Configuration Protection**: Protected configuration files and registry
- **Uninstallation Prevention**: Prevents unauthorized removal

### Data Security
- **Encrypted Communication**: HTTPS for all API communications
- **Secure Storage**: Encrypted storage of sensitive configuration
- **Audit Logging**: Comprehensive logging of all security events
- **Access Control**: Restricted access to monitoring data

## Troubleshooting

### USB Blocking Issues

1. **Device Not Blocked**
   - Verify USB blocking is enabled in configuration
   - Check device ID format in Google Sheet
   - Ensure API key and spreadsheet ID are correct
   - Check Windows Event Logs for errors

2. **API Connection Issues**
   - Verify Google Sheets API is enabled
   - Check API key permissions
   - Ensure spreadsheet is shared with service account
   - Test API access manually

3. **Cache Problems**
   - Restart the monitoring service
   - Check cache expiration settings
   - Verify network connectivity
   - Clear application cache if needed

### General Issues

1. **Service Not Starting**
   - Run as Administrator
   - Check .NET Framework installation
   - Verify Windows Service permissions
   - Check configuration file syntax

2. **N8N Integration Issues**
   - Verify N8N is running
   - Check webhook URL configuration
   - Test network connectivity
   - Review N8N workflow logs

## Compliance and Best Practices

### Privacy Considerations
- **Employee Notification**: Inform employees about monitoring activities
- **Data Retention**: Implement appropriate data retention policies
- **Access Control**: Restrict access to monitoring data
- **Audit Logging**: Maintain logs of who accessed monitoring data

### Security Best Practices
- **Regular Updates**: Keep application and dependencies updated
- **API Key Rotation**: Regularly rotate Google API keys
- **Backup Configuration**: Regularly backup configuration files
- **Monitor Logs**: Regularly review security and activity logs

### USB Security Best Practices
- **Regular Whitelist Review**: Periodically review and update whitelist
- **Device Documentation**: Maintain detailed device documentation
- **Approval Process**: Implement formal device approval process
- **Incident Response**: Have procedures for unauthorized device attempts

## Support and Documentation

- **Setup Guide**: [GOOGLE_SHEETS_SETUP.md](GOOGLE_SHEETS_SETUP.md)
- **Security Documentation**: [SECURITY.md](SECURITY.md)
- **Quick Setup**: [SETUP.md](SETUP.md)
- **Deployment Scripts**: `deploy-secure.ps1`

---

**Note**: This application implements enterprise-grade security features including advanced USB device control. Ensure proper authorization and compliance with organizational policies before deployment. 
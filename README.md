# Employee Activity Monitor

A comprehensive Windows application for monitoring employee activities including USB drive usage, file transfers, application installations, and network activities. The system integrates with N8N for automated reporting and email alerts.

## Features

### 🔍 Monitoring Capabilities
- **USB Drive Monitoring**: Detects connection/disconnection of USB devices
- **File Transfer Monitoring**: Tracks file operations on USB drives and external storage
- **Application Installation Monitoring**: Detects software installation activities
- **Blacklisted Application Detection**: Identifies and alerts on prohibited software
- **Network Activity Monitoring**: Monitors suspicious network connections
- **Real-time Activity Logging**: Comprehensive logging of all detected activities

### 📧 Automated Reporting
- **N8N Integration**: Sends activity data to N8N workflows
- **Email Alerts**: Automated email notifications based on activity severity
- **Configurable Severity Levels**: Low, Medium, High, and Critical alerts
- **Detailed Activity Reports**: Includes computer name, user, timestamp, and activity details

### 🎨 Modern UI
- **Real-time Status Indicators**: Visual status for each monitoring component
- **Activity Log Display**: Live scrolling log of detected activities
- **Export Functionality**: Export activity logs to text files
- **Administrative Controls**: Start/stop monitoring and test connections

## System Requirements

- **Operating System**: Windows 10/11 (64-bit)
- **.NET Runtime**: .NET 6.0 or later
- **Administrative Privileges**: Required for system monitoring
- **N8N Instance**: For automated reporting (optional)

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

### 2. Install N8N (Optional)

```bash
# Install N8N globally
npm install -g n8n

# Start N8N
n8n start

# Access N8N at http://localhost:5678
```

### 3. Import N8N Workflow

1. Open N8N at `http://localhost:5678`
2. Import the workflow from `n8n-workflow.json`
3. Configure email settings in the workflow
4. Activate the workflow

## Configuration

### Application Settings

Edit `MainWindow.xaml.cs` to configure the N8N webhook URL:

```csharp
private void InitializeMonitoringService()
{
    // Update this URL to match your N8N instance
    var n8nWebhookUrl = "http://localhost:5678/webhook/monitoring";
    _monitoringService = new MonitoringService(n8nWebhookUrl);
    _monitoringService.ActivityDetected += OnActivityDetected;
}
```

### Blacklisted Applications

Edit the `LoadBlacklistedApps()` method in `MonitoringService.cs`:

```csharp
private List<string> LoadBlacklistedApps()
{
    return new List<string>
    {
        "tor.exe", "vpn.exe", "proxy.exe", "anonymizer.exe",
        "cryptolocker.exe", "ransomware.exe", "keylogger.exe",
        "spyware.exe", "malware.exe", "trojan.exe",
        // Add your custom blacklisted applications here
    };
}
```

### Suspicious Domains

Edit the `LoadSuspiciousDomains()` method:

```csharp
private List<string> LoadSuspiciousDomains()
{
    return new List<string>
    {
        "mega.nz", "dropbox.com", "google-drive.com", "onedrive.com",
        "we-transfer.com", "file.io", "transfernow.net",
        // Add your custom suspicious domains here
    };
}
```

## Usage

### Starting the Application

1. **Run as Administrator**: Right-click the executable and select "Run as administrator"
2. **Start Monitoring**: Click "Start Monitoring" to begin activity monitoring
3. **Test N8N Connection**: Click "Test N8N Connection" to verify integration
4. **Monitor Activities**: Watch the activity log for real-time events

### Understanding Activity Types

| Activity Type | Description | Severity |
|---------------|-------------|----------|
| **UsbDrive** | USB device connection/disconnection | Medium |
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

### Email Configuration

Update the email settings in the N8N workflow:

```json
{
  "fromEmail": "security@yourcompany.com",
  "toEmail": "admin@yourcompany.com"
}
```

### Customizing Alerts

Modify the workflow to add additional actions:

- **Slack Notifications**: Send alerts to Slack channels
- **SMS Alerts**: Send text messages for critical events
- **Database Logging**: Store activities in a database
- **Ticket Creation**: Create support tickets automatically

## Security Considerations

### Privacy and Compliance

- **Employee Notification**: Inform employees about monitoring activities
- **Data Retention**: Implement appropriate data retention policies
- **Access Control**: Restrict access to monitoring data
- **Audit Logging**: Maintain logs of who accessed monitoring data

### Technical Security

- **Encrypted Communication**: Use HTTPS for N8N communication
- **Authentication**: Implement proper authentication for N8N
- **Network Security**: Secure the network connection to N8N
- **Data Protection**: Encrypt sensitive monitoring data

## Troubleshooting

### Common Issues

1. **Administrative Privileges Required**
   - Ensure the application is running as administrator
   - Check Windows User Account Control settings

2. **N8N Connection Failed**
   - Verify N8N is running on the correct port
   - Check firewall settings
   - Ensure the webhook URL is correct

3. **Monitoring Not Working**
   - Check Windows Management Instrumentation (WMI) service
   - Verify Windows Event Log service is running
   - Check for antivirus software interference

4. **High CPU Usage**
   - Adjust monitoring sensitivity in the code
   - Implement activity throttling
   - Monitor system resources

### Debug Mode

Enable debug logging by modifying the application:

```csharp
// Add debug logging
LogActivity($"Debug: {detailedInformation}");
```

## Development

### Project Structure

```
SystemMonitor/
├── App.xaml                 # Application entry point
├── App.xaml.cs             # Application logic
├── MainWindow.xaml         # Main UI
├── MainWindow.xaml.cs      # UI event handlers
├── MonitoringService.cs    # Core monitoring logic
├── app.manifest           # Administrative privileges
└── SystemMonitor.csproj   # Project configuration
```

### Adding New Monitoring Features

1. **Create New Activity Type**:
   ```csharp
   public enum ActivityType
   {
       // ... existing types
       NewActivityType
   }
   ```

2. **Implement Monitoring Logic**:
   ```csharp
   private void StartNewMonitoring()
   {
       // Add your monitoring logic here
   }
   ```

3. **Update UI**:
   ```xaml
   <TextBlock Text="New Monitoring:" FontWeight="SemiBold"/>
   <Ellipse x:Name="NewStatus" Width="12" Height="12" Fill="Red"/>
   ```

## License

This project is provided as-is for educational and business use. Please ensure compliance with local laws and regulations regarding employee monitoring.

## Support

For technical support or feature requests, please contact your system administrator or IT department.

---

**Note**: This application requires administrative privileges and should be used in accordance with company policies and local regulations regarding employee monitoring. 
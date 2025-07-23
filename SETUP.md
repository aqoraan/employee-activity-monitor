# Quick Setup Guide - Employee Activity Monitor

## Prerequisites

- Windows 10/11 (64-bit)
- .NET 6.0 or later
- Administrative privileges
- Node.js (for N8N integration)

## Quick Deployment

### 1. Build and Deploy

```powershell
# Run the deployment script as Administrator
.\deploy.ps1 -InstallN8n
```

### 2. Start N8N (if installed)

```bash
n8n start
```

### 3. Import N8N Workflow

1. Open browser: `http://localhost:5678`
2. Import workflow: `n8n-workflow.json`
3. Configure email settings
4. Activate workflow

### 4. Run the Application

1. Right-click "Employee Activity Monitor" shortcut
2. Select "Run as administrator"
3. Click "Start Monitoring"

## Manual Setup

### Build Application

```bash
cd SystemMonitor
dotnet restore
dotnet build --configuration Release
dotnet publish --configuration Release --output ./publish
```

### Install N8N

```bash
npm install -g n8n
n8n start
```

### Configure Email Settings

Edit `n8n-workflow.json` and update email settings:

```json
{
  "fromEmail": "security@yourcompany.com",
  "toEmail": "admin@yourcompany.com"
}
```

## Configuration

### Application Settings

Edit `config.json` in the application directory:

```json
{
  "n8nWebhookUrl": "http://localhost:5678/webhook/monitoring",
  "blacklistedApps": [
    "tor.exe", "vpn.exe", "proxy.exe"
  ],
  "monitoringSettings": {
    "enableUsbMonitoring": true,
    "enableFileTransferMonitoring": true,
    "enableAppInstallationMonitoring": true,
    "enableNetworkMonitoring": true,
    "autoStartMonitoring": false,
    "sendToN8n": true
  }
}
```

## Testing

### Test USB Monitoring
1. Insert a USB drive
2. Check activity log for USB connection event
3. Create a file on the USB drive
4. Check for file transfer event

### Test Application Monitoring
1. Install any application
2. Check for installation detection
3. Run a blacklisted application (if available)
4. Check for blacklisted app alert

### Test N8N Integration
1. Click "Test N8N Connection"
2. Check email for test message
3. Verify webhook is working

## Troubleshooting

### Common Issues

1. **"Administrative privileges required"**
   - Right-click application → "Run as administrator"

2. **"N8N connection failed"**
   - Verify N8N is running: `http://localhost:5678`
   - Check firewall settings
   - Verify webhook URL in config

3. **"Monitoring not working"**
   - Check Windows Services:
     - Windows Management Instrumentation
     - Windows Event Log
   - Disable antivirus temporarily for testing

4. **"High CPU usage"**
   - Reduce monitoring sensitivity in config
   - Disable unnecessary monitoring features

### Debug Mode

Enable detailed logging by modifying the application:

```csharp
// In MainWindow.xaml.cs
LogActivity($"Debug: {detailedInformation}");
```

## Security Notes

- **Employee Notification**: Inform employees about monitoring
- **Data Retention**: Implement appropriate retention policies
- **Access Control**: Restrict access to monitoring data
- **Compliance**: Ensure compliance with local regulations

## Support

For issues or questions:
1. Check the activity log for error messages
2. Verify configuration settings
3. Test individual monitoring components
4. Review Windows Event Logs

---

**Important**: This application monitors employee activities. Ensure compliance with company policies and local regulations. 
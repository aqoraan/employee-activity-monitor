# Google Sheets USB Whitelist Setup Guide

## Overview

The Employee Activity Monitor can block unauthorized USB drives by checking against a whitelist stored in Google Sheets. This provides centralized management of approved USB devices across your organization.

## Prerequisites

1. **Google Cloud Project**: You need a Google Cloud project with APIs enabled
2. **Google Sheets API**: Must be enabled in your Google Cloud project
3. **Service Account**: A service account with access to Google Sheets
4. **Google Sheet**: A shared Google Sheet containing the USB whitelist

## Step 1: Create Google Cloud Project

### 1.1 Create New Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a project" → "New Project"
3. Enter project name: `Employee Activity Monitor`
4. Click "Create"

### 1.2 Enable APIs
1. In your project, go to "APIs & Services" → "Library"
2. Search for and enable these APIs:
   - **Google Sheets API**
   - **Google Drive API** (if needed for file access)

## Step 2: Create Service Account

### 2.1 Create Service Account
1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "Service Account"
3. Enter details:
   - **Name**: `usb-whitelist-service`
   - **Description**: `Service account for USB whitelist management`
4. Click "Create and Continue"

### 2.2 Grant Permissions
1. For "Role", select "Editor" (or create custom role)
2. Click "Continue"
3. Click "Done"

### 2.3 Generate API Key
1. Click on your service account
2. Go to "Keys" tab
3. Click "Add Key" → "Create new key"
4. Choose "JSON" format
5. Download the JSON file (keep it secure!)

## Step 3: Create Google Sheet

### 3.1 Create New Sheet
1. Go to [Google Sheets](https://sheets.google.com/)
2. Create a new spreadsheet
3. Name it: `USB Device Whitelist`

### 3.2 Set Up Structure
Create the following structure in your sheet:

| Column A | Column B | Column C |
|----------|----------|----------|
| **Device ID** | **Description** | **Approved By** |
| USB\VID_0951&PID_1666 | Kingston DataTraveler | admin@company.com |
| USB\VID_0781&PID_5567 | SanDisk Cruzer | admin@company.com |

### 3.3 Share Sheet
1. Click "Share" button
2. Add your service account email (from the JSON file)
3. Give "Editor" permissions
4. Click "Send"

## Step 4: Get Sheet Information

### 4.1 Get Spreadsheet ID
1. Open your Google Sheet
2. Look at the URL: `https://docs.google.com/spreadsheets/d/SPREADSHEET_ID/edit`
3. Copy the `SPREADSHEET_ID` part

### 4.2 Get API Key
1. Go to Google Cloud Console → "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "API Key"
3. Copy the API key
4. (Optional) Restrict the API key to Google Sheets API only

## Step 5: Configure Application

### 5.1 Update Configuration
Edit your `config.json` file:

```json
{
  "usbBlockingSettings": {
    "enableUsbBlocking": true,
    "googleSheetsApiKey": "YOUR_API_KEY_HERE",
    "googleSheetsSpreadsheetId": "YOUR_SPREADSHEET_ID_HERE",
    "googleSheetsRange": "A:A",
    "cacheExpirationMinutes": 5,
    "blockAllUsbStorage": false,
    "allowWhitelistedOnly": true,
    "logBlockedDevices": true,
    "sendBlockingAlerts": true
  }
}
```

### 5.2 Deploy with Configuration
```powershell
# Run deployment with USB blocking enabled
.\deploy-secure.ps1 -InstallAsService
```

## Step 6: Test Configuration

### 6.1 Test API Access
```powershell
# Test Google Sheets API access
$apiKey = "YOUR_API_KEY"
$spreadsheetId = "YOUR_SPREADSHEET_ID"
$url = "https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/A:A?key=$apiKey"
Invoke-RestMethod -Uri $url
```

### 6.2 Test USB Blocking
1. Insert an unauthorized USB drive
2. Check Windows Event Logs for blocking events
3. Verify email alerts are sent

## USB Device ID Formats

### Common Formats
- **USB\VID_XXXX&PID_XXXX**: Standard USB device format
- **USBSTOR\Disk&Ven_XXXX&Prod_XXXX**: USB storage device format
- **USB\VID_XXXX&PID_XXXX&REV_XXXX**: USB device with revision

### Finding Device IDs
1. **Device Manager Method**:
   - Open Device Manager
   - Right-click USB device → Properties
   - Go to "Details" tab
   - Select "Hardware Ids" from dropdown

2. **PowerShell Method**:
   ```powershell
   Get-PnpDevice | Where-Object {$_.Class -eq "USB"} | Select-Object FriendlyName, InstanceId
   ```

3. **WMI Method**:
   ```powershell
   Get-WmiObject -Class Win32_USBHub | Select-Object DeviceID, Description
   ```

## Managing the Whitelist

### Adding Devices
1. Insert the USB device
2. Get the device ID using methods above
3. Add to Google Sheet in Column A
4. Add description in Column B
5. Add approver in Column C

### Removing Devices
1. Delete the row from Google Sheet
2. The device will be blocked on next connection

### Bulk Import
You can import multiple devices at once:
1. Prepare CSV file with device IDs
2. Import into Google Sheet
3. Add descriptions and approvers

## Security Considerations

### API Key Security
- **Restrict API Key**: Limit to Google Sheets API only
- **IP Restrictions**: Restrict to your network IPs
- **Regular Rotation**: Rotate API keys periodically

### Sheet Security
- **Access Control**: Only share with necessary service accounts
- **Audit Logging**: Enable Google Workspace audit logs
- **Backup**: Regularly backup your whitelist

### Application Security
- **Encrypted Storage**: API keys are stored encrypted
- **Network Security**: Use HTTPS for all API calls
- **Logging**: All blocking events are logged

## Troubleshooting

### Common Issues

1. **"API Key Invalid"**
   - Verify API key is correct
   - Check if Google Sheets API is enabled
   - Ensure API key has proper permissions

2. **"Spreadsheet Not Found"**
   - Verify spreadsheet ID is correct
   - Check if service account has access
   - Ensure sheet is shared properly

3. **"USB Not Blocked"**
   - Check if USB blocking is enabled in config
   - Verify device ID format in sheet
   - Check Windows Event Logs for errors

4. **"Cache Issues"**
   - Restart the monitoring service
   - Check cache expiration settings
   - Verify network connectivity

### Debug Commands
```powershell
# Check service status
Get-Service -Name "EmployeeActivityMonitor"

# View USB blocking logs
Get-EventLog -LogName Application -Source "EmployeeActivityMonitor" | Where-Object {$_.Message -like "*USB*"}

# Test Google Sheets API
$headers = @{ "Authorization" = "Bearer $apiKey" }
Invoke-RestMethod -Uri "https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId" -Headers $headers
```

## Advanced Configuration

### Custom Ranges
You can specify custom ranges for different columns:
```json
{
  "googleSheetsRange": "A:C"  // Include description and approver columns
}
```

### Multiple Sheets
For large organizations, you can use multiple sheets:
```json
{
  "googleSheetsSpreadsheetId": "main-sheet-id",
  "googleSheetsRange": "A:A"
}
```

### Local Fallback
You can add local whitelist as backup:
```json
{
  "localWhitelist": [
    "USB\\VID_0951&PID_1666",
    "USB\\VID_0781&PID_5567"
  ]
}
```

## Monitoring and Alerts

### Email Alerts
USB blocking events trigger email alerts with:
- Device ID that was blocked
- Timestamp of blocking
- Computer and user information
- Reason for blocking

### Event Logs
All blocking events are logged to:
- Windows Event Log (Application)
- N8N workflow (if configured)
- Local activity log

### Dashboard Integration
Blocking events appear in:
- Application dashboard
- N8N workflow monitoring
- Windows Event Viewer

---

**Note**: This setup provides enterprise-grade USB device control with centralized management through Google Sheets. Ensure proper testing in your environment before deploying to production. 
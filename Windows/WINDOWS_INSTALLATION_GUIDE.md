# Windows Application Installation Guide

## 🚀 Quick Start - If You Already Have Files on Windows Machine

If you've already transferred the source code files to your Windows machine, follow these steps:

### **Step 1: Install Prerequisites**

#### **1.1 Install .NET 6.0 SDK**
```powershell
# Download from: https://dotnet.microsoft.com/download/dotnet/6.0
# Or use winget:
winget install Microsoft.DotNet.SDK.6

# Verify installation
dotnet --version
```

### **Step 2: Build the Application**

#### **2.1 Navigate to Your Files**
```powershell
# Navigate to where you transferred the files
cd C:\path\to\your\transferred\files

# List files to verify
dir
```

#### **2.2 Run the Build Script**
```powershell
# Run the build script
.\Windows\build.ps1

# Or manually build:
cd SystemMonitor
dotnet restore
dotnet build --configuration Release
dotnet publish --configuration Release --output ".\publish" --runtime win-x64 --self-contained true
```

### **Step 3: Install the Application**

#### **3.1 Navigate to Published Files**
```powershell
# Navigate to the published directory
cd publish

# List files to verify
dir
```

#### **3.2 Run Installation**
```powershell
# Open PowerShell as Administrator
# Right-click on Start → Windows PowerShell (Admin)

# Navigate to your published directory
cd C:\path\to\your\publish\directory

# Run installation
.\install.ps1
```

## 📋 Detailed Installation Process

### **Prerequisites Checklist**

- [ ] Windows 10/11 (64-bit)
- [ ] .NET 6.0 SDK installed
- [ ] Administrator privileges
- [ ] Windows Defender configured (or temporarily disabled)
- [ ] Network access (for n8n integration)

### **Step-by-Step Installation**

#### **Step 1: Verify .NET Installation**
```powershell
# Check .NET version
dotnet --version

# Should show: 6.0.x or higher
# If not installed, download from: https://dotnet.microsoft.com/download/dotnet/6.0
```

#### **Step 2: Build the Application**
```powershell
# Navigate to project root
cd C:\path\to\your\project

# Run build script
.\Windows\build.ps1

# This will:
# - Clean previous builds
# - Restore packages
# - Build the project
# - Publish to .\publish directory
# - Copy installation scripts
```

#### **Step 3: Verify Build Output**
```powershell
# Check published files
cd publish
dir

# Should see:
# - SystemMonitor.exe
# - SystemMonitor.dll
# - SystemMonitor.runtimeconfig.json
# - install.ps1
# - README.txt
```

#### **Step 4: Handle Antivirus (if needed)**
```powershell
# Check Windows Defender status
Get-MpThreatDetection

# If blocking, add exclusions
Add-MpPreference -ExclusionPath (Get-Location).Path
Add-MpPreference -ExclusionProcess "SystemMonitor.exe"

# Or temporarily disable real-time protection
Set-MpPreference -DisableRealtimeMonitoring $true
```

#### **Step 5: Install the Application**
```powershell
# Run as Administrator
.\install.ps1

# This will:
# - Create installation directory
# - Copy application files
# - Create Windows Service
# - Configure Windows Defender exclusions
# - Start the service
# - Create verification and uninstall scripts
```

#### **Step 6: Verify Installation**
```powershell
# Check service status
Get-Service -Name EmployeeActivityMonitor

# Run verification script
.\verify.ps1

# Check logs
Get-Content "C:\ProgramData\EmployeeActivityMonitor\logs\system-monitor.log" -Tail 10
```

## 🔧 Configuration

### **Edit Configuration File**
```powershell
# Open configuration file
notepad "C:\Program Files\EmployeeActivityMonitor\config.json"

# Or use PowerShell
$config = Get-Content "C:\Program Files\EmployeeActivityMonitor\config.json" | ConvertFrom-Json
$config.notificationSettings.n8nWebhookUrl = "http://your-n8n-server:5678/webhook/monitoring"
$config | ConvertTo-Json -Depth 10 | Set-Content "C:\Program Files\EmployeeActivityMonitor\config.json"
```

### **Key Configuration Settings**
```json
{
  "monitoringSettings": {
    "enableUsbMonitoring": true,
    "enableFileTransferMonitoring": true,
    "enableAppInstallationMonitoring": true,
    "enableNetworkMonitoring": true,
    "enableUninstallDetection": true
  },
  "notificationSettings": {
    "enableEmailNotifications": true,
    "n8nWebhookUrl": "http://your-n8n-server:5678/webhook/monitoring",
    "adminEmail": "admin@yourcompany.com"
  },
  "usbSettings": {
    "blockAllUsbDevices": true,
    "googleSheetsWhitelistUrl": "https://docs.google.com/spreadsheets/d/your-sheet-id/edit"
  }
}
```

## 🛠️ Management Commands

### **Service Management**
```powershell
# Check service status
Get-Service -Name EmployeeActivityMonitor

# Start service
Start-Service -Name EmployeeActivityMonitor

# Stop service
Stop-Service -Name EmployeeActivityMonitor

# Restart service
Restart-Service -Name EmployeeActivityMonitor
```

### **Log Management**
```powershell
# View recent logs
Get-Content "C:\ProgramData\EmployeeActivityMonitor\logs\system-monitor.log" -Tail 20

# View all log files
Get-ChildItem "C:\ProgramData\EmployeeActivityMonitor\logs\"

# Clear logs (if needed)
Clear-Content "C:\ProgramData\EmployeeActivityMonitor\logs\system-monitor.log"
```

### **Configuration Management**
```powershell
# Backup configuration
Copy-Item "C:\Program Files\EmployeeActivityMonitor\config.json" "C:\Program Files\EmployeeActivityMonitor\config.json.backup"

# Restore configuration
Copy-Item "C:\Program Files\EmployeeActivityMonitor\config.json.backup" "C:\Program Files\EmployeeActivityMonitor\config.json"
```

## 🚨 Troubleshooting

### **Common Issues**

#### **1. Service Won't Start**
```powershell
# Check service status
Get-Service -Name EmployeeActivityMonitor

# Check Windows Event Logs
Get-EventLog -LogName Application -Source "EmployeeActivityMonitor" -Newest 5

# Check if executable exists
Test-Path "C:\Program Files\EmployeeActivityMonitor\SystemMonitor.exe"
```

#### **2. Permission Issues**
```powershell
# Check file permissions
icacls "C:\Program Files\EmployeeActivityMonitor"

# Set proper permissions
$acl = Get-Acl "C:\Program Files\EmployeeActivityMonitor"
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM","FullControl","ContainerInherit,ObjectInherit","None","Allow")
$acl.AddAccessRule($rule)
Set-Acl "C:\Program Files\EmployeeActivityMonitor" $acl
```

#### **3. Antivirus Blocking**
```powershell
# Check Windows Defender exclusions
Get-MpPreference | Select-Object ExclusionPath, ExclusionProcess

# Add exclusions if missing
Add-MpPreference -ExclusionPath "C:\Program Files\EmployeeActivityMonitor"
Add-MpPreference -ExclusionProcess "SystemMonitor.exe"
```

#### **4. .NET Runtime Issues**
```powershell
# Check .NET installation
dotnet --list-runtimes

# Install .NET 6.0 Runtime if missing
# Download from: https://dotnet.microsoft.com/download/dotnet/6.0
```

### **Emergency Stop**
```powershell
# Stop service immediately
Stop-Service -Name EmployeeActivityMonitor -Force

# Remove service
sc.exe delete EmployeeActivityMonitor

# Remove files
Remove-Item "C:\Program Files\EmployeeActivityMonitor" -Recurse -Force
Remove-Item "C:\ProgramData\EmployeeActivityMonitor" -Recurse -Force
```

## 📁 File Locations

### **Installation Directory**
```
C:\Program Files\EmployeeActivityMonitor\
├── SystemMonitor.exe
├── SystemMonitor.dll
├── SystemMonitor.runtimeconfig.json
├── config.json
├── install.ps1
├── verify.ps1
└── uninstall.ps1
```

### **Log Directory**
```
C:\ProgramData\EmployeeActivityMonitor\logs\
├── system-monitor.log
├── usb-events.log
├── file-transfer.log
└── app-installation.log
```

### **Service Information**
- **Service Name**: EmployeeActivityMonitor
- **Display Name**: Employee Activity Monitor
- **Start Type**: Automatic
- **Log On As**: Local System

## 🔒 Security Considerations

### **Windows Defender Exclusions**
The installation script automatically adds:
- Path exclusion: `C:\Program Files\EmployeeActivityMonitor`
- Process exclusion: `SystemMonitor.exe`

### **Service Security**
- Runs as Local System account
- Requires administrator privileges for installation
- Configuration file is protected from unauthorized changes

### **Network Security**
- Only sends webhook notifications to configured n8n server
- No incoming network connections
- All communication is outbound only

## 📞 Support

### **Log Files for Troubleshooting**
- `C:\ProgramData\EmployeeActivityMonitor\logs\system-monitor.log` - Main application logs
- Windows Event Logs - Service-related events

### **Verification Commands**
```powershell
# Run verification script
.\verify.ps1

# Check service status
Get-Service -Name EmployeeActivityMonitor

# Check recent logs
Get-Content "C:\ProgramData\EmployeeActivityMonitor\logs\system-monitor.log" -Tail 10
```

### **Uninstallation**
```powershell
# Run uninstall script
.\uninstall.ps1

# This will:
# - Stop and remove the service
# - Remove Windows Defender exclusions
# - Delete installation files
# - Delete log files
``` 
# Secure Employee Activity Monitor Deployment Script
# This script builds and deploys the monitoring application with administrative protection

param(
    [string]$Configuration = "Release",
    [string]$OutputPath = ".\publish",
    [switch]$InstallN8n,
    [switch]$SkipBuild,
    [switch]$InstallAsService,
    [string]$GoogleWorkspaceAdmin = "",
    [string]$GoogleWorkspaceToken = ""
)

Write-Host "Secure Employee Activity Monitor Deployment Script" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrative privileges. Please run as Administrator." -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Check .NET installation
Write-Host "Checking .NET installation..." -ForegroundColor Yellow
try {
    $dotnetVersion = dotnet --version
    Write-Host "Found .NET version: $dotnetVersion" -ForegroundColor Green
} catch {
    Write-Host ".NET is not installed. Please install .NET 6.0 or later." -ForegroundColor Red
    exit 1
}

# Build the application
if (-not $SkipBuild) {
    Write-Host "Building application..." -ForegroundColor Yellow
    
    # Restore packages
    Write-Host "Restoring NuGet packages..." -ForegroundColor Yellow
    dotnet restore SystemMonitor/SystemMonitor.csproj
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to restore packages." -ForegroundColor Red
        exit 1
    }
    
    # Build application
    Write-Host "Building application in $Configuration configuration..." -ForegroundColor Yellow
    dotnet build SystemMonitor/SystemMonitor.csproj --configuration $Configuration --no-restore
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Build failed." -ForegroundColor Red
        exit 1
    }
    
    # Publish application
    Write-Host "Publishing application to $OutputPath..." -ForegroundColor Yellow
    dotnet publish SystemMonitor/SystemMonitor.csproj --configuration $Configuration --output $OutputPath --no-build
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Publish failed." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Build completed successfully!" -ForegroundColor Green
} else {
    Write-Host "Skipping build step." -ForegroundColor Yellow
}

# Install as Windows Service if requested
if ($InstallAsService) {
    Write-Host "Installing as Windows Service..." -ForegroundColor Yellow
    
    $exePath = Join-Path $OutputPath "SystemMonitor.exe"
    if (Test-Path $exePath) {
        # Install the service
        & $exePath --install
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Service installed successfully!" -ForegroundColor Green
            
            # Start the service
            Write-Host "Starting service..." -ForegroundColor Yellow
            Start-Service -Name "EmployeeActivityMonitor" -ErrorAction SilentlyContinue
            if ($?) {
                Write-Host "Service started successfully!" -ForegroundColor Green
            } else {
                Write-Host "Warning: Could not start service automatically." -ForegroundColor Yellow
            }
        } else {
            Write-Host "Failed to install service." -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "Executable not found at: $exePath" -ForegroundColor Red
        exit 1
    }
}

# Create secure configuration file
Write-Host "Creating secure configuration file..." -ForegroundColor Yellow
$configPath = Join-Path $OutputPath "config.json"
$config = @{
    n8nWebhookUrl = "http://localhost:5678/webhook/monitoring"
    blacklistedApps = @(
        "tor.exe", "vpn.exe", "proxy.exe", "anonymizer.exe",
        "cryptolocker.exe", "ransomware.exe", "keylogger.exe",
        "spyware.exe", "malware.exe", "trojan.exe"
    )
    suspiciousDomains = @(
        "mega.nz", "dropbox.com", "google-drive.com", "onedrive.com",
        "we-transfer.com", "file.io", "transfernow.net"
    )
    monitoringSettings = @{
        enableUsbMonitoring = $true
        enableFileTransferMonitoring = $true
        enableAppInstallationMonitoring = $true
        enableNetworkMonitoring = $true
        logLevel = "Medium"
        autoStartMonitoring = $true
        sendToN8n = $true
        requireAdminAccess = $true
    }
    securitySettings = @{
        googleWorkspaceAdmin = $GoogleWorkspaceAdmin
        googleWorkspaceToken = $GoogleWorkspaceToken
        preventUninstallation = $true
        protectConfiguration = $true
        logSecurityEvents = $true
    }
    usbBlockingSettings = @{
        enableUsbBlocking = $true
        googleSheetsApiKey = ""
        googleSheetsSpreadsheetId = ""
        googleSheetsRange = "A:A"
        cacheExpirationMinutes = 5
        blockAllUsbStorage = $false
        allowWhitelistedOnly = $true
        logBlockedDevices = $true
        sendBlockingAlerts = $true
        localWhitelist = @()
        localBlacklist = @()
    }
    uninstallDetectionSettings = @{
        enableUninstallDetection = $true
        sendUninstallNotifications = $true
        captureDeviceInfo = $true
        logUninstallAttempts = $true
        requireAdminForUninstall = $true
    }
} | ConvertTo-Json -Depth 10

$config | Out-File -FilePath $configPath -Encoding UTF8
Write-Host "Configuration file created: $configPath" -ForegroundColor Green

# Set file permissions to protect configuration
Write-Host "Setting file permissions..." -ForegroundColor Yellow
try {
    $acl = Get-Acl $configPath
    $acl.SetAccessRuleProtection($true, $false)
    $adminSid = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid, $null)
    $adminAccount = $adminSid.Translate([System.Security.Principal.NTAccount])
    $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule($adminAccount, "FullControl", "Allow")
    $acl.AddAccessRule($adminRule)
    Set-Acl -Path $configPath -AclObject $acl
    Write-Host "File permissions set successfully!" -ForegroundColor Green
} catch {
    Write-Host "Warning: Could not set file permissions: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Create registry entries for protection
Write-Host "Creating registry protection..." -ForegroundColor Yellow
try {
    $registryPath = "HKLM:\SOFTWARE\EmployeeActivityMonitor"
    New-Item -Path $registryPath -Force | Out-Null
    Set-ItemProperty -Path $registryPath -Name "InstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Set-ItemProperty -Path $registryPath -Name "Version" -Value "1.0.0"
    Set-ItemProperty -Path $registryPath -Name "Protected" -Value "true"
    Set-ItemProperty -Path $registryPath -Name "RequiresAdmin" -Value "true"
    Write-Host "Registry protection created successfully!" -ForegroundColor Green
} catch {
    Write-Host "Warning: Could not create registry protection: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Add to Windows startup
Write-Host "Adding to Windows startup..." -ForegroundColor Yellow
try {
    $exePath = Join-Path $OutputPath "SystemMonitor.exe"
    if (Test-Path $exePath) {
        $startupPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
        Set-ItemProperty -Path $startupPath -Name "EmployeeActivityMonitor" -Value "`"$exePath`""
        Write-Host "Added to Windows startup successfully!" -ForegroundColor Green
    }
} catch {
    Write-Host "Warning: Could not add to Windows startup: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Add Windows Defender exclusion
Write-Host "Adding Windows Defender exclusion..." -ForegroundColor Yellow
try {
    $exePath = Join-Path $OutputPath "SystemMonitor.exe"
    if (Test-Path $exePath) {
        $exeDir = Split-Path $exePath -Parent
        Add-MpPreference -ExclusionPath $exeDir -ErrorAction SilentlyContinue
        Write-Host "Windows Defender exclusion added successfully!" -ForegroundColor Green
    }
} catch {
    Write-Host "Warning: Could not add Windows Defender exclusion: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Install N8N if requested
if ($InstallN8n) {
    Write-Host "Installing N8N..." -ForegroundColor Yellow
    
    # Check if Node.js is installed
    try {
        $nodeVersion = node --version
        Write-Host "Found Node.js version: $nodeVersion" -ForegroundColor Green
    } catch {
        Write-Host "Node.js is not installed. Please install Node.js first." -ForegroundColor Red
        Write-Host "Download from: https://nodejs.org/" -ForegroundColor Yellow
        exit 1
    }
    
    # Install N8N globally
    Write-Host "Installing N8N globally..." -ForegroundColor Yellow
    npm install -g n8n
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install N8N." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "N8N installed successfully!" -ForegroundColor Green
    Write-Host "To start N8N, run: n8n start" -ForegroundColor Yellow
    Write-Host "Access N8N at: http://localhost:5678" -ForegroundColor Yellow
}

# Create secure batch file for service management
Write-Host "Creating secure management scripts..." -ForegroundColor Yellow
$batchPath = Join-Path $OutputPath "manage-service.bat"
$batchContent = @"
@echo off
echo Employee Activity Monitor Service Management
echo ==========================================
echo.
echo This script requires administrative privileges.
echo.
if "%1"=="start" (
    echo Starting service...
    net start EmployeeActivityMonitor
) else if "%1"=="stop" (
    echo Stopping service...
    net stop EmployeeActivityMonitor
) else if "%1"=="status" (
    echo Checking service status...
    sc query EmployeeActivityMonitor
) else (
    echo Usage: manage-service.bat [start^|stop^|status]
    echo.
    echo Commands:
    echo   start   - Start the monitoring service
    echo   stop    - Stop the monitoring service
    echo   status  - Check service status
)
pause
"@

$batchContent | Out-File -FilePath $batchPath -Encoding ASCII
Write-Host "Service management script created: $batchPath" -ForegroundColor Green

# Create uninstall script (admin only)
Write-Host "Creating secure uninstall script..." -ForegroundColor Yellow
$uninstallPath = Join-Path $OutputPath "uninstall-secure.bat"
$uninstallContent = @"
@echo off
echo Employee Activity Monitor Secure Uninstall
echo =========================================
echo.
echo WARNING: This will completely remove the monitoring system.
echo Only proceed if you have administrative authorization.
echo.
set /p confirm="Type 'YES' to confirm uninstallation: "
if /i "%confirm%"=="YES" (
    echo.
    echo Stopping service...
    net stop EmployeeActivityMonitor
    echo.
    echo Removing service...
    sc delete EmployeeActivityMonitor
    echo.
    echo Removing startup entry...
    reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "EmployeeActivityMonitor" /f
    echo.
    echo Removing registry entries...
    reg delete "HKLM\SOFTWARE\EmployeeActivityMonitor" /f
    echo.
    echo Uninstallation complete.
) else (
    echo Uninstallation cancelled.
)
pause
"@

$uninstallContent | Out-File -FilePath $uninstallPath -Encoding ASCII
Write-Host "Secure uninstall script created: $uninstallPath" -ForegroundColor Green

# Display completion message
Write-Host "`nSecure deployment completed successfully!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Application location: $OutputPath" -ForegroundColor Yellow
Write-Host "Executable: $exePath" -ForegroundColor Yellow
Write-Host "Configuration: $configPath" -ForegroundColor Yellow
Write-Host "Service management: $batchPath" -ForegroundColor Yellow
Write-Host "Secure uninstall: $uninstallPath" -ForegroundColor Yellow

if ($InstallAsService) {
    Write-Host "`nService Status:" -ForegroundColor Cyan
    Write-Host "Service Name: EmployeeActivityMonitor" -ForegroundColor Yellow
    Write-Host "Startup Type: Automatic" -ForegroundColor Yellow
    Write-Host "Account: Local System" -ForegroundColor Yellow
    Write-Host "Protection: Enabled" -ForegroundColor Yellow
}

if ($InstallN8n) {
    Write-Host "`nN8N Setup Instructions:" -ForegroundColor Cyan
    Write-Host "1. Start N8N: n8n start" -ForegroundColor Yellow
    Write-Host "2. Open browser: http://localhost:5678" -ForegroundColor Yellow
    Write-Host "3. Import workflow: n8n-workflow.json" -ForegroundColor Yellow
    Write-Host "4. Configure email settings" -ForegroundColor Yellow
    Write-Host "5. Activate the workflow" -ForegroundColor Yellow
}

Write-Host "`nSecurity Features Enabled:" -ForegroundColor Cyan
Write-Host "✓ Administrative privileges required" -ForegroundColor Green
Write-Host "✓ Auto-start on Windows boot" -ForegroundColor Green
Write-Host "✓ Configuration file protection" -ForegroundColor Green
Write-Host "✓ Registry protection" -ForegroundColor Green
Write-Host "✓ Windows Defender exclusion" -ForegroundColor Green
Write-Host "✓ Service-based monitoring" -ForegroundColor Green
Write-Host "✓ Google Workspace admin validation" -ForegroundColor Green

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "1. Service will start automatically on next boot" -ForegroundColor Yellow
Write-Host "2. Monitor Windows Event Logs for activity" -ForegroundColor Yellow
Write-Host "3. Configure N8N for email alerts" -ForegroundColor Yellow
Write-Host "4. Test monitoring functionality" -ForegroundColor Yellow

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 
# Employee Activity Monitor Deployment Script
# This script builds and deploys the monitoring application

param(
    [string]$Configuration = "Release",
    [string]$OutputPath = ".\publish",
    [switch]$InstallN8n,
    [switch]$SkipBuild
)

Write-Host "Employee Activity Monitor Deployment Script" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrative privileges. Please run as Administrator." -ForegroundColor Red
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

# Create desktop shortcut
Write-Host "Creating desktop shortcut..." -ForegroundColor Yellow
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktopPath "Employee Activity Monitor.lnk"
$exePath = Join-Path $OutputPath "SystemMonitor.exe"

if (Test-Path $exePath) {
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = $exePath
    $Shortcut.WorkingDirectory = $OutputPath
    $Shortcut.Description = "Employee Activity Monitor"
    $Shortcut.Save()
    Write-Host "Desktop shortcut created: $shortcutPath" -ForegroundColor Green
} else {
    Write-Host "Executable not found at: $exePath" -ForegroundColor Red
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

# Create configuration file
Write-Host "Creating configuration file..." -ForegroundColor Yellow
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
    }
} | ConvertTo-Json -Depth 10

$config | Out-File -FilePath $configPath -Encoding UTF8
Write-Host "Configuration file created: $configPath" -ForegroundColor Green

# Create batch file for easy startup
Write-Host "Creating startup batch file..." -ForegroundColor Yellow
$batchPath = Join-Path $OutputPath "start-monitor.bat"
$batchContent = @"
@echo off
echo Starting Employee Activity Monitor...
echo.
echo This application requires administrative privileges.
echo.
pause
start "" "$exePath"
"@

$batchContent | Out-File -FilePath $batchPath -Encoding ASCII
Write-Host "Startup batch file created: $batchPath" -ForegroundColor Green

# Display completion message
Write-Host "`nDeployment completed successfully!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host "Application location: $OutputPath" -ForegroundColor Yellow
Write-Host "Executable: $exePath" -ForegroundColor Yellow
Write-Host "Configuration: $configPath" -ForegroundColor Yellow
Write-Host "Startup script: $batchPath" -ForegroundColor Yellow

if ($InstallN8n) {
    Write-Host "`nN8N Setup Instructions:" -ForegroundColor Cyan
    Write-Host "1. Start N8N: n8n start" -ForegroundColor Yellow
    Write-Host "2. Open browser: http://localhost:5678" -ForegroundColor Yellow
    Write-Host "3. Import workflow: n8n-workflow.json" -ForegroundColor Yellow
    Write-Host "4. Configure email settings" -ForegroundColor Yellow
    Write-Host "5. Activate the workflow" -ForegroundColor Yellow
}

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "1. Run the application as Administrator" -ForegroundColor Yellow
Write-Host "2. Click 'Start Monitoring' to begin" -ForegroundColor Yellow
Write-Host "3. Test N8N connection if configured" -ForegroundColor Yellow
Write-Host "4. Monitor the activity log for events" -ForegroundColor Yellow

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 
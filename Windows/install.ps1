# Employee Activity Monitor Installation Script
# Run as Administrator

param(
    [string]$InstallPath = "C:\Program Files\EmployeeActivityMonitor",
    [string]$ServiceName = "EmployeeActivityMonitor",
    [string]$DisplayName = "Employee Activity Monitor"
)

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator"
    exit 1
}

Write-Host "=== Employee Activity Monitor Installation ===" -ForegroundColor Cyan

# Step 1: Create installation directory
Write-Host "Creating installation directory..." -ForegroundColor Yellow
if (!(Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    Write-Host "✓ Installation directory created: $InstallPath" -ForegroundColor Green
} else {
    Write-Host "✓ Installation directory already exists: $InstallPath" -ForegroundColor Green
}

# Step 2: Copy application files
Write-Host "Copying application files..." -ForegroundColor Yellow
$currentDir = Get-Location
$files = Get-ChildItem -Path $currentDir -File | Where-Object { $_.Name -notlike "install.ps1" }
foreach ($file in $files) {
    Copy-Item -Path $file.FullName -Destination $InstallPath -Force
    Write-Host "  ✓ Copied: $($file.Name)" -ForegroundColor Green
}

# Step 3: Create log directory
Write-Host "Creating log directory..." -ForegroundColor Yellow
$logPath = "C:\ProgramData\EmployeeActivityMonitor\logs"
if (!(Test-Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath -Force | Out-Null
    Write-Host "✓ Log directory created: $logPath" -ForegroundColor Green
} else {
    Write-Host "✓ Log directory already exists: $logPath" -ForegroundColor Green
}

# Step 4: Create configuration file if it doesn't exist
Write-Host "Setting up configuration..." -ForegroundColor Yellow
$configPath = "$InstallPath\config.json"
if (!(Test-Path $configPath)) {
    $defaultConfig = @{
        monitoringSettings = @{
            enableUsbMonitoring = $true
            enableFileTransferMonitoring = $true
            enableAppInstallationMonitoring = $true
            enableNetworkMonitoring = $true
            enableUninstallDetection = $true
        }
        notificationSettings = @{
            enableEmailNotifications = $true
            n8nWebhookUrl = "http://your-n8n-server:5678/webhook/monitoring"
            adminEmail = "admin@yourcompany.com"
        }
        securitySettings = @{
            requireAdminPrivileges = $true
            preventUninstallation = $true
            enableConfigurationProtection = $true
        }
        usbSettings = @{
            blockAllUsbDevices = $true
            googleSheetsWhitelistUrl = "https://docs.google.com/spreadsheets/d/your-sheet-id/edit"
            allowedUsbDevices = @()
        }
        loggingSettings = @{
            logLevel = "Info"
            enableEnhancedLogging = $true
            logRotationSizeMB = 10
            maxLogFiles = 5
        }
    }
    
    $defaultConfig | ConvertTo-Json -Depth 10 | Set-Content $configPath
    Write-Host "✓ Default configuration created: $configPath" -ForegroundColor Green
} else {
    Write-Host "✓ Configuration file already exists: $configPath" -ForegroundColor Green
}

# Step 5: Stop and remove existing service if it exists
Write-Host "Checking for existing service..." -ForegroundColor Yellow
if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
    Write-Host "Stopping existing service..." -ForegroundColor Yellow
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    Write-Host "Removing existing service..." -ForegroundColor Yellow
    sc.exe delete $ServiceName | Out-Null
    Write-Host "✓ Existing service removed" -ForegroundColor Green
}

# Step 6: Create Windows Service
Write-Host "Creating Windows Service..." -ForegroundColor Yellow
$exePath = "$InstallPath\SystemMonitor.exe"
if (Test-Path $exePath) {
    sc.exe create $ServiceName binPath= "`"$exePath`"" start= auto DisplayName= $DisplayName
    sc.exe description $ServiceName "Employee Activity Monitoring Service - Monitors USB connections, file transfers, and application installations"
    Write-Host "✓ Windows Service created: $ServiceName" -ForegroundColor Green
} else {
    Write-Error "Executable not found: $exePath"
    exit 1
}

# Step 7: Set service recovery options
Write-Host "Configuring service recovery..." -ForegroundColor Yellow
sc.exe failure $ServiceName reset= 86400 actions= restart/60000/restart/60000/restart/60000
Write-Host "✓ Service recovery configured" -ForegroundColor Green

# Step 8: Add Windows Defender exclusions
Write-Host "Adding Windows Defender exclusions..." -ForegroundColor Yellow
try {
    Add-MpPreference -ExclusionPath $InstallPath -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionProcess "SystemMonitor.exe" -ErrorAction SilentlyContinue
    Write-Host "✓ Windows Defender exclusions added" -ForegroundColor Green
} catch {
    Write-Host "⚠ Windows Defender exclusions could not be added (may not be available)" -ForegroundColor Yellow
}

# Step 9: Start the service
Write-Host "Starting the service..." -ForegroundColor Yellow
Start-Service -Name $ServiceName
if ((Get-Service -Name $ServiceName).Status -eq "Running") {
    Write-Host "✓ Service started successfully" -ForegroundColor Green
} else {
    Write-Error "Failed to start service"
    exit 1
}

# Step 10: Create uninstall script
Write-Host "Creating uninstall script..." -ForegroundColor Yellow
$uninstallScript = @"
# Employee Activity Monitor Uninstall Script
# Run as Administrator

param(
    [string]`$ServiceName = "EmployeeActivityMonitor",
    [string]`$InstallPath = "C:\Program Files\EmployeeActivityMonitor"
)

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator"
    exit 1
}

Write-Host "=== Employee Activity Monitor Uninstallation ===" -ForegroundColor Cyan

# Stop and remove service
if (Get-Service -Name `$ServiceName -ErrorAction SilentlyContinue) {
    Write-Host "Stopping service..." -ForegroundColor Yellow
    Stop-Service -Name `$ServiceName -Force
    Write-Host "Removing service..." -ForegroundColor Yellow
    sc.exe delete `$ServiceName
    Write-Host "✓ Service removed" -ForegroundColor Green
}

# Remove Windows Defender exclusions
try {
    Remove-MpPreference -ExclusionPath `$InstallPath -ErrorAction SilentlyContinue
    Remove-MpPreference -ExclusionProcess "SystemMonitor.exe" -ErrorAction SilentlyContinue
    Write-Host "✓ Windows Defender exclusions removed" -ForegroundColor Green
} catch {
    Write-Host "⚠ Windows Defender exclusions could not be removed" -ForegroundColor Yellow
}

# Remove installation directory
if (Test-Path `$InstallPath) {
    Write-Host "Removing installation directory..." -ForegroundColor Yellow
    Remove-Item -Path `$InstallPath -Recurse -Force
    Write-Host "✓ Installation directory removed" -ForegroundColor Green
}

# Remove log directory
`$logPath = "C:\ProgramData\EmployeeActivityMonitor"
if (Test-Path `$logPath) {
    Write-Host "Removing log directory..." -ForegroundColor Yellow
    Remove-Item -Path `$logPath -Recurse -Force
    Write-Host "✓ Log directory removed" -ForegroundColor Green
}

Write-Host "✓ Uninstallation completed successfully!" -ForegroundColor Green
"@

$uninstallScript | Out-File -FilePath "$InstallPath\uninstall.ps1" -Encoding UTF8
Write-Host "✓ Uninstall script created: $InstallPath\uninstall.ps1" -ForegroundColor Green

# Step 11: Create verification script
Write-Host "Creating verification script..." -ForegroundColor Yellow
$verifyScript = @"
# Employee Activity Monitor Verification Script

param(
    [string]`$ServiceName = "EmployeeActivityMonitor",
    [string]`$InstallPath = "C:\Program Files\EmployeeActivityMonitor"
)

Write-Host "=== Employee Activity Monitor Verification ===" -ForegroundColor Cyan

# Check service status
Write-Host "Service Status:" -ForegroundColor Yellow
`$service = Get-Service -Name `$ServiceName -ErrorAction SilentlyContinue
if (`$service) {
    Write-Host "  ✓ Service exists" -ForegroundColor Green
    Write-Host "  Status: `$(`$service.Status)" -ForegroundColor Green
    Write-Host "  Start Type: `$(`$service.StartType)" -ForegroundColor Green
} else {
    Write-Host "  ✗ Service not found" -ForegroundColor Red
}

# Check installation directory
Write-Host "Installation Directory:" -ForegroundColor Yellow
if (Test-Path `$InstallPath) {
    Write-Host "  ✓ Installation directory exists" -ForegroundColor Green
    `$files = Get-ChildItem -Path `$InstallPath -File
    Write-Host "  Files: `$(`$files.Count)" -ForegroundColor Green
} else {
    Write-Host "  ✗ Installation directory not found" -ForegroundColor Red
}

# Check log directory
Write-Host "Log Directory:" -ForegroundColor Yellow
`$logPath = "C:\ProgramData\EmployeeActivityMonitor\logs"
if (Test-Path `$logPath) {
    Write-Host "  ✓ Log directory exists" -ForegroundColor Green
    `$logs = Get-ChildItem -Path `$logPath -File
    Write-Host "  Log files: `$(`$logs.Count)" -ForegroundColor Green
} else {
    Write-Host "  ✗ Log directory not found" -ForegroundColor Red
}

# Check configuration
Write-Host "Configuration:" -ForegroundColor Yellow
`$configPath = "`$InstallPath\config.json"
if (Test-Path `$configPath) {
    Write-Host "  ✓ Configuration file exists" -ForegroundColor Green
    try {
        `$config = Get-Content `$configPath | ConvertFrom-Json
        Write-Host "  USB Monitoring: `$(`$config.monitoringSettings.enableUsbMonitoring)" -ForegroundColor Green
        Write-Host "  File Transfer Monitoring: `$(`$config.monitoringSettings.enableFileTransferMonitoring)" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠ Configuration file could not be parsed" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ✗ Configuration file not found" -ForegroundColor Red
}

# Check Windows Defender exclusions
Write-Host "Windows Defender Exclusions:" -ForegroundColor Yellow
try {
    `$exclusions = Get-MpPreference
    `$pathExcluded = `$exclusions.ExclusionPath -contains `$InstallPath
    `$processExcluded = `$exclusions.ExclusionProcess -contains "SystemMonitor.exe"
    Write-Host "  Path excluded: `$pathExcluded" -ForegroundColor `$(if (`$pathExcluded) { "Green" } else { "Red" })
    Write-Host "  Process excluded: `$processExcluded" -ForegroundColor `$(if (`$processExcluded) { "Green" } else { "Red" })
} catch {
    Write-Host "  ⚠ Could not check Windows Defender exclusions" -ForegroundColor Yellow
}

Write-Host "=== Verification Complete ===" -ForegroundColor Cyan
"@

$verifyScript | Out-File -FilePath "$InstallPath\verify.ps1" -Encoding UTF8
Write-Host "✓ Verification script created: $InstallPath\verify.ps1" -ForegroundColor Green

# Step 12: Final verification
Write-Host "Performing final verification..." -ForegroundColor Yellow
& "$InstallPath\verify.ps1"

Write-Host "=== Installation Completed Successfully! ===" -ForegroundColor Green
Write-Host "Installation Path: $InstallPath" -ForegroundColor Cyan
Write-Host "Service Name: $ServiceName" -ForegroundColor Cyan
Write-Host "Log Path: $logPath" -ForegroundColor Cyan
Write-Host "Configuration: $configPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "To uninstall, run: $InstallPath\uninstall.ps1" -ForegroundColor Yellow
Write-Host "To verify installation, run: $InstallPath\verify.ps1" -ForegroundColor Yellow 
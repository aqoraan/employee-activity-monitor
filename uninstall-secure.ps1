# Secure Uninstall Script for Employee Activity Monitor
# This script sends device information to admin before uninstalling

param(
    [switch]$Force,
    [switch]$SkipNotification,
    [string]$AdminEmail = "admin@yourcompany.com"
)

Write-Host "Secure Uninstall Script - Employee Activity Monitor" -ForegroundColor Red
Write-Host "==================================================" -ForegroundColor Red

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrative privileges. Please run as Administrator." -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Get device information
Write-Host "Gathering device information..." -ForegroundColor Yellow

function Get-DeviceInfo {
    $deviceInfo = @{
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
        SerialNumber = "Unknown"
        MacAddresses = @()
        BiosSerialNumber = "Unknown"
        MotherboardSerialNumber = "Unknown"
        WindowsProductId = "Unknown"
        InstallationPath = "Unknown"
    }

    try {
        # Get system serial number
        $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
        $deviceInfo.SerialNumber = $computerSystem.SerialNumber

        # Get MAC addresses
        $networkAdapters = Get-WmiObject -Class Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -eq $true }
        foreach ($adapter in $networkAdapters) {
            if ($adapter.MACAddress) {
                $deviceInfo.MacAddresses += $adapter.MACAddress
            }
        }

        # Get BIOS serial number
        $bios = Get-WmiObject -Class Win32_BIOS
        $deviceInfo.BiosSerialNumber = $bios.SerialNumber

        # Get motherboard serial number
        $baseBoard = Get-WmiObject -Class Win32_BaseBoard
        $deviceInfo.MotherboardSerialNumber = $baseBoard.SerialNumber

        # Get Windows Product ID
        $productId = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductId).ProductId
        $deviceInfo.WindowsProductId = $productId

        # Get installation path
        $service = Get-Service -Name "EmployeeActivityMonitor" -ErrorAction SilentlyContinue
        if ($service) {
            $deviceInfo.InstallationPath = $service.BinaryPathName
        }
    }
    catch {
        Write-Host "Warning: Could not gather complete device information: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    return $deviceInfo
}

$deviceInfo = Get-DeviceInfo

# Display device information
Write-Host "Device Information:" -ForegroundColor Cyan
Write-Host "  Computer Name: $($deviceInfo.ComputerName)" -ForegroundColor White
Write-Host "  User Name: $($deviceInfo.UserName)" -ForegroundColor White
Write-Host "  Serial Number: $($deviceInfo.SerialNumber)" -ForegroundColor White
Write-Host "  Primary MAC Address: $($deviceInfo.MacAddresses[0])" -ForegroundColor White
Write-Host "  BIOS Serial Number: $($deviceInfo.BiosSerialNumber)" -ForegroundColor White
Write-Host "  Motherboard Serial Number: $($deviceInfo.MotherboardSerialNumber)" -ForegroundColor White
Write-Host "  Windows Product ID: $($deviceInfo.WindowsProductId)" -ForegroundColor White
Write-Host "  Installation Path: $($deviceInfo.InstallationPath)" -ForegroundColor White

if ($deviceInfo.MacAddresses.Count -gt 1) {
    Write-Host "  All MAC Addresses:" -ForegroundColor White
    for ($i = 0; $i -lt $deviceInfo.MacAddresses.Count; $i++) {
        Write-Host "    $($i + 1). $($deviceInfo.MacAddresses[$i])" -ForegroundColor White
    }
}

# Send uninstall notification if not skipped
if (-not $SkipNotification) {
    Write-Host "`nSending uninstall notification..." -ForegroundColor Yellow
    
    try {
        # Create notification data
        $notificationData = @{
            eventType = "UninstallDetected"
            timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            severity = "Critical"
            computer = $deviceInfo.ComputerName
            user = $deviceInfo.UserName
            deviceInfo = @{
                serialNumber = $deviceInfo.SerialNumber
                primaryMacAddress = $deviceInfo.MacAddresses[0]
                allMacAddresses = $deviceInfo.MacAddresses
                biosSerialNumber = $deviceInfo.BiosSerialNumber
                motherboardSerialNumber = $deviceInfo.MotherboardSerialNumber
                windowsProductId = $deviceInfo.WindowsProductId
                installationPath = $deviceInfo.InstallationPath
                deviceFingerprint = "$($deviceInfo.ComputerName)_$($deviceInfo.SerialNumber)_$($deviceInfo.MacAddresses[0])"
            }
            uninstallDetails = @{
                processId = $PID
                processName = "PowerShell"
                commandLine = $MyInvocation.Line
                uninstallTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
        }

        # Convert to JSON
        $json = $notificationData | ConvertTo-Json -Depth 10

        # Send to N8N webhook
        $webhookUrl = "http://localhost:5678/webhook/monitoring"
        $headers = @{
            "Content-Type" = "application/json"
        }

        $response = Invoke-RestMethod -Uri $webhookUrl -Method POST -Body $json -Headers $headers -ErrorAction Stop
        
        Write-Host "Uninstall notification sent successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Failed to send uninstall notification: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "Continuing with uninstallation..." -ForegroundColor Yellow
    }
}

# Confirm uninstallation
if (-not $Force) {
    Write-Host "`n⚠️  WARNING: This will completely remove the Employee Activity Monitor software." -ForegroundColor Red
    Write-Host "All monitoring and security features will be disabled." -ForegroundColor Red
    Write-Host "`nDevice information has been captured and sent to administrators." -ForegroundColor Yellow
    
    $confirm = Read-Host "`nType 'YES' to confirm uninstallation"
    if ($confirm -ne "YES") {
        Write-Host "Uninstallation cancelled." -ForegroundColor Green
        exit 0
    }
}

Write-Host "`nStarting secure uninstallation..." -ForegroundColor Yellow

# Stop the service
Write-Host "Stopping Employee Activity Monitor service..." -ForegroundColor Yellow
try {
    Stop-Service -Name "EmployeeActivityMonitor" -Force -ErrorAction Stop
    Write-Host "Service stopped successfully." -ForegroundColor Green
}
catch {
    Write-Host "Warning: Could not stop service: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Remove the service
Write-Host "Removing Windows service..." -ForegroundColor Yellow
try {
    $servicePath = Get-Service -Name "EmployeeActivityMonitor" -ErrorAction SilentlyContinue
    if ($servicePath) {
        $binaryPath = $servicePath.BinaryPathName
        if ($binaryPath) {
            # Run the uninstall command
            & $binaryPath --uninstall
        }
    }
    
    # Remove service using sc command
    sc.exe delete "EmployeeActivityMonitor" | Out-Null
    Write-Host "Service removed successfully." -ForegroundColor Green
}
catch {
    Write-Host "Warning: Could not remove service: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Remove startup entry
Write-Host "Removing startup entry..." -ForegroundColor Yellow
try {
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "EmployeeActivityMonitor" -ErrorAction SilentlyContinue
    Write-Host "Startup entry removed." -ForegroundColor Green
}
catch {
    Write-Host "Warning: Could not remove startup entry: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Remove registry entries
Write-Host "Removing registry entries..." -ForegroundColor Yellow
try {
    Remove-Item -Path "HKLM:\SOFTWARE\EmployeeActivityMonitor" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Registry entries removed." -ForegroundColor Green
}
catch {
    Write-Host "Warning: Could not remove registry entries: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Remove Windows Defender exclusion
Write-Host "Removing Windows Defender exclusion..." -ForegroundColor Yellow
try {
    $exePath = $deviceInfo.InstallationPath
    if ($exePath -and $exePath -ne "Unknown") {
        $exeDir = Split-Path $exePath -Parent
        Remove-MpPreference -ExclusionPath $exeDir -ErrorAction SilentlyContinue
        Write-Host "Windows Defender exclusion removed." -ForegroundColor Green
    }
}
catch {
    Write-Host "Warning: Could not remove Windows Defender exclusion: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Remove application files
Write-Host "Removing application files..." -ForegroundColor Yellow
try {
    $installPath = $deviceInfo.InstallationPath
    if ($installPath -and $installPath -ne "Unknown") {
        $appDir = Split-Path $installPath -Parent
        if (Test-Path $appDir) {
            Remove-Item -Path $appDir -Recurse -Force -ErrorAction Stop
            Write-Host "Application files removed." -ForegroundColor Green
        }
    }
}
catch {
    Write-Host "Warning: Could not remove application files: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Clean up uninstall detection files
Write-Host "Cleaning up detection files..." -ForegroundColor Yellow
try {
    $uninstallFlagPath = "$env:ProgramData\EmployeeActivityMonitor\uninstall_detected.flag"
    if (Test-Path $uninstallFlagPath) {
        Remove-Item -Path $uninstallFlagPath -Force -ErrorAction SilentlyContinue
    }
    
    $monitorDir = "$env:ProgramData\EmployeeActivityMonitor"
    if (Test-Path $monitorDir) {
        Remove-Item -Path $monitorDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Host "Detection files cleaned up." -ForegroundColor Green
}
catch {
    Write-Host "Warning: Could not clean up detection files: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n✅ Uninstallation completed successfully!" -ForegroundColor Green
Write-Host "Device information has been sent to administrators for tracking." -ForegroundColor Yellow
Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 
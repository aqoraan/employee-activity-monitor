# Employee Activity Monitor Build Script
# This script builds the Windows application for deployment

param(
    [string]$Configuration = "Release",
    [string]$OutputPath = ".\publish",
    [string]$Runtime = "win-x64"
)

Write-Host "=== Employee Activity Monitor Build Script ===" -ForegroundColor Cyan

# Check if .NET is installed
Write-Host "Checking .NET installation..." -ForegroundColor Yellow
try {
    $dotnetVersion = dotnet --version
    Write-Host "✓ .NET version: $dotnetVersion" -ForegroundColor Green
} catch {
    Write-Error ".NET is not installed. Please install .NET 6.0 SDK or later."
    Write-Host "Download from: https://dotnet.microsoft.com/download/dotnet/6.0" -ForegroundColor Yellow
    exit 1
}

# Navigate to the SystemMonitor directory
$projectPath = ".\SystemMonitor"
if (!(Test-Path $projectPath)) {
    Write-Error "SystemMonitor directory not found. Please run this script from the project root."
    exit 1
}

Set-Location $projectPath
Write-Host "Working directory: $(Get-Location)" -ForegroundColor Yellow

# Clean previous builds
Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
dotnet clean --configuration $Configuration
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to clean project"
    exit 1
}
Write-Host "✓ Clean completed" -ForegroundColor Green

# Restore packages
Write-Host "Restoring packages..." -ForegroundColor Yellow
dotnet restore
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to restore packages"
    exit 1
}
Write-Host "✓ Packages restored" -ForegroundColor Green

# Build the project
Write-Host "Building project..." -ForegroundColor Yellow
dotnet build --configuration $Configuration --no-restore
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to build project"
    exit 1
}
Write-Host "✓ Build completed" -ForegroundColor Green

# Publish the application
Write-Host "Publishing application..." -ForegroundColor Yellow
dotnet publish --configuration $Configuration --output $OutputPath --runtime $Runtime --self-contained true --publish-single-file false
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to publish application"
    exit 1
}
Write-Host "✓ Publish completed" -ForegroundColor Green

# Copy installation script to output directory
Write-Host "Copying installation script..." -ForegroundColor Yellow
$installScriptPath = "..\Windows\install.ps1"
if (Test-Path $installScriptPath) {
    Copy-Item $installScriptPath -Destination $OutputPath -Force
    Write-Host "✓ Installation script copied" -ForegroundColor Green
} else {
    Write-Host "⚠ Installation script not found at: $installScriptPath" -ForegroundColor Yellow
}

# Create a simple README for the deployment
Write-Host "Creating deployment README..." -ForegroundColor Yellow
$readmeContent = @"
# Employee Activity Monitor - Windows Deployment

## Installation Instructions

1. **Prerequisites:**
   - Windows 10/11
   - .NET 6.0 Runtime (if not self-contained)
   - Administrator privileges

2. **Installation:**
   ```powershell
   # Open PowerShell as Administrator
   cd "$(Split-Path $OutputPath -Leaf)"
   .\install.ps1
   ```

3. **Verification:**
   ```powershell
   .\verify.ps1
   ```

4. **Uninstallation:**
   ```powershell
   .\uninstall.ps1
   ```

## Files Included:
- SystemMonitor.exe - Main application executable
- SystemMonitor.dll - Application library
- SystemMonitor.runtimeconfig.json - Runtime configuration
- install.ps1 - Installation script
- verify.ps1 - Verification script (created during installation)
- uninstall.ps1 - Uninstallation script (created during installation)

## Configuration:
The application will create a default configuration file at:
`C:\Program Files\EmployeeActivityMonitor\config.json`

Edit this file to configure:
- Monitoring settings
- Notification settings
- USB blocking rules
- Logging options

## Logs:
Log files are stored at:
`C:\ProgramData\EmployeeActivityMonitor\logs\`

## Service:
The application runs as a Windows Service named "EmployeeActivityMonitor"

Build Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Runtime: $Runtime
Configuration: $Configuration
"@

$readmeContent | Out-File -FilePath "$OutputPath\README.txt" -Encoding UTF8
Write-Host "✓ Deployment README created" -ForegroundColor Green

# List files in output directory
Write-Host "`nFiles in output directory:" -ForegroundColor Cyan
Get-ChildItem -Path $OutputPath | ForEach-Object {
    $size = if ($_.PSIsContainer) { "DIR" } else { "$([math]::Round($_.Length / 1KB, 2)) KB" }
    Write-Host "  $($_.Name) ($size)" -ForegroundColor White
}

# Calculate total size
$totalSize = (Get-ChildItem -Path $OutputPath -Recurse -File | Measure-Object -Property Length -Sum).Sum
$totalSizeMB = [math]::Round($totalSize / 1MB, 2)
Write-Host "`nTotal size: $totalSizeMB MB" -ForegroundColor Cyan

Write-Host "`n=== Build Completed Successfully! ===" -ForegroundColor Green
Write-Host "Output directory: $(Resolve-Path $OutputPath)" -ForegroundColor Cyan
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Copy the entire '$OutputPath' directory to your target Windows machine" -ForegroundColor White
Write-Host "2. Open PowerShell as Administrator on the target machine" -ForegroundColor White
Write-Host "3. Navigate to the copied directory" -ForegroundColor White
Write-Host "4. Run: .\install.ps1" -ForegroundColor White 
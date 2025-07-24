# Fix Package Restore Issues Script
# This script helps resolve NuGet package restore problems

param(
    [string]$ProjectPath = ".\SystemMonitor"
)

Write-Host "=== Fixing Package Restore Issues ===" -ForegroundColor Cyan

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

# Navigate to the project directory
if (!(Test-Path $ProjectPath)) {
    Write-Error "Project directory not found: $ProjectPath"
    exit 1
}

Set-Location $ProjectPath
Write-Host "Working directory: $(Get-Location)" -ForegroundColor Yellow

# Step 1: Clear NuGet cache
Write-Host "Clearing NuGet cache..." -ForegroundColor Yellow
dotnet nuget locals all --clear
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ NuGet cache cleared" -ForegroundColor Green
} else {
    Write-Host "⚠ Failed to clear NuGet cache" -ForegroundColor Yellow
}

# Step 2: Delete existing obj and bin directories
Write-Host "Cleaning build artifacts..." -ForegroundColor Yellow
if (Test-Path "obj") {
    Remove-Item -Path "obj" -Recurse -Force
    Write-Host "✓ Removed obj directory" -ForegroundColor Green
}
if (Test-Path "bin") {
    Remove-Item -Path "bin" -Recurse -Force
    Write-Host "✓ Removed bin directory" -ForegroundColor Green
}

# Step 3: Restore packages with verbose output
Write-Host "Restoring packages..." -ForegroundColor Yellow
dotnet restore --verbosity detailed
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Packages restored successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Package restore failed" -ForegroundColor Red
    Write-Host "Trying alternative restore method..." -ForegroundColor Yellow
    
    # Try alternative restore method
    dotnet restore --force
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Packages restored with force flag" -ForegroundColor Green
    } else {
        Write-Error "Package restore failed even with force flag"
        exit 1
    }
}

# Step 4: Verify packages
Write-Host "Verifying packages..." -ForegroundColor Yellow
dotnet list package
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Package verification completed" -ForegroundColor Green
} else {
    Write-Host "⚠ Package verification failed" -ForegroundColor Yellow
}

# Step 5: Try to build
Write-Host "Testing build..." -ForegroundColor Yellow
dotnet build --no-restore
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Build test successful" -ForegroundColor Green
} else {
    Write-Host "✗ Build test failed" -ForegroundColor Red
    Write-Host "Check the error messages above for specific issues" -ForegroundColor Yellow
}

Write-Host "`n=== Package Fix Completed ===" -ForegroundColor Cyan
Write-Host "If issues persist, try:" -ForegroundColor Yellow
Write-Host "1. Update .NET SDK to latest version" -ForegroundColor White
Write-Host "2. Check internet connection for NuGet.org access" -ForegroundColor White
Write-Host "3. Try running: dotnet restore --interactive" -ForegroundColor White
Write-Host "4. Check if your organization blocks NuGet.org" -ForegroundColor White 
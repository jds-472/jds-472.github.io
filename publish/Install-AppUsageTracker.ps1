# Install-AppUsageTracker.ps1
# PowerShell script to install certificate and then the app

param(
    [switch]$Force,
    [switch]$Silent
)

Write-Host "App Usage Tracker Installation Script" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Function to test if script is running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to restart script as administrator
function Start-AsAdministrator {
    $scriptPath = $MyInvocation.MyCommand.Path
    $arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`""
    if ($Force) { $arguments += " -Force" }
    if ($Silent) { $arguments += " -Silent" }
    
    Start-Process PowerShell -Verb RunAs -ArgumentList $arguments
    exit
}

# Check if running as administrator
if (-not (Test-Administrator)) {
    Write-Warning "Administrator privileges required for certificate installation."
    
    if ($Silent) {
        Write-Host "Attempting to restart as Administrator..." -ForegroundColor Yellow
        Start-AsAdministrator
    } else {
        $restart = Read-Host "Restart as Administrator? (Y/n)"
        if ($restart -ne "n" -and $restart -ne "N") {
            Start-AsAdministrator
        } else {
            Write-Host "Continuing with limited privileges..." -ForegroundColor Yellow
        }
    }
}

try {
    # Configuration
    $baseUrl = "https://jds-472.github.io/publish"
    $certUrl = "$baseUrl/AppUsageTracker.cer"
    $appInstallerUrl = "$baseUrl/AppUsageTracker.appinstaller"
    
    # Temporary paths
    $tempDir = $env:TEMP
    $certPath = Join-Path $tempDir "AppUsageTracker.cer"
    
    Write-Host "Step 1: Downloading certificate..." -ForegroundColor Cyan
    
    # Download with progress
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($certUrl, $certPath)
    Write-Host "✓ Certificate downloaded to: $certPath" -ForegroundColor Green
    
    Write-Host "Step 2: Installing certificate..." -ForegroundColor Cyan
    
    # Try to install to LocalMachine first, fallback to CurrentUser
    $certInstalled = $false
    
    if (Test-Administrator) {
        try {
            $cert = Import-Certificate -FilePath $certPath -CertStoreLocation Cert:\LocalMachine\Root -ErrorAction Stop
            Write-Host "✓ Certificate installed to LocalMachine\Root" -ForegroundColor Green
            $certInstalled = $true
        }
        catch {
            Write-Warning "Failed to install to LocalMachine: $($_.Exception.Message)"
        }
    }
    
    if (-not $certInstalled) {
        try {
            $cert = Import-Certificate -FilePath $certPath -CertStoreLocation Cert:\CurrentUser\Root -ErrorAction Stop
            Write-Host "✓ Certificate installed to CurrentUser\Root" -ForegroundColor Green
            $certInstalled = $true
        }
        catch {
            Write-Error "Failed to install certificate: $($_.Exception.Message)"
            throw
        }
    }
    
    Write-Host "Step 3: Launching application installer..." -ForegroundColor Cyan
    
    # Launch AppInstaller
    $process = Start-Process -FilePath "ms-appinstaller:?source=$appInstallerUrl" -PassThru
    
    if ($process) {
        Write-Host "✓ App Installer launched successfully" -ForegroundColor Green
        Write-Host "Please follow the App Installer prompts to complete installation." -ForegroundColor Cyan
    } else {
        Write-Warning "Could not launch App Installer. Opening fallback URL..."
        Start-Process $appInstallerUrl
    }
    
    # Cleanup
    if (Test-Path $certPath) {
        Remove-Item $certPath -Force -ErrorAction SilentlyContinue
        Write-Host "✓ Temporary files cleaned up" -ForegroundColor Green
    }
    
    Write-Host "`n🎉 Installation process completed!" -ForegroundColor Green
    Write-Host "After App Installer finishes, you'll find 'App Usage Tracker' in your Start Menu." -ForegroundColor Cyan
    
} catch {
    Write-Error "❌ Installation failed: $($_.Exception.Message)"
    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Make sure you have an internet connection" -ForegroundColor Yellow
    Write-Host "2. Try running as Administrator" -ForegroundColor Yellow
    Write-Host "3. Check Windows version (requires Windows 10 1709+)" -ForegroundColor Yellow
    Write-Host "4. Try manual installation from the website" -ForegroundColor Yellow
    exit 1
}

if (-not $Silent) {
    Write-Host "`nPress any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
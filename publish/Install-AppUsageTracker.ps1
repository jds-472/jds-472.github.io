# App Usage Tracker - One-Click Installer
# This script installs the certificate and then launches the app installer

param(
    [switch]$Silent = $false
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Configuration
$BaseUrl = "https://jds-472.github.io/publish"
$CertificateUrl = "$BaseUrl/AppUsageTracker.cer"
$AppInstallerUrl = "$BaseUrl/AppUsageTracker.appinstaller"
$TempDir = [System.IO.Path]::GetTempPath()
$CertPath = Join-Path $TempDir "AppUsageTracker.cer"

function Write-Status {
    param([string]$Message, [string]$Color = "Green")
    if (-not $Silent) {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Test-AdminRights {
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

function Install-Certificate {
    param([string]$CertificatePath)
    
    try {
        # Import to Trusted Root Certification Authorities
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertificatePath)
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
        $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
        $store.Add($cert)
        $store.Close()
        
        Write-Status "✓ Certificate installed successfully" "Green"
        return $true
    }
    catch {
        Write-Status "✗ Failed to install certificate: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Start-AppInstaller {
    param([string]$AppInstallerUrl)
    
    try {
        Write-Status "Launching App Installer..." "Yellow"
        Start-Process "ms-appinstaller:?source=$AppInstallerUrl"
        Write-Status "✓ App Installer launched successfully" "Green"
        return $true
    }
    catch {
        Write-Status "✗ Failed to launch App Installer: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Main installation process
try {
    Write-Status "Starting App Usage Tracker installation..." "Cyan"
    Write-Status "=======================================" "Cyan"
    
    # Check if running as administrator
    if (-not (Test-AdminRights)) {
        Write-Status "Administrator privileges required for certificate installation." "Yellow"
        Write-Status "Attempting to restart as administrator..." "Yellow"
        
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`""
        if ($Silent) { $arguments += " -Silent" }
        
        Start-Process PowerShell -Verb RunAs -ArgumentList $arguments -Wait
        exit 0
    }
    
    Write-Status "Running with administrator privileges ✓" "Green"
    
    # Download certificate
    Write-Status "Downloading certificate..." "Yellow"
    try {
        Invoke-WebRequest -Uri $CertificateUrl -OutFile $CertPath -UseBasicParsing
        Write-Status "✓ Certificate downloaded" "Green"
    }
    catch {
        Write-Status "✗ Failed to download certificate: $($_.Exception.Message)" "Red"
        if (-not $Silent) {
            Read-Host "Press Enter to exit"
        }
        exit 1
    }
    
    # Install certificate
    Write-Status "Installing certificate..." "Yellow"
    if (-not (Install-Certificate -CertificatePath $CertPath)) {
        if (-not $Silent) {
            Read-Host "Press Enter to exit"
        }
        exit 1
    }
    
    # Clean up certificate file
    try {
        Remove-Item $CertPath -Force
    }
    catch {
        # Ignore cleanup errors
    }
    
    # Launch App Installer
    Write-Status "Starting application installation..." "Yellow"
    if (Start-AppInstaller -AppInstallerUrl $AppInstallerUrl) {
        Write-Status "=======================================" "Cyan"
        Write-Status "Installation process completed!" "Cyan"
        Write-Status "The App Installer should now be open." "Green"
        Write-Status "Follow the prompts to complete the installation." "Green"
    }
    else {
        Write-Status "Manual installation required:" "Yellow"
        Write-Status "Please visit: $AppInstallerUrl" "Yellow"
    }
    
    if (-not $Silent) {
        Write-Status ""
        Read-Host "Press Enter to exit"
    }
}
catch {
    Write-Status "✗ Installation failed: $($_.Exception.Message)" "Red"
    if (-not $Silent) {
        Read-Host "Press Enter to exit"
    }
    exit 1
}
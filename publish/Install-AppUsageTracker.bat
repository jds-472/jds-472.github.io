@echo off
setlocal EnableDelayedExpansion

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running with administrator privileges...
) else (
    echo This installer requires administrator privileges to install the certificate.
    echo Please run as administrator or the installation may fail.
    echo.
    pause
    echo Continuing anyway...
)

echo ========================================
echo App Usage Tracker Installer
echo ========================================
echo.

:: Set variables
set "TEMP_DIR=%TEMP%\AppUsageTracker"
set "CERT_URL=https://jds-472.github.io/publish/AppUsageTracker.cer"
set "APPINSTALLER_URL=https://jds-472.github.io/publish/AppUsageTracker.appinstaller"
set "CERT_FILE=%TEMP_DIR%\AppUsageTracker.cer"
set "APPINSTALLER_FILE=%TEMP_DIR%\AppUsageTracker.appinstaller"

:: Create temp directory
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

echo Step 1: Downloading certificate...
powershell -Command "try { Invoke-WebRequest -Uri '%CERT_URL%' -OutFile '%CERT_FILE%' -UseBasicParsing; Write-Host 'Certificate downloaded successfully' } catch { Write-Host 'Failed to download certificate: ' + $_.Exception.Message; exit 1 }"
if %errorLevel% neq 0 (
    echo Failed to download certificate!
    pause
    exit /b 1
)

echo Step 2: Installing certificate...
certutil -addstore -enterprise -f "Root" "%CERT_FILE%" >nul 2>&1
if %errorLevel% == 0 (
    echo Certificate installed successfully to Trusted Root Certification Authorities
) else (
    echo Warning: Failed to install certificate to machine store, trying user store...
    certutil -addstore -user -f "Root" "%CERT_FILE%" >nul 2>&1
    if %errorLevel% == 0 (
        echo Certificate installed to user store
    ) else (
        echo Failed to install certificate! You may need to install it manually.
        echo Certificate location: %CERT_FILE%
        pause
    )
)

echo Step 3: Downloading app installer...
powershell -Command "try { Invoke-WebRequest -Uri '%APPINSTALLER_URL%' -OutFile '%APPINSTALLER_FILE%' -UseBasicParsing; Write-Host 'App installer downloaded successfully' } catch { Write-Host 'Failed to download app installer: ' + $_.Exception.Message; exit 1 }"
if %errorLevel% neq 0 (
    echo Failed to download app installer!
    pause
    exit /b 1
)

echo Step 4: Launching app installer...
echo Opening Windows App Installer...
start "" "%APPINSTALLER_FILE%"

echo.
echo ========================================
echo Installation process initiated!
echo.
echo The Windows App Installer should now open.
echo Follow the prompts to complete the installation.
echo.
echo If the app installer doesn't open, you can manually
echo run the file located at: %APPINSTALLER_FILE%
echo ========================================
echo.

:: Ask if user wants to cleanup temp files
echo Would you like to keep the downloaded files for future use? (y/n)
set /p cleanup="Press 'n' and Enter to delete temp files, or just Enter to keep them: "
if /i "%cleanup%"=="n" (
    echo Cleaning up temporary files...
    del "%CERT_FILE%" 2>nul
    del "%APPINSTALLER_FILE%" 2>nul
    rmdir "%TEMP_DIR%" 2>nul
    echo Cleanup complete.
)

echo.
echo Installation script completed.
pause
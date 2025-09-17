@echo off
REM Example usage scenarios for Windows Regional Settings Reset
REM 
REM This file demonstrates various ways to use the reset script
REM Copy and modify these examples as needed

echo ========================================
echo Windows Regional Settings Reset Examples
echo ========================================
echo.

echo 1. Basic Reset to Polish (Default)
echo    reset-regional.bat
echo.

echo 2. Reset to English (US)
echo    reset-regional.bat en-US
echo.

echo 3. Reset to German without confirmation
echo    reset-regional.bat de-DE force
echo.

echo 4. PowerShell Direct Usage
echo    PowerShell -ExecutionPolicy Bypass -File Reset-RegionalSettings.ps1 -Locale "fr-FR"
echo.

echo 5. Automated Deployment (IT Scenario)
echo    FOR /F %%i IN (computers.txt) DO (
echo        psexec \\%%i -s reset-regional.bat pl-PL force
echo    )
echo.

echo 6. Check Supported Locales
echo    PowerShell -ExecutionPolicy Bypass -File Reset-RegionalSettings.ps1 -Locale "invalid"
echo.

echo Choose an example to execute or press any key to exit...
pause >nul
@echo off
REM ================================================================
REM Enhanced Example Usage Scenarios v2.0
REM Windows Regional Settings Reset - Comprehensive Examples
REM ================================================================
REM 
REM This file demonstrates various ways to use the enhanced reset
REM script suite with new features and capabilities.

echo ========================================
echo Windows Regional Settings Reset Examples v2.0
echo ========================================
echo.

echo === BASIC USAGE ===
echo.
echo 1. Basic Reset to Polish (Default)
echo    reset-regional.bat
echo.

echo 2. Reset to English (US) with Confirmation
echo    reset-regional.bat en-US
echo.

echo 3. Reset to German without Confirmation
echo    reset-regional.bat de-DE force
echo.

echo === ENHANCED FEATURES ===
echo.

echo 4. Silent Mode for Automation
echo    reset-regional.bat en-US silent
echo.

echo 5. Custom Configuration File
echo    reset-regional.bat config=custom.json
echo.

echo 6. Custom Log File Location
echo    reset-regional.bat fr-FR log=C:\Logs\regional.log
echo.

echo 7. Skip Backup Creation (Not Recommended)
echo    reset-regional.bat de-DE nobackup force
echo.

echo 8. Combined Options
echo    reset-regional.bat es-ES force config=enterprise.json log=\\server\logs\regional.log
echo.

echo === POWERSHELL DIRECT USAGE ===
echo.

echo 9. PowerShell with Configuration
echo    PowerShell -ExecutionPolicy Bypass -File Reset-RegionalSettings.ps1 -Locale "it-IT" -ConfigFile "config.json"
echo.

echo 10. PowerShell Restore from Backup
echo     PowerShell -ExecutionPolicy Bypass -File Reset-RegionalSettings.ps1 -RestoreFromBackup "C:\Temp\RegionalSettings_Backup_20231201_143022"
echo.

echo 11. PowerShell with Custom Log
echo     PowerShell -ExecutionPolicy Bypass -File Reset-RegionalSettings.ps1 -Locale "pt-PT" -LogPath "C:\Custom\regional.log"
echo.

echo === BACKUP MANAGEMENT ===
echo.

echo 12. List All Available Backups
echo     backup-manager.bat list
echo.

echo 13. Restore from Specific Backup
echo     backup-manager.bat restore RegionalSettings_Backup_20231201_143022
echo.

echo 14. Clean Backups Older Than 30 Days
echo     backup-manager.bat cleanup 30
echo.

echo 15. Verify Backup Integrity
echo     backup-manager.bat verify
echo.

echo === ENTERPRISE DEPLOYMENT SCENARIOS ===
echo.

echo 16. Corporate Workstation Setup
echo     FOR /F %%i IN (computers.txt) DO (
echo         psexec \\%%i -s reset-regional.bat en-US force log=\\server\logs\%%i_regional.log
echo     )
echo.

echo 17. Automated Deployment with Configuration
echo     FOR /F %%i IN (workstations.txt) DO (
echo         copy corporate.json \\%%i\c$\temp\
echo         psexec \\%%i -s reset-regional.bat config=c:\temp\corporate.json silent
echo     )
echo.

echo 18. Mass Backup Cleanup
echo     FOR /F %%i IN (servers.txt) DO (
echo         psexec \\%%i -s backup-manager.bat cleanup 14
echo     )
echo.

echo === TESTING AND VALIDATION ===
echo.

echo 19. Comprehensive System Validation
echo     validate.bat
echo.

echo 20. Check Current Regional Settings
echo     reg query "HKCU\Control Panel\International"
echo.

echo 21. PowerShell Locale Information
echo     powershell -Command "Get-WinSystemLocale; Get-WinUserLanguageList; Get-WinHomeLocation"
echo.

echo === TROUBLESHOOTING SCENARIOS ===
echo.

echo 22. Emergency Restore
echo     backup-manager.bat list
echo     backup-manager.bat restore [select-backup-from-list]
echo.

echo 23. Force Registry Access Test
echo     powershell -Command "Test-Path 'HKCU:\Control Panel\International'"
echo.

echo 24. Check PowerShell Execution Policy
echo     powershell -Command "Get-ExecutionPolicy"
echo.

echo 25. View Recent Log Files
echo     dir %TEMP%\RegionalSettings_*.log /od
echo.

echo === ADVANCED CONFIGURATION EXAMPLES ===
echo.

echo 26. Custom Configuration for Office Environment
echo     Content of office-config.json:
echo     {
echo       "defaultLocale": "en-US",
echo       "features": {
echo         "resetOfficeSettings": true,
echo         "resetBrowserSettings": false,
echo         "resetMruLists": true
echo       },
echo       "backup": {
echo         "retentionDays": 60,
echo         "customBackupPath": "\\server\backups\regional"
echo       }
echo     }
echo.

echo 27. Minimal Configuration for Kiosk Systems
echo     Content of kiosk-config.json:
echo     {
echo       "defaultLocale": "en-US",
echo       "skipBackup": true,
echo       "features": {
echo         "resetBrowserSettings": true,
echo         "resetOfficeSettings": false,
echo         "resetSystemLocale": false
echo       }
echo     }
echo.

echo === HELP AND INFORMATION ===
echo.

echo 28. Show Batch Wrapper Help
echo     reset-regional.bat /?
echo.

echo 29. Show Backup Manager Help
echo     backup-manager.bat /?
echo.

echo 30. Check Supported Locales
echo     PowerShell -ExecutionPolicy Bypass -File Reset-RegionalSettings.ps1 -Locale "invalid"
echo.

echo ========================================
echo.
echo Choose an example to execute, modify the commands as needed,
echo or press any key to exit...
echo.
echo For more information, see README.md
echo ========================================
echo.

pause >nul
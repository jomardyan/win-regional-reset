@echo off
REM ================================================================
REM Backup Manager for Windows Regional Settings Reset v2.0
REM ================================================================
REM This script provides advanced backup management capabilities
REM including restore, cleanup, and verification functions.

setlocal enabledelayedexpansion

set "VERSION=2.0"
set "SCRIPT_NAME=Regional Settings Backup Manager"

if "%~1"=="/?" goto :show_help
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help
if "%~1"=="help" goto :show_help

echo ========================================
echo %SCRIPT_NAME% v%VERSION%
echo ========================================
echo.

set "ACTION=%~1"
set "BACKUP_ROOT=%TEMP%"
set "ERROR_COUNT=0"

REM Check administrator privileges
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo ERROR: Administrator privileges required for backup operations.
    echo Please run as administrator.
    echo.
    pause
    exit /b 1
)

if "%ACTION%"=="" (
    echo No action specified. Use /? for help.
    goto :show_menu
)

goto :process_action

:show_menu
echo Available actions:
echo   1. List backups
echo   2. Restore from backup
echo   3. Clean old backups
echo   4. Verify backup integrity
echo   5. Exit
echo.
set /p "choice=Choose an action (1-5): "

if "%choice%"=="1" set "ACTION=list"
if "%choice%"=="2" set "ACTION=restore"
if "%choice%"=="3" set "ACTION=cleanup"
if "%choice%"=="4" set "ACTION=verify"
if "%choice%"=="5" exit /b 0

if "%ACTION%"=="" (
    echo Invalid choice. Please try again.
    echo.
    goto :show_menu
)

:process_action
echo Processing action: %ACTION%
echo.

if /i "%ACTION%"=="list" goto :list_backups
if /i "%ACTION%"=="restore" goto :restore_backup
if /i "%ACTION%"=="cleanup" goto :cleanup_backups
if /i "%ACTION%"=="verify" goto :verify_backups
if /i "%ACTION%"=="export" goto :export_backup
if /i "%ACTION%"=="import" goto :import_backup

echo Unknown action: %ACTION%
echo Use /? for help.
goto :final_exit

:list_backups
echo [ACTION] Listing available backups...
echo.

set "BACKUP_COUNT=0"
for /d %%d in ("%BACKUP_ROOT%\RegionalSettings_Backup_*") do (
    set /a BACKUP_COUNT+=1
    set "BACKUP_DIR=%%d"
    set "BACKUP_NAME=%%~nd"
    
    REM Extract date/time from folder name
    set "DATETIME=!BACKUP_NAME:RegionalSettings_Backup_=!"
    set "DATE_PART=!DATETIME:~0,8!"
    set "TIME_PART=!DATETIME:~9,6!"
    
    REM Format date and time
    set "FORMATTED_DATE=!DATE_PART:~0,4!-!DATE_PART:~4,2!-!DATE_PART:~6,2!"
    set "FORMATTED_TIME=!TIME_PART:~0,2!:!TIME_PART:~2,2!:!TIME_PART:~4,2!"
    
    echo Backup #!BACKUP_COUNT!:
    echo   Directory: %%~nd
    echo   Full Path: %%d
    echo   Date/Time: !FORMATTED_DATE! !FORMATTED_TIME!
    
    REM Count files in backup
    set "FILE_COUNT=0"
    for %%f in ("%%d\*.reg") do set /a FILE_COUNT+=1
    echo   Registry Files: !FILE_COUNT!
    
    REM Get folder size
    for /f "tokens=3" %%s in ('dir "%%d" ^| findstr /i "bytes"') do set "FOLDER_SIZE=%%s"
    echo   Size: !FOLDER_SIZE! bytes
    echo.
)

if %BACKUP_COUNT% EQU 0 (
    echo No backups found in %BACKUP_ROOT%
) else (
    echo Total backups found: %BACKUP_COUNT%
)

goto :action_complete

:restore_backup
echo [ACTION] Restoring from backup...
echo.

if "%~2"=="" (
    echo Available backups:
    call :list_backups >nul
    echo.
    set /p "BACKUP_FOLDER=Enter backup folder name (or full path): "
) else (
    set "BACKUP_FOLDER=%~2"
)

REM Validate backup folder
if not exist "%BACKUP_FOLDER%" (
    if exist "%BACKUP_ROOT%\%BACKUP_FOLDER%" (
        set "BACKUP_FOLDER=%BACKUP_ROOT%\%BACKUP_FOLDER%"
    ) else (
        echo ERROR: Backup folder not found: %BACKUP_FOLDER%
        set /a ERROR_COUNT+=1
        goto :action_complete
    )
)

echo Restoring from: %BACKUP_FOLDER%
echo.

REM Count registry files
set "REG_COUNT=0"
for %%f in ("%BACKUP_FOLDER%\*.reg") do set /a REG_COUNT+=1

if %REG_COUNT% EQU 0 (
    echo ERROR: No registry files found in backup folder.
    set /a ERROR_COUNT+=1
    goto :action_complete
)

echo Found %REG_COUNT% registry file(s) to restore.
echo.
echo WARNING: This will overwrite current registry settings!
set /p "CONFIRM=Are you sure you want to continue? (y/N): "

if /i not "%CONFIRM%"=="y" (
    echo Restore operation cancelled.
    goto :action_complete
)

echo.
echo Restoring registry files...

set "RESTORED_COUNT=0"
set "FAILED_COUNT=0"

for %%f in ("%BACKUP_FOLDER%\*.reg") do (
    echo Restoring: %%~nf.reg
    reg import "%%f" >nul 2>&1
    if !errorLevel! EQU 0 (
        set /a RESTORED_COUNT+=1
        echo   [SUCCESS] %%~nf.reg
    ) else (
        set /a FAILED_COUNT+=1
        set /a ERROR_COUNT+=1
        echo   [FAILED] %%~nf.reg
    )
)

echo.
echo Restore Summary:
echo   Successfully restored: %RESTORED_COUNT%
echo   Failed to restore: %FAILED_COUNT%

if %FAILED_COUNT% EQU 0 (
    echo.
    echo All registry files restored successfully!
    echo A system restart is recommended for changes to take effect.
) else (
    echo.
    echo Some files failed to restore. Check permissions and try again.
)

goto :action_complete

:cleanup_backups
echo [ACTION] Cleaning up old backups...
echo.

if "%~2"=="" (
    set /p "DAYS=Enter number of days to keep (default 30): "
    if "!DAYS!"=="" set "DAYS=30"
) else (
    set "DAYS=%~2"
)

echo Cleaning backups older than %DAYS% days...
echo.

REM Calculate cutoff date
powershell -Command "(Get-Date).AddDays(-%DAYS%).ToString('yyyyMMdd')" > "%TEMP%\cutoff_date.tmp"
set /p CUTOFF_DATE=<"%TEMP%\cutoff_date.tmp"
del "%TEMP%\cutoff_date.tmp"

echo Cutoff date: %CUTOFF_DATE%
echo.

set "DELETED_COUNT=0"
set "KEPT_COUNT=0"

for /d %%d in ("%BACKUP_ROOT%\RegionalSettings_Backup_*") do (
    set "BACKUP_NAME=%%~nd"
    set "DATETIME=!BACKUP_NAME:RegionalSettings_Backup_=!"
    set "DATE_PART=!DATETIME:~0,8!"
    
    if !DATE_PART! LSS %CUTOFF_DATE% (
        echo Deleting old backup: %%~nd
        rmdir /s /q "%%d" >nul 2>&1
        if !errorLevel! EQU 0 (
            set /a DELETED_COUNT+=1
        ) else (
            echo   [ERROR] Could not delete %%~nd
            set /a ERROR_COUNT+=1
        )
    ) else (
        set /a KEPT_COUNT+=1
    )
)

echo.
echo Cleanup Summary:
echo   Backups deleted: %DELETED_COUNT%
echo   Backups kept: %KEPT_COUNT%

goto :action_complete

:verify_backups
echo [ACTION] Verifying backup integrity...
echo.

set "VERIFIED_COUNT=0"
set "CORRUPTED_COUNT=0"

for /d %%d in ("%BACKUP_ROOT%\RegionalSettings_Backup_*") do (
    echo Verifying: %%~nd
    set "BACKUP_VALID=1"
    
    REM Check if folder contains .reg files
    set "REG_FILE_COUNT=0"
    for %%f in ("%%d\*.reg") do set /a REG_FILE_COUNT+=1
    
    if !REG_FILE_COUNT! EQU 0 (
        echo   [ERROR] No registry files found
        set "BACKUP_VALID=0"
    ) else (
        echo   [INFO] Found !REG_FILE_COUNT! registry files
        
        REM Verify each .reg file
        for %%f in ("%%d\*.reg") do (
            REM Check if file is readable and has content
            for %%z in ("%%f") do (
                if %%~zz EQU 0 (
                    echo   [ERROR] Empty file: %%~nf.reg
                    set "BACKUP_VALID=0"
                ) else (
                    REM Basic syntax check
                    findstr /i "Windows Registry Editor" "%%f" >nul
                    if !errorLevel! NEQ 0 (
                        echo   [ERROR] Invalid registry file: %%~nf.reg
                        set "BACKUP_VALID=0"
                    )
                )
            )
        )
    )
    
    if !BACKUP_VALID! EQU 1 (
        echo   [PASS] Backup is valid
        set /a VERIFIED_COUNT+=1
    ) else (
        echo   [FAIL] Backup is corrupted or incomplete
        set /a CORRUPTED_COUNT+=1
        set /a ERROR_COUNT+=1
    )
    echo.
)

echo Verification Summary:
echo   Valid backups: %VERIFIED_COUNT%
echo   Corrupted backups: %CORRUPTED_COUNT%

goto :action_complete

:show_help
echo %SCRIPT_NAME% v%VERSION%
echo.
echo DESCRIPTION:
echo   Advanced backup management for Windows Regional Settings Reset.
echo   Provides restore, cleanup, and verification capabilities.
echo.
echo USAGE:
echo   %~nx0 [action] [parameters]
echo.
echo ACTIONS:
echo   list                    List all available backups
echo   restore [folder]        Restore from specified backup folder
echo   cleanup [days]          Remove backups older than specified days
echo   verify                  Verify integrity of all backups
echo   export [folder] [file]  Export backup to compressed file
echo   import [file]           Import backup from compressed file
echo.
echo EXAMPLES:
echo   %~nx0 list
echo   %~nx0 restore RegionalSettings_Backup_20231201_143022
echo   %~nx0 cleanup 30
echo   %~nx0 verify
echo.
echo NOTES:
echo   - Requires Administrator privileges
echo   - Backups are stored in %%TEMP%% by default
echo   - Registry imports may require system restart
echo.
goto :final_exit

:action_complete
echo.
if %ERROR_COUNT% EQU 0 (
    echo Action completed successfully.
) else (
    echo Action completed with %ERROR_COUNT% error(s).
)

:final_exit
echo.
pause
exit /b %ERROR_COUNT%
@echo off
REM ================================================================
REM Scheduled Task Manager for Regional Settings Reset v2.0
REM ================================================================
REM This script creates and manages scheduled tasks for automatic
REM backup and maintenance of regional settings.

setlocal enabledelayedexpansion

set "VERSION=2.0"
set "SCRIPT_NAME=Regional Settings Scheduler"

if "%~1"=="/?" goto :show_help
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help
if "%~1"=="help" goto :show_help

echo ========================================
echo %SCRIPT_NAME% v%VERSION%
echo ========================================
echo.

set "ACTION=%~1"
set "FREQUENCY=%~2"
set "TIME=%~3"

REM Check administrator privileges
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo ERROR: Administrator privileges required for scheduled task operations.
    echo Please run as administrator.
    echo.
    pause
    exit /b 1
)

if "%ACTION%"=="" goto :show_menu

goto :process_action

:show_menu
echo Available actions:
echo   1. Create backup schedule
echo   2. Create maintenance schedule  
echo   3. List scheduled tasks
echo   4. Remove scheduled tasks
echo   5. Run task now
echo   6. Exit
echo.
set /p "choice=Choose an action (1-6): "

if "%choice%"=="1" set "ACTION=create-backup"
if "%choice%"=="2" set "ACTION=create-maintenance"
if "%choice%"=="3" set "ACTION=list"
if "%choice%"=="4" set "ACTION=remove"
if "%choice%"=="5" set "ACTION=run-now"
if "%choice%"=="6" exit /b 0

if "%ACTION%"=="" (
    echo Invalid choice. Please try again.
    echo.
    goto :show_menu
)

:process_action
echo Processing action: %ACTION%
echo.

if /i "%ACTION%"=="create-backup" goto :create_backup_schedule
if /i "%ACTION%"=="create-maintenance" goto :create_maintenance_schedule
if /i "%ACTION%"=="list" goto :list_tasks
if /i "%ACTION%"=="remove" goto :remove_tasks
if /i "%ACTION%"=="run-now" goto :run_task_now

echo Unknown action: %ACTION%
goto :show_help

:create_backup_schedule
echo [ACTION] Creating backup schedule...
echo.

if "%FREQUENCY%"=="" (
    echo Available frequencies:
    echo   DAILY - Run every day
    echo   WEEKLY - Run weekly
    echo   MONTHLY - Run monthly
    echo.
    set /p "FREQUENCY=Enter frequency (DAILY/WEEKLY/MONTHLY): "
)

if "%TIME%"=="" (
    set /p "TIME=Enter time (HH:MM format, e.g., 14:30): "
)

set "TASK_NAME=RegionalSettings_AutoBackup"
set "SCRIPT_PATH=%~dp0backup-manager.bat"

echo Creating scheduled task: %TASK_NAME%
echo Frequency: %FREQUENCY%
echo Time: %TIME%
echo Script: %SCRIPT_PATH%
echo.

schtasks /create /tn "%TASK_NAME%" /tr "\"%SCRIPT_PATH%\" create" /sc %FREQUENCY% /st %TIME% /ru "SYSTEM" /f

if %errorLevel% EQU 0 (
    echo [SUCCESS] Backup schedule created successfully.
    echo Task will run %FREQUENCY% at %TIME%
) else (
    echo [ERROR] Failed to create backup schedule.
)

goto :action_complete

:create_maintenance_schedule
echo [ACTION] Creating maintenance schedule...
echo.

if "%FREQUENCY%"=="" (
    echo Available frequencies:
    echo   WEEKLY - Run weekly (recommended)
    echo   MONTHLY - Run monthly
    echo.
    set /p "FREQUENCY=Enter frequency (WEEKLY/MONTHLY): "
)

if "%TIME%"=="" (
    set /p "TIME=Enter time (HH:MM format, e.g., 02:00): "
)

set "TASK_NAME=RegionalSettings_Maintenance"
set "SCRIPT_PATH=%~dp0backup-manager.bat"

echo Creating scheduled task: %TASK_NAME%
echo Frequency: %FREQUENCY%
echo Time: %TIME%
echo Script: %SCRIPT_PATH%
echo.

schtasks /create /tn "%TASK_NAME%" /tr "\"%SCRIPT_PATH%\" cleanup 30" /sc %FREQUENCY% /st %TIME% /ru "SYSTEM" /f

if %errorLevel% EQU 0 (
    echo [SUCCESS] Maintenance schedule created successfully.
    echo Task will run %FREQUENCY% at %TIME% to clean old backups
) else (
    echo [ERROR] Failed to create maintenance schedule.
)

goto :action_complete

:list_tasks
echo [ACTION] Listing scheduled tasks...
echo.

echo Regional Settings related tasks:
schtasks /query /tn "RegionalSettings_*" /fo TABLE /nh 2>nul

if %errorLevel% NEQ 0 (
    echo No Regional Settings scheduled tasks found.
)

goto :action_complete

:remove_tasks
echo [ACTION] Removing scheduled tasks...
echo.

echo Available tasks to remove:
schtasks /query /tn "RegionalSettings_*" /fo LIST 2>nul

if %errorLevel% NEQ 0 (
    echo No Regional Settings scheduled tasks found.
    goto :action_complete
)

echo.
set /p "TASK_NAME=Enter task name to remove (or 'ALL' for all tasks): "

if /i "%TASK_NAME%"=="ALL" (
    echo Removing all Regional Settings tasks...
    for /f "tokens=*" %%t in ('schtasks /query /tn "RegionalSettings_*" /fo LIST ^| findstr "TaskName:"') do (
        for /f "tokens=2*" %%a in ("%%t") do (
            echo Removing: %%b
            schtasks /delete /tn "%%b" /f >nul 2>&1
        )
    )
    echo [SUCCESS] All Regional Settings tasks removed.
) else (
    echo Removing task: %TASK_NAME%
    schtasks /delete /tn "%TASK_NAME%" /f
    
    if %errorLevel% EQU 0 (
        echo [SUCCESS] Task removed successfully.
    ) else (
        echo [ERROR] Failed to remove task.
    )
)

goto :action_complete

:run_task_now
echo [ACTION] Running scheduled task now...
echo.

echo Available tasks:
schtasks /query /tn "RegionalSettings_*" /fo LIST 2>nul

if %errorLevel% NEQ 0 (
    echo No Regional Settings scheduled tasks found.
    goto :action_complete
)

echo.
set /p "TASK_NAME=Enter task name to run: "

echo Running task: %TASK_NAME%
schtasks /run /tn "%TASK_NAME%"

if %errorLevel% EQU 0 (
    echo [SUCCESS] Task started successfully.
    echo Check Task Scheduler for execution status.
) else (
    echo [ERROR] Failed to start task.
)

goto :action_complete

:show_help
echo USAGE:
echo   %~nx0 [action] [frequency] [time]
echo.
echo ACTIONS:
echo   create-backup [DAILY^|WEEKLY^|MONTHLY] [HH:MM]    Create backup schedule
echo   create-maintenance [WEEKLY^|MONTHLY] [HH:MM]     Create maintenance schedule
echo   list                                           List all scheduled tasks
echo   remove [task_name^|ALL]                        Remove scheduled tasks
echo   run-now [task_name]                           Run task immediately
echo.
echo EXAMPLES:
echo   %~nx0 create-backup DAILY 14:30
echo   %~nx0 create-maintenance WEEKLY 02:00
echo   %~nx0 list
echo   %~nx0 remove RegionalSettings_AutoBackup
echo   %~nx0 run-now RegionalSettings_AutoBackup
echo.
echo NOTES:
echo   - Requires Administrator privileges
echo   - Tasks run with SYSTEM privileges
echo   - Backup tasks create registry backups
echo   - Maintenance tasks clean old backup files
echo.
goto :final_exit

:action_complete
echo.
echo Action completed.

:final_exit
echo.
pause
exit /b 0
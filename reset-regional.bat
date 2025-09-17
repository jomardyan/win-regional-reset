@echo off
setlocal enabledelayedexpansion

REM ================================================================
REM Windows Regional Settings Reset - Batch Wrapper
REM ================================================================
REM This batch file provides an easy way to execute the PowerShell
REM script for resetting Windows regional settings.
REM
REM Usage:
REM   reset-regional.bat                    - Reset to Polish (default)
REM   reset-regional.bat en-US             - Reset to English (US)
REM   reset-regional.bat de-DE force       - Reset to German with no prompts
REM ================================================================

echo.
echo ========================================
echo Windows Regional Settings Reset
echo ========================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo ERROR: This script requires Administrator privileges.
    echo.
    echo Please right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

REM Get script directory
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%Reset-RegionalSettings.ps1"

REM Check if PowerShell script exists
if not exist "%PS_SCRIPT%" (
    echo ERROR: PowerShell script not found: %PS_SCRIPT%
    echo.
    pause
    exit /b 1
)

REM Parse command line arguments
set "LOCALE=pl-PL"
set "FORCE_FLAG="

if not "%~1"=="" (
    set "LOCALE=%~1"
)

if not "%~2"=="" (
    if /i "%~2"=="force" (
        set "FORCE_FLAG=-Force"
    )
)

if not "%~1"=="" (
    if /i "%~1"=="force" (
        set "LOCALE=pl-PL"
        set "FORCE_FLAG=-Force"
    )
)

echo Target Locale: %LOCALE%
if not "%FORCE_FLAG%"=="" (
    echo Force Mode: Enabled
)
echo.

REM Check PowerShell execution policy
powershell -Command "Get-ExecutionPolicy" | findstr /i "restricted" >nul
if %errorLevel% EQU 0 (
    echo WARNING: PowerShell execution policy is Restricted.
    echo This may prevent the script from running.
    echo.
    echo You can change it temporarily by running:
    echo   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
    echo.
    set /p "continue=Continue anyway? (y/N): "
    if /i not "!continue!"=="y" (
        echo Operation cancelled.
        pause
        exit /b 1
    )
    echo.
)

REM Execute PowerShell script
echo Executing PowerShell script...
echo.

powershell -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Locale "%LOCALE%" %FORCE_FLAG%

set "PS_EXIT_CODE=%errorLevel%"

echo.
if %PS_EXIT_CODE% EQU 0 (
    echo Batch script completed successfully.
) else (
    echo Batch script completed with errors. Exit code: %PS_EXIT_CODE%
)

echo.
pause
exit /b %PS_EXIT_CODE%
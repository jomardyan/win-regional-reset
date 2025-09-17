@echo off
setlocal enabledelayedexpansion

REM ================================================================
REM Windows Regional Settings Reset - Enhanced Batch Wrapper v2.0
REM ================================================================
REM This batch file provides an enhanced interface for executing the
REM PowerShell script for resetting Windows regional settings.
REM
REM Usage:
REM   reset-regional.bat [locale] [options]
REM
REM Parameters:
REM   locale      - Target locale (e.g., pl-PL, en-US, de-DE)
REM   options     - Additional options:
                   force, silent, nobackup, config=file
REM
REM Examples:
REM   reset-regional.bat                    - Reset to default (Polish)
REM   reset-regional.bat en-US             - Reset to English (US)
REM   reset-regional.bat de-DE force       - Reset to German with no prompts
REM   reset-regional.bat silent            - Silent execution with default locale
REM   reset-regional.bat config=custom.json - Use custom configuration
REM   reset-regional.bat /?                - Show this help
REM ================================================================

set "VERSION=2.0"
set "SCRIPT_NAME=Windows Regional Settings Reset"
set "ERROR_LEVEL=0"

REM Parse help request first
if "%~1"=="/?" goto :show_help
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help
if "%~1"=="help" goto :show_help

REM Initialize variables
set "LOCALE=pl-PL"
set "FORCE_FLAG="
set "SILENT_MODE=0"
set "CONFIG_FILE="
set "NOBACKUP_FLAG="
set "LOG_FILE="
set "SHOW_BANNER=1"

REM Show banner unless in silent mode
if "%SILENT_MODE%"=="0" (
    echo.
    echo ========================================
    echo %SCRIPT_NAME% v%VERSION%
    echo ========================================
    echo.
)

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

REM Enhanced parameter parsing
set "PARAM_COUNT=0"
for %%i in (%*) do set /a PARAM_COUNT+=1

REM Parse all parameters
set "PARAM_INDEX=1"
:parse_params
if %PARAM_INDEX% GTR %PARAM_COUNT% goto :params_done

REM Get current parameter
set "CURRENT_PARAM="
for /f "tokens=%PARAM_INDEX%" %%i in ("%*") do set "CURRENT_PARAM=%%i"

REM Check parameter type
echo %CURRENT_PARAM% | findstr /i "^force$" >nul
if %errorLevel% EQU 0 (
    set "FORCE_FLAG=-Force"
    goto :next_param
)

echo %CURRENT_PARAM% | findstr /i "^silent$" >nul
if %errorLevel% EQU 0 (
    set "SILENT_MODE=1"
    set "SHOW_BANNER=0"
    goto :next_param
)

echo %CURRENT_PARAM% | findstr /i "^nobackup$" >nul
if %errorLevel% EQU 0 (
    set "NOBACKUP_FLAG=-SkipBackup"
    goto :next_param
)

echo %CURRENT_PARAM% | findstr /i "^config=" >nul
if %errorLevel% EQU 0 (
    for /f "tokens=2 delims==" %%j in ("%CURRENT_PARAM%") do set "CONFIG_FILE=%%j"
    goto :next_param
)

echo %CURRENT_PARAM% | findstr /i "^log=" >nul
if %errorLevel% EQU 0 (
    for /f "tokens=2 delims==" %%j in ("%CURRENT_PARAM%") do set "LOG_FILE=%%j"
    goto :next_param
)

REM Check if it's a locale (contains dash)
echo %CURRENT_PARAM% | findstr "-" >nul
if %errorLevel% EQU 0 (
    set "LOCALE=%CURRENT_PARAM%"
    goto :next_param
)

REM Unknown parameter
if "%SILENT_MODE%"=="0" (
    echo WARNING: Unknown parameter: %CURRENT_PARAM%
    echo.
)

:next_param
set /a PARAM_INDEX+=1
goto :parse_params

:params_done

REM Build PowerShell command with all parameters
set "PS_PARAMS=-Locale \"%LOCALE%\""
if not "%FORCE_FLAG%"=="" set "PS_PARAMS=%PS_PARAMS% %FORCE_FLAG%"
if not "%CONFIG_FILE%"=="" set "PS_PARAMS=%PS_PARAMS% -ConfigFile \"%CONFIG_FILE%\""
if not "%LOG_FILE%"=="" set "PS_PARAMS=%PS_PARAMS% -LogPath \"%LOG_FILE%\""
if not "%NOBACKUP_FLAG%"=="" set "PS_PARAMS=%PS_PARAMS% %NOBACKUP_FLAG%"

REM Show execution details unless in silent mode
if "%SILENT_MODE%"=="0" (
    echo Target Locale: %LOCALE%
    if not "%FORCE_FLAG%"=="" echo Force Mode: Enabled
    if not "%CONFIG_FILE%"=="" echo Configuration File: %CONFIG_FILE%
    if not "%LOG_FILE%"=="" echo Custom Log File: %LOG_FILE%
    if not "%NOBACKUP_FLAG%"=="" echo Backup: Disabled
    echo.
)

REM Validate configuration file if specified
if not "%CONFIG_FILE%"=="" (
    if not exist "%CONFIG_FILE%" (
        echo ERROR: Configuration file not found: %CONFIG_FILE%
        echo.
        goto :error_exit
    )
    if "%SILENT_MODE%"=="0" echo Configuration file validated: %CONFIG_FILE%
)

REM Execute PowerShell script with enhanced error handling
if "%SILENT_MODE%"=="0" (
    echo Executing PowerShell script...
    echo Command: powershell -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %PS_PARAMS%
    echo.
)

powershell -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %PS_PARAMS%
set "PS_EXIT_CODE=%errorLevel%"

REM Handle different exit codes
if "%SILENT_MODE%"=="0" (
    echo.
    if %PS_EXIT_CODE% EQU 0 (
        echo Script completed successfully.
    ) else if %PS_EXIT_CODE% EQU 1 (
        echo Script failed with critical errors.
        set "ERROR_LEVEL=1"
    ) else if %PS_EXIT_CODE% EQU 2 (
        echo Script completed with some warnings/failures.
        echo Check the log file for details.
        set "ERROR_LEVEL=2"
    ) else (
        echo Script completed with unknown exit code: %PS_EXIT_CODE%
        set "ERROR_LEVEL=%PS_EXIT_CODE%"
    )
) else (
    REM In silent mode, only output critical errors
    if %PS_EXIT_CODE% GTR 0 (
        echo SILENT_ERROR: Script failed with exit code %PS_EXIT_CODE%
    )
)

goto :final_exit

:show_help
echo %SCRIPT_NAME% v%VERSION%
echo.
echo DESCRIPTION:
echo   Resets all Windows regional settings to a specified locale.
echo   Includes Windows 11 registry memory slots and comprehensive
echo   application settings reset.
echo.
echo USAGE:
echo   %~nx0 [locale] [options]
echo.
echo PARAMETERS:
echo   locale          Target locale code (default: pl-PL)
echo                   Supported: pl-PL, en-US, en-GB, de-DE, fr-FR,
echo                             es-ES, it-IT, pt-PT, ru-RU, zh-CN,
echo                             ja-JP, ko-KR
echo.
echo OPTIONS:
echo   force           Skip confirmation prompts
echo   silent          Run in silent mode (minimal output)
echo   nobackup        Skip registry backup creation
echo   config=file     Use custom configuration file
echo   log=file        Specify custom log file path
echo   /?, -h, help    Show this help message
echo.
echo EXAMPLES:
echo   %~nx0                         Reset to Polish (default) with prompts
echo   %~nx0 en-US                   Reset to English (US) with prompts
echo   %~nx0 de-DE force             Reset to German without prompts
echo   %~nx0 silent                  Silent reset to default locale
echo   %~nx0 fr-FR config=custom.json Use custom configuration
echo   %~nx0 en-GB log=custom.log    Reset with custom log file
echo.
echo REQUIREMENTS:
echo   - Windows 10/11
echo   - Administrator privileges
echo   - PowerShell 5.0 or later
echo.
echo For more information, see README.md
echo.
goto :final_exit

:error_exit
set "ERROR_LEVEL=1"
if "%SILENT_MODE%"=="0" pause
goto :final_exit

:final_exit
if "%SILENT_MODE%"=="0" (
    echo.
    if %ERROR_LEVEL% EQU 0 (
        echo Batch wrapper completed successfully.
    ) else (
        echo Batch wrapper completed with errors. Exit code: %ERROR_LEVEL%
    )
    echo.
    pause
)
exit /b %ERROR_LEVEL%